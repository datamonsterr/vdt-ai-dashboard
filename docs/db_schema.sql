-- VDT AI Postgres Schema
-- Purpose: Store processed Kafka events, derived metrics, alerts, and pipeline metadata
-- Notes:
-- - Multi-tenant via organizations and projects
-- - 30-day data retention to be enforced by external scheduler (see retention section)
-- - Avoids extensions for portability; consider TimescaleDB for scale later

BEGIN;

-- Required for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Organizations and Users (Clerk-managed auth; we mirror minimal info)
CREATE TABLE IF NOT EXISTS organizations (
	id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	name          TEXT NOT NULL,
	slug          TEXT UNIQUE NOT NULL,
	created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
	updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS users (
	id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	clerk_user_id   TEXT UNIQUE NOT NULL,
	email           TEXT NOT NULL,
	display_name    TEXT,
	created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS organization_members (
	organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
	user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	role            TEXT NOT NULL DEFAULT 'member', -- member|admin|owner
	created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
	PRIMARY KEY (organization_id, user_id)
);

-- Projects scoped within an organization
CREATE TABLE IF NOT EXISTS projects (
	id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
	name            TEXT NOT NULL,
	slug            TEXT NOT NULL,
	description     TEXT,
	created_by      UUID REFERENCES users(id) ON DELETE SET NULL,
	created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
	updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
	UNIQUE (organization_id, slug)
);

-- API keys per project (hash at rest)
CREATE TABLE IF NOT EXISTS api_keys (
	id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	project_id      UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
	name            TEXT NOT NULL,
	prefix          TEXT NOT NULL, -- first few chars for lookup/display
	key_hash        TEXT NOT NULL, -- bcrypt/argon2 hashed
	last_used_at    TIMESTAMPTZ,
	created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
	revoked_at      TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_api_keys_project ON api_keys(project_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_prefix ON api_keys(prefix);

-- Pipelines and stages
CREATE TABLE IF NOT EXISTS pipelines (
	id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	project_id      UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
	name            TEXT NOT NULL,
	description     TEXT,
	created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
	updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
	UNIQUE (project_id, name)
);

CREATE TYPE pipeline_phase AS ENUM ('ingest','preprocess','train','validate','inference','postprocess','export');

CREATE TABLE IF NOT EXISTS pipeline_stages (
	id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	pipeline_id     UUID NOT NULL REFERENCES pipelines(id) ON DELETE CASCADE,
	name            TEXT NOT NULL,
	phase           pipeline_phase NOT NULL,
	position        INT NOT NULL DEFAULT 0,
	config          JSONB NOT NULL DEFAULT '{}',
	created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
	updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
	UNIQUE (pipeline_id, name)
);

-- Core events captured after processing Kafka messages
CREATE TYPE event_type AS ENUM ('info','metric','error','warning','audit');

CREATE TABLE IF NOT EXISTS events (
	id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
	project_id      UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
	pipeline_id     UUID REFERENCES pipelines(id) ON DELETE SET NULL,
	stage_id        UUID REFERENCES pipeline_stages(id) ON DELETE SET NULL,
	event_type      event_type NOT NULL,
	name            TEXT NOT NULL,
	message         TEXT,
	attributes      JSONB NOT NULL DEFAULT '{}',
	status_code     INT, -- HTTP-like code for errors
	error_stack     TEXT,
	trace_id        TEXT,
	span_id         TEXT,
	latency_ms      INT,
	occurred_at     TIMESTAMPTZ NOT NULL,
	ingested_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
	UNIQUE (trace_id, span_id, occurred_at) DEFERRABLE INITIALLY DEFERRED
);
CREATE INDEX IF NOT EXISTS idx_events_org_time ON events(organization_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_events_project_time ON events(project_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_events_pipeline_stage_time ON events(pipeline_id, stage_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_events_type_time ON events(event_type, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_events_trace ON events(trace_id);

-- Time-series metrics
CREATE TABLE IF NOT EXISTS metrics (
	id              BIGSERIAL PRIMARY KEY,
	organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
	project_id      UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
	pipeline_id     UUID REFERENCES pipelines(id) ON DELETE SET NULL,
	stage_id        UUID REFERENCES pipeline_stages(id) ON DELETE SET NULL,
	metric_name     TEXT NOT NULL,
	metric_value    DOUBLE PRECISION NOT NULL,
	labels          JSONB NOT NULL DEFAULT '{}', -- e.g., {"model":"v1","split":"prod"}
	unit            TEXT,
	ts              TIMESTAMPTZ NOT NULL,
	created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_metrics_lookup ON metrics(organization_id, project_id, metric_name, ts DESC);
CREATE INDEX IF NOT EXISTS idx_metrics_pipeline ON metrics(pipeline_id, stage_id, ts DESC);
CREATE INDEX IF NOT EXISTS idx_metrics_gin_labels ON metrics USING GIN (labels);

-- Data quality checks configuration and results
CREATE TYPE dq_check_type AS ENUM ('record_count','missing_data','anomaly');

CREATE TABLE IF NOT EXISTS dq_checks (
	id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	project_id      UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
	name            TEXT NOT NULL,
	check_type      dq_check_type NOT NULL,
	config          JSONB NOT NULL DEFAULT '{}', -- thresholds, columns, etc.
	is_active       BOOLEAN NOT NULL DEFAULT TRUE,
	created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
	UNIQUE (project_id, name)
);

CREATE TABLE IF NOT EXISTS dq_results (
	id              BIGSERIAL PRIMARY KEY,
	check_id        UUID NOT NULL REFERENCES dq_checks(id) ON DELETE CASCADE,
	status          TEXT NOT NULL, -- pass|fail|warn
	details         JSONB NOT NULL DEFAULT '{}',
	ts              TIMESTAMPTZ NOT NULL,
	created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_dq_results_check_ts ON dq_results(check_id, ts DESC);

-- Alerting rules and notifications
CREATE TABLE IF NOT EXISTS alert_rules (
	id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	project_id      UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
	name            TEXT NOT NULL,
	description     TEXT,
	is_active       BOOLEAN NOT NULL DEFAULT TRUE,
	-- rule DSL stored as JSON; e.g., {"metric":"error_rate","threshold":0.1,"window":"5m","op":">"}
	rule            JSONB NOT NULL,
	created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
	updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
	UNIQUE (project_id, name)
);

CREATE TABLE IF NOT EXISTS alerts (
	id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	rule_id         UUID NOT NULL REFERENCES alert_rules(id) ON DELETE CASCADE,
	status          TEXT NOT NULL, -- firing|resolved
	summary         TEXT NOT NULL,
	details         JSONB NOT NULL DEFAULT '{}',
	triggered_at    TIMESTAMPTZ NOT NULL,
	resolved_at     TIMESTAMPTZ,
	created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_alerts_rule_time ON alerts(rule_id, triggered_at DESC);

CREATE TABLE IF NOT EXISTS email_notifications (
	id              BIGSERIAL PRIMARY KEY,
	alert_id        UUID NOT NULL REFERENCES alerts(id) ON DELETE CASCADE,
	recipient_email TEXT NOT NULL,
	status          TEXT NOT NULL, -- queued|sent|failed
	provider_id     TEXT,
	sent_at         TIMESTAMPTZ,
	created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Spark job monitoring
CREATE TABLE IF NOT EXISTS spark_jobs (
	id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	project_id      UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
	app_name        TEXT NOT NULL,
	job_id          TEXT NOT NULL,
	status          TEXT NOT NULL, -- running|success|failed
	metrics         JSONB NOT NULL DEFAULT '{}',
	started_at      TIMESTAMPTZ NOT NULL,
	finished_at     TIMESTAMPTZ,
	created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
	UNIQUE (project_id, job_id, started_at)
);
CREATE INDEX IF NOT EXISTS idx_spark_jobs_project_time ON spark_jobs(project_id, started_at DESC);

-- Views for dashboard summaries (simple examples; expand as needed)
CREATE OR REPLACE VIEW v_project_error_counts AS
SELECT
	e.project_id,
	date_trunc('hour', e.occurred_at) AS hour,
	count(*) FILTER (WHERE e.event_type = 'error') AS error_count
FROM events e
GROUP BY 1,2;

-- Retention: 30-day cleanup functions (schedule via cron or external job)
CREATE OR REPLACE FUNCTION cleanup_old_data(p_cutoff TIMESTAMPTZ)
RETURNS VOID AS $$
BEGIN
	DELETE FROM email_notifications WHERE created_at < p_cutoff;
	DELETE FROM alerts WHERE triggered_at < p_cutoff;
	DELETE FROM dq_results WHERE ts < p_cutoff;
	DELETE FROM metrics WHERE ts < p_cutoff;
	DELETE FROM events WHERE occurred_at < p_cutoff;
END;
$$ LANGUAGE plpgsql;

-- Example external scheduler command (not executed here):
-- SELECT cleanup_old_data(now() - interval '30 days');

COMMIT;

