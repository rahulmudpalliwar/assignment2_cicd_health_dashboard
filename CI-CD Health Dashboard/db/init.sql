CREATE TABLE IF NOT EXISTS builds (
  id SERIAL PRIMARY KEY,
  tool TEXT NOT NULL,
  external_id TEXT UNIQUE NOT NULL,
  repo TEXT,
  branch TEXT,
  status TEXT,
  conclusion TEXT,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  duration_seconds INTEGER,
  url TEXT,
  logs TEXT
);
CREATE INDEX IF NOT EXISTS idx_builds_started_at ON builds(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_builds_repo ON builds(repo);
CREATE TABLE IF NOT EXISTS alerts (
  id SERIAL PRIMARY KEY,
  build_id INTEGER NOT NULL REFERENCES builds(id) ON DELETE CASCADE,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  recipient TEXT NOT NULL,
  channel TEXT NOT NULL
);
