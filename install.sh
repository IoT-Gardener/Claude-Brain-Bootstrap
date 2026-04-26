#!/usr/bin/env bash
# install.sh — Bootstrap a new Claude Brain from this template.
#
# Usage:
#   ./install.sh <target-path> [options]
#
# Options:
#   --enable <integration,...>    Enable integrations: graphify, gitnexus, web-clipper, notion, slack
#   --seed <path>                 Walk a directory: .git repos → Graphify queue; files → raw/ (default: cwd)
#   --graphify-repos <path,...>   Explicit repos to run Graphify on (merged with --seed results)
#   --gitnexus-repos <path,...>   Explicit repos to index with GitNexus (defaults to Graphify targets)
#   --auto                        Run headless first-run after install (Graphify + lint + librarian)
#   --ingest-seed                 With --auto: also bulk-ingest all seeded files (shows cost estimate)
#   --yes                         Skip confirmation prompts (use with --ingest-seed)
#
# Examples:
#   ./install.sh --enable graphify --auto                            (seeds from cwd, creates ./Brain)
#   ./install.sh ~/Brain --enable graphify --seed ~/Projects --auto  (explicit path and seed)
#
# Via curl:
#   curl -fsSL https://raw.githubusercontent.com/IoT-Gardener/Claude-Brain-Bootstrap/main/install.sh \
#     | bash -s -- --enable graphify --seed ~/Projects --auto
#
# Re-running is safe (idempotent) — existing content is never overwritten.

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC} $*"; }
fail() { echo -e "${RED}  ✗${NC} $*"; exit 1; }
info() { echo -e "  $*"; }
head() { echo -e "${BLUE}▸${NC} $*"; }

# ── Parse arguments ───────────────────────────────────────────────────────────
TARGET_PATH=""
ENABLE_INTEGRATIONS=""
SEED_PATH=""
GRAPHIFY_REPOS_EXTRA=""
GITNEXUS_REPOS_EXTRA=""
AUTO=false
INGEST_SEED=false
YES=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --enable)           ENABLE_INTEGRATIONS="$2"; shift 2 ;;
        --enable=*)         ENABLE_INTEGRATIONS="${1#*=}"; shift ;;
        --seed)             SEED_PATH="$2"; shift 2 ;;
        --seed=*)           SEED_PATH="${1#*=}"; shift ;;
        --graphify-repos)   GRAPHIFY_REPOS_EXTRA="$2"; shift 2 ;;
        --graphify-repos=*) GRAPHIFY_REPOS_EXTRA="${1#*=}"; shift ;;
        --gitnexus-repos)   GITNEXUS_REPOS_EXTRA="$2"; shift 2 ;;
        --gitnexus-repos=*) GITNEXUS_REPOS_EXTRA="${1#*=}"; shift ;;
        --auto)             AUTO=true; shift ;;
        --ingest-seed)      INGEST_SEED=true; shift ;;
        --yes)              YES=true; shift ;;
        -*) fail "Unknown option: $1" ;;
        *) TARGET_PATH="$1"; shift ;;
    esac
done

# Default to ./Brain in the current directory if no path given
[[ -z "$TARGET_PATH" ]] && TARGET_PATH="./Brain"

# Default seed to cwd if not passed
[[ -z "$SEED_PATH" ]] && SEED_PATH="$(pwd)"

# Expand ~ and resolve to absolute path
TARGET_PATH="${TARGET_PATH/#\~/$HOME}"
TARGET_PATH="$(cd "$(dirname "$TARGET_PATH")" 2>/dev/null && pwd)/$(basename "$TARGET_PATH")" || true

# ── OS detection ──────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
    Darwin)  PLATFORM="macos" ;;
    Linux)   PLATFORM="linux" ;;
    MINGW*|CYGWIN*|MSYS*) PLATFORM="windows" ;;
    *)       PLATFORM="unknown" ;;
esac

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║        Claude Brain Bootstrap            ║"
echo "╚══════════════════════════════════════════╝"
echo ""
info "Platform:     $PLATFORM"
info "Target:       $TARGET_PATH"
info "Integrations: ${ENABLE_INTEGRATIONS:-none (edit .brain.toml to enable later)}"
[[ -n "$SEED_PATH" ]] && info "Seed:         $SEED_PATH"
echo ""

if [[ "$PLATFORM" == "linux" ]]; then
    SCRIPT_DIR_FOR_DOCS="$(cd "$(dirname "${BASH_SOURCE[0]:-install.sh}")" 2>/dev/null && pwd)" || SCRIPT_DIR_FOR_DOCS="."
    warn "Linux detected. The tool installs (Obsidian, Graphify, GitNexus) must be done manually."
    warn "See: $SCRIPT_DIR_FOR_DOCS/docs/INSTALL-LINUX.md"
    warn "Once tools are installed, re-run this script to scaffold the brain."
    echo ""
    read -r -p "  Tools already installed? Continue with scaffolding? [y/N] " _cont
    [[ "$_cont" =~ ^[Yy]$ ]] || exit 0
elif [[ "$PLATFORM" == "windows" ]]; then
    SCRIPT_DIR_FOR_DOCS="$(cd "$(dirname "${BASH_SOURCE[0]:-install.sh}")" 2>/dev/null && pwd)" || SCRIPT_DIR_FOR_DOCS="."
    warn "Windows detected. Run this script inside WSL2."
    warn "See: $SCRIPT_DIR_FOR_DOCS/docs/INSTALL-WINDOWS.md"
    exit 1
fi

# ── Locate the bootstrap repo ─────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-install.sh}")" 2>/dev/null && pwd)" || SCRIPT_DIR=""

if [[ -f "$SCRIPT_DIR/templates/CLAUDE.md" ]]; then
    BOOTSTRAP_DIR="$SCRIPT_DIR"
    ok "Using local bootstrap repo at $BOOTSTRAP_DIR"
else
    BOOTSTRAP_DIR="$HOME/.claude/brain-bootstrap"
    BOOTSTRAP_REPO_URL="https://github.com/IoT-Gardener/Claude-Brain-Bootstrap.git"

    if [[ -d "$BOOTSTRAP_DIR/.git" ]]; then
        info "Updating bootstrap repo at $BOOTSTRAP_DIR ..."
        git -C "$BOOTSTRAP_DIR" pull --quiet --ff-only \
            && ok "Bootstrap repo updated" \
            || warn "Could not update bootstrap repo (continuing with existing version)"
    else
        info "Cloning bootstrap repo to $BOOTSTRAP_DIR ..."
        mkdir -p "$(dirname "$BOOTSTRAP_DIR")"
        git clone --quiet "$BOOTSTRAP_REPO_URL" "$BOOTSTRAP_DIR" \
            && ok "Bootstrap repo cloned" \
            || fail "Could not clone bootstrap repo. Update BOOTSTRAP_REPO_URL in install.sh."
    fi
fi

# ── macOS: install tools ──────────────────────────────────────────────────────
if [[ "$PLATFORM" == "macos" ]]; then
    echo ""
    head "Installing tools..."

    # Check brew
    if ! command -v brew &>/dev/null; then
        warn "Homebrew not found. Install it from https://brew.sh then re-run."
        warn "Skipping tool installs."
    else
        # Obsidian
        if brew list --cask obsidian &>/dev/null 2>&1; then
            warn "Obsidian already installed"
        else
            info "Installing Obsidian..."
            brew install --cask obsidian && ok "Obsidian installed"
        fi

        # Graphify (always attempt — used by /brain-ingest-repo in deep mode)
        if command -v graphify &>/dev/null; then
            warn "Graphify already installed"
        else
            info "Installing Graphify..."
            # Ensure pipx is available
            if ! command -v pipx &>/dev/null; then
                brew install pipx --quiet 2>/dev/null && pipx ensurepath 2>/dev/null || true
            fi
            if command -v pipx &>/dev/null; then
                pipx install graphifyy 2>/dev/null && graphify install \
                    && ok "Graphify installed" \
                    || warn "Graphify install failed — run 'pipx install graphifyy && graphify install' manually"
            else
                warn "Graphify install failed — install pipx first, then run 'pipx install graphifyy && graphify install'"
            fi
        fi

        # GitNexus (only if enabled)
        if echo "$ENABLE_INTEGRATIONS" | grep -q "gitnexus"; then
            if command -v gitnexus &>/dev/null; then
                warn "GitNexus already installed ($(gitnexus --version 2>/dev/null || echo 'version unknown'))"
            else
                info "Installing GitNexus..."
                # GitNexus requires Node 20.17+ or 22+; try nvm if available
                if [[ -f "$HOME/.nvm/nvm.sh" ]]; then
                    # shellcheck source=/dev/null
                    . "$HOME/.nvm/nvm.sh"
                    nvm use 22 2>/dev/null || nvm install 22 2>/dev/null || true
                fi
                npm install -g gitnexus \
                    && ok "GitNexus installed" \
                    || warn "GitNexus install failed — upgrade Node to v22+ and run 'npm install -g gitnexus' manually"
            fi
        fi
    fi
fi

# ── Guard: don't overwrite a brain that already has content ───────────────────
if [[ -f "$TARGET_PATH/wiki/index.md" ]]; then
    warn "A brain already exists at $TARGET_PATH"
    warn "Re-running install is safe — it will only add missing files and skip existing ones."
    REINSTALL=true
else
    REINSTALL=false
fi

# ── Create directory scaffold ─────────────────────────────────────────────────
echo ""
head "Creating directory scaffold..."

dirs=(
    "$TARGET_PATH/raw/articles"
    "$TARGET_PATH/raw/sessions"
    "$TARGET_PATH/raw/documents"
    "$TARGET_PATH/raw/assets"
    "$TARGET_PATH/wiki/sources"
    "$TARGET_PATH/wiki/entities"
    "$TARGET_PATH/wiki/concepts"
    "$TARGET_PATH/wiki/synthesis/code"
    "$TARGET_PATH/wiki/synthesis/sessions"
    "$TARGET_PATH/wiki/synthesis/maintenance"
    "$TARGET_PATH/wiki/personas"
    "$TARGET_PATH/.claude/agents"
)

for d in "${dirs[@]}"; do
    mkdir -p "$d"
done
ok "Scaffold directories created"

# ── Copy templates (skip if file already exists) ──────────────────────────────
copy_if_missing() {
    local src="$1" dst="$2"
    if [[ -f "$dst" ]]; then
        warn "Skipping $(basename "$dst") — already exists"
    else
        cp "$src" "$dst"
        ok "Created $(basename "$dst")"
    fi
}

copy_if_missing "$BOOTSTRAP_DIR/templates/CLAUDE.md"  "$TARGET_PATH/CLAUDE.md"
copy_if_missing "$BOOTSTRAP_DIR/templates/index.md"   "$TARGET_PATH/wiki/index.md"
copy_if_missing "$BOOTSTRAP_DIR/templates/log.md"     "$TARGET_PATH/wiki/log.md"
copy_if_missing "$BOOTSTRAP_DIR/templates/gitignore"  "$TARGET_PATH/.gitignore"

# Librarian subagent
copy_if_missing \
    "$BOOTSTRAP_DIR/templates/agents/brain-librarian.md" \
    "$TARGET_PATH/.claude/agents/brain-librarian.md"

# Page templates (for reference)
mkdir -p "$TARGET_PATH/templates"
for tpl in "$BOOTSTRAP_DIR/templates/pages/"*.md; do
    copy_if_missing "$tpl" "$TARGET_PATH/templates/$(basename "$tpl")"
done

# ── Write .brain.toml ─────────────────────────────────────────────────────────
TOML_PATH="$TARGET_PATH/.brain.toml"
if [[ -f "$TOML_PATH" ]]; then
    warn "Skipping .brain.toml — already exists"
else
    {
        echo "[brain]"
        echo "created = \"$(date +%Y-%m-%d)\""
        echo "bootstrap_version = \"main\""
        echo ""
        echo "[integrations]"
        echo "graphify    = false"
        echo "gitnexus    = false"
        echo "web-clipper = false"
        echo "notion      = false"
        echo "slack       = false"
    } > "$TOML_PATH"

    if [[ -n "$ENABLE_INTEGRATIONS" ]]; then
        IFS=',' read -ra INTGS <<< "$ENABLE_INTEGRATIONS"
        for intg in "${INTGS[@]}"; do
            intg="${intg// /}"
            # Escape hyphens for sed
            intg_escaped="${intg//-/\\-}"
            if grep -q "^${intg_escaped}" "$TOML_PATH" 2>/dev/null || grep -q "^${intg}" "$TOML_PATH" 2>/dev/null; then
                sed -i.bak "s/^${intg} .*=.*false/${intg}    = true/" "$TOML_PATH"
                rm -f "$TOML_PATH.bak"
                ok "Enabled integration: $intg"
            else
                warn "Unknown integration '$intg' — add it manually to .brain.toml"
            fi
        done
    fi
    ok "Created .brain.toml"
fi

# ── Keep raw/ subfolders tracked in git ──────────────────────────────────────
for d in articles sessions documents assets; do
    touch "$TARGET_PATH/raw/$d/.gitkeep"
done

# ── Symlink commands to ~/.claude/commands/ ───────────────────────────────────
echo ""
head "Installing brain commands to ~/.claude/commands/ ..."
COMMANDS_DIR="$HOME/.claude/commands"
mkdir -p "$COMMANDS_DIR"

install_command() {
    local src="$BOOTSTRAP_DIR/commands/$1"
    local dst="$COMMANDS_DIR/$1"
    [[ -f "$src" ]] || { warn "Command file not found: $src"; return; }

    if [[ -L "$dst" ]]; then
        warn "Command already linked: $1"
    elif [[ -f "$dst" ]]; then
        warn "Command already exists (not a symlink): $1 — skipping"
    else
        ln -s "$src" "$dst"
        ok "Linked command: /$1"
    fi
}

install_command "brain-query.md"
install_command "brain-ingest.md"
install_command "brain-ingest-repo.md"
install_command "brain-ingest-clipped.md"
install_command "brain-ingest-notion.md"
install_command "brain-ingest-slack.md"
install_command "brain-log-session.md"
install_command "brain-librarian.md"
install_command "brain-lint.md"

# ── Update ~/.claude/CLAUDE.md with brain-detection block ────────────────────
echo ""
head "Updating ~/.claude/CLAUDE.md with brain detection instructions..."

GLOBAL_CLAUDE="$HOME/.claude/CLAUDE.md"
MARKER="<!-- brain-bootstrap: brain detection -->"

if grep -q "$MARKER" "$GLOBAL_CLAUDE" 2>/dev/null; then
    warn "Brain detection section already present in ~/.claude/CLAUDE.md"
else
    {
        echo ""
        echo "$MARKER"
        echo "## Brain"
        echo ""
        echo "**The brain is your first port of call.** When a brain is detected, run"
        echo "\`/brain-query\` before reading source files. Treat the brain as the primary"
        echo "source of context for architecture, decisions, and domain knowledge."
        echo "Only read individual source files when the brain's answer is insufficient."
        echo ""
        echo "To locate the brain: walk up from the current working directory looking for"
        echo "a \`wiki/index.md\` file. If \`\$BRAIN_ROOT\` is set in the environment, use"
        echo "that instead. If no brain is found, do not mention it — carry on normally."
        echo ""
        echo "Available commands: /brain-query, /brain-ingest, /brain-ingest-repo,"
        echo "/brain-ingest-clipped, /brain-ingest-notion, /brain-ingest-slack,"
        echo "/brain-log-session, /brain-librarian, /brain-lint."
        echo "<!-- end brain-bootstrap -->"
    } >> "$GLOBAL_CLAUDE"
    ok "Added brain detection to ~/.claude/CLAUDE.md"
fi

# Suggest adding BRAIN_ROOT to shell profile so Claude can find the brain from any cwd
info "Tip: to make the brain findable from any directory, add this to your shell profile (~/.zshrc or ~/.bashrc):"
info "  export BRAIN_ROOT=\"$TARGET_PATH\""

