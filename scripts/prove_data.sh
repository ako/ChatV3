#!/usr/bin/env bash
# Evidence by OQL against the running app (+ one SQL count for the pgvector table, which is not a Mendix entity).
set -euo pipefail
cd "$(dirname "$0")/../app"
q() { echo "-- $1"; ./mxcli oql -q -p BikeHelpdesk.mpr "$1" 2>&1 | grep -v '^WARNING'; echo; }
{
echo "# Data evidence $(date -u +%FT%TZ)"
q "select Sku, Name, Kind, Price from Helpdesk.Product order by Sku"
q "select Title, Body from Helpdesk.Policy order by Title"
q "select Name from PgVectorKnowledgeBase.PgVectorKnowledgeBase"
echo "-- SQL: chunks stored in the pgvector table 'policies' (id, human readable id, dims)"
PGPASSWORD=mendix psql -h 127.0.0.1 -U mendix bikehelpdesk -c "select count(*) as chunks from policies" -c "select * from policies_metadata limit 0" 2>&1 | head -8
PGPASSWORD=mendix psql -h 127.0.0.1 -U mendix bikehelpdesk -At -c "select 'vector extension: '||extversion from pg_extension where extname='vector'"
echo
q "select ToolName, ToolCallStatus, Input from GenAICommons.ToolSpan order by StartTime"
q "select ServerName from GenAICommons.MCPSpan"
q "select count(*) as traces from GenAICommons.Trace"
q "select count(*) as spans from GenAICommons.Span"
q "select count(*) as usage_rows, sum(InputTokens) as input_tokens, sum(OutputTokens) as output_tokens from GenAICommons.Usage"
q "select Subject, Category, Status from Helpdesk.Ticket"
q "select Name from System.WorkflowUserTask"
} | tee ../evidence/data-oql.txt
