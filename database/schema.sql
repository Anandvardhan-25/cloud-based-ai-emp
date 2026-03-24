-- Cloud-Based AI Workforce Intelligence Platform
-- Phase 1: PostgreSQL schema (normalized, production-oriented)
--
-- Notes:
-- - Uses UUID PKs for distributed safety.
-- - Uses CITEXT for case-insensitive usernames/emails.
-- - Adds optional pg_trgm indexes for fast ILIKE search.
-- - Uses soft-delete via deleted_at on key business tables.

BEGIN;

-- Extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Enums (keep business constraints explicit and queryable)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'employment_status') THEN
    CREATE TYPE employment_status AS ENUM ('ACTIVE', 'ON_LEAVE', 'SUSPENDED', 'TERMINATED');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'project_status') THEN
    CREATE TYPE project_status AS ENUM ('PLANNED', 'ACTIVE', 'ON_HOLD', 'COMPLETED', 'CANCELLED');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_status') THEN
    CREATE TYPE task_status AS ENUM ('TODO', 'IN_PROGRESS', 'BLOCKED', 'DONE', 'CANCELLED');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_priority') THEN
    CREATE TYPE task_priority AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'metric_source') THEN
    CREATE TYPE metric_source AS ENUM ('SYSTEM', 'MANUAL', 'INTEGRATION', 'AI_DERIVED');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ai_context_type') THEN
    CREATE TYPE ai_context_type AS ENUM (
      'PERFORMANCE_SUMMARY',
      'SKILL_ROADMAP',
      'HR_EMAIL',
      'ROLE_RECOMMENDATION',
      'PRODUCTIVITY_INSIGHTS',
      'RESUME_SUGGESTIONS'
    );
  END IF;
END$$;

-- Shared audit trigger
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ===============
-- Core IAM tables
-- ===============

CREATE TABLE IF NOT EXISTS roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  description text,
  created_at timestamptz NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS employees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_number text NOT NULL,
  first_name text NOT NULL,
  last_name text NOT NULL,
  work_email citext NOT NULL,
  work_phone text,
  job_title text NOT NULL,
  department text,
  manager_id uuid NULL REFERENCES employees(id) ON DELETE SET NULL,
  hire_date date NOT NULL,
  status employment_status NOT NULL DEFAULT 'ACTIVE',
  created_at timestamptz NOT NULL DEFAULT NOW(),
  updated_at timestamptz NOT NULL DEFAULT NOW(),
  deleted_at timestamptz NULL,
  CONSTRAINT employees_employee_number_chk CHECK (length(employee_number) >= 3),
  CONSTRAINT employees_work_email_chk CHECK (position('@' in work_email::text) > 1)
);

-- Partial uniques to support soft delete
CREATE UNIQUE INDEX IF NOT EXISTS ux_employees_employee_number_active
  ON employees (employee_number)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_employees_work_email_active
  ON employees (work_email)
  WHERE deleted_at IS NULL;

-- Search acceleration
CREATE INDEX IF NOT EXISTS ix_employees_name_trgm
  ON employees USING gin ((lower(first_name || ' ' || last_name)) gin_trgm_ops)
  WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NULL UNIQUE REFERENCES employees(id) ON DELETE SET NULL,
  username citext NOT NULL,
  email citext NOT NULL,
  password_hash text NOT NULL,
  is_active boolean NOT NULL DEFAULT TRUE,
  last_login_at timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT NOW(),
  updated_at timestamptz NOT NULL DEFAULT NOW(),
  deleted_at timestamptz NULL,
  CONSTRAINT users_username_chk CHECK (length(username::text) >= 3),
  CONSTRAINT users_email_chk CHECK (position('@' in email::text) > 1)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_users_username_active
  ON users (username)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_users_email_active
  ON users (email)
  WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS user_roles (
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id uuid NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
  granted_at timestamptz NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, role_id)
);

-- =============
-- Skill catalog
-- =============

