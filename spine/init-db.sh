#!/bin/bash
set -e
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres <<'SQL'
CREATE DATABASE mem0_app;
SQL
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d mem0_app -c "CREATE EXTENSION IF NOT EXISTS vector;"
