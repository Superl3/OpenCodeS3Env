# Prompt For OpenCode Agent

Use this prompt on another machine after cloning the repo:

```text
Run `bash bootstrap/install.sh` in this repository and verify that:
1) ~/.config/opencode/opencode.json exists and includes instruction entries for AGENTS/planner/builder/orchestrator.
2) ~/.config/opencode/oh-my-opencode-slim.jsonc exists with preset `openai_pro` and `tmux.enabled=false`.
3) ~/.config/opencode/plugin/shell-strategy/shell_strategy.md exists.
4) If ocx is installed, restore plugins from ~/.config/opencode/ocx.lock.
Then report what changed and any skipped steps.
```
