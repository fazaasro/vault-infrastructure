#!/bin/bash
# memsearch-index.sh
# Index repository markdown files into SQLite FTS5

DB_PATH=".scripts/index.db"

echo "🔍 Starting repository index..."

# Create database and schema
sqlite3 "$DB_PATH" 'CREATE VIRTUAL TABLE IF NOT EXISTS documents USING fts5(title, content, path, tokenize="porter unicode61");'
sqlite3 "$DB_PATH" 'CREATE TABLE IF NOT EXISTS meta(key TEXT PRIMARY KEY, value TEXT);'
echo "✓ Database created"

# Clear existing documents
sqlite3 "$DB_PATH" "DELETE FROM documents;"

total=0

# Index files one by one
if [ -f "README.md" ]; then
  sqlite3 "$DB_PATH" "INSERT INTO documents(title, content, path) VALUES('README.md', readfile('README.md'), 'README.md');"
  ((total++))
  echo "✓ Indexed README.md"
fi

# Index .docs/**/*.md files
if [ -d ".docs" ]; then
  find .docs -name "*.md" -type f | while read -r file; do
    filename=$(basename "$file")
    rel_path="${file#./}"
    sqlite3 "$DB_PATH" "INSERT INTO documents(title, content, path) VALUES('$filename', readfile('$file'), '$rel_path');"
    ((total++))
  done
  echo "✓ Indexed .docs/*.md"
fi

# Index DEPLOYMENT*.md files
for file in DEPLOYMENT*.md; do
  if [ -f "$file" ]; then
    sqlite3 "$DB_PATH" "INSERT INTO documents(title, content, path) VALUES('$file', readfile('$file'), '$file');"
    ((total++))
  done
done

# Update metadata
sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO meta(key, value) VALUES('last_updated', '$(date +%s)');"

count=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM documents;")
size=$(du -h "$DB_PATH" 2>/dev/null | cut -f1)

echo "✅ Indexed $count documents ($size)"
echo "📊 Database: $DB_PATH"
