#!/bin/zsh

# MyAI Setup Script

# Display banner
cat << 'BANNER'

  ███╗   ███╗        █████╗ ██╗
  ████╗ ████║██╗ ██╗██╔══██╗██║
  ██╔████╔██║╚██▄██╔╝███████║██║
  ██║╚██╔╝██║ ╚███╔╝ ██╔══██║██║
  ██║ ╚═╝ ██║  ███║  ██║  ██║██║
  ╚═╝     ╚═╝  ╚══╝  ╚═╝  ╚═╝╚═╝

  Personal AI Agent System

BANNER

echo "Welcome to MyAI Setup!"
echo ""
echo "This script will walk you through configuring your personal AI agent."
echo "You'll be asked to make a few choices along the way."
echo ""

# --- Shell Detection ---

detect_shell() {
    if [ -n "$SHELL" ]; then
        DEFAULT_SHELL="$SHELL"
    elif command -v getent >/dev/null 2>&1; then
        DEFAULT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        DEFAULT_SHELL=$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')
    else
        DEFAULT_SHELL="/bin/bash"
    fi
    SHELL_NAME=$(basename "$DEFAULT_SHELL")
}

get_config_file() {
    case "$SHELL_NAME" in
        bash)
            if [ -f "$HOME/.bash_profile" ] || [ ! -f "$HOME/.bashrc" ]; then
                CONFIG_FILE="$HOME/.bash_profile"
            else
                CONFIG_FILE="$HOME/.bashrc"
            fi
            ;;
        zsh)
            CONFIG_FILE="$HOME/.zshrc"
            ;;
        fish)
            CONFIG_FILE="$HOME/.config/fish/config.fish"
            ;;
        *)
            CONFIG_FILE="$HOME/.bashrc"
            echo "Warning: Unknown shell '$SHELL_NAME', defaulting to .bashrc"
            ;;
    esac
}

detect_shell
get_config_file

echo "Detected shell: $SHELL_NAME"
echo "Config file: $CONFIG_FILE"
echo ""

# --- Component Checking ---

SCRIPT_DIR="${0:A:h}"
COMPONENTS_FILE="$SCRIPT_DIR/third-party-components.md"

