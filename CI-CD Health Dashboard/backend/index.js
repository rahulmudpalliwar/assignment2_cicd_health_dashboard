import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import pkg from 'pg';
const { Pool } = pkg;
import nodemailer from 'nodemailer';

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

const port = process.env.PORT || 3000;
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

// Optional integrations
const githubToken = process.env.GITHUB_TOKEN || '';
const githubRepos = (process.env.GITHUB_REPOS || '').split(',').map(s => s.trim()).filter(Boolean);
const jenkinsBaseUrl = process.env.JENKINS_BASE_URL || '';
const jenkinsUser = process.env.JENKINS_USER || '';
const jenkinsToken = process.env.JENKINS_TOKEN || '';

// Optional alerts configuration (email only)
const smtpHost = process.env.SMTP_HOST || '';
const smtpPort = Number(process.env.SMTP_PORT || 587);
const smtpUser = process.env.SMTP_USER || '';
const smtpPass = process.env.SMTP_PASS || '';
const alertFrom = process.env.ALERT_FROM || 'CI/CD Dashboard <noreply@example.com>';
const alertTo = (process.env.ALERT_TO || '').split(',').map(s => s.trim()).filter(Boolean);

let mailer = null;
if (smtpHost) {
  const base = { host: smtpHost, port: smtpPort, secure: smtpPort === 465 };
  if (smtpUser && smtpPass) {
    mailer = nodemailer.createTransport({ ...base, auth: { user: smtpUser, pass: smtpPass } });
  } else {
    // Allow unauthenticated SMTP (e.g., MailHog/mailcatcher) for local/dev
    mailer = nodemailer.createTransport(base);
  }
} else {
  // Fallback: no SMTP configured, use JSON transport (simulates send, prints to console)
  mailer = nodemailer.createTransport({ jsonTransport: true });
}

async function upsertBuild(build) {
  const {
    tool,
    external_id,
    repo,
    branch,
    status,
    conclusion,
    started_at,
    completed_at,
    duration_seconds,
    url,
    logs
  } = build;
  const result = await pool.query(
    `INSERT INTO builds (tool, external_id, repo, branch, status, conclusion, started_at, completed_at, duration_seconds, url, logs)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
     ON CONFLICT (external_id)
     DO UPDATE SET repo=EXCLUDED.repo, branch=EXCLUDED.branch, status=EXCLUDED.status, conclusion=EXCLUDED.conclusion,
                   started_at=EXCLUDED.started_at, completed_at=EXCLUDED.completed_at, duration_seconds=EXCLUDED.duration_seconds,
                   url=EXCLUDED.url, logs=COALESCE(EXCLUDED.logs, builds.logs)
     RETURNING id, conclusion`,
    [tool, external_id, repo, branch, status, conclusion, started_at, completed_at, duration_seconds, url, logs || null]
  );
  const row = result.rows[0];
  if (row && row.conclusion === 'failure') {
    await sendAlertIfNeeded(row.id, build);
  }
  return row;
}

async function sendAlertIfNeeded(buildId, build) {
  const existing = await pool.query('SELECT id FROM alerts WHERE build_id=$1 LIMIT 1', [buildId]);
  if (existing.rowCount > 0) return;

  const title = `[ALERT] ${build.tool} failed: ${build.repo || ''} ${build.branch ? '('+build.branch+')' : ''}`.trim();
  const text = `${title}\nStatus: ${build.status}\nConclusion: ${build.conclusion}\nURL: ${build.url || 'n/a'}\nCompleted: ${build.completed_at || 'n/a'}`;

  // Email only
  if (mailer && alertTo.length > 0) {
    try {
      await mailer.sendMail({ from: alertFrom, to: alertTo.join(','), subject: title, text });
      await pool.query('INSERT INTO alerts (build_id, recipient, channel) VALUES ($1,$2,$3)', [buildId, alertTo.join(','), 'email']);
    } catch (_) {}
  }
}

async function pollGitHubActions() {
  if (!githubToken || githubRepos.length === 0) return;
  for (const repo of githubRepos) {
    try {
      const resp = await fetch(`https://api.github.com/repos/${repo}/actions/runs?per_page=20`, {
        headers: { Authorization: `Bearer ${githubToken}`, 'Accept': 'application/vnd.github+json', 'User-Agent': 'cicd-dashboard' }
      });
      if (!resp.ok) continue;
      const data = await resp.json();
      for (const run of (data.workflow_runs || [])) {
        const build = {
          tool: 'github',
          external_id: String(run.id),
          repo,
          branch: run.head_branch || null,
          status: run.status || null,
          conclusion: run.conclusion || (run.status === 'completed' ? 'unknown' : null),
          started_at: run.run_started_at ? new Date(run.run_started_at) : null,
          completed_at: run.updated_at ? new Date(run.updated_at) : null,
          duration_seconds: run.run_started_at && run.updated_at ? Math.max(0, Math.round((new Date(run.updated_at) - new Date(run.run_started_at)) / 1000)) : null,
          url: run.html_url || null,
          logs: null
        };
        await upsertBuild(build);
      }
    } catch (_) {}
  }
}

