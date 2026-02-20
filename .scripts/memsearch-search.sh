#!/bin/bash
# memsearch-search.sh
# Fast native FTS5 search

DB_PATH=".scripts/index.db"

if [ -z "$1" ]; then
  echo "Usage: $0 <query> [limit]"
  echo "  query: Search terms"
  echo "  limit: Number of results (default: 5)"
  exit 1
fi

QUERY="$1"
LIMIT="${2:-5}"

# Escape query for SQL (remove SQL operators)
SAFE_QUERY=$(printf '%s' "$QUERY" | sed "s/'/''/g" | sed 's/[.-]/ /g')

# Perform search with ranking
sqlite3 "$DB_PATH" << SQL
SELECT 
  path,
  substr(content, 1, 300) as snippet,
  rank,
  bm25(documents) as relevance
FROM documents
WHERE documents MATCH '$SAFE_QUERY'
ORDER BY rank
LIMIT $LIMIT;
SQL
