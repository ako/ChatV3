# BikeHelpdesk: Mendix 11.16 agentic smoke test (mxcli)

One module (`Helpdesk`), one entity per feature, one page per feature. See `FINDINGS.md` for surprises and
`evidence/` for the proof of each feature.

| Script (`app/mdlsource/`) | Item |
|---|---|
| `01-data.mdl` | Product, `Product_CompatibleWith`, 6 seeded products, PostgreSQL configuration |
| `02-agents.mdl` | Model, Knowledge Base, Consumed MCP Service, `HelpdeskAgent` (2 microflow tools + KB + MCP) |
| `03-chat.mdl` | Conversational UI chat page for HelpdeskAgent |
| `04-vectordb.mdl` | PgVector knowledge base `policies`, 3 policy texts, nearest-chunk retrieval |
| `05-sparql.mdl` | DuckDB (jdbc 2.0.0.1) Java action, R2RML mapping in `resources/duckdb/`, `Tool_ProductGraph` |
| `06-mcp-server.mdl` | `Tool_GetProduct` published over MCP Server (`/helpdesk/mcp`, token header) |
| `07-mcp-client.mdl` | the Consumed MCP Service points at that server |
| `08-workflow.mdl` | 2-step workflow: AI step (HelpdeskAgent) then user task |
| `09-runtime-agent.mdl` | Agent Commons agent on OpenRouter (free model) with `Tool_GetProduct` |
| `10-startup.mdl` `11-navigation.mdl` `12-security.mdl` | after-startup composer, menu, Prototype security + demo user |

Order: `scripts/exec_all.sh` (01 05 02 04 06 07 08 09 03 10 11 12).

```bash
scripts/run.sh            # app on :8080; keys are @env: references (MX_EMBEDDINGS_KEY, MX_KB_KEY, OPENROUTER_KEY, MX_GENAI_KEY)
scripts/test.sh           # mxcli test --local (stop the dev app first)
scripts/prove_mcp.sh      # item 6, external curl
node scripts/chat_prove.js; node scripts/prove_pages.js   # browser proofs (log in as the demo user, always log out)
scripts/prove_data.sh     # OQL / SQL evidence
```
After a fresh clone run `mxcli sync-java-deps -p app/BikeHelpdesk.mpr` (vendorlib/ is not committed). Open the project
once in Studio Pro 11.16 and commit the result: that conversion has **not** been done here.
