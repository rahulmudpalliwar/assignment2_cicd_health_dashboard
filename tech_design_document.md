# Technical Design

## Architecture
- React SPA calls Express API
- Express polls providers (GitHub/Jenkins) on a schedule and ingests webhooks
- Postgres stores builds and alerts
- Nodemailer sends alerts on failures

## API Structure
- GET `/api/metrics`
  - Response: `{ successRate, failureRate, avgBuildTimeSeconds, lastBuild: { status, conclusion, repo, tool, finishedAt } }`
- GET `/api/builds?limit=50`
  - Response: `[{ id, tool, repo, branch, status, conclusion, durationSeconds, url, startedAt, completedAt }]`
- GET `/api/builds/:id/logs`
  - Response: `{ id, logs }`
- POST `/api/webhook/github` and `/api/webhook/jenkins`
  - Parses payloads, upserts `builds`, triggers alerts on failures

## DB Schema
- Table `builds`
  - `id` serial PK
  - `tool` text
  - `external_id` text unique
  - `repo` text
  - `branch` text
  - `status` text
  - `conclusion` text
  - `started_at` timestamptz
  - `completed_at` timestamptz
  - `duration_seconds` integer
  - `url` text
  - `logs` text
- Table `alerts`
  - `id` serial PK
  - `build_id` integer FK -> builds(id)
  - `sent_at` timestamptz default now()
  - `recipient` text
  - `channel` text

## UI Layout
- Header with overall status (last build)
- Metric cards: success rate, failure rate, average build time
- Latest builds table with status chips and links to provider

## Scheduling
- Poll every 60s for configured sources
- Deduplicate by `external_id`
