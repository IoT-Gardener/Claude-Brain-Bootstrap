# /brain-ingest-clipped

Ingest the most recently clipped article from `raw/articles/` (Web Clipper target).

## Usage

```
/brain-ingest-clipped
/brain-ingest-clipped <filename>   (target a specific file if multiple are pending)
```

## Steps

1. **Locate the brain.** Use `$BRAIN_ROOT` if set. Otherwise walk up from cwd looking for `wiki/index.md`. If not found, tell the user and stop.

2. **Check integration is enabled.** Read `$BRAIN_ROOT/.brain.toml`. If `web-clipper` is not `true` under `[integrations]`, tell the user: "Web Clipper integration is not enabled for this brain. Set `web-clipper = true` in `.brain.toml` to enable it." Then stop.

3. **Find the target file.**
   - If a filename was passed, use it.
   - Otherwise, list `$BRAIN_ROOT/raw/articles/` sorted by modification time, newest first. Use the most recent file.
   - If the directory is empty, tell the user nothing is waiting to ingest.

4. **Check for duplicate.** Derive the slug from the filename or its `title` frontmatter field. If `wiki/sources/<slug>.md` already exists, warn the user and ask whether to skip or update.

5. **Run the full ingest flow** (identical to `/brain-ingest`) on the target file:
   - Write `wiki/sources/<slug>.md`
   - Update `wiki/index.md`
   - Cross-link 5–15 related wiki pages
   - Create missing entity/concept pages
   - Append to `wiki/log.md`: `## [YYYY-MM-DD] ingest | <Title> (web-clipper)`