CREATE TABLE IF NOT EXISTS skills (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  category text NOT NULL,
  description text,
  created_at timestamptz NOT NULL DEFAULT NOW(),
  CONSTRAINT skills_name_chk CHECK (length(name) >= 2)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_skills_name_category
  ON skills (lower(name), lower(category));

CREATE TABLE IF NOT EXISTS employee_skills (
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  skill_id uuid NOT NULL REFERENCES skills(id) ON DELETE RESTRICT,
  proficiency_level smallint NOT NULL,
  years_experience numeric(4,1) NOT NULL DEFAULT 0,
  last_assessed_at date NULL,
  evidence_url text NULL,
  created_at timestamptz NOT NULL DEFAULT NOW(),
  updated_at timestamptz NOT NULL DEFAULT NOW(),
  PRIMARY KEY (employee_id, skill_id),
  CONSTRAINT employee_skills_proficiency_chk CHECK (proficiency_level BETWEEN 1 AND 5),
  CONSTRAINT employee_skills_years_chk CHECK (years_experience >= 0)
);

CREATE INDEX IF NOT EXISTS ix_employee_skills_skill
  ON employee_skills (skill_id, proficiency_level DESC);

-- ===================
-- Projects and tasks
-- ===================

CREATE TABLE IF NOT EXISTS projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_code text NOT NULL,
  name text NOT NULL,
  description text,
  status project_status NOT NULL DEFAULT 'PLANNED',
  owner_employee_id uuid NULL REFERENCES employees(id) ON DELETE SET NULL,
  start_date date NULL,
  end_date date NULL,
  created_at timestamptz NOT NULL DEFAULT NOW(),
  updated_at timestamptz NOT NULL DEFAULT NOW(),
  deleted_at timestamptz NULL,
  CONSTRAINT projects_code_chk CHECK (length(project_code) >= 3),
  CONSTRAINT projects_dates_chk CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_projects_code_active
  ON projects (project_code)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_projects_status
  ON projects (status)
  WHERE deleted_at IS NULL;

-- Normalized project membership (needed for allocation and role recommendation)
CREATE TABLE IF NOT EXISTS project_members (
  project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE RESTRICT,
  role_in_project text NOT NULL,
  allocation_percent smallint NOT NULL DEFAULT 100,
  start_date date NULL,
  end_date date NULL,
  created_at timestamptz NOT NULL DEFAULT NOW(),
  updated_at timestamptz NOT NULL DEFAULT NOW(),
  PRIMARY KEY (project_id, employee_id),
  CONSTRAINT project_members_alloc_chk CHECK (allocation_percent BETWEEN 0 AND 100),
  CONSTRAINT project_members_dates_chk CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
);

CREATE INDEX IF NOT EXISTS ix_project_members_employee
  ON project_members (employee_id);

CREATE TABLE IF NOT EXISTS tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  status task_status NOT NULL DEFAULT 'TODO',
  priority task_priority NOT NULL DEFAULT 'MEDIUM',
  assignee_employee_id uuid NULL REFERENCES employees(id) ON DELETE SET NULL,
  reporter_employee_id uuid NULL REFERENCES employees(id) ON DELETE SET NULL,
  due_date date NULL,
  estimated_hours numeric(6,2) NULL,
  actual_hours numeric(6,2) NULL,
  completed_at timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT NOW(),
  updated_at timestamptz NOT NULL DEFAULT NOW(),
  deleted_at timestamptz NULL,
  CONSTRAINT tasks_title_chk CHECK (length(title) >= 3),
  CONSTRAINT tasks_hours_chk CHECK (
    (estimated_hours IS NULL OR estimated_hours >= 0) AND
    (actual_hours IS NULL OR actual_hours >= 0)
  )
);

CREATE INDEX IF NOT EXISTS ix_tasks_project_status
  ON tasks (project_id, status)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_tasks_assignee_status
  ON tasks (assignee_employee_id, status)
  WHERE deleted_at IS NULL;

-- =======================
-- Performance & training
-- =======================

