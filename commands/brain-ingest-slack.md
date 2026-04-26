# /brain-ingest-slack

Fetch a Slack thread via MCP and ingest it into the wiki as a source page.

## Usage

```
/brain-ingest-slack <slack-thread-url>
```

## Steps

1. **Locate the brain.** Use `$BRAIN_ROOT` if set. Otherwise walk up from cwd looking for `wiki/index.md`. If not found, tell the user and stop.

2. **Check integration is enabled.** Read `$BRAIN_ROOT/.brain.toml`. If `slack` is not `true` under `[integrations]`, tell the user: "Slack integration is not enabled for this brain. Set `slack = true` in `.brain.toml` and authenticate the Slack MCP. See `integrations/slack.md` in the bootstrap repo for setup steps." Then stop.

3. **Fetch the Slack thread** via the Slack MCP tool. If authentication fails, surface the error and stop.

4. **Determine what's worth keeping.** Not every thread deserves a wiki page. If the thread is short, routine, or purely operational with no durable knowledge, say so and ask the user whether to proceed.

5. **Derive the slug**: `slack-<YYYY-MM-DD>-<brief-topic>`.

6. **Write `$BRAIN_ROOT/wiki/sources/<slug>.md`** using the source page template. Set:
   - `source_type: mcp-slack`
   - `source_url`: the original thread URL
   - Summarise the key decision, finding, or context — not a transcript.

7. **Update `wiki/index.md`**: add entry under `## Sources`.

8. **Cross-link** to relevant entity/concept pages. Create any missing ones.

9. **Append to `wiki/log.md`**: `## [YYYY-MM-DD] ingest | slack: <brief-topic>`

> **Note:** Slack content may contain confidential information. Ensure this brain's git remote is appropriate before committing.
