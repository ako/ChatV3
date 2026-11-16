#!/usr/bin/env bash
# mxcli test --local with keys as @env: references (same constants as run.sh). Stop the dev app first.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE/../app"
export HELPDESK_ENC_KEY="${HELPDESK_ENC_KEY:-$(cat .mxcli/enc.key)}"
export HELPDESK_MCP_TOKEN="${HELPDESK_MCP_TOKEN:-$(cat .mxcli/mcp.token)}"
exec ./mxcli test tests/ -p BikeHelpdesk.mpr --local \
  --constant 'Encryption.EncryptionKey=@env:HELPDESK_ENC_KEY' \
  --constant 'Helpdesk.McpToken=@env:HELPDESK_MCP_TOKEN' \
  --constant 'Helpdesk.EmbeddingsKey=@env:MX_EMBEDDINGS_KEY' \
  --constant 'Helpdesk.PgVectorJdbcUrl=jdbc:postgresql://localhost:5432/bikehelpdesk_test' \
  --constant 'Helpdesk.PgConnection=host=127.0.0.1 port=5432 dbname=bikehelpdesk_test user=mendix password=mendix' "$@"
