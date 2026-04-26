# Integration: Obsidian Web Clipper

Lets you clip articles from any browser directly into `raw/articles/` with one click, then ingest them with `/brain-ingest-clipped`.

## What it does

The Obsidian Web Clipper browser extension saves the current page as a markdown file into your vault. Configured to point at a brain's `raw/articles/` folder, it becomes the capture front-end for the `/brain-ingest-clipped` skill.

## Requirements

- Obsidian installed and the brain opened as a vault (see Milestone 2 setup).
- The [Obsidian Web Clipper](https://obsidian.md/clipper) browser extension (Chrome / Firefox / Safari).

## Enable for a brain

1. In the brain's `.brain.toml`, set:
   ```toml
   [integrations]
   web-clipper = true
   ```

2. Install the Web Clipper extension from [obsidian.md/clipper](https://obsidian.md/clipper).

3. Open the extension settings. Under **Vault**, select this brain's vault. Under **Note location**, set the folder to `raw/articles`.

4. Set a frontmatter template so clipped articles are immediately ingest-ready:
   ```
   ---
   title: {{title}}
   source_url: {{url}}
   captured: {{date}}
   tags: []
   ---
   ```

5. In Obsidian settings → **Files and links** → **Default location for new attachments**, set to `raw/assets`. This ensures any images the clipper downloads land in the right place.

6. Optionally hotkey "Download attachments for current file" in Obsidian — useful for articles with images you want the agent to be able to read.

## Workflow

1. Browse to an article worth keeping.
2. Click the Web Clipper extension icon → clip.
3. Switch to Claude Code in the brain directory.
4. Run `/brain-ingest-clipped` — the skill picks up the newest file in `raw/articles/` and ingests it.

## Disable

Set `web-clipper = false` in `.brain.toml`. The skill will refuse to run and remind you.