check_components() {
    local section=""
    local missing_required=()
    local missing_required_formulas=()
    local found_optional=()
    local missing_optional=()
    local has_brew=false

    if [ ! -f "$COMPONENTS_FILE" ]; then
        echo "Warning: Components file not found: $COMPONENTS_FILE"
        return 1
    fi

    # Check for Homebrew first
    if command -v brew >/dev/null 2>&1; then
        has_brew=true
    fi

    while IFS= read -r line; do
        # Detect section headers
        if [[ "$line" == "## Required" ]]; then
            section="required"
            continue
        elif [[ "$line" == "## Optional" ]]; then
            section="optional"
            continue
        fi

        # Parse table rows (skip header and separator lines)
        if [[ "$line" == \|*\|*\|*\| ]] && [[ "$line" != *"---"* ]] && [[ "$line" != *"Component"* ]]; then
            # Extract component name, command, and brew formula from table row
            local component=$(echo "$line" | cut -d'|' -f2 | xargs)
            local command=$(echo "$line" | cut -d'|' -f3 | sed 's/`//g' | xargs)
            local formula=$(echo "$line" | cut -d'|' -f4 | sed 's/`//g' | xargs)

            if [ -n "$command" ] && [ -n "$section" ]; then
                if command -v "$command" >/dev/null 2>&1; then
                    if [ "$section" = "optional" ]; then
                        found_optional+=("$component")
                    fi
                else
                    if [ "$section" = "required" ]; then
                        missing_required+=("$component ($command)")
                        if [ -n "$formula" ]; then
                            missing_required_formulas+=("$formula")
                        fi
                    else
                        missing_optional+=("$component")
                    fi
                fi
            fi
        fi
    done < "$COMPONENTS_FILE"

    # Report results
    echo "Component Check:"
    echo "----------------"

    if [ ${#missing_required[@]} -gt 0 ]; then
        echo "Missing required components:"
        for comp in "${missing_required[@]}"; do
            echo "  ✗ $comp"
        done
        echo ""

        # Offer to install via Homebrew
        if [ ${#missing_required_formulas[@]} -gt 0 ]; then
            if [ "$has_brew" = true ]; then
                echo "Homebrew detected. Would you like to install missing components?"
                read "install_choice?Install via brew? (y/n): "
                if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
                    echo ""
                    for formula in "${missing_required_formulas[@]}"; do
                        echo "Installing $formula..."
                        brew install "$formula"
                    done
                    echo ""
                    echo "Installation complete. Re-checking components..."
                    echo ""
                    check_components
                    return
                fi
            else
                echo "Homebrew is not installed. Would you like to install it?"
                read "install_brew?Install Homebrew? (y/n): "
                if [ "$install_brew" = "y" ] || [ "$install_brew" = "Y" ]; then
                    echo ""
                    echo "Installing Homebrew..."
                    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                    echo ""
                    echo "Homebrew installed. Re-checking components..."
                    echo ""
                    check_components
                    return
                fi
            fi
        fi

        echo ""
        echo "Please install the following required components and re-run this script:"
        for comp in "${missing_required[@]}"; do
            echo "  - $comp"
        done
        exit 1
    else
        echo "  ✓ All required components found"
    fi

    if [ ${#found_optional[@]} -gt 0 ]; then
        echo "Optional components available:"
        for comp in "${found_optional[@]}"; do
            echo "  ✓ $comp"
        done
    fi

    if [ ${#missing_optional[@]} -gt 0 ]; then
        echo "Optional components not found:"
        for comp in "${missing_optional[@]}"; do
            echo "  - $comp"
        done
    fi

    echo ""
}

check_components

# --- AI System Name ---

echo "Your personal AI assistant needs a name."
echo "Mine's called Max, but you're free to call yours whatever you like."
echo ""
read "ai_name?What would you like to call it? (default: Max): "

if [ -z "$ai_name" ]; then
    AI_SYSTEM_NAME="Max"
else
    AI_SYSTEM_NAME="$ai_name"
fi

echo ""
echo "Great! Your AI assistant will be called: $AI_SYSTEM_NAME"
echo ""

# --- AI Agent Backend Selection ---

echo "Open Code is your primary AI agent backend."
echo "You can optionally enable additional backends, but this is not required."
echo ""

# Initialize array of enabled agents
ENABLED_AGENTS=("opencode")

# Check for Claude Code
if command -v claude >/dev/null 2>&1; then
    read "enable_claude?Enable Claude Code as an additional backend? (Y/n): "
    if [ -z "$enable_claude" ] || [ "$enable_claude" = "y" ] || [ "$enable_claude" = "Y" ]; then
        ENABLED_AGENTS+=("claude")
        echo "  ✓ Claude Code enabled"
    fi
else
    read "install_claude?Claude Code is not installed. Would you like to install it? (optional) (y/n): "
    if [ "$install_claude" = "y" ] || [ "$install_claude" = "Y" ]; then
        echo "  Installing Claude Code..."
        brew install claude-code
        if command -v claude >/dev/null 2>&1; then
            ENABLED_AGENTS+=("claude")
            echo "  ✓ Claude Code installed and enabled"
        else
            echo "  ✗ Installation failed"
        fi
    fi
fi

# Check for Gemini
if command -v gemini >/dev/null 2>&1; then
    read "enable_gemini?Enable Gemini CLI as an additional backend? (Y/n): "
    if [ -z "$enable_gemini" ] || [ "$enable_gemini" = "y" ] || [ "$enable_gemini" = "Y" ]; then
        ENABLED_AGENTS+=("gemini")
        echo "  ✓ Gemini CLI enabled"
    fi
else
    read "install_gemini?Gemini CLI is not installed. Would you like to install it? (optional) (y/n): "
    if [ "$install_gemini" = "y" ] || [ "$install_gemini" = "Y" ]; then
        echo "  Installing Gemini CLI..."
        brew install gemini-cli
        if command -v gemini >/dev/null 2>&1; then
            ENABLED_AGENTS+=("gemini")
            echo "  ✓ Gemini CLI installed and enabled"
        else
            echo "  ✗ Installation failed"
        fi
    fi
fi

echo ""
echo "Enabled backends: ${ENABLED_AGENTS[*]}"
echo ""

# --- Default Backend Selection ---

DEFAULT_AGENT="opencode"

if [ ${#ENABLED_AGENTS[@]} -gt 1 ]; then
    echo "You have multiple backends enabled. Which would you like as your default?"
    echo ""

    # Build menu
    i=1
    for agent in "${ENABLED_AGENTS[@]}"; do
        case "$agent" in
            opencode) echo "  $i) Open Code" ;;
            claude)   echo "  $i) Claude Code" ;;
            gemini)   echo "  $i) Gemini CLI" ;;
        esac
        ((i++))
    done
    echo ""

    read "default_choice?Select default (1-${#ENABLED_AGENTS[@]}, default: 1): "

    if [ -z "$default_choice" ]; then
        default_choice=1
    fi

    if [[ "$default_choice" =~ ^[0-9]+$ ]] && [ "$default_choice" -ge 1 ] && [ "$default_choice" -le ${#ENABLED_AGENTS[@]} ]; then
        DEFAULT_AGENT="${ENABLED_AGENTS[$default_choice]}"
    fi

    case "$DEFAULT_AGENT" in
        opencode) echo "Default backend: Open Code" ;;
        claude)   echo "Default backend: Claude Code" ;;
        gemini)   echo "Default backend: Gemini CLI" ;;
    esac
    echo ""
fi

# --- MYAI_HOME Environment Variable ---

echo "MyAI needs a home directory to store its configuration and scripts."
echo ""

if [ -n "$MYAI_HOME" ]; then
    echo "MYAI_HOME is already set to: $MYAI_HOME"
    read "keep_home?Keep this location? (Y/n): "
    if [ "$keep_home" = "n" ] || [ "$keep_home" = "N" ]; then
        unset MYAI_HOME
    fi
fi

if [ -z "$MYAI_HOME" ]; then
    read "myai_home?Where would you like to install MyAI? (default: ~/.myai): "
    if [ -z "$myai_home" ]; then
        MYAI_HOME="$HOME/.myai"
    else
        # Expand ~ if user typed it
        MYAI_HOME="${myai_home/#\~/$HOME}"
    fi
fi

echo "MYAI_HOME: $MYAI_HOME"

# Create directory if it doesn't exist
if [ ! -d "$MYAI_HOME" ]; then
    echo "Creating directory: $MYAI_HOME"
    mkdir -p "$MYAI_HOME"
fi

# Create bin subdirectory
if [ ! -d "$MYAI_HOME/bin" ]; then
    mkdir -p "$MYAI_HOME/bin"
    echo "Created bin directory: $MYAI_HOME/bin"
fi

# Check if MYAI_HOME is already in shell config
if grep -q "export MYAI_HOME=" "$CONFIG_FILE" 2>/dev/null; then
    # Update existing entry
    sed -i '' "s|export MYAI_HOME=.*|export MYAI_HOME=\"$MYAI_HOME\"|" "$CONFIG_FILE"
    echo "Updated MYAI_HOME in $CONFIG_FILE"
else
    # Add new entry
    echo "" >> "$CONFIG_FILE"
    echo "# MyAI configuration" >> "$CONFIG_FILE"
    echo "export MYAI_HOME=\"$MYAI_HOME\"" >> "$CONFIG_FILE"
    echo "Added MYAI_HOME to $CONFIG_FILE"
fi

# Check if bin is in PATH in shell config
if ! grep -q 'MYAI_HOME/bin' "$CONFIG_FILE" 2>/dev/null; then
    echo 'export PATH="$MYAI_HOME/bin:$PATH"' >> "$CONFIG_FILE"
    echo "Added MYAI_HOME/bin to PATH in $CONFIG_FILE"
fi

echo ""

# --- Context Directory ---

echo "$AI_SYSTEM_NAME needs a directory to work in."
echo "This is where your AI assistant will store its context and files."
echo ""

DEFAULT_CONTEXT_DIR="$HOME/Documents/$AI_SYSTEM_NAME"

# Check if default context directory already exists
if [ -d "$DEFAULT_CONTEXT_DIR" ]; then
    echo "Context directory already exists: $DEFAULT_CONTEXT_DIR"
    read "keep_context?Keep this location? (Y/n): "
    if [ "$keep_context" = "n" ] || [ "$keep_context" = "N" ]; then
        read "context_dir?Where would you like the context directory? "
        if [ -n "$context_dir" ]; then
            CONTEXT_DIR="${context_dir/#\~/$HOME}"
        else
            CONTEXT_DIR="$DEFAULT_CONTEXT_DIR"
        fi
    else
        CONTEXT_DIR="$DEFAULT_CONTEXT_DIR"
    fi
else
    read "context_dir?Where would you like the context directory? (default: $DEFAULT_CONTEXT_DIR): "
    if [ -z "$context_dir" ]; then
        CONTEXT_DIR="$DEFAULT_CONTEXT_DIR"
    else
        # Expand ~ if user typed it
        CONTEXT_DIR="${context_dir/#\~/$HOME}"
    fi
fi

echo "Context directory: $CONTEXT_DIR"

# Create directory if it doesn't exist
if [ ! -d "$CONTEXT_DIR" ]; then
    echo "Creating directory: $CONTEXT_DIR"
    mkdir -p "$CONTEXT_DIR"
fi

echo ""

# --- Create Launcher Script ---

LAUNCHER_PATH="$MYAI_HOME/bin/$AI_SYSTEM_NAME"

echo "Creating launcher script: $LAUNCHER_PATH"

cat > "$LAUNCHER_PATH" << 'LAUNCHER_HEADER'
#!/bin/zsh
# MyAI Launcher Script
# Generated by setup.sh

LAUNCHER_HEADER

# Add configuration
cat >> "$LAUNCHER_PATH" << LAUNCHER_CONFIG
AI_NAME="$AI_SYSTEM_NAME"
CONTEXT_DIR="$CONTEXT_DIR"
DEFAULT_AGENT="$DEFAULT_AGENT"
LAUNCHER_CONFIG

# Add enabled agents array
echo "ENABLED_AGENTS=(${ENABLED_AGENTS[@]})" >> "$LAUNCHER_PATH"

# Add the rest of the launcher logic
cat >> "$LAUNCHER_PATH" << 'LAUNCHER_BODY'

show_help() {
    echo "Usage: $AI_NAME [--agent <name>] [args...]"
    echo ""
    echo "Options:"
    for agent in "${ENABLED_AGENTS[@]}"; do
        local label=""
        case "$agent" in
            opencode) label="Open Code" ;;
            claude)   label="Claude Code" ;;
            gemini)   label="Gemini CLI" ;;
        esac
        if [ "$agent" = "$DEFAULT_AGENT" ]; then
            echo "  --$agent    Use $label (default)"
        else
            echo "  --$agent    Use $label"
        fi
    done
    echo "  --help        Show this help message"
    echo ""
    echo "Default: $DEFAULT_AGENT"
}

# Parse arguments
AGENT="$DEFAULT_AGENT"
PASS_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --opencode)
            AGENT="opencode"
            shift
            ;;
        --claude)
            AGENT="claude"
            shift
            ;;
        --gemini)
            AGENT="gemini"
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            PASS_ARGS+=("$1")
            shift
            ;;
    esac