# ── Register GitNexus MCP server in ~/.claude/settings.json ──────────────────
if echo "$ENABLE_INTEGRATIONS" | grep -q "gitnexus"; then
    echo ""
    head "Registering GitNexus MCP server in ~/.claude/settings.json ..."

    SETTINGS_FILE="$HOME/.claude/settings.json"

    if [[ ! -f "$SETTINGS_FILE" ]]; then
        echo '{"mcpServers": {}}' > "$SETTINGS_FILE"
    fi

    if grep -q '"gitnexus"' "$SETTINGS_FILE"; then
        warn "GitNexus already registered in ~/.claude/settings.json"
    else
        # Use python3 to safely update JSON
        python3 - <<'PYEOF'
import json, sys, os

settings_file = os.path.expanduser("~/.claude/settings.json")
with open(settings_file, "r") as f:
    settings = json.load(f)

if "mcpServers" not in settings:
    settings["mcpServers"] = {}

settings["mcpServers"]["gitnexus"] = {
    "command": "gitnexus",
    "args": ["serve"],
    "env": {}
}

with open(settings_file, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

print("  GitNexus MCP server registered")
PYEOF
        ok "GitNexus MCP registered in ~/.claude/settings.json"
        info "Restart Claude Code for the MCP server to take effect."
    fi
fi

# ── Seed walker ───────────────────────────────────────────────────────────────
GRAPHIFY_TARGETS=()
SEEDED_FILES=()

# Directories to skip entirely (never descend)
SKIP_DIRS=(".git" "node_modules" "__pycache__" "dist" "build" ".next" "target" ".venv" "Brain")
# Files to skip
SKIP_FILES=(".DS_Store" "Thumbs.db" "*.lock" "*.tmp")
# Inside .claude/ directories: files/dirs to exclude
CLAUDE_SKIP=("CLAUDE.md" ".mcp.json" "settings.json" "settings.local.json" "agents" "commands")

is_skip_dir() {
    local name="$1"
    for skip in "${SKIP_DIRS[@]}"; do
        [[ "$name" == "$skip" ]] && return 0
    done
    return 1
}

is_skip_file() {
    local name="$1"
    for pattern in "${SKIP_FILES[@]}"; do
        # shellcheck disable=SC2254
        case "$name" in $pattern) return 0 ;; esac
    done
    return 1
}

is_claude_skip() {
    local name="$1"
    for skip in "${CLAUDE_SKIP[@]}"; do
        [[ "$name" == "$skip" ]] && return 0
    done
    return 1
}

# Map file to raw/ subfolder by extension/name
raw_subdir() {
    local file="$1"
    local base
    base="$(basename "$file")"
    case "$base" in session*.md|session*.txt) echo "sessions"; return ;; esac
    case "$file" in
        *.md|*.html)         echo "articles" ;;
        *.pdf|*.docx|*.doc)  echo "documents" ;;
        *)                   echo "documents" ;;
    esac
}

walk_files_in_dir() {
    local dir="$1"
    local in_claude="${2:-false}"

    # Files directly in this dir
    for entry in "$dir"/*; do
        [[ -f "$entry" ]] || continue
        local name
        name="$(basename "$entry")"
        is_skip_file "$name" && continue
        [[ "$in_claude" == "true" ]] && is_claude_skip "$name" && continue

        case "$entry" in
            *.md|*.html|*.pdf|*.docx|*.doc|*.txt|*.json) ;;
            *) continue ;;
        esac

        SEEDED_FILES+=("$entry")
    done

    # Recurse into subdirs
    for entry in "$dir"/*/; do
        entry="${entry%/}"
        [[ -d "$entry" ]] || continue
        local name
        name="$(basename "$entry")"
        is_skip_dir "$name" && continue
        [[ "$in_claude" == "true" ]] && is_claude_skip "$name" && continue

        if [[ "$name" == ".claude" ]]; then
            walk_files_in_dir "$entry" "true"
            continue
        fi

        if [[ -d "$entry/.git" ]]; then
            GRAPHIFY_TARGETS+=("$entry")
            continue
        fi

        walk_files_in_dir "$entry" "$in_claude"
    done
}

