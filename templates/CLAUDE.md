# Brain — Operating Manual

## Local persona

<!-- Fill this in after install. Tell the agent who you are, what this brain covers,
     any standing constraints, and how you like to work together.
     Examples:
       - "This brain covers my notes, projects, and writing."
       - "This brain covers work at [Company]. Never copy source code verbatim into wiki — summaries only."
       - "My writing style is concise, direct, no filler phrases."
     Keep it to 5-10 bullet points. The agent reads this on every session. -->

- (your name and role)
- (what this brain covers)
- (any standing constraints or preferences)

---

## What this brain is

An LLM-maintained knowledge base following the Karpathy wiki pattern. You (the agent) own and maintain the `wiki/` directory. The human curates `raw/` and gives direction. The wiki compounds — good query-time answers get filed back, so the brain grows smarter over time.

**Key principle:** the human never has to maintain the wiki manually. You handle all bookkeeping. The human drops sources and directs; you read, synthesise, cross-link, and keep it healthy.

---

## Directory layout

```
raw/             ← human-only inbox; you read but never write here
  articles/      ← web-clipped articles
  sessions/      ← exported Claude / AI session transcripts
  documents/     ← PDFs, exported docs
  assets/        ← images, attachments
wiki/            ← you own this entirely
  index.md       ← content catalog; READ THIS FIRST on every query
  log.md         ← append-only session/operation log
  sources/       ← one summary page per raw item ingested
  entities/      ← people, hardware, services, repos, orgs
  concepts/      ← techniques, patterns, tools, rules, ideas
  synthesis/     ← query-time answers worth keeping; filed back here
    code/        ← Graphify/repo digests (staleness: 14 days)
    sessions/    ← end-of-session structured summaries
    maintenance/ ← librarian judgement-call checklists
  personas/      ← personas (writing voices, characters, decks)
.claude/
  agents/
    brain-librarian.md  ← librarian subagent definition
CLAUDE.md        ← this file; the brain's schema and operating manual
.brain.toml      ← local integration flags (graphify, gitnexus, web-clipper, notion, slack…)
```

---

## Operation: Ingest

Triggered by the user dropping a file into `raw/<type>/` and running `/brain-ingest`.

Steps:
1. Read the source file fully.
2. Write `wiki/sources/<slug>.md` — summary page (use the source page template).
3. Update `wiki/index.md` — add an entry under the appropriate category.
4. Identify 5–15 existing wiki pages touched by this source. For each:
   - Add a cross-reference link pointing to the new source page.
   - Update any claims the source supersedes (mark old claims with `> superseded by [[new-page]]`).
   - Create the page if it doesn't exist yet (use the appropriate template).
5. Append to `wiki/log.md`: `## [YYYY-MM-DD] ingest | <Title>`

If there is nothing in the wiki yet, create at least 3 pages from this first source (one source page + two entity or concept pages).

---

## Operation: Query

Triggered by the user asking a question or running `/brain-query`.

Steps:
1. Read `wiki/index.md` in full.
2. Identify the 3–8 most relevant pages from the index. Read them.
3. Follow cross-links to related pages where they add material detail.
4. If `.brain.toml` has `gitnexus = true` and the question is code-related, query the GitNexus MCP for structural detail (call graphs, file imports, function lookups). Use alongside wiki results — they are complementary, not alternatives.
5. Answer with inline citations (`[[page-name]]` for wiki; `(gitnexus)` for GitNexus-sourced facts).
6. If the answer is a synthesis worth keeping (non-obvious, combines multiple sources, likely to be asked again), ask the user: "This seems worth filing — should I save it to `wiki/synthesis/<slug>.md`?" If yes, write it using the synthesis template and update `wiki/index.md`.

---

## Operation: Lint

Triggered by the user running `/brain-lint` (recommended weekly).

Check and report:
- **Orphan pages** — pages with zero inbound wiki-links. List them; suggest parent pages or deletion.
- **Dangling links** — `[[links]]` that point to non-existent pages. Suggest creating the target or correcting the link.
- **Stale code pages** — `wiki/synthesis/code/*.md` pages where `updated` is more than 14 days ago. Flag for re-running `/brain-ingest-repo --update`.
- **Stale prose pages** — all other pages where `updated` is more than 90 days ago and `status: active`. Flag for review.
- **Superseded claims** — pages that still assert something contradicted by a newer source. Propose updating.
- **Index gaps** — pages in `wiki/` not listed in `index.md`. Add them.
- **Empty pages** — pages with only frontmatter and no body. Flag or populate.

With `--apply`, fix what can be fixed automatically (index gaps, dangling links where the target clearly exists under a different slug). Always confirm with the user before deleting anything.

## Operation: Librarian

Triggered by the user running `/brain-librarian`. Runs in a separate subagent context (defined at `.claude/agents/brain-librarian.md`) so it doesn't pollute the current session.

The librarian runs a deeper maintenance pass than lint:
- **Auto-applies** mechanical fixes (index gaps, backlinks, frontmatter normalisation, log entries) without asking.
- **Writes a judgement-call checklist** to `wiki/synthesis/maintenance/YYYY-MM-DD.md` for anything requiring human review (supersession, duplicate concepts, stub cleanup, stale page prompts).

Run weekly, after bulk ingests, or any time the wiki feels disorganised.

## Operation: Ingest repo

Triggered by `/brain-ingest-repo <path>`. Produces a digest of a git repo at `wiki/synthesis/code/<repo>.md`. Auto-selects deep mode (Graphify) if `graphify = true` in `.brain.toml`, otherwise shallow (manual sampling). Use `--update` to refresh without a confirmation prompt.

## Available commands

Core: `/brain-query`, `/brain-ingest`, `/brain-ingest-repo`, `/brain-log-session`, `/brain-librarian`, `/brain-lint`.

Integration-gated (enable in `.brain.toml`): `/brain-ingest-clipped` (web-clipper), `/brain-ingest-notion` (notion), `/brain-ingest-slack` (slack).

---

## Page conventions

Every wiki page starts with YAML frontmatter:

```yaml
---
title: Human-readable title
type: source | entity | concept | synthesis | persona
tags: [tag1, tag2]
created: YYYY-MM-DD
updated: YYYY-MM-DD
status: active | archived | stub
supersedes: []   # list slugs this page replaces, if any
source_count: 0  # for concept/entity pages: number of sources that informed this
---
```

After frontmatter:
- **One-line TL;DR** at the very top of the body (no heading). This is what the index summary quotes.
- Prefer bullet points over prose paragraphs. Dense bullets > long paragraphs for LLM retrieval.
- Use `[[wiki-links]]` (not file paths) for cross-references. These survive file moves.
- Keep pages focused — split if a page is trying to cover two clearly distinct things.

---

## Index conventions (`wiki/index.md`)

The index is the agent's map. It is read first on every query. Keep it fast to scan.

Format per entry:
```
- [[page-slug]] — one-line summary (tags: tag1, tag2)
```

Grouped by category: Sources · Entities · Concepts · Synthesis · Personas.

When a page is archived, move its index entry to an `## Archived` section at the bottom rather than deleting it — it may be referenced by log entries.

---

## Log conventions (`wiki/log.md`)

Append-only. One `##` entry per operation:

```
## [YYYY-MM-DD] ingest | Article Title
## [YYYY-MM-DD] query | Topic queried (brief note on what was found)
## [YYYY-MM-DD] lint | N issues found, N fixed
## [YYYY-MM-DD] session | Brief session summary
```

Never edit past entries. Use `grep "^\#\# \[" wiki/log.md | tail -10` to see recent activity.
