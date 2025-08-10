-- This file is mounted into Postgres container to bootstrap schema
\i '/docker-entrypoint-initdb.d/01_schema.sql'
-- Initialize database for local development
CREATE DATABASE vdt_ai;
CREATE USER vdt_ai_user WITH PASSWORD 'vdt_ai_password';
GRANT ALL PRIVILEGES ON DATABASE vdt_ai TO vdt_ai_user;
