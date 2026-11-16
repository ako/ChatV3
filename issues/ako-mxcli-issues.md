# Issues to file on ako/mxcli (drafts; could not be filed from the session, see FINDINGS.md)

Found with mxcli nightly-20261115-c1a579a7b, Mendix 11.16.1. Repro project: this repository (`app/`, scripts in `app/mdlsource/`).

## 1. `replace()` is listed as an expression function and passes `check`, but mxbuild rejects it (CE0117)
`mxcli syntax microflow expressions functions` lists `replace(String, String, String) -> String`.
`set $N = length($Json) - length(replace($Json, 'sku', ''));` passes `mxcli check` and fails `docker check` with
`CE0117 Error(s) in expression`. `replaceAll` works. Expected: drop `replace` from the registry (or flag MDL044).
Same family: `count()` is correctly flagged (MDL044).

## 2. `create agent`: `UsageType` is not validated, and the skill documents the wrong values
`.ai-context/skills/agents` says `UsageType: task | Conversational`. Agent Editor accepts `Task` / `Chat`
(`AgentEditorCommons.UsageType_StringToENUM`). `UsageType: Conversational` passes `check`, `exec` and `docker check`;
at startup the agent is rejected ("Usage Type is not valid for the Agent") and, because the import fails, the
published MCP server is not started either. Expected: MDL-AGENT warning like MDL-AGENT01/02, and fix the skill text.

## 3. `docker check` does not compile Java actions
`create java action` with a body using `Core` but no `import com.mendix.core.Core;` passes `check`, `exec`, and
`docker check` (0 errors). Only `mxcli test --local` / `run` (the real build) reports `cannot find symbol Core`.
Expected: either import `Core` in generated files like Studio Pro does, or have `docker check` compile Java.

## 4. `marketplace install` does not install dependencies
Agent Editor + the six modules the skill lists leaves `docker check` at 66 errors (CE1613 DatabaseConnector, needed by
PgVector Knowledge Base), then 22 (CE0462: Markdown viewer and Events widgets used by Conversational UI). Expected:
resolve and install declared dependencies, or list them in the install output / agents skill.

## 5. `create or modify microflow` cannot change a flow it did not write, and the way out drops grants
Adding an `on error` handler to an existing flow, or changing a returned expression, is refused with
MDL-V1-REBUILD ("no free room for the fragment" / "Join has no activity to address"). The suggested remedy
(`drop` + `create`) writes on every run, which breaks "a second exec must write nothing", and a drop in an earlier
run loses the module-role grants. Expected: `alter microflow` examples for these two cases, or splice that can
re-layout the neighbourhood.

## 6. `alter navigation ... insert` is not idempotent
Running a script twice appended the same menu item twice. `create or modify navigation` with the full menu is
idempotent; the navigation skill should say so, or `insert` should skip an item with the same caption.

## 7. `mxcli run restart` cannot replay a run started with `--constant X=@env:Y`
It prints `--db-password @env:MX_DB_PASSWORD ...` and exits non-zero; the state file records the args but the
`@env:` ones are not replayed. Workaround: `run stop` + start again.

## 8. DuckDB community extensions cannot be INSTALLed from a local path (doc + example request)
`INSTALL '<local path>'` verifies against the core key only, so the community `rdf` extension is refused as
unsigned and a failed INSTALL closes the statement. What works: `INSTALL rdf FROM community` once, then bundle the
installed `rdf.duckdb_extension` + `.info` and copy both into `<extension_directory>/<version>/<platform>/`.
Also `DriverManager.getConnection("jdbc:duckdb:")` finds no driver inside the Mendix runtime; use
`new org.duckdb.DuckDBDriver().connect(...)`. Worth a note in the java-dependencies / java-actions skills.
