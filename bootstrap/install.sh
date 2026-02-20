#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSET_DIR="$REPO_ROOT/bootstrap/opencode"
TARGET_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
INSTR_DIR="$TARGET_DIR/instructions"
NODE_BIN_DIR="$TARGET_DIR/node_modules/.bin"
export PATH="$NODE_BIN_DIR:$PATH"
SHELL_STRATEGY_REPO="https://github.com/JRedeker/opencode-shell-strategy"
SHELL_STRATEGY_REF="1f83c6e477d2d2f1cb791d7cc9be7f165a4f670b"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$TARGET_DIR/backup-$TIMESTAMP"
BACKUP_ENABLED=0

log() {
  printf '%s\n' "$*"
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log "ERROR: required command not found: $cmd"
    exit 1
  fi
}

preflight_checks() {
  require_command git
  require_command node

  if ! command -v bun >/dev/null 2>&1 && ! command -v npm >/dev/null 2>&1; then
    log "ERROR: neither bun nor npm is installed. Install one of them and retry."
    exit 1
  fi
}

backup_target() {
  local rel="$1"
  local src="$TARGET_DIR/$rel"

  if [ -e "$src" ]; then
    if [ "$BACKUP_ENABLED" -eq 0 ]; then
      mkdir -p "$BACKUP_DIR"
      BACKUP_ENABLED=1
    fi

    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    cp -a "$src" "$BACKUP_DIR/$rel"
  fi
}

copy_asset() {
  local rel="$1"
  backup_target "$rel"
  mkdir -p "$TARGET_DIR/$(dirname "$rel")"
  cp "$ASSET_DIR/$rel" "$TARGET_DIR/$rel"
}

copy_instruction() {
  local name="$1"
  backup_target "instructions/$name"
  mkdir -p "$INSTR_DIR"
  cp "$REPO_ROOT/$name" "$INSTR_DIR/$name"
}

ensure_shell_strategy() {
  local dir="$TARGET_DIR/plugin/shell-strategy"
  mkdir -p "$TARGET_DIR/plugin"

  if [ -d "$dir/.git" ]; then
    git -C "$dir" remote set-url origin "$SHELL_STRATEGY_REPO"
    git -C "$dir" fetch --force --tags origin
  else
    git clone --depth 1 "$SHELL_STRATEGY_REPO" "$dir"
  fi

  git -C "$dir" checkout --force "$SHELL_STRATEGY_REF"
}

install_js_dependencies() {
  if command -v bun >/dev/null 2>&1; then
    bun install --cwd "$TARGET_DIR"
    return
  fi

  if command -v npm >/dev/null 2>&1; then
    npm install --prefix "$TARGET_DIR" --yes
    return
  fi

  log "WARN: bun/npm not found. Skipped dependency install."
}

install_ocx_cli() {
  log "INFO: ocx CLI not found; attempting auto-install via bun/npm."

  if command -v bun >/dev/null 2>&1; then
    bun install --global ocx
    return
  fi

  if command -v npm >/dev/null 2>&1; then
    npm install --global ocx --yes
    return
  fi

  log "ERROR: Unable to install ocx because neither bun nor npm is available."
  return 1
}

restore_ocx_plugins() {
  if ! command -v ocx >/dev/null 2>&1; then
    if ! install_ocx_cli; then
      log "WARN: ocx not available. Skipped OCX plugin restore."
      return
    fi
  fi

  local packages
  packages="$(node -e 'const fs=require("fs"); const p=process.argv[1]; const j=JSON.parse(fs.readFileSync(p,"utf8")); console.log(Object.keys(j.installed||{}).join(" "));' "$TARGET_DIR/ocx.lock" | tr -d '\r')"

  if [ -n "$packages" ]; then
    # shellcheck disable=SC2086
    ocx add --cwd "$TARGET_DIR" --force $packages
  fi

  while IFS= read -r pkgver; do
    pkgver="${pkgver%$'\r'}"
    [ -z "$pkgver" ] && continue
    ocx update --cwd "$TARGET_DIR" "$pkgver"
  done < <(node -e 'const fs=require("fs"); const p=process.argv[1]; const j=JSON.parse(fs.readFileSync(p,"utf8")); for (const [name, meta] of Object.entries(j.installed||{})) { if (meta && meta.version) console.log(`${name}@${meta.version}`) }' "$TARGET_DIR/ocx.lock" | tr -d '\r')
}

validate_json() {
  node -e 'const fs=require("fs"); for (const p of process.argv.slice(1)) { JSON.parse(fs.readFileSync(p,"utf8")); console.log("OK", p); }' \
    "$TARGET_DIR/opencode.json" \
    "$TARGET_DIR/oh-my-opencode.json" \
    "$TARGET_DIR/oh-my-opencode-slim.jsonc" \
    "$TARGET_DIR/ocx.lock" \
    "$TARGET_DIR/package.json"
}

verify_required_state() {
  node -e '
    const fs = require("fs")
    const path = require("path")
    const target = process.argv[1]
    const requiredPlugins = [
      "oh-my-opencode-slim",
      "opencode-handoff@github:joshuadavidthomas/opencode-handoff#v0.4.0",
      "opencode-ralph-loop@1.0.7",
      "@tarquinen/opencode-dcp@latest",
    ]
    const requiredInstructions = [
      "~/.config/opencode/plugin/shell-strategy/shell_strategy.md",
      "~/.config/opencode/instructions/AGENTS.md",
      "~/.config/opencode/instructions/orchestrator_append.md",
      "~/.config/opencode/instructions/planner_append.md",
      "~/.config/opencode/instructions/builder_append.md",
    ]
    const config = JSON.parse(fs.readFileSync(path.join(target, "opencode.json"), "utf8"))
    const plugins = Array.isArray(config.plugin) ? config.plugin : []
    const missing = requiredPlugins.filter((name) => !plugins.includes(name))
    if (missing.length > 0) {
      console.error("ERROR: Missing required plugins:", missing.join(", "))
      process.exit(1)
    }
    const instructions = Array.isArray(config.instructions) ? config.instructions : []
    const missingInstructions = requiredInstructions.filter((entry) => !instructions.includes(entry))
    if (missingInstructions.length > 0) {
      console.error("ERROR: Missing required instruction entries:", missingInstructions.join(", "))
      process.exit(1)
    }
    const requiredFiles = [
      "oh-my-opencode-slim.jsonc",
      "plugin/shell-strategy/shell_strategy.md",
      "instructions/AGENTS.md",
      "instructions/orchestrator_append.md",
      "instructions/planner_append.md",
      "instructions/builder_append.md",
    ]
    const missingFiles = requiredFiles.filter((rel) => !fs.existsSync(path.join(target, rel)))
    if (missingFiles.length > 0) {
      console.error("ERROR: Missing required files:", missingFiles.join(", "))
      process.exit(1)
    }
    if (config.autoupdate !== "notify") {
      console.error("ERROR: opencode.json must set autoupdate to \"notify\" for stable bootstrap behavior")
      process.exit(1)
    }
    console.log("OK required state")
  ' "$TARGET_DIR"
}

main() {
  preflight_checks

  log "Installing OpenCode setup into: $TARGET_DIR"

  mkdir -p "$TARGET_DIR"

  copy_asset "opencode.json"
  copy_asset "oh-my-opencode.json"
  copy_asset "oh-my-opencode-slim.jsonc"
  copy_asset "dcp.jsonc"
  copy_asset "ocx.jsonc"
  copy_asset "ocx.lock"
  copy_asset "package.json"
  copy_asset "bun.lock"

  copy_instruction "AGENTS.md"
  copy_instruction "orchestrator_append.md"
  copy_instruction "planner_append.md"
  copy_instruction "builder_append.md"

  ensure_shell_strategy
  install_js_dependencies
  restore_ocx_plugins
  validate_json
  verify_required_state

  if [ "$BACKUP_ENABLED" -eq 1 ]; then
    log "Backup created: $BACKUP_DIR"
  else
    log "No prior config files to back up."
  fi

  log "Done. Restart OpenCode to load the new setup."
}

main "$@"
