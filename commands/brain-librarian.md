# /brain-librarian

Invoke the brain librarian subagent for a full maintenance pass.

The librarian runs in its own context window so it doesn't pollute the current session. It applies mechanical fixes automatically and surfaces judgement calls as a checklist for your review — it does not silently make opinionated changes.

Run this weekly, after a bulk ingest, or any time the wiki feels disorganised.

## Usage

```
/brain-librarian
```

No arguments. The librarian auto-detects the brain from cwd.

## Steps

1. **Locate the brain.** Use `$BRAIN_ROOT` if set. Otherwise walk up from cwd looking for `wiki/index.md`. If not found, tell the user and stop.

2. **Invoke the librarian subagent.** Hand off control to the `brain-librarian` subagent defined at `$BRAIN_ROOT/.claude/agents/brain-librarian.md`. Pass `$BRAIN_ROOT` as context.

   The subagent will:
   - **Auto-apply mechanical fixes** (no confirmation needed): index gaps, missing backlinks, frontmatter normalisation, stale log entries.
   - **Write a judgement-call checklist** to `$BRAIN_ROOT/wiki/synthesis/maintenance/YYYY-MM-DD.md` for anything that requires human review: supersession candidates, duplicate concepts, stub pages, pages flagged for refresh.

3. **Report the result.** When the subagent returns, summarise:
   - N mechanical fixes applied (list them briefly).
   - Path to the maintenance checklist (if any judgement calls were found).
   - Any errors or pages the librarian couldn't process.

4. Tell the user: "Review `wiki/synthesis/maintenance/YYYY-MM-DD.md` and apply any checklist items you agree with."
