# /brain-log-session

Write a structured end-of-session summary to `wiki/synthesis/sessions/<date>-<topic>.md`.

This command makes conversations disposable. Once a session's key decisions, findings, and context are filed here, the full transcript can be compacted or discarded — and the brain will restore enough context for productive work in the next session.

Run this at the end of any meaningful session before compacting.

## Usage

```
/brain-log-session
/brain-log-session <topic>   (skip the topic prompt)
```

## Steps

1. **Locate the brain.** Use `$BRAIN_ROOT` if set. Otherwise walk up from cwd looking for `wiki/index.md`. If not found, tell the user and stop.

2. **Determine the topic.** If `<topic>` was passed as an argument, use it. Otherwise, ask the user: "What's the one-line topic for this session?" (e.g. "auth refactor", "homelab VLAN design", "chapter 3 draft"). Keep it to 3–6 words — it becomes the filename.

3. **Derive the slug.** Combine today's date and the topic: `YYYY-MM-DD-topic-in-kebab-case`. Check if `$BRAIN_ROOT/wiki/synthesis/sessions/<slug>.md` already exists — if so, append `-2` (or increment) to avoid collision.

4. **Synthesise the session.** Review the conversation so far and extract:
   - **What we worked on** — the task or question that drove the session (1–2 sentences).
   - **Key decisions** — any choices made, with a brief reason for each. If a decision was close, note what was rejected and why.
   - **Findings** — things learned, discovered, or confirmed that aren't already in the wiki.
   - **Open threads** — unresolved questions or things explicitly deferred to a future session.
   - **Actions taken** — files written, configs changed, commands run, PRs opened.
   - **Next steps** — concrete follow-ups, if any.
   Do not transcribe the conversation. Extract signal only.

5. **Write `$BRAIN_ROOT/wiki/synthesis/sessions/<slug>.md`** using the synthesis page template:
   ```yaml
   ---
   title: <YYYY-MM-DD> — <Topic>
   type: synthesis
   subtype: session
   tags: [session, <relevant-tags>]
   created: YYYY-MM-DD
   updated: YYYY-MM-DD
   project: <project-name-if-applicable>
   ---
   ```
   Body: the structured synthesis from step 4, in dense bullets.

6. **Update `wiki/index.md`**: add entry under `## Synthesis › ### Sessions`:
   ```
   - [[<slug>]] — <one-line summary> (tags: session, <tags>)
   ```

7. **Cross-link to relevant wiki pages.** If decisions or findings touch existing entity, concept, or code-synthesis pages, add a reference to this session page in the relevant section. If something in this session supersedes a claim in an existing page, mark it `> superseded by [[<slug>]]`.

8. **Append to `wiki/log.md`**:
   ```
   ## [YYYY-MM-DD] session | <topic>
   ```

9. **Confirm.** Tell the user: "Session logged to `wiki/synthesis/sessions/<slug>.md`. Safe to compact."