CREATE TABLE IF NOT EXISTS performance_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  project_id uuid NULL REFERENCES projects(id) ON DELETE SET NULL,
  period_start date NOT NULL,
  period_end date NOT NULL,
  metric_key text NOT NULL,
  metric_value numeric(18,6) NOT NULL,
  unit text NULL,
  source metric_source NOT NULL DEFAULT 'SYSTEM',
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT NOW(),
  CONSTRAINT performance_metrics_period_chk CHECK (period_end >= period_start),
  CONSTRAINT performance_metrics_key_chk CHECK (length(metric_key) >= 2)
);

CREATE INDEX IF NOT EXISTS ix_performance_metrics_employee_period
  ON performance_metrics (employee_id, period_start DESC, period_end DESC);

CREATE INDEX IF NOT EXISTS ix_performance_metrics_project_period
  ON performance_metrics (project_id, period_start DESC, period_end DESC);

CREATE TABLE IF NOT EXISTS training_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  skill_id uuid NULL REFERENCES skills(id) ON DELETE SET NULL,
  training_title text NOT NULL,
  provider text NULL,
  started_at date NULL,
  completed_at date NULL,
  outcome text NULL,
  hours numeric(6,2) NULL,
  certificate_url text NULL,
  recommendation_source metric_source NOT NULL DEFAULT 'MANUAL',
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT NOW(),
  CONSTRAINT training_history_title_chk CHECK (length(training_title) >= 3),
  CONSTRAINT training_history_hours_chk CHECK (hours IS NULL OR hours >= 0),
  CONSTRAINT training_history_dates_chk CHECK (completed_at IS NULL OR started_at IS NULL OR completed_at >= started_at)
);

CREATE INDEX IF NOT EXISTS ix_training_history_employee
  ON training_history (employee_id, created_at DESC);

CREATE INDEX IF NOT EXISTS ix_training_history_skill
  ON training_history (skill_id, created_at DESC);

-- ==========================
-- AI observability / audit
-- ==========================

CREATE TABLE IF NOT EXISTS ai_feedback_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  generated_by_user_id uuid NULL REFERENCES users(id) ON DELETE SET NULL,
  context_type ai_context_type NOT NULL,
  correlation_id uuid NOT NULL DEFAULT gen_random_uuid(),
  model_name text NOT NULL,
  prompt_version text NOT NULL,
  input_payload jsonb NOT NULL,
  output_payload jsonb NOT NULL,
  token_usage jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT NOW(),
  CONSTRAINT ai_feedback_logs_model_chk CHECK (length(model_name) >= 2),
  CONSTRAINT ai_feedback_logs_prompt_chk CHECK (length(prompt_version) >= 1)
);

CREATE INDEX IF NOT EXISTS ix_ai_feedback_employee_time
  ON ai_feedback_logs (employee_id, created_at DESC);

CREATE INDEX IF NOT EXISTS ix_ai_feedback_context_time
  ON ai_feedback_logs (context_type, created_at DESC);

CREATE INDEX IF NOT EXISTS ix_ai_feedback_input_gin
  ON ai_feedback_logs USING gin (input_payload);

CREATE INDEX IF NOT EXISTS ix_ai_feedback_output_gin
  ON ai_feedback_logs USING gin (output_payload);

-- updated_at triggers (avoid manual updates)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_employees_updated_at') THEN
    CREATE TRIGGER trg_employees_updated_at BEFORE UPDATE ON employees
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_users_updated_at') THEN
    CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_employee_skills_updated_at') THEN
    CREATE TRIGGER trg_employee_skills_updated_at BEFORE UPDATE ON employee_skills
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_projects_updated_at') THEN
    CREATE TRIGGER trg_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_project_members_updated_at') THEN
    CREATE TRIGGER trg_project_members_updated_at BEFORE UPDATE ON project_members
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_tasks_updated_at') THEN
    CREATE TRIGGER trg_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;
END$$;

-- Seed roles (idempotent)
INSERT INTO roles (name, description)
VALUES
  ('ADMIN', 'Platform administrator with full access'),
  ('HR', 'HR role: workforce governance, reviews, training'),
  ('MANAGER', 'Manager role: projects, tasks, team performance'),
  ('EMPLOYEE', 'Employee role: personal profile, tasks, growth')
ON CONFLICT (name) DO NOTHING;

COMMIT;
