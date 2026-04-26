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
pip3 install graphify
```

Verify:
```bash
graphify --version
```

Requires Python 3.9+. Install via Homebrew Python on macOS if needed:
```bash
brew install python
pip3 install graphify
```

## Basic use

```bash
# Run on a repo — outputs to stdout by default
graphify /path/to/repo

# Write output to a file
graphify /path/to/repo --output /tmp/repo-graph.md

# Limit depth (useful for large monorepos)
graphify /path/to/repo --depth 3
```

The `/brain-ingest-repo` command runs Graphify automatically when `graphify = true` in `.brain.toml` and ingests its output into the wiki. You rarely need to call Graphify directly.

## Re-running (refresh)

Graphify pages have `staleness: 14d` frontmatter. When the page is older than 14 days, `/brain-lint` flags it for refresh. Re-run `/brain-ingest-repo <repo> --update` to overwrite with a fresh digest. The `--update` flag skips the "page already exists" confirmation.

## Supported languages

Graphify uses tree-sitter parsers. Broadly supported: Python, TypeScript, JavaScript, Rust, Go, Ruby, C/C++. Check `graphify --list-languages` for the current list.

## Troubleshooting

**`graphify: command not found`** — pip installed to a non-PATH location. Try `python3 -m graphify` or add `~/.local/bin` to your PATH.

**Empty output** — repo may be too small or use an unsupported language. `/brain-ingest-repo` (the manual shallow digest) works on any repo regardless of language.

**Slow on large repos** — use `--depth` to limit traversal, or run on a subdirectory (e.g. `graphify /path/to/repo/src`).
