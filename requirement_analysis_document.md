# Requirement Analysis

## Key features
- Collect pipeline executions from GitHub Actions or Jenkins
- Real-time metrics: success/failure rate, average build time, last build status
- List latest builds, view details and logs
- Send email alerts on failures
- Containerized deployment

## Tech choices
- Backend: Node.js + Express (rapid API, rich ecosystem)
- DB: PostgreSQL (reliable relational store for metrics and history)
- Frontend: React + Vite (fast dev/build, simple SPA)
- Email: Nodemailer with SMTP
- Deployment: Docker Compose

## APIs/tools required
- GitHub REST API v3: Actions runs `/repos/{owner}/{repo}/actions/runs`
- Jenkins JSON API: `JOB_URL/api/json` and `lastBuild/api/json`
- SMTP server for email delivery

## Non-functional
- Simplicity and clarity over completeness
- Polling with conservative intervals
- Minimal secrets surface via `.env`
