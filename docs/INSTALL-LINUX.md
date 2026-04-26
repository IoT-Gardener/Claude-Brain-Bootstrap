# Installing Claude Brain on Linux (Pop!_OS / Ubuntu)

This guide covers manual installation on Debian/Ubuntu-based Linux distributions. The macOS `install.sh` script handles the platform-specific tool installs automatically; on Linux you run the equivalent steps yourself, then call `install.sh` for the brain scaffold and command setup.

## Prerequisites

- `bash` 4.0+
- `git`
- `curl`
- Claude Code CLI installed and authenticated (`claude --version`)
- Node.js 18+ (for GitNexus)
- Python 3.9+ (for Graphify)

## Step 1 — Install Obsidian

**Option A — AppImage (recommended, works everywhere):**
```bash
# Download the latest AppImage from the Obsidian releases page
# https://obsidian.md/download → Linux → AppImage
chmod +x Obsidian-*.AppImage
./Obsidian-*.AppImage
```

**Option B — Flatpak (if Flatpak is available):**
```bash
flatpak install flathub md.obsidian.Obsidian
```

**Option C — Snap:**
```bash
sudo snap install obsidian --classic
```

**Option D — .deb (Ubuntu 22.04+):**
```bash
# Download the .deb from https://obsidian.md/download → Linux → .deb
sudo dpkg -i obsidian_*.deb
sudo apt-get install -f  # fix any dependency issues
```

## Step 2 — Install Graphify

```bash
pip3 install graphify
```

If `pip3` is not found:
```bash
sudo apt-get install python3-pip
pip3 install graphify
```

Verify:
```bash
graphify --version
```

If `graphify` is not on PATH after install, add `~/.local/bin` to your PATH:
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Step 3 — Install GitNexus (optional)

```bash
npm install -g gitnexus
```

If `npm` is not found:
```bash
# Install Node.js via NodeSource (recommended over apt for a recent version)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
npm install -g gitnexus
```

Verify:
```bash
gitnexus --version
```

## Step 4 — Clone the bootstrap repo

```bash
git clone https://github.com/IoT-Gardener/Claude-Brain-Bootstrap.git ~/.claude/brain-bootstrap
```

Or, if you already have it locally, `cd` into it:
```bash
cd /path/to/Claude-Brain-Bootstrap
```

## Step 5 — Run install.sh

Run `install.sh` from the bootstrap repo. On Linux, the script detects the platform, skips the Homebrew tool installs, and asks you to confirm that you've installed the tools manually. Press `y` to continue. Everything else — scaffold, templates, symlinks, `.brain.toml`, brain-detection block, git init — works identically to macOS.

```bash
bash install.sh ~/Brain \
  --enable graphify,gitnexus \
  --seed ~/ \
  --auto
```

Adjust `--enable` to include only the integrations you want, and `--seed` to point at the directory you want to pull content from.

## Step 6 — Open in Obsidian

1. Launch Obsidian.
2. **Open folder as vault** → select the brain directory (e.g. `~/Brain`).
3. Enable community plugins: **Dataview** (for dashboard queries) and optionally **Smart Connections**.
4. Enable core plugins: **Backlinks**, **Graph view**, **Outgoing links**.

## Step 7 — Post-install

Same as macOS:
- Fill in `## Local persona` in the brain's `CLAUDE.md`.
- Run `/brain-librarian` once to confirm hybrid behaviour.
- Open the graph view and confirm the wiki looks connected.

## Notes

- `raw/` is gitignored by default. Your seed files are copied there but not committed.
- The brain is initialised as a local git repo. Add a remote whenever you're ready: `git remote add origin <url> && git push -u origin main`.
- If `claude` is not on PATH, install it per the Claude Code documentation before running `install.sh`.
