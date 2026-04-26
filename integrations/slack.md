# Integration: Slack MCP

Lets you ingest specific Slack threads live via `/brain-ingest-slack <url>` — captures decisions and context worth keeping without dumping your whole message history.

## What it does

The Slack MCP server authenticates with your Slack workspace and lets Claude Code read threads you link to. The `/brain-ingest-slack` skill fetches the thread, extracts what's worth keeping (decisions, findings, context — not a transcript), and writes a source page to the wiki.

**Thread-by-thread, not channel-wide.** You curate what enters the brain by choosing which threads to ingest. This avoids noise and keeps the wiki high-signal.

## Enable for a brain

1. In the brain's `.brain.toml`, set:
   ```toml
   [integrations]
   slack = true
   ```

2. Authenticate the Slack MCP. Connect the **Slack** integration from Claude.ai's integrations panel or your MCP settings. Authorise the workspaces you want accessible.

3. Test by running `/brain-ingest-slack <any-thread-url>` from within the brain directory.

## Getting a Slack thread URL

In Slack: hover the message that starts the thread → click the three-dot menu → **Copy link**. This gives you the `https://your-workspace.slack.com/archives/...` URL the skill expects.

## Workflow

1. Come across a Slack thread with a decision, design discussion, or useful context.
2. Copy the thread link.
3. From the brain directory: `/brain-ingest-slack <url>`
4. The skill assesses whether the thread has durable knowledge worth keeping, then writes `wiki/sources/slack-<date>-<topic>.md`, updates the index, cross-links related pages.

## Security note

Slack content almost always contains confidential information. Keep brains that use this integration away from public git remotes, or ensure `raw/` and `wiki/sources/` entries from Slack are excluded from commits if needed.

## Disable

Set `slack = false` in `.brain.toml`. The skill will refuse to run.
