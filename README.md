# CI/CD Health Dashboard

Monitor the health of your CI/CD pipelines (GitHub Actions or Jenkins) with real-time metrics, historical builds, and email alerts. The stack includes: Node.js/Express backend, PostgreSQL, React (Vite) frontend, and Docker Compose for containerization.

## Prerequisites
- Node.js v18+
- Docker & Docker Compose
- PostgreSQL (local or containerized)
- GitHub account with access to Actions workflows
- Jenkins server with API access

## Features
- Success/Failure rate
- Average build time
- Last build status
- Latest builds list with details
- Ingestion via polling (GitHub Actions/Jenkins) and webhooks
- Email alerts on failures

## Quick Start (Docker)
1. Copy env template and adjust values:
```bash
cp backend/.env.example backend/.env
```
2. Start all services:
```bash
docker compose up -d --build
```
3. Open the UI: `http://localhost:3000`
4. Backend API: `http://localhost:3000/api`

## Environment Variables
Edit `backend/.env`:
- Core
  - PORT=3000
  - DATABASE_URL=postgres://postgres:postgres@db:5432/cicd
- GitHub Actions polling (optional)
  - GITHUB_TOKEN=
  - GITHUB_REPOS=owner1/repo1,owner2/repo2
- Jenkins polling (optional)
  - JENKINS_BASE_URL=
  - JENKINS_USER=
  - JENKINS_TOKEN=
- Email (for alerts)
  - SMTP_HOST=
  - SMTP_PORT=587
  - SMTP_USER=
  - SMTP_PASS=
  - ALERT_FROM="CI/CD Dashboard <noreply@example.com>"
  - ALERT_TO=alerts@example.com,team@example.com

## Webhooks (optional)
- GitHub: set a webhook to `POST /api/webhook/github` (content type: `application/json`).
- Jenkins: set a webhook (e.g., with Notification plugin) to `POST /api/webhook/jenkins`.

## Architecture Summary
- Backend: Node.js/Express app exposes REST API, polls providers, stores builds in Postgres, sends email alerts.
- DB: PostgreSQL with `builds` and `alerts` tables.
- Frontend: React app renders metrics and latest builds.
- Docker: `docker-compose.yml` orchestrates `db`, `backend`, and `frontend`.
  <img width="877" height="371" alt="image" src="https://github.com/user-attachments/assets/6ccfed12-a696-45e3-82b2-1d2d46ffdd1a" />


## Development (without Docker)
1. Start Postgres locally and create DB `cicd`. Apply `db/init.sql`.
2. Backend
```bash
cd backend
cp .env.example .env
npm install
npm run dev
```
3. Frontend
```bash
cd frontend
npm install
npm run dev
```

## API Overview
- GET `/api/metrics`
- GET `/api/builds?limit=50`
- GET `/api/builds/:id/logs`
- POST `/api/webhook/github`
- POST `/api/webhook/jenkins`

## How AI tools were used
See `prompot_logs.md` for prompt examples and `requirement_analysis_document.md` and `tech_design_document.md` for generated analyses/designs.

## Key learning and assumptions
- Polling intervals are modest to avoid provider rate limits (60s by default).
- Email is sent once per newly observed failure (dedup by `external_id`).
- Logs are optional and truncated when too large.

## License
MIT
