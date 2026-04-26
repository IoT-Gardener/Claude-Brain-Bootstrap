# Claude Brain Bootstrap

A personal knowledge base that Claude maintains for you — so every session starts with real context about your code, writing, decisions, and ongoing work, without mass-reading files from scratch each time.

Follows the [Karpathy LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f): you curate what goes in, the agent maintains the structure.

---

## How it works

The brain is a folder of plain markdown files — an `index.md` that acts as a map, and a `wiki/` directory that Claude owns and maintains. You own a `raw/` inbox where source material lands before being ingested.

```
Brain/
├── raw/          ← your inbox: articles, docs, session transcripts
├── wiki/         ← Claude's: sources, entities, concepts, synthesis
│   ├── index.md  ← the map — read first on every query
│   ├── log.md    ← append-only operation log
│   ├── sources/  ← one page per ingested item
│   ├── entities/ ← people, repos, services, tools
│   ├── concepts/ ← patterns, techniques, decisions
│   └── synthesis/
│       ├── code/      ← Graphify repo digests (stale after 14 days)
│       └── sessions/  ← end-of-session summaries
└── CLAUDE.md     ← brain schema + your local persona
```

**The brain is Claude's first port of call.** When you open Claude Code in any project, it detects the relevant brain and runs `/brain-query` before reading source files. The brain answers from its wiki; only if the wiki falls short does it reach into individual files.

**Three tools work together:**

| Tool | Job | Output |
|---|---|---|
| **Wiki** (`wiki/`) | Persistent knowledge store — decisions, architecture, finished writing | Markdown pages Claude reads on every query |
| **Graphify** | Deep semantic repo analysis — function signatures, call graphs, module dependencies | `wiki/synthesis/code/<repo>.md` (refreshed every 14 days) |
| **GitNexus** | Live structural code queries via MCP — "what calls this function?" | Real-time MCP responses during sessions |

Graphify and GitNexus complement each other: Graphify gives you a browsable, persistent map in Obsidian; GitNexus gives you live precision during active coding sessions.

**Obsidian** opens the same markdown files the brain uses. You get a visual graph of connections, backlinks, Dataview dashboards for stale content, and the Web Clipper for capturing articles directly into `raw/`.

---

## Install on macOS

One command installs everything: Obsidian, Graphify, GitNexus, the brain scaffold, slash commands, and runs an initial setup pass.

