# /brain-lint

Health check the wiki. Reports structural issues; optionally fixes safe ones automatically.

## Usage

```
/brain-lint
/brain-lint --apply    (auto-fix safe issues, including re-ingesting stale code pages; always confirms before deleting)
```

Run weekly, or any time the wiki feels disorganised.

## Steps

1. **Locate the brain.** Use `$BRAIN_ROOT` if set. Otherwise walk up from cwd looking for `wiki/index.md`. If not found, tell the user and stop.

2. **Collect all wiki pages.** List every `.md` file under `$BRAIN_ROOT/wiki/` recursively (excluding `index.md` and `log.md`).

3. **Check for orphan pages.** A page is an orphan if no other wiki page contains `[[<slug>]]`. List all orphans. Suggest for each: link it from a parent page, add it to the index, or delete it if it's truly empty/redundant.

4. **Check for dangling links.** Scan every page for `[[slug]]` references that don't correspond to an existing file. List them. With `--apply`, attempt to resolve obvious typos or case differences. Never silently delete a reference.

5. **Check for stale pages.** Two staleness thresholds:
   - **Code synthesis pages** (`wiki/synthesis/code/*.md` or pages with `subtype: code` frontmatter): flag if `updated` is more than **14 days** ago. Read the page's `source_repo` frontmatter field to get the repo path. With `--apply`, automatically re-run `/brain-ingest-repo <source_repo> --update` for each stale code page, overwriting it with a fresh digest. Note: this costs tokens and takes time proportional to the number of stale repos.
   - **All other pages** with `status: active`: flag if `updated` is more than **90 days** ago. Flag for review; do not auto-archive.

6. **Check for superseded claims.** If a page's `supersedes:` list names pages that still have `status: active` and don't yet carry a `> superseded by [[...]]` marker, add the marker with `--apply`.

7. **Check for index gaps.** List any pages under `wiki/` that have no entry in `wiki/index.md`. With `--apply`, add them automatically using the page's TL;DR line as the summary.

8. **Check for empty pages.** List pages that have frontmatter but no body content. Suggest populating or deleting.

9. **Report.** Produce a summary:
   ```
   Brain lint report — [YYYY-MM-DD]
   ✓ N pages checked
   ⚠ N orphans
   ⚠ N dangling links
   ⚠ N stale pages (>90d)
   ⚠ N index gaps
   ⚠ N empty pages
   ```
   Follow with per-issue details and suggested actions.

10. **Append to `wiki/log.md`**: `## [YYYY-MM-DD] lint | N issues found, N fixed`
