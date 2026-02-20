#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"

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
  const configPath = path.join(target, "opencode.json")
  if (!fs.existsSync(configPath)) {
    console.error(`ERROR: Missing ${configPath}`)
    process.exit(1)
  }
  const config = JSON.parse(fs.readFileSync(configPath, "utf8"))
  const plugins = Array.isArray(config.plugin) ? config.plugin : []
  const missingPlugins = requiredPlugins.filter((name) => !plugins.includes(name))
  if (missingPlugins.length > 0) {
    console.error("ERROR: Missing required plugins:", missingPlugins.join(", "))
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
    console.error("ERROR: opencode.json should set autoupdate to \"notify\"")
    process.exit(1)
  }
  console.log(`OK: OpenCode state verified in ${target}`)
' "$TARGET_DIR"
