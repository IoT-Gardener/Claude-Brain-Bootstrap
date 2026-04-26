# /brain-query

Query the brain's wiki and return a cited answer. When GitNexus is enabled and the question is code-related, supplements wiki results with live structural queries via the GitNexus MCP.

## Usage

```
/brain-query <question>
/brain-query <question> --keep
```

`--keep` files the answer back to `wiki/synthesis/` so it compounds.

## Steps

1. **Locate the brain.** Use `$BRAIN_ROOT` if set. Otherwise walk up from the current working directory looking for a `wiki/index.md` file. If not found, tell the user and stop.

2. **Read `$BRAIN_ROOT/wiki/index.md`** in full. This is the map — identify the 3–8 most relevant pages to the question.

3. **Read those pages.** Follow `[[wiki-links]]` to related pages where they add material detail. Read at most 15 pages total to avoid context bloat.

4. **Supplement with GitNexus if enabled.** Check `$BRAIN_ROOT/.brain.toml`. If `gitnexus = true` and the question is code-related (asks about functions, files, call chains, imports, implementations, or specific code behaviour), query the GitNexus MCP for structural detail. Use GitNexus answers alongside wiki citations — they are complementary. GitNexus answers structural questions ("what calls X?") that the wiki may not have at the required precision.

5. **Answer** with inline citations in the form `([[page-slug]])` for wiki sources. Prefix GitNexus-sourced facts with `(gitnexus)`. If information is missing from both wiki and GitNexus, say so clearly — do not hallucinate.

6. **If `--keep` was passed** (or if the answer is non-obvious, cross-domain, or likely to be asked again), offer to file it:
   - Write `$BRAIN_ROOT/wiki/synthesis/<slug>.md` using the synthesis page template.
   - Add an entry to `$BRAIN_ROOT/wiki/index.md` under `## Synthesis`.
   - Append to `$BRAIN_ROOT/wiki/log.md`: `## [YYYY-MM-DD] query | <question> → filed to synthesis/<slug>`

7. If `--keep` was not passed and the answer was not filed, still append to the log:
   `## [YYYY-MM-DD] query | <question> (not filed)`
