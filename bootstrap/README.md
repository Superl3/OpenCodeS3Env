# Reproducible OpenCode Setup

This repository includes a portable installer that recreates the current OpenCode setup on another machine.

## What gets reproduced

- Global OpenCode config under `~/.config/opencode`
- Slim presets (`openai_pro`, `openai_spark`) and model routing
- DCP and OCX config + lock files
- Instruction stack (`AGENTS.md`, orchestrator/planner/builder append files)
- Shell strategy plugin pinned to a known commit
- Permission mode set to `allow` to minimize approval prompts

## Usage

Prerequisites:
- `git`
- `node`
- `bun` or `npm`
- Optional: `ocx` (for restoring locked OCX plugins)

1. Clone this repository on the target machine.
2. Run:

```bash
bash bootstrap/install.sh
```

3. Start OpenCode and run a quick smoke test.

You can also reuse `bootstrap/AGENT_INSTALL_PROMPT.md` as a copy/paste prompt for an OpenCode agent.

## Optional environment variable

- `OPENCODE_CONFIG_DIR`: override default target (`~/.config/opencode`)

## Notes

- The installer is non-interactive and creates timestamped backups in the target config directory before overwriting files.
- If `ocx` is installed, plugins from `ocx.lock` are restored automatically.
- If `bun` is available, dependencies are installed with `bun`; otherwise it falls back to `npm`.
