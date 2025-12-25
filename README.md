# MyAI

A Personal AI Agent System that provides a unified interface to multiple AI coding assistants.

## Features

- **Unified Launcher**: Single command to access Open Code, Claude Code, or Gemini CLI
- **Personalized Setup**: Name your AI assistant and configure it to your preferences
- **Multiple Backends**: Use Open Code as default, with optional Claude Code and Gemini support
- **Easy Switching**: Use flags (`--claude`, `--gemini`) or aliases (`buddyc`, `buddyg`) to switch backends
- **Automatic Installation**: Offers to install missing components via Homebrew

## Quick Start

```bash
./setup.sh
```

The interactive setup will guide you through:
1. Naming your AI assistant
2. Selecting which backends to enable
3. Choosing installation and context directories
4. Setting up convenient shell aliases

## Requirements

- **Required**: Open Code (`opencode`)
- **Optional**: Claude Code (`claude`), Gemini CLI (`gemini`), Homebrew (`brew`)

## Usage

After setup, use your AI assistant:

```bash
# Use default backend (Open Code)
Buddy

# Use Claude Code
Buddy --claude
buddyc

# Use Gemini
Buddy --gemini
buddyg

# Show help
Buddy --help
```

## File Structure

```
MyAI/
├── setup.sh                    # Main setup script
├── third-party-components.md   # Component definitions
├── CLAUDE.md                   # Claude Code guidance
└── README.md                   # This file

After setup:
~/.myai/
└── bin/
    └── [YourAIName]            # Generated launcher script

~/Documents/[YourAIName]/       # Context directory (configurable)
```

## Configuration

The setup modifies your shell configuration file (`.zshrc`, `.bashrc`, etc.) to add:
- `MYAI_HOME` environment variable
- `$MYAI_HOME/bin` to your PATH
- Optional aliases for quick backend switching
