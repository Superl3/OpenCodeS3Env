#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

main() {
  require_command opencode

  log "Running OpenCode upgrade..."
  opencode upgrade

  log "Re-applying managed OpenCode config..."
  bash "$REPO_ROOT/bootstrap/install.sh"

  log "Verifying managed OpenCode state..."
  bash "$REPO_ROOT/bootstrap/verify-opencode-state.sh"

  log "Done. OpenCode upgrade completed with config recovery."
}

main "$@"
