# GitNexus

GitNexus is a local MCP server that indexes your git repos and answers structural code queries in real time: "what calls this function?", "what files import this module?", "show me all implementations of this interface." It uses a local index (no network, no LLM tokens per query) so responses are fast and cheap.

## How it differs from Graphify

| | GitNexus | Graphify |
|---|---|---|
| **Job** | Answer live structural queries via MCP | Build a static wiki orientation page |
| **When** | Index once; query any time | Run on demand; output ages at 14 days |
| **Output** | MCP responses (ephemeral) | `wiki/synthesis/code/<repo>.md` |
| **Cost** | Index time + near-zero per query | LLM tokens at run time |
| **Best for** | "What calls this function?" | "Orient me on this codebase" |

## Install

```bash
npm install -g gitnexus
```

Verify:
```bash
gitnexus --version
```

Requires Node.js 18+.

## Index a repo

```bash
gitnexus analyze /path/to/repo
```

GitNexus builds a local index of the repo's structure. Re-index after significant refactors:
```bash
gitnexus analyze /path/to/repo --force
```

The index is stored at `~/.gitnexus/indexes/<repo-hash>/`. It does not contain source code — only structural metadata.

## Register as an MCP server

Add GitNexus to `~/.claude/settings.json` so Claude Code can query it during sessions:

```json
{
  "mcpServers": {
    "gitnexus": {
      "command": "gitnexus",
      "args": ["serve"],
      "env": {}
    }
  }
}
```

`install.sh` adds this automatically when `gitnexus = true` in `.brain.toml`. To add it manually, edit `~/.claude/settings.json` and add the `gitnexus` entry under `mcpServers` (create the key if it doesn't exist). The server is idempotent — it's safe to register multiple times, but only one entry is needed.

Restart Claude Code after editing `settings.json`.

## Querying via Claude

Once registered, Claude can use GitNexus transparently. Useful queries:
- "What functions call `processPayment`?"
- "Which files import from `lib/auth`?"
- "What implements the `IUserRepository` interface?"
- "Show me the call chain from `main` to `sendEmail`."

GitNexus does not answer semantic questions ("what does this do?") — use `/brain-query` or `/brain-ingest-repo` for orientation. GitNexus answers structural questions ("who calls this?") that require precision.

## Multiple repos

Index each repo you want available:
```bash
gitnexus analyze ~/Work/my-api
gitnexus analyze ~/Work/my-frontend
gitnexus analyze ~/Work/my-services
```

All indexed repos are available to the single `gitnexus serve` MCP server instance.

## Troubleshooting

**`gitnexus: command not found`** — npm global bin not on PATH. Add `$(npm root -g)/../bin` to your PATH, or use `npx gitnexus`.

**Stale results** — re-run `gitnexus analyze <repo>` after large refactors. The index doesn't auto-update on file changes.

**MCP server not responding** — confirm `gitnexus` is in `~/.claude/settings.json` under `mcpServers` and that you've restarted Claude Code.
