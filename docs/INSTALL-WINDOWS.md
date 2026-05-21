# Installing Claude Brain on Windows (WSL2)

Claude Brain is designed for a Unix environment. On Windows, the recommended path is **WSL2 (Windows Subsystem for Linux)** running Ubuntu. This gives you a full Linux shell where `install.sh` runs without modification.

Native PowerShell / CMD installation is not supported — the `bash` installer and symlinked slash commands require a POSIX shell.

## Prerequisites

- Windows 10 (build 19041+) or Windows 11
- WSL2 with Ubuntu 22.04+ installed
- Claude Code CLI installed **inside WSL2** and authenticated
- Windows Terminal (recommended)

## Step 1 — Install WSL2 and Ubuntu

If WSL2 is not already set up:
```powershell
# Run in PowerShell as Administrator
wsl --install -d Ubuntu-22.04
```
Restart when prompted. Ubuntu will finish setup on first launch — set a username and password.

Verify WSL2 is being used (not WSL1):
```powershell
wsl --list --verbose
```
The Ubuntu entry should show `VERSION 2`.

## Step 2 — Install Obsidian (Windows native)

Obsidian runs natively on Windows and can open folders inside WSL2 via the `\\wsl$` path.

```powershell
# Via winget (recommended)
winget install Obsidian.Obsidian
```

Or download the installer from https://obsidian.md/download → Windows.

To open a WSL2 brain as an Obsidian vault:
1. Launch Obsidian → **Open folder as vault**.
2. Navigate to `\\wsl$\Ubuntu\home\<username>\<brain-path>` (e.g. `\\wsl$\Ubuntu\home\yourname\Work\Brain`).

Changes are reflected live — Obsidian reads directly from the WSL2 filesystem.

## Step 3 — Install tools inside WSL2

Open a WSL2 terminal and run:

**Graphify:**
```bash
pipx install graphifyy
# If pipx not found:
sudo apt-get install pipx && pipx ensurepath && pipx install graphifyy
```

**GitNexus (optional):**
```bash
# Install Node.js via NodeSource
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
npm install -g gitnexus
```

**Claude Code CLI (inside WSL2):**
Follow the Claude Code installation guide for Linux. Authenticate with `claude auth login`.

## Step 4 — Clone the bootstrap repo (inside WSL2)

```bash
git clone https://github.com/IoT-Gardener/Claude-Brain-Bootstrap.git ~/.claude/brain-bootstrap
```

Or `cd` into an existing local clone:
```bash
cd /path/to/Claude-Brain-Bootstrap
```

## Step 5 — Run install.sh (inside WSL2)

```bash
bash install.sh ~/Brain \
  --enable graphify,gitnexus \
  --seed ~/ \
  --auto
```

Adjust `--enable` to include only the integrations you want, and `--seed` to point at the directory you want to pull content from.

The script runs identically to macOS (minus the Homebrew tool installs, which you did above).

## Step 6 — Open in Obsidian

1. Launch Obsidian (Windows).
2. **Open folder as vault** → navigate to `\\wsl$\Ubuntu\home\<username>\<brain-path>`.
3. Enable community plugins: **Dataview**. Enable core plugins: **Backlinks**, **Graph view**.

## Step 7 — Post-install

Same as macOS:
- Fill in `## Local persona` in the brain's `CLAUDE.md`.
- Run `/brain-librarian` once (inside WSL2 terminal with Claude Code) to confirm hybrid behaviour.
- Open the graph view and confirm the wiki looks connected.

## Notes

- All brain operations (Claude Code, git, slash commands) run inside WSL2. Obsidian is the only Windows-native component.
- File paths inside WSL2 (e.g. `~/Brain`) and the Windows path (`\\wsl$\Ubuntu\home\<user>\Brain`) refer to the same files. Use the WSL2 path for all CLI operations.
- `raw/` is gitignored by default. Seeded files are not committed.
- The brain is initialised as a local git repo. Add a remote whenever you're ready: `git remote add origin <url> && git push -u origin main`.
- Performance note: file-heavy operations (large `--seed` walks) are fast on WSL2 ext4. Avoid placing brain directories on Windows NTFS paths (i.e. `/mnt/c/...`) — WSL2 filesystem access is significantly slower there.
