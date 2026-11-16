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
