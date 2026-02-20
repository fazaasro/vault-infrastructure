-- Native FTS5 Search Initialization Script
-- Run: sqlite3 index.db < .scripts/memsearch-init.sql

-- Create FTS5 virtual table for full-text search
CREATE VIRTUAL TABLE IF NOT EXISTS documents USING fts5(
  title,
  content,
  path,
  tokenize='porter unicode61'
);

-- Create metadata table for tracking
CREATE TABLE IF NOT EXISTS meta (
  key TEXT PRIMARY KEY,
  value TEXT
);

-- Insert initial metadata
INSERT OR REPLACE INTO meta (key, value) VALUES ('last_updated', '0');
