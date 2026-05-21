# /end-session

End-of-session housekeeping: sync any new or updated non-git `.md` files into `raw/articles/`, ingest them into the wiki, then log the session.

Run this at the end of any working session. It replaces the manual "copy files → ingest → log" workflow.

## Usage

```
/end-session
/end-session <topic>   (skip the session topic prompt)
```

## Steps

### 1 — Locate the brain

Use `$BRAIN_ROOT` if set. Otherwise walk up from cwd looking for `wiki/index.md`. If not found, tell the user and stop.

### 2 — Find candidate files

Run the following shell logic to collect `.md` files that are **not** inside any git repository:

```bash
find ~/Documents -name "*.md" -not -path "*/.git/*" | while read f; do
  if ! git -C "$(dirname "$f")" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    echo "$f"
  fi
done
```

Exclude `$BRAIN_ROOT` and its subdirectories (those are wiki pages, not source docs).

### 3 — Disambiguate filenames

The `raw/articles/` directory is flat. Before copying, check each candidate's basename against what already exists there:

- If the basename is unique across all candidates, use it unchanged.
- If two or more candidate files share the same basename (e.g. multiple `Overview.md` files), disambiguate by appending the **immediate parent directory name** in title-case with a hyphen: `Overview.md` from `Almoria/` → `Overview-Almoria.md`.
- Tell the user about any renames performed.

### 4 — Compare against raw/

For each candidate (using its final disambiguated name):

```bash
raw="$BRAIN_ROOT/raw/articles/<disambiguated-name>.md"
src_mtime=$(stat -c %Y "$src_file")
raw_mtime=$(stat -c %Y "$raw" 2>/dev/null || echo 0)
```

- If `$raw` does not exist → **copy** (new file).
- If `$src_mtime > $raw_mtime` → **copy** (source is newer).
- Otherwise → **skip** (raw is up to date).

Report the counts: N new, N updated, N skipped.

### 5 — Copy files

Copy each new/updated candidate to `$BRAIN_ROOT/raw/articles/<disambiguated-name>.md`.

Do **not** overwrite if nothing changed (the mtime check in step 4 handles this).

### 6 — Ingest into the wiki

If any files were copied:

- Call `/brain-ingest` with the full list of newly copied files, space-separated:
  ```
  /brain-ingest raw/articles/file1.md raw/articles/file2.md …
  ```
- Follow the full `/brain-ingest` steps for each file.

If nothing was copied, skip this step and tell the user: "raw/ is already up to date — nothing to ingest."

### 7 — Log the session

Call `/brain-log-session` (passing `<topic>` if one was given to `/end-session`).

This writes the session synthesis, updates `wiki/index.md`, and appends to `wiki/log.md`.

### 8 — Confirm

Report a brief summary:

```
End-of-session complete.
  Synced:   N files copied to raw/articles/
  Ingested: N wiki source pages created/updated
  Logged:   wiki/synthesis/sessions/<slug>.md
```
