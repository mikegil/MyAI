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

1. **Banner** - ASCII art display with lowercase 'y' in MyAI
2. **Shell Detection** - `detect_shell()` and `get_config_file()` functions
3. **Component Checking** - `check_components()` parses `third-party-components.md`
4. **AI System Name** - User names their assistant (default: Max)
5. **AI Agent Backend Selection** - Open Code required; Claude/Gemini optional (default: Y)
6. **Default Backend Selection** - If multiple backends enabled, user chooses default (default: Open Code)
7. **MYAI_HOME Environment Variable** - Installation directory setup (keeps existing by default)
8. **Context Directory** - Working directory for the AI (keeps existing by default)
9. **Create Launcher Script** - Single script with `--opencode`, `--claude`, `--gemini` flags
10. **Shell Aliases** - Aliases for non-default backends only (e.g., `buddyo`, `buddyc`, `buddyg`)
11. **Setup Complete** - Summary message showing all configuration

## Component System

`third-party-components.md` uses markdown tables with columns:
- Component name
- Command (for `command -v` check)
- Brew Formula (for installation)
- Description

The script parses this file to check/install dependencies. Required components block setup if missing; optional ones are offered for installation.

## Generated Launcher

The launcher script at `$MYAI_HOME/bin/$AI_NAME`:
- Uses user-selected default backend (Open Code if not specified)
- Accepts `--opencode`, `--claude`, `--gemini` flags to override default
- Shows `(default)` marker in `--help` for the selected default
- Validates agent is in `ENABLED_AGENTS` array
- Changes to context directory before exec

## Shell Aliases

Aliases are only created for non-default backends:
- If Open Code is default: `Buddyc`, `Buddyg` (and lowercase versions)
- If Claude is default: `Buddyo`, `Buddyg` (and lowercase versions)
- If Gemini is default: `Buddyo`, `Buddyc` (and lowercase versions)

## Prompt Defaults

Most prompts default to Y (press Enter to accept):
- Enable Claude Code: Y
- Enable Gemini CLI: Y
- Default backend: 1 (Open Code)
- Keep MYAI_HOME location: Y
- Keep context directory: Y
- Add aliases: Y

## Testing

Run with piped input for non-interactive testing (all defaults):
```bash
printf "Buddy\n\n\n\n\n\n\n" | ./setup.sh
```

Or with specific choices:
```bash
printf "Buddy\ny\ny\n2\ny\n\ny\n" | ./setup.sh  # Claude as default
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
