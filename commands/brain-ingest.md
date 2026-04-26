# /brain-ingest

Ingest a file from the brain's `raw/` directory into the wiki.

## Usage

```
/brain-ingest <path-to-file>
/brain-ingest  (no path — prompts for the most recent file in raw/)
```

Path can be absolute or relative to `$BRAIN_ROOT`.

## Steps

1. **Locate the brain.** Use `$BRAIN_ROOT` if set. Otherwise walk up from cwd looking for `wiki/index.md`. If not found, tell the user and stop.

2. **Validate the file** is inside `$BRAIN_ROOT/raw/`. If not, warn the user — ingesting files outside `raw/` is unusual and should be intentional. Ask to confirm.

3. **Read the file fully.** For images, read them visually. For PDFs, read all pages. For large files (>50 pages / >100k tokens), summarise by section rather than word-for-word.

4. **Determine the slug.** Derive a short kebab-case slug from the title or filename: `article-title-here`. Check it doesn't already exist in `wiki/sources/` — if it does, ask the user whether to update the existing page or create a new versioned one.

5. **Write `wiki/sources/<slug>.md`** using the source page template. Fill in:
   - `title`, `type: source`, `source_url` (if available from frontmatter or content), `source_type`
   - TL;DR on line 1 of the body
   - Key points (dense bullets)
   - Relevant entities and concepts (with `[[links]]`)

6. **Update `wiki/index.md`**: add `- [[<slug>]] — <TL;DR> (tags: …)` under `## Sources`.

7. **Cross-link to existing wiki pages.** Read `wiki/index.md` and identify 5–15 pages the source touches. For each:
   - Add a reference to `[[<slug>]]` in that page's relevant section.
   - If a claim in an existing page is superseded by new information, mark it: `> superseded by [[<slug>]]` and update `supersedes:` in the new page's frontmatter.
   - If a relevant entity or concept page doesn't exist yet, create it from the appropriate template.

8. **Append to `wiki/log.md`**: `## [YYYY-MM-DD] ingest | <Title>`
