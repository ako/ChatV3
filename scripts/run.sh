#!/usr/bin/env bash
# Start BikeHelpdesk locally. Keys are passed as @env: references: values never reach argv, logs or git.
# Needs in the environment: MX_EMBEDDINGS_KEY, MX_KB_KEY, OPENROUTER_KEY (MX_GENAI_KEY when you have one).
# Generated per run: Encryption key (32 chars) and the MCP token.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE/../app"
# stable per machine (stored passwords are encrypted with it), kept in the git-ignored .mxcli/
mkdir -p .mxcli
[ -s .mxcli/enc.key ] || (umask 077; openssl rand -hex 16 > .mxcli/enc.key)
export HELPDESK_ENC_KEY="${HELPDESK_ENC_KEY:-$(cat .mxcli/enc.key)}"
[ -s .mxcli/mcp.token ] || (umask 077; openssl rand -hex 24 > .mxcli/mcp.token)
export HELPDESK_MCP_TOKEN="${HELPDESK_MCP_TOKEN:-$(cat .mxcli/mcp.token)}"
args=(
  --constant 'Encryption.EncryptionKey=@env:HELPDESK_ENC_KEY'
  --constant 'Helpdesk.McpToken=@env:HELPDESK_MCP_TOKEN'
  --constant 'Helpdesk.EmbeddingsKey=@env:MX_EMBEDDINGS_KEY'
  --constant 'Helpdesk.KBKey=@env:MX_KB_KEY'
  --constant 'Helpdesk.OpenRouterKey=@env:OPENROUTER_KEY'
  --constant 'Helpdesk.ChatUseOpenRouter=true'
  --constant 'GenAICommons.StoreTraces=true'
)
# MX_GENAI_KEY (Mendix Cloud text generation) is optional here: without it the Model/Agent Editor documents cannot
# import (the connector fetches the model list from the resource), and the OpenRouter twin agent serves the chat.
[ -n "${MX_GENAI_KEY:-}" ] && args+=(--constant 'Helpdesk.GenAIKey=@env:MX_GENAI_KEY')
# Databases + PgVector. CREATE EXTENSION needs a superuser (pgvector is not a trusted extension), so it is done here,
# for both the app database and the one `mxcli test --local` uses.
pg() { su postgres -c "psql -qAt $*"; }
pg -c "\"CREATE ROLE mendix LOGIN PASSWORD 'mendix' CREATEDB\"" 2>/dev/null || true
for db in bikehelpdesk bikehelpdesk_test; do
  [ "$(pg -c "\"select 1 from pg_database where datname='$db'\"")" = 1 ] || pg -c "\"CREATE DATABASE $db OWNER mendix\""
  pg -d "$db" -c "\"CREATE EXTENSION IF NOT EXISTS vector\"" >/dev/null
done
exec ./mxcli run --local --ensure-db --detach -p BikeHelpdesk.mpr \
  --runtime-setting ApplicationRootUrl=http://localhost:8080/ "${args[@]}" "$@"