**Prerequisites:** [Claude Code](https://claude.ai/code) installed and authenticated, [Homebrew](https://brew.sh).

```bash
curl -fsSL https://raw.githubusercontent.com/IoT-Gardener/Claude-Brain-Bootstrap/main/install.sh \
  | bash -s -- --enable graphify,gitnexus --seed ~/ --auto
```

This creates a `Brain/` folder in the current directory. To install elsewhere, pass the path as the first argument:

```bash
... | bash -s -- ~/Brain --enable graphify,gitnexus --seed ~/ --auto
```

Pass only the `--enable` flags for integrations you want — omit any you don't need.

### What `--auto` does

With `--auto`, the installer runs a headless Claude Code pass after scaffolding:

1. Runs **Graphify** on every git repo found under `--seed` — writes a semantic digest to `wiki/synthesis/code/<repo>.md`
2. Runs **`/brain-lint`** — fixes structural issues in the wiki (index gaps, broken links, stale pages)
3. Runs **`/brain-librarian`** — applies mechanical maintenance fixes; writes a checklist of judgement calls for your review

Each step is independent — if Graphify fails on one repo, the rest continue. All operations are idempotent: safe to re-run if something is interrupted.

Files copied to `raw/` by `--seed` sit there until you deliberately ingest them with `/brain-ingest`. To auto-ingest everything in one go:

```bash
... --auto --ingest-seed
```

This prints a file count and cost estimate before running, and asks for confirmation. Add `--yes` to skip the prompt.

### Flags

| Flag | Description |
|---|---|
| `--enable graphify,gitnexus` | Enable integrations (comma-separated). Options: `graphify`, `gitnexus`, `web-clipper`, `notion`, `slack` |
| `--seed <path>` | Walk a directory: git repos → Graphify queue; other files → `raw/` |
| `--graphify-repos <path,...>` | Explicit repos to run Graphify on (merged with `--seed` results) |
| `--auto` | Run headless first-run after install (Graphify + lint + librarian) |
| `--ingest-seed` | With `--auto`: also bulk-ingest all seeded files (shows cost estimate first) |
| `--yes` | Skip confirmation prompts |

### After install

1. Fill in `## Local persona` in `<brain>/CLAUDE.md` — tell Claude who you are, what this brain covers, and any standing preferences.
2. Open the brain as an **Obsidian vault** → enable the **Dataview** and **Backlinks** plugins → add a dashboard note (see below).
3. Open Claude Code in any project directory. The brain auto-detects from `cwd`.

**Obsidian dashboard** — create a note with this Dataview query to track staleness:

````markdown
## Stale code pages (>14 days)
```dataview
TABLE updated, source_repo
FROM "wiki/synthesis/code"
WHERE date(updated) < date(today) - dur(14 days)
SORT updated ASC
```

## Stale prose pages (>90 days)
```dataview
TABLE updated, type
FROM "wiki"
WHERE status = "active" AND date(updated) < date(today) - dur(90 days)
AND !contains(file.folder, "synthesis/code")
SORT updated ASC
```
````

---

## Slash commands

Once installed, these commands are available in any Claude Code session:

| Command | What it does |
|---|---|
| `/brain-query <question>` | Query the wiki + GitNexus (if enabled); return a cited answer |
| `/brain-ingest <file>` | Ingest a file from `raw/` into the wiki |
| `/brain-ingest-repo <path>` | Repo digest — deep (Graphify) if enabled, shallow otherwise |
| `/brain-log-session` | Write an end-of-session summary so the conversation becomes disposable |
| `/brain-librarian` | Full maintenance pass — auto-fixes + judgement-call checklist |
| `/brain-lint` | Fast diagnostic; `--apply` to auto-fix including stale code re-ingest |

Web Clipper (`/brain-ingest-clipped`), Notion (`/brain-ingest-notion`), and Slack (`/brain-ingest-slack`) are available but gated on their respective `.brain.toml` flags — these are a later milestone.

---

## Linux / Windows

- **Linux (Pop!_OS / Ubuntu):** see [`docs/INSTALL-LINUX.md`](docs/INSTALL-LINUX.md) — install tools manually, then run `install.sh` identically.
- **Windows:** see [`docs/INSTALL-WINDOWS.md`](docs/INSTALL-WINDOWS.md) — requires WSL2. Obsidian runs natively on Windows and reads the WSL2 brain directory via `\\wsl$`.

---

## Integrations

| Integration | Purpose | Setup |
|---|---|---|
| **Graphify** | Semantic code analysis | [`integrations/graphify.md`](integrations/graphify.md) |
| **GitNexus** | Live cross-repo code queries via MCP | [`integrations/gitnexus.md`](integrations/gitnexus.md) |
| **Web Clipper** | Browser → `raw/articles/` capture _(M3)_ | [`integrations/web-clipper.md`](integrations/web-clipper.md) |
| **Notion MCP** | Fetch Notion pages into wiki _(M3)_ | [`integrations/notion.md`](integrations/notion.md) |
| **Slack MCP** | Extract decisions from Slack threads _(M3)_ | [`integrations/slack.md`](integrations/slack.md) |

Enable/disable integrations in `.brain.toml`.

---

## Design principles

- **Brain first, files second.** Claude queries the wiki before reading source files. The brain exists to avoid mass-reading.
- **LLM-owned wiki, human-owned `raw/`.** You drop sources; Claude maintains the structure.
- **Curation over completeness.** Signal-to-noise is the brain's value. `--auto` deliberately stops short of bulk ingest; `--ingest-seed` is the explicit opt-in.
- **Plain markdown, no lock-in.** Obsidian, Claude, your editor, and git all see the same files.
- **Symlinked commands.** `~/.claude/commands/brain-*.md` → this repo — `git pull` here updates every brain's commands.
- **Two staleness thresholds.** Code pages go stale in 14 days (code changes fast). Prose pages go stale in 90 days. Both are flagged by lint and auto-refreshed by the librarian.
