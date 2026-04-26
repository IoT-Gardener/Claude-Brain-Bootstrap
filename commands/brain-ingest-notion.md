# /brain-ingest-notion

Fetch a Notion page via MCP and ingest it into the wiki as a source page. Always fetches live — does not require a manual export.

## Usage

```
/brain-ingest-notion <notion-page-url>
```

## Steps

1. **Locate the brain.** Use `$BRAIN_ROOT` if set. Otherwise walk up from cwd looking for `wiki/index.md`. If not found, tell the user and stop.

2. **Check integration is enabled.** Read `$BRAIN_ROOT/.brain.toml`. If `notion` is not `true` under `[integrations]`, tell the user: "Notion integration is not enabled for this brain. Set `notion = true` in `.brain.toml` and authenticate the Notion MCP. See `integrations/notion.md` in the bootstrap repo for setup steps." Then stop.

3. **Fetch the Notion page** via the Notion MCP tool. If authentication fails or the page isn't accessible, surface the error clearly and stop.

4. **Derive the slug** from the page title: `notion-<kebab-title>`. Check for an existing page with this slug.

5. **Write `$BRAIN_ROOT/wiki/sources/<slug>.md`** using the source page template. Set:
   - `source_type: mcp-notion`
   - `source_url`: the original Notion URL
   - `created`: today's date

6. **Update `wiki/index.md`**: add entry under `## Sources`.

7. **Cross-link** to 5–15 related wiki pages. Create missing entity/concept pages as needed.

8. **Append to `wiki/log.md`**: `## [YYYY-MM-DD] ingest | notion: <Page Title>`

> **Note:** Notion content may contain confidential information. Ensure this brain's git remote is appropriate before committing.
