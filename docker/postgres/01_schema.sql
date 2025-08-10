-- Bootstrap VDT AI schema into the container database
\echo 'Applying VDT AI schema'
BEGIN;
-- Requires pgcrypto
CREATE EXTENSION IF NOT EXISTS pgcrypto;
\i '/docker-entrypoint-initdb.d/db_schema.sql'
COMMIT;
