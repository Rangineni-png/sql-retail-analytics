BEGIN;

CREATE SCHEMA IF NOT EXISTS retail;

-- Optional but useful (safe to keep; if it errors we can remove)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

COMMIT;