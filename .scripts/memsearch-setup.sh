#!/bin/bash
# memsearch-setup.sh
# One-time setup for native FTS5 search

set -e

echo "🚀 Setting up native memsearch..."

# 1. Create .scripts directory if needed
mkdir -p .scripts

# 2. Initialize database
echo "📦 Initializing database..."
sqlite3 .scripts/index.db < .scripts/memsearch-init.sql

# 3. Index files
echo "📄 Indexing markdown files..."
chmod +x .scripts/memsearch-index.sh
./.scripts/memsearch-index.sh

# 4. Make search script executable
chmod +x .scripts/memsearch-search.sh

echo ""
echo "✅ memsearch setup complete!"
echo ""
echo "Commands:"
echo "  Search:    ./.scripts/memsearch-search.sh 'query' [limit]"
echo "  Re-index:  ./.scripts/memsearch-index.sh"
echo "  Status:    sqlite3 .scripts/index.db 'SELECT COUNT(*) FROM documents;'"
echo ""
echo "For details, see: README-MEMSEARCH.md"