done

# Check if agent is enabled
if [[ ! " ${ENABLED_AGENTS[*]} " =~ " ${AGENT} " ]]; then
    echo "Error: Agent '$AGENT' is not enabled."
    echo "Enabled agents: ${ENABLED_AGENTS[*]}"
    exit 1
fi

# Change to context directory
cd "$CONTEXT_DIR" || {
    echo "Error: Could not change to context directory: $CONTEXT_DIR" >&2
    exit 1
}

# Launch the agent
exec "$AGENT" "${PASS_ARGS[@]}"
LAUNCHER_BODY

chmod +x "$LAUNCHER_PATH"
echo "Launcher script created: $LAUNCHER_PATH"
echo ""

# --- Shell Aliases ---

# Only offer aliases if we have multiple backends enabled
if [ ${#ENABLED_AGENTS[@]} -gt 1 ]; then
    echo "Would you like to set up some convenient aliases for non-default backends?"

    # Check if name has capitals
    AI_NAME_LOWER="${AI_SYSTEM_NAME:l}"
    HAS_CAPITALS=false
    if [ "$AI_SYSTEM_NAME" != "$AI_NAME_LOWER" ]; then
        HAS_CAPITALS=true
    fi

    # Show aliases for non-default backends only
    if [[ " ${ENABLED_AGENTS[*]} " =~ " opencode " ]] && [ "$DEFAULT_AGENT" != "opencode" ]; then
        echo "  ${AI_SYSTEM_NAME}o  -> $AI_SYSTEM_NAME --opencode"
    fi
    if [[ " ${ENABLED_AGENTS[*]} " =~ " claude " ]] && [ "$DEFAULT_AGENT" != "claude" ]; then
        echo "  ${AI_SYSTEM_NAME}c  -> $AI_SYSTEM_NAME --claude"
    fi
    if [[ " ${ENABLED_AGENTS[*]} " =~ " gemini " ]] && [ "$DEFAULT_AGENT" != "gemini" ]; then
        echo "  ${AI_SYSTEM_NAME}g  -> $AI_SYSTEM_NAME --gemini"
    fi

    if [ "$HAS_CAPITALS" = true ]; then
        echo "  ${AI_NAME_LOWER}    -> $AI_SYSTEM_NAME"
        if [[ " ${ENABLED_AGENTS[*]} " =~ " opencode " ]] && [ "$DEFAULT_AGENT" != "opencode" ]; then
            echo "  ${AI_NAME_LOWER}o   -> $AI_SYSTEM_NAME --opencode"
        fi
        if [[ " ${ENABLED_AGENTS[*]} " =~ " claude " ]] && [ "$DEFAULT_AGENT" != "claude" ]; then
            echo "  ${AI_NAME_LOWER}c   -> $AI_SYSTEM_NAME --claude"
        fi
        if [[ " ${ENABLED_AGENTS[*]} " =~ " gemini " ]] && [ "$DEFAULT_AGENT" != "gemini" ]; then
            echo "  ${AI_NAME_LOWER}g   -> $AI_SYSTEM_NAME --gemini"
        fi
    fi
    echo ""

    read "setup_aliases?Add these aliases to your shell? (Y/n): "

    if [ -z "$setup_aliases" ] || [ "$setup_aliases" = "y" ] || [ "$setup_aliases" = "Y" ]; then
        # Remove old aliases if they exist
        sed -i '' "/^alias ${AI_SYSTEM_NAME}o=/d" "$CONFIG_FILE" 2>/dev/null
        sed -i '' "/^alias ${AI_SYSTEM_NAME}c=/d" "$CONFIG_FILE" 2>/dev/null
        sed -i '' "/^alias ${AI_SYSTEM_NAME}g=/d" "$CONFIG_FILE" 2>/dev/null
        sed -i '' "/^alias ${AI_NAME_LOWER}=/d" "$CONFIG_FILE" 2>/dev/null
        sed -i '' "/^alias ${AI_NAME_LOWER}o=/d" "$CONFIG_FILE" 2>/dev/null
        sed -i '' "/^alias ${AI_NAME_LOWER}c=/d" "$CONFIG_FILE" 2>/dev/null
        sed -i '' "/^alias ${AI_NAME_LOWER}g=/d" "$CONFIG_FILE" 2>/dev/null

        # Add aliases for non-default backends only
        if [[ " ${ENABLED_AGENTS[*]} " =~ " opencode " ]] && [ "$DEFAULT_AGENT" != "opencode" ]; then
            echo "alias ${AI_SYSTEM_NAME}o=\"$AI_SYSTEM_NAME --opencode\"" >> "$CONFIG_FILE"
            echo "  ✓ Added alias: ${AI_SYSTEM_NAME}o"
        fi
        if [[ " ${ENABLED_AGENTS[*]} " =~ " claude " ]] && [ "$DEFAULT_AGENT" != "claude" ]; then
            echo "alias ${AI_SYSTEM_NAME}c=\"$AI_SYSTEM_NAME --claude\"" >> "$CONFIG_FILE"
            echo "  ✓ Added alias: ${AI_SYSTEM_NAME}c"
        fi
        if [[ " ${ENABLED_AGENTS[*]} " =~ " gemini " ]] && [ "$DEFAULT_AGENT" != "gemini" ]; then
            echo "alias ${AI_SYSTEM_NAME}g=\"$AI_SYSTEM_NAME --gemini\"" >> "$CONFIG_FILE"
            echo "  ✓ Added alias: ${AI_SYSTEM_NAME}g"
        fi

        if [ "$HAS_CAPITALS" = true ]; then
            echo "alias ${AI_NAME_LOWER}=\"$AI_SYSTEM_NAME\"" >> "$CONFIG_FILE"
            echo "  ✓ Added alias: ${AI_NAME_LOWER}"
            if [[ " ${ENABLED_AGENTS[*]} " =~ " opencode " ]] && [ "$DEFAULT_AGENT" != "opencode" ]; then
                echo "alias ${AI_NAME_LOWER}o=\"$AI_SYSTEM_NAME --opencode\"" >> "$CONFIG_FILE"
                echo "  ✓ Added alias: ${AI_NAME_LOWER}o"
            fi
            if [[ " ${ENABLED_AGENTS[*]} " =~ " claude " ]] && [ "$DEFAULT_AGENT" != "claude" ]; then
                echo "alias ${AI_NAME_LOWER}c=\"$AI_SYSTEM_NAME --claude\"" >> "$CONFIG_FILE"
                echo "  ✓ Added alias: ${AI_NAME_LOWER}c"
            fi
            if [[ " ${ENABLED_AGENTS[*]} " =~ " gemini " ]] && [ "$DEFAULT_AGENT" != "gemini" ]; then
                echo "alias ${AI_NAME_LOWER}g=\"$AI_SYSTEM_NAME --gemini\"" >> "$CONFIG_FILE"
                echo "  ✓ Added alias: ${AI_NAME_LOWER}g"
            fi
        fi
        echo ""
    fi
fi

# --- Setup Complete ---

echo "════════════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "  AI Assistant:    $AI_SYSTEM_NAME"
echo "  MYAI_HOME:       $MYAI_HOME"
echo "  Context Dir:     $CONTEXT_DIR"
echo "  Backends:        ${ENABLED_AGENTS[*]}"
echo "  Default:         $DEFAULT_AGENT"
echo ""
echo "  Launcher:        $LAUNCHER_PATH"
echo ""
echo "  To get started, run:"
echo "    source $CONFIG_FILE"
echo "    $AI_SYSTEM_NAME"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""

