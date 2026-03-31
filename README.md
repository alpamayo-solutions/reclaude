# reclaude

Pin [Claude Code](https://docs.anthropic.com/en/docs/claude-code) sessions to iTerm2 panes. After a reboot, iTerm2 restores your layout and each pane automatically resumes its Claude conversation.

No tmux. No screen. Just iTerm2 Dynamic Profiles and fish shell.

## Install

```fish
fisher install alpamayo-solutions/reclaude
```

Requires:
- [Fish shell](https://fishshell.com/)
- [Fisher](https://github.com/jorgebucaran/fisher)
- [iTerm2](https://iterm2.com/)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Python 3 (for JSON manipulation)

## Quick start

```fish
# Create a session pinned to a project directory
reclaude new api --dir ~/Projects/my-app/api
reclaude new frontend --dir ~/Projects/my-app/web

# Arrange your panes with Cmd+D / Cmd+Shift+D, then save:
#   Window > Save Window Arrangement As... > "my-workspace"
#   Window > Save Current Window Arrangement as Default

# After reboot, iTerm2 restores the layout and each pane
# resumes its Claude session automatically.
```

## Commands

| Command | Description |
|---------|-------------|
| `reclaude new <name> [--dir <path>]` | Create a session profile and open in a new tab |
| `reclaude open <name> [--split h\|v]` | Open an existing session in a new tab or split pane |
| `reclaude save` | Save current window arrangement as default |
| `reclaude list` | List all session profiles |
| `reclaude remove <name>` | Remove a session profile |
| `reclaude help` | Show help and setup instructions |

## How it works

1. `reclaude new` creates an [iTerm2 Dynamic Profile](https://iterm2.com/documentation-dynamic-profiles.html) that runs a launch helper as its Initial Text
2. The launch helper tries `claude --resume <name>`, falling back to `claude --name <name>` on first run
3. Profiles are stored in `~/Library/Application Support/iTerm2/DynamicProfiles/claude-sessions.json`
4. iTerm2's built-in window arrangement restore handles layout persistence

## Setup for auto-restore

After creating sessions and arranging your panes:

1. **Save the arrangement**: Window > Save Window Arrangement As...
2. **Set it as default**: Window > Save Current Window Arrangement as Default
3. **Enable restore on launch**: iTerm2 > Settings > General > Startup > set to "Open Default Window Arrangement"

That's it. Next time iTerm2 starts, your Claude sessions resume exactly where you left them.

## License

MIT
