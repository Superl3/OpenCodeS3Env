# Prompt For OpenCode Agent

Use this prompt on another machine after cloning the repo:

```text
Run `bash bootstrap/install.sh` in this repository and verify that:
1) ~/.config/opencode/opencode.json exists and includes plugin entries for `oh-my-opencode-slim`, `opencode-handoff`, `opencode-ralph-loop`, and `@tarquinen/opencode-dcp`.
2) ~/.config/opencode/opencode.json includes instruction entries for:
   - ~/.config/opencode/instructions/AGENTS.md
   - ~/.config/opencode/instructions/orchestrator_append.md
   - ~/.config/opencode/instructions/planner_append.md
   - ~/.config/opencode/instructions/builder_append.md
3) The four instruction files above exist on disk.
4) ~/.config/opencode/oh-my-opencode-slim.jsonc exists with preset `openai_pro` and `tmux.enabled=false`.
5) ~/.config/opencode/plugin/shell-strategy/shell_strategy.md exists.
6) OCX components are restored from ~/.config/opencode/ocx.lock (auto-install ocx CLI if missing).
Then report what changed and any skipped steps.

After installation, run `bash bootstrap/verify-opencode-state.sh` and confirm `OK`.

For future upgrades, always use `bash bootstrap/update-opencode-safe.sh` instead of raw `opencode upgrade`.
```
