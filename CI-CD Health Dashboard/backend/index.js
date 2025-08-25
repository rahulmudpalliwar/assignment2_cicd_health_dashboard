import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import pkg from 'pg';
const { Pool } = pkg;

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

const port = process.env.PORT || 3000;
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

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

app.listen(port, () => console.log('Backend listening on :'+port));
