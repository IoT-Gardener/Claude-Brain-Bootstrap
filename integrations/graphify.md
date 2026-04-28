# Graphify

Graphify uses tree-sitter to parse source code and an LLM to extract a structured semantic graph: function signatures, call relationships, module dependencies, type hierarchies, and key patterns. It produces a dense, LLM-retrievable digest of a codebase without copying source verbatim.

## How it differs from GitNexus

| | Graphify | GitNexus |
|---|---|---|
| **Job** | Build a static wiki page summarising a repo | Answer live structural queries via MCP |
| **When** | Run on demand; output ages at 14 days | Index once; query any time |
| **Output** | `wiki/synthesis/code/<repo>.md` | MCP responses (not stored in wiki) |
| **Cost** | LLM tokens at run time | Index time + near-zero per query |
| **Best for** | "Orient me on this codebase" | "What calls this function?" |

Use both together: Graphify gives Claude a pre-loaded map; GitNexus answers structural questions that need live precision.

## Install

```bash
pipx install graphifyy
graphify install
```

`graphify install` sets up Graphify as a Claude Code skill (available as `/graphify` in sessions). The `graphify` CLI is also available directly in your shell for programmatic use.

Requires Python 3.10+ and `pipx`. Install pipx via Homebrew if needed:
```bash
brew install pipx
pipx ensurepath
```

Verify:
```bash
graphify --version
```

## Basic use

```bash
# Run on a repo — produces a markdown report + interactive HTML graph
graphify /path/to/repo

# Deep analysis (slower but richer)
graphify /path/to/repo --mode deep
```

Output is written to `graphify-out/` in the current directory: a markdown report (`graphify-out/GRAPH_REPORT.md`) and an interactive HTML graph (`graphify-out/GRAPH_REPORT.html`). `/brain-ingest-repo` reads the markdown report and writes the digest to the wiki automatically.

The `/brain-ingest-repo` command runs Graphify automatically when `graphify = true` in `.brain.toml`. You rarely need to call it directly.

## Re-running (refresh)

Graphify pages have `staleness: 14d` frontmatter. When the page is older than 14 days, `/brain-lint` flags it for refresh. Re-run `/brain-ingest-repo <repo> --update` to overwrite with a fresh digest. The `--update` flag skips the "page already exists" confirmation.

## Supported languages

Graphify uses tree-sitter parsers. Broadly supported: Python, TypeScript, JavaScript, Rust, Go, Ruby, C/C++.

## Troubleshooting

**`graphify: command not found`** — pipx installed to a non-PATH location. Run `pipx ensurepath` and restart your shell.

**Empty output** — repo may be too small or use an unsupported language. `/brain-ingest-repo` falls back to shallow (manual) mode automatically in this case.

**Slow on large repos** — use `--mode deep` selectively, or run on a subdirectory.
