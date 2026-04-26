# Integration: Notion MCP

Lets you ingest Notion pages live via `/brain-ingest-notion <url>` — no manual export needed. Always fetches fresh content.

## What it does

The Notion MCP server authenticates with your Notion account and lets Claude Code read any page you have access to. The `/brain-ingest-notion` skill uses it to fetch a page, summarise it, and write a source page to the wiki.

**Fetch, don't bulk-export.** This integration is intentionally on-demand — you point it at a specific page when you want it in the brain, rather than syncing your whole Notion workspace. This keeps the wiki focused and avoids stale bulk data.

## Enable for a brain

1. In the brain's `.brain.toml`, set:
   ```toml
   [integrations]
   notion = true
   ```

2. Authenticate the Notion MCP. In Claude.ai or Claude Code, connect the **Notion** integration from the integrations panel (or via MCP settings). Grant access to the workspaces / pages you want the brain to be able to reach.

3. Test the connection by running `/brain-ingest-notion <any-notion-page-url>` from within the brain directory.

## Workflow

1. Find a Notion page worth ingesting (a decision doc, a spec, a team wiki page).
2. Copy the page URL.
3. From the brain directory: `/brain-ingest-notion <url>`
4. The skill fetches it, writes `wiki/sources/notion-<slug>.md`, updates the index, cross-links related pages.

## Security note

Notion content may contain confidential information. Before enabling this integration on a brain with a public or shared git remote, ensure your `.gitignore` excludes sensitive pages from commits.

The skill adds a retrieval timestamp to each source page, so you always know when the snapshot was taken. Re-run the skill on the same URL to refresh it; the existing page will be updated in place.

## Disable

Set `notion = false` in `.brain.toml`. The skill will refuse to run.