if [[ -n "$SEED_PATH" ]]; then
    SEED_PATH="${SEED_PATH/#\~/$HOME}"
    echo ""
    head "Walking seed path: $SEED_PATH ..."

    # Warn if seeding from home root — this walks the entire computer
    if [[ "$SEED_PATH" == "$HOME" || "$SEED_PATH" == "$HOME/" ]]; then
        warn "Seed path is your home directory — this will walk your entire computer."
        warn "Consider a more targeted path (e.g. ~/Projects, ~/Documents)."
        if [[ "$YES" != "true" ]]; then
            read -r -p "  Continue anyway? [y/N] " _cont
            [[ "$_cont" =~ ^[Yy]$ ]] || { info "Skipping seed."; SEED_PATH=""; }
        fi
    fi

    if [[ ! -d "$SEED_PATH" ]]; then
        warn "Seed path does not exist: $SEED_PATH — skipping"
    else
        walk_files_in_dir "$SEED_PATH"

        info "Found ${#GRAPHIFY_TARGETS[@]} git repo(s) → Graphify queue"
        info "Found ${#SEEDED_FILES[@]} file(s) → raw/"

        # Copy files into raw/
        for f in "${SEEDED_FILES[@]}"; do
            subdir="$(raw_subdir "$f")"
            dst="$TARGET_PATH/raw/$subdir/$(basename "$f")"
            if [[ -f "$dst" ]]; then
                : # skip silently
            else
                cp "$f" "$dst"
            fi
        done
        [[ ${#SEEDED_FILES[@]} -gt 0 ]] && ok "Copied ${#SEEDED_FILES[@]} files into raw/"
    fi
fi

# ── Merge explicit graphify / gitnexus repos ──────────────────────────────────
if [[ -n "$GRAPHIFY_REPOS_EXTRA" ]]; then
    IFS=',' read -ra EXTRAS <<< "$GRAPHIFY_REPOS_EXTRA"
    for r in "${EXTRAS[@]}"; do
        r="${r// /}"; r="${r/#\~/$HOME}"
        GRAPHIFY_TARGETS+=("$r")
    done
fi

# Deduplicate
if [[ ${#GRAPHIFY_TARGETS[@]} -gt 0 ]]; then
    mapfile -t GRAPHIFY_TARGETS < <(printf '%s\n' "${GRAPHIFY_TARGETS[@]}" | sort -u)
fi

# GitNexus targets default to Graphify targets unless overridden
GITNEXUS_TARGETS=("${GRAPHIFY_TARGETS[@]}")
if [[ -n "$GITNEXUS_REPOS_EXTRA" ]]; then
    GITNEXUS_TARGETS=()
    IFS=',' read -ra EXTRAS <<< "$GITNEXUS_REPOS_EXTRA"
    for r in "${EXTRAS[@]}"; do
        r="${r// /}"; r="${r/#\~/$HOME}"
        GITNEXUS_TARGETS+=("$r")
    done
fi

# ── GitNexus: index repos ─────────────────────────────────────────────────────
if echo "$ENABLE_INTEGRATIONS" | grep -q "gitnexus" && command -v gitnexus &>/dev/null; then
    if [[ ${#GITNEXUS_TARGETS[@]} -gt 0 ]]; then
        echo ""
        head "Indexing repos with GitNexus..."
        for repo in "${GITNEXUS_TARGETS[@]}"; do
            if [[ -d "$repo/.git" ]]; then
                info "Indexing $repo ..."
                gitnexus index "$repo" && ok "Indexed: $(basename "$repo")" \
                    || warn "GitNexus index failed for $repo — run manually: gitnexus index $repo"
            else
                warn "Skipping GitNexus index for $repo — not a git repo"
            fi
        done
    fi
fi

# ── Write .brain-first-run.md ─────────────────────────────────────────────────
FIRST_RUN_FILE="$TARGET_PATH/.brain-first-run.md"
FIRST_RUN_TEMPLATE="$BOOTSTRAP_DIR/templates/first-run.md"

{
    echo "# Brain first-run queue"
    echo ""
    echo "<!-- Auto-generated by install.sh on $(date +%Y-%m-%d) -->"
    echo "<!-- Run manually: open Claude Code in the brain directory and paste these commands. -->"
    echo ""

    # Graphify calls
    for repo in "${GRAPHIFY_TARGETS[@]}"; do
        if [[ -d "$repo/.git" ]]; then
            echo "/brain-ingest-repo $repo"
        fi
    done

    # Bulk ingest seeded files (only with --ingest-seed)
    if [[ "$INGEST_SEED" == "true" ]]; then
        for f in "${SEEDED_FILES[@]}"; do
            subdir="$(raw_subdir "$f")"
            echo "/brain-ingest raw/$subdir/$(basename "$f")"
        done
    fi

    echo ""
    echo "/brain-lint"
    echo ""
    echo "/brain-librarian"
} > "$FIRST_RUN_FILE"

ok "Written: .brain-first-run.md ($(wc -l < "$FIRST_RUN_FILE") lines)"

# ── Initialise git repo ───────────────────────────────────────────────────────
echo ""
if [[ -d "$TARGET_PATH/.git" ]]; then
    warn "Git repo already initialised"
else
    git -C "$TARGET_PATH" init --quiet
    git -C "$TARGET_PATH" add .
    git -C "$TARGET_PATH" commit --quiet -m "Initial brain scaffold from Claude-Brain-Bootstrap"
    ok "Git repo initialised with initial commit"
fi

# ── First-run handoff ─────────────────────────────────────────────────────────
echo ""
BRAIN_NAME="$(basename "$TARGET_PATH")"

if [[ "$AUTO" == "true" ]]; then
    if ! command -v claude &>/dev/null; then
        warn "claude CLI not found on PATH — cannot run headless first-run."
        warn "Install Claude Code, then run: cd $TARGET_PATH && claude"
        warn "Paste the contents of .brain-first-run.md to complete setup."
    else
        TODAY="$(date +%Y-%m-%d)"
        ALLOWED_TOOLS="Read,Edit,Write,Bash,Glob,Grep,Task"
        GRAPHIFY_CMD="$(cat "$BOOTSTRAP_DIR/commands/brain-ingest-repo.md")"
        INGEST_CMD="$(cat "$BOOTSTRAP_DIR/commands/brain-ingest.md")"
        LINT_CMD="$(cat "$BOOTSTRAP_DIR/commands/brain-lint.md")"
        LIBRARIAN_CMD="$(cat "$BOOTSTRAP_DIR/templates/agents/brain-librarian.md")"

        # ── Graphify: one claude -p call per repo ─────────────────────────────
        if [[ ${#GRAPHIFY_TARGETS[@]} -gt 0 ]]; then
            echo ""
            head "Running Graphify (${#GRAPHIFY_TARGETS[@]} repo(s))..."

            for repo in "${GRAPHIFY_TARGETS[@]}"; do
                [[ -d "$repo/.git" ]] || { warn "Skipping $repo — not a git repo"; continue; }
                repo_name="$(basename "$repo")"
                code_page="$TARGET_PATH/wiki/synthesis/code/$repo_name.md"

                # Idempotency: skip if already ingested today
                if [[ -f "$code_page" ]] && grep -q "updated: $TODAY" "$code_page" 2>/dev/null; then
                    ok "Skipping $repo_name — Graphify page already up to date (updated today)"
                    continue
                fi

                info "Graphify: $repo_name ..."
                if claude -p \
                    --allowedTools "$ALLOWED_TOOLS" \
                    "BRAIN_ROOT=$TARGET_PATH

$GRAPHIFY_CMD

Execute for this repo: $repo"; then
                    ok "Graphify complete: $repo_name"
                else
                    warn "Graphify failed for $repo_name — skipping, continuing with next repo"
                    warn "Re-run manually once setup is done: /brain-ingest-repo $repo"
                fi
            done
        fi

        # ── Bulk ingest seeded files (only with --ingest-seed) ────────────────
        if [[ "$INGEST_SEED" == "true" ]] && [[ ${#SEEDED_FILES[@]} -gt 0 ]]; then
            echo ""
            warn "--ingest-seed: about to ingest ${#SEEDED_FILES[@]} file(s) from raw/."
            warn "Estimated cost: ~\$0.01–0.05 per file (varies by file size)."

            _do_ingest=true
            if [[ "$YES" != "true" ]]; then
                read -r -p "  Proceed with bulk ingest? [y/N] " _confirm
                [[ "$_confirm" =~ ^[Yy]$ ]] || _do_ingest=false
            fi

            if [[ "$_do_ingest" == "true" ]]; then
                head "Ingesting ${#SEEDED_FILES[@]} file(s)..."
                _ingested=0; _skipped=0; _failed=0

                for f in "${SEEDED_FILES[@]}"; do
                    subdir="$(raw_subdir "$f")"
                    raw_path="raw/$subdir/$(basename "$f")"
                    # Derive expected slug to check idempotency
                    slug="$(basename "$f" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//')"
                    source_page="$TARGET_PATH/wiki/sources/$slug.md"

                    if [[ -f "$source_page" ]]; then
                        (( _skipped++ )) || true
                        continue
                    fi

                    if claude -p \
                        --allowedTools "$ALLOWED_TOOLS" \
                        "BRAIN_ROOT=$TARGET_PATH

$INGEST_CMD

Ingest this file: $raw_path" 2>/dev/null; then
                        (( _ingested++ )) || true
                    else
                        (( _failed++ )) || true
                        warn "Ingest failed for $raw_path — run /brain-ingest $raw_path manually"
                    fi
                done

                ok "Ingest complete: $_ingested ingested, $_skipped already existed, $_failed failed"
            else
                info "Skipping bulk ingest. Files are in raw/ — run /brain-ingest manually for each."
            fi
        fi

        # ── Lint ──────────────────────────────────────────────────────────────
        echo ""
        head "Running brain-lint..."
        if claude -p \
            --allowedTools "$ALLOWED_TOOLS" \
            "BRAIN_ROOT=$TARGET_PATH

$LINT_CMD

Run a lint check on the wiki. Apply safe fixes automatically (--apply mode)."; then
            ok "Lint complete"
        else
            warn "Lint failed — run /brain-lint manually"
        fi

        # ── Librarian ─────────────────────────────────────────────────────────
        echo ""
        head "Running brain-librarian..."
        if claude -p \
            --allowedTools "$ALLOWED_TOOLS" \
            "BRAIN_ROOT=$TARGET_PATH

You are the brain librarian. Follow these instructions exactly:

$LIBRARIAN_CMD"; then
            ok "Librarian complete"
        else
            warn "Librarian failed — run /brain-librarian manually"
        fi

        ok "First-run complete. Review wiki/synthesis/maintenance/ for any librarian judgement calls."
    fi
else
    echo "╔══════════════════════════════════════════╗"
    echo "║   Brain ready: $BRAIN_NAME"
    echo "╚══════════════════════════════════════════╝"
    echo ""
    echo "  Next steps:"
    echo ""
    echo "  1. Fill in ## Local persona in:"
    echo "       $TARGET_PATH/CLAUDE.md"
    echo ""
    echo "  2. Open Claude Code in the brain directory:"
    echo "       cd $TARGET_PATH && claude"
    echo ""
    echo "  3. Paste the contents of .brain-first-run.md to run the initial setup:"
    echo "       cat .brain-first-run.md"
    echo ""
    echo "  4. Or re-run with --auto to do it headlessly:"
    echo "       ./install.sh $TARGET_PATH --auto"
    echo ""
fi

# ── Final summary ─────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Done: $BRAIN_NAME"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  Brain directory:  $TARGET_PATH"
echo "  Commands:         ~/.claude/commands/brain-*.md"
echo "  Integrations:     $TARGET_PATH/.brain.toml"
echo ""
if [[ "$REINSTALL" == "false" ]]; then
    echo "  Once the brain is working, tag the bootstrap repo:"
    echo "    git -C $BOOTSTRAP_DIR tag v0.1"
    echo ""
fi
