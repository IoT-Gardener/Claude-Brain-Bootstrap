# /brain-ingest-repo

Ingest a git repository into `wiki/synthesis/code/<repo>.md`. Never copies source verbatim — produces a human+LLM-readable digest only.

**Two modes, auto-selected:**
- **Deep** (when `graphify = true` in `.brain.toml` and Graphify is installed): runs Graphify (tree-sitter + LLM) to extract function signatures, call graphs, and module dependencies — a full semantic map.
- **Shallow** (default / Graphify not available): Claude manually samples README, config files, and key source files to produce a prose digest. Works on any repo regardless of language, no external tools required.

Both modes write the same output format and frontmatter, so the page can be refreshed by either mode. Use `--update` to refresh an existing page without a confirmation prompt.

## Usage

```
/brain-ingest-repo <path-to-repo>
/brain-ingest-repo <path-to-repo> --update   (refresh an existing digest)
```

## Steps

1. **Locate the brain.** Use `$BRAIN_ROOT` if set. Otherwise walk up from cwd looking for `wiki/index.md`. If not found, tell the user and stop.

2. **Determine mode.** Read `$BRAIN_ROOT/.brain.toml`. If `graphify = true`, attempt deep mode: verify that `graphify` is on PATH (`graphify --version`). If Graphify is missing, warn and fall back to shallow. Otherwise use shallow mode.

3. **Validate the repo path.** Confirm the path exists and contains a `.git` directory. If not, warn and stop.

4. **Determine the slug.** Use the repo directory name as the slug (`my-repo` from `/path/to/my-repo`). Check if `$BRAIN_ROOT/wiki/synthesis/code/<slug>.md` already exists:
   - If it exists and `--update` was not passed: ask the user whether to update or abort.
   - If it exists and `--update` was passed: proceed — the page will be overwritten.
   - If it does not exist: proceed.

5. **Gather content.**
   - **Deep mode**: run `graphify <path-to-repo>` and read its full output.
   - **Shallow mode**: read in order, skipping anything that doesn't exist:
     - `README.md` / `README.rst`
     - `CLAUDE.md` / `AGENTS.md` / `.cursorrules`
     - `docs/` directory (list structure, read top-level files)
     - `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod`
     - Top-level directory listing
     - The 3–5 most central source files (inferred from README, imports, or structure)
     - Skip generated files, `node_modules`, `vendor`, `dist`, lock files.

6. **Write `$BRAIN_ROOT/wiki/synthesis/code/<slug>.md`** with frontmatter:
   ```yaml
   ---
   title: <Repo Name> — code map
   type: synthesis
   subtype: code
   tags: [code, <language>, <key-framework>]
   created: YYYY-MM-DD
   updated: YYYY-MM-DD
   staleness: 14d
   source_repo: <absolute-path-to-repo>
   mode: deep | shallow
   ---
   ```
   Body content:
   - **TL;DR** — one sentence: what the repo does and its tech stack.
   - **Purpose & domain** — what problem it solves, who uses it.
   - **Tech stack** — language, key frameworks, DB, infra, test tooling.
   - **Architecture** — key modules/layers, data flow, entry points. Brief ASCII diagram if it helps.
   - **Key entities** — the 5–10 most important types, classes, or functions (name + one-line purpose). Deep mode will have richer detail here.
   - **Call graph highlights** — notable function relationships or call chains. Deep mode only; omit in shallow.
   - **Patterns & conventions** — naming, error handling, async model, anything surprising.
   - **Current state** — maturity, known gaps, recent churn areas.
   - **Open questions** — things worth watching or clarifying.
   Do not paste source code verbatim.

7. **Update `wiki/index.md`**: add/update entry under `## Synthesis › ### Code`:
   ```
   - [[<slug>]] — <TL;DR> (tags: code, <language>)
   ```

8. **Cross-link to existing wiki pages.** Read `wiki/index.md` and identify entity or concept pages the repo touches (frameworks used, patterns applied, owners). For each, add a `[[<slug>]]` reference and mark any outdated claims with `> superseded by [[<slug>]]`. Create missing entity/concept pages if warranted.

9. **Append to `wiki/log.md`**:
   ```
   ## [YYYY-MM-DD] ingest | repo: <repo-name> (<deep|shallow>)
   ```

10. **Check GitNexus.** Read `$BRAIN_ROOT/.brain.toml`. If `gitnexus = true`, check whether this repo has been indexed by running `gitnexus index --status <path-to-repo>`. If not indexed, or if the index is older than this run, suggest: "Run `gitnexus index <path-to-repo>` to enable live structural queries alongside this digest."

11. **Summarise.** Report: the page written, mode used (deep/shallow), cross-links made, any new entity/concept pages created, and GitNexus index status.