async function pollJenkins() {
  if (!jenkinsBaseUrl || !jenkinsUser || !jenkinsToken) return;
  try {
    const resp = await fetch(`${jenkinsBaseUrl}/api/json?tree=jobs[name,url,builds[number,result,timestamp,duration,fullDisplayName,url]]`, {
      headers: { 'Authorization': 'Basic ' + Buffer.from(`${jenkinsUser}:${jenkinsToken}`).toString('base64') }
    });
    if (!resp.ok) return;
    const data = await resp.json();
    for (const job of (data.jobs || [])) {
      for (const b of (job.builds || []).slice(0, 20)) {
        const startedAt = b.timestamp ? new Date(b.timestamp) : null;
        const completedAt = b.timestamp && b.duration ? new Date(b.timestamp + b.duration) : null;
        const build = {
          tool: 'jenkins',
          external_id: `${job.name}-${b.number}`,
          repo: job.name,
          branch: null,
          status: completedAt ? 'completed' : 'in_progress',
          conclusion: b.result ? String(b.result).toLowerCase() : (completedAt ? 'unknown' : null),
          started_at: startedAt,
          completed_at: completedAt,
          duration_seconds: b.duration ? Math.round(b.duration / 1000) : null,
          url: b.url || job.url || null,
          logs: null
        };
        await upsertBuild(build);
      }
    }
  } catch (_) {}
}

app.get('/api/health', async (req, res) => {
  try { await pool.query('SELECT 1'); res.json({ ok: true }); }
  catch(e){ res.status(500).json({ ok: false }); }
});

app.get('/api/metrics', async (req, res) => {
  const stats = await pool.query("SELECT COUNT(*) FILTER (WHERE conclusion='success') AS successes, COUNT(*) FILTER (WHERE conclusion='failure') AS failures, AVG(duration_seconds) AS avg_duration FROM builds");
  const last = await pool.query("SELECT status, conclusion, repo, tool, completed_at FROM builds ORDER BY completed_at DESC NULLS LAST, started_at DESC NULLS LAST LIMIT 1");
  const s = Number(stats.rows[0]?.successes||0), f=Number(stats.rows[0]?.failures||0), t=s+f; 
  res.json({ successRate: t? s/t:0, failureRate: t? f/t:0, avgBuildTimeSeconds: stats.rows[0]?.avg_duration? Number(stats.rows[0].avg_duration):0, lastBuild: last.rows[0]||null });
});

app.get('/api/builds', async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit||'50'),200);
  const result = await pool.query('SELECT id, tool, repo, branch, status, conclusion, duration_seconds, url, started_at, completed_at FROM builds ORDER BY started_at DESC NULLS LAST LIMIT $1',[limit]);
  res.json(result.rows);
});

app.get('/api/builds/:id/logs', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (!id) return res.status(400).json({ error: 'invalid id' });
  const result = await pool.query('SELECT logs FROM builds WHERE id=$1 LIMIT 1', [id]);
  if (result.rowCount === 0) return res.status(404).json({ error: 'not found' });
  res.json({ logs: result.rows[0].logs || '' });
});

// Webhooks (optional)
app.post('/api/webhook/github', async (req, res) => {
  try {
    const run = req.body.workflow_run || req.body;
    if (!run || !run.id) return res.status(400).json({ ok: false });
    const repo = (req.body.repository && req.body.repository.full_name) || run.repository?.full_name || '';
    const build = {
      tool: 'github',
      external_id: String(run.id),
      repo,
      branch: run.head_branch || null,
      status: run.status || null,
      conclusion: run.conclusion || null,
      started_at: run.run_started_at ? new Date(run.run_started_at) : null,
      completed_at: run.updated_at ? new Date(run.updated_at) : null,
      duration_seconds: run.run_started_at && run.updated_at ? Math.max(0, Math.round((new Date(run.updated_at) - new Date(run.run_started_at)) / 1000)) : null,
      url: run.html_url || null,
      logs: null
    };
    const row = await upsertBuild(build);
    res.json({ ok: true, id: row?.id });
  } catch (e) { res.status(500).json({ ok: false }); }
});

app.post('/api/webhook/jenkins', async (req, res) => {
  try {
    const b = req.body;
    if (!b || (!b.name && !b.jobName)) return res.status(400).json({ ok: false });
    const name = b.name || b.jobName;
    const number = b.number || b.build?.number || 'unknown';
    const startedAt = b.timestamp ? new Date(b.timestamp) : null;
    const durationMs = b.duration || b.build?.duration || 0;
    const completedAt = startedAt && durationMs ? new Date(startedAt.getTime() + durationMs) : null;
    const build = {
      tool: 'jenkins',
      external_id: `${name}-${number}`,
      repo: name,
      branch: null,
      status: completedAt ? 'completed' : 'in_progress',
      conclusion: (b.result || b.build?.status || '').toLowerCase() || (completedAt ? 'unknown' : null),
      started_at: startedAt,
      completed_at: completedAt,
      duration_seconds: durationMs ? Math.round(durationMs / 1000) : null,
      url: b.build?.full_url || b.url || null,
      logs: null
    };
    const row = await upsertBuild(build);
    res.json({ ok: true, id: row?.id });
  } catch (e) { res.status(500).json({ ok: false }); }
});

// Background polling scheduler
const pollIntervalMs = Number(process.env.POLL_INTERVAL_MS || 60000);
async function runPollers() {
  await Promise.all([pollGitHubActions(), pollJenkins()]);
}
setInterval(runPollers, pollIntervalMs);
// Kick off soon after start
setTimeout(runPollers, 5000);

app.listen(port, () => console.log('Backend listening on :'+port));
