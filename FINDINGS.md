# FINDINGS

Surprises hit while building the BikeHelpdesk smoke test (mxcli nightly-20261115, Mendix 11.16.1).

## Environment
- **`MX_GENAI_KEY` was not provided.** The environment had `MX_KB_KEY` (a Mendix Cloud *KNOWLEDGE_BASE* resource,
  not text generation), `MX_EMBEDDINGS_KEY` (EMBEDDINGS_GENERATION, `eu.cohere.embed-v4:0`) and `OPENROUTER_KEY`.
  So HelpdeskAgent's own Mendix Cloud model cannot be called here; live proofs for the agent use the
  `OverwritingDeployedModel` parameter of `AgentCommons.ChatContext_Create_ForAgent` with a free OpenRouter model.
- No Docker daemon and no Studio Pro in the sandbox: the one-time Studio Pro 11.16 conversion could not be done here.
- `marketplace install` does not resolve dependencies. Needed beyond the 7 listed: DatabaseConnector (PgVector),
  the Markdown viewer and Events widgets (ConversationalUI), WorkflowCommons, CommunityCommons.
  `docker check` after the 7 modules: 66 errors (CE1613 DatabaseConnector); after DatabaseConnector: 22 (CE0462 widgets).

## mxcli
- `replace()` is in `mxcli syntax microflow expressions functions` and passes `check`, but mxbuild rejects it
  (CE0117); only `replaceAll`/`replaceFirst` exist in Mendix.
- `docker check` does not compile Java actions: a missing `import com.mendix.core.Core;` in a `create java action`
  body was only found by `mxcli test --local` (build step). The generated file does not import `Core` for you.
- `mxcli test` needs `declare $result <Type>` in the test block; `div` yields Decimal (MDL041/CE0117).

## DuckDB (SPARQL in the runtime)
- jdbc 2.0.0.1 = DuckDB v2.0.0. `DriverManager.getConnection("jdbc:duckdb:")` fails with "No suitable driver" inside
  the Mendix runtime (userlib class loader); use `new org.duckdb.DuckDBDriver().connect(...)`.
- `INSTALL '<path>'` accepts a core extension (postgres_scanner) but refuses the community `rdf` extension
  ("doesn't have a valid signature"): local-path INSTALL only checks the core key, and a failed INSTALL kills the
  statement. What works: `INSTALL rdf FROM community` once, then bundle that installed file + its `.info` and unpack
  both next to each other in `<extension_directory>/v2.0.0/linux_amd64/`, then `LOAD rdf` by name.
- SPARQL result column labels come back as `v_<var>`.

## Agent Editor / GenAI runtime
- **Agent Editor documents cannot import without a real Mendix Cloud text key.** `ASU_AgentEditor` fetches the model
  list from the resource; a locally forged placeholder key fails with "Something went wrong while attempting to
  retrieve model information from the backend". The Agent still imports, but with no model on its in-use version.
- **Even with the `OverwritingDeployedModel` argument of `ChatContext_Create_ForAgent` set, the chat stops at
  "Select a model on the agent version in use"** (`Agent_Call_WithHistory` reads the version's model, not the chat's).
  The verification shim `Helpdesk.Chat_UseOpenRouterModel` puts the OpenRouter model on the version at startup
  (only when `Helpdesk.ChatUseOpenRouter` is true). A real `MX_GENAI_KEY` makes the shim unnecessary.
- **`UsageType` is `Task` or `Chat`** (case-insensitive). The agents skill documents `Task | Conversational`, and
  `mxcli check` accepts anything: the failure is a startup log line, and it also stops the published MCP server
  from starting. `AgentCommons.ENUM_Agent_UsageType` shows the enum key `Conversational` has caption `Chat`.
- Agent tool microflow names are fixed (ako/mxcli#2265): no tool was renamed.
- `Agent_Call_WithoutHistory` takes the user message from the agent version's UserPrompt, so it cannot classify
  arbitrary text; the workflow's AI step uses `Agent_Call_WithHistory` with its own `Request`.
- A reasoning free model returned an empty answer under `MaxTokens = 20`: the classification step then fell back to
  "Other". No cap, then "Warranty".
- Free OpenRouter models are rate limited (`google/gemma-4-31b-it:free` returned 429); `nvidia/nemotron-3.5-lightning:free`
  called the tool correctly every time. The model is a constant (`Helpdesk.OpenRouterModel`).
- Registering the Mendix Cloud KB/embeddings keys at startup creates a `ConsumedKnowledgeBase` whose display name is
  taken from the key (it contained a person's name): do not select it into evidence.

## PgVector
- `CREATE EXTENSION vector` needs a superuser here (pgvector 0.6 is not a trusted extension), so the app's own
  `DatabaseConfiguration_CreateExtension` fails with "permission denied". `scripts/run.sh` creates it as `postgres`.
- `Encryption.EncryptionKey` must be stable between runs: a PgVector password stored with a random per-run key fails
  to decrypt on the next start ("Cannot decrypt the text..."). The key now lives in the git-ignored `.mxcli/enc.key`.

## MCP
- The authentication microflow must return a `System.User`. With security Off there is no `MxAdmin`, so it returned
  empty and every call was refused ("Authorization error when sending message" in the consumed client). Creating the
  user inside the authenticator raced between parallel requests ("user name already in use"): a startup microflow
  (`MCP_EnsureUser`) creates `mcp_service`. At Prototype security it needs a user role, and its password must satisfy
  the password policy.
- With the agent importing, the published service and the consumed `SelfMcp` both start, and the trace shows an
  `MCPSpan` with `ServerName = SelfMcp` for `get_product`.

## MDL workflow traps
- `create or modify microflow` refuses edits it cannot splice (MDL-V1-REBUILD): the only way forward is a one-time
  `drop microflow` (which also drops its grants; script 12 re-grants). Done once each for `MCP_Authenticate` and
  `ASU_Startup`; after that every script is idempotent (second run: model files byte-identical).
- `alter navigation ... insert` is not idempotent (it duplicated the menu item); `create or modify navigation`
  with the whole menu is.
- A workflow user task targeted with an XPath is visible to those users but not assigned: "My open tasks" stayed
  empty until `auto assign single user` with a one-user XPath.
- `mxcli run restart` cannot replay `@env:` constants (it prints a `--db-password` hint); stop + `scripts/run.sh`.
- `mxcli lint` after the build: 0 errors, 35 warnings (CONV010/021 conventions, entity access SEC001, ARCH003),
  report score 69/100. None are build blockers.

## Not done / not possible here
- The one-time Studio Pro 11.16 conversion (no Studio Pro in the sandbox; `mx convert` does not do it).
- Mendix Cloud text generation (`MX_GENAI_KEY` missing): HelpdeskAgent was exercised on the OpenRouter model.
- Issues on ako/mxcli: filed after the first attempt to attach the repo was denied and a later explicit request
  succeeded: #2308-#2314 plus a comment on #1409 (see `issues/ako-mxcli-issues.md`).
