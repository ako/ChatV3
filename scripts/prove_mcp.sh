#!/usr/bin/env bash
# Item 6: an external client (curl) initializes, lists and calls the published MCP server. The token is read from
# the git-ignored file run.sh keeps and is never printed.
set -euo pipefail
cd "$(dirname "$0")/.."
TOKEN="$(cat app/.mxcli/mcp.token)"
U="${HELPDESK_URL:-http://localhost:8080}/helpdesk/mcp"
H=(-H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' -H "X-Api-Token: $TOKEN")
out=evidence/mcp-external.txt
{
echo "# External MCP client (curl) against $U"
echo "## without a token"
curl -s -m 20 -o /dev/null -w "HTTP %{http_code}\n" -X POST "$U" -H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"curl","version":"1"}}}'
echo "## initialize"
SID=$(curl -s -m 20 -D - -o /tmp/mcp_init.txt -X POST "$U" "${H[@]}" -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"curl","version":"1"}}}' | grep -i '^mcp-session-id' | tr -d '\r' | awk '{print $2}')
cat /tmp/mcp_init.txt; echo
curl -s -m 20 -o /dev/null -X POST "$U" "${H[@]}" -H "Mcp-Session-Id: $SID" -d '{"jsonrpc":"2.0","method":"notifications/initialized"}'
echo "## tools/list"
curl -s -m 20 -X POST "$U" "${H[@]}" -H "Mcp-Session-Id: $SID" -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'; echo
echo "## tools/call get_product {Sku: BAT-418}"
curl -s -m 30 -X POST "$U" "${H[@]}" -H "Mcp-Session-Id: $SID" -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get_product","arguments":{"Sku":"BAT-418"}}}'; echo
} | sed "s/$TOKEN/<token>/g" | tee "$out"
