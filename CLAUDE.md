# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MyAI is a Personal AI Agent System that creates personalized AI assistant configurations. The setup script configures a unified launcher that can invoke multiple AI agent backends (Open Code, Claude Code, Gemini) from a single command.

## Key Files

- `setup.sh` - Main interactive setup script (zsh)
- `third-party-components.md` - Defines required and optional components with brew formulas
- `setup_v1.sh` - Legacy version (deprecated)

## Setup Script Structure

The script is organized into labeled sections:

1. **Banner** - ASCII art display
2. **Shell Detection** - `detect_shell()` and `get_config_file()` functions
3. **Component Checking** - `check_components()` parses `third-party-components.md`
4. **AI System Name** - User names their assistant (default: Max)
5. **AI Agent Backend Selection** - Open Code required; Claude/Gemini optional
6. **MYAI_HOME Environment Variable** - Installation directory setup
7. **Context Directory** - Working directory for the AI
8. **Create Launcher Script** - Single script with `--opencode`, `--claude`, `--gemini` flags
9. **Shell Aliases** - Optional lowercase aliases (e.g., `buddyc`, `buddyg`)
10. **Setup Complete** - Summary message

## Component System

`third-party-components.md` uses markdown tables with columns:
- Component name
- Command (for `command -v` check)
- Brew Formula (for installation)
- Description

The script parses this file to check/install dependencies. Required components block setup if missing; optional ones are offered for installation.

## Generated Launcher

The launcher script at `$MYAI_HOME/bin/$AI_NAME`:
- Defaults to Open Code
- Accepts `--claude`, `--gemini`, `--opencode` flags
- Validates agent is in `ENABLED_AGENTS` array
- Changes to context directory before exec

## Shell Config Modifications

The script modifies the user's shell config file to add:
- `MYAI_HOME` export
- `$MYAI_HOME/bin` to PATH
- Optional aliases for quick access

## Testing

Run with piped input for non-interactive testing:
```bash
printf "Buddy\ny\ny\ny\n\ny\n" | ./setup.sh
```

## Allowed Commands

The following commands are pre-approved and don't require user confirmation:

```
Bash(chmod:*)
Bash(./setup.sh)
Bash(command -v:*)
Bash(printf:*)
Bash(cat:*)
Bash($MYAI_HOME/bin/Buddy:*)
Bash(git add:*)
Bash(git commit:*)
Bash(git log:*)
Bash(git remote add:*)
Bash(git push:*)
Read(/Users/mgilbert/**)
```
