#!/bin/zsh

# Setup script for MyAI 

echo "Setting up MyAI..."

# Detect default shell (moved early for reuse in other setup operations)
# Use $SHELL if available, otherwise try to get from passwd/dscl
if [ -n "$SHELL" ]; then
    DEFAULT_SHELL="$SHELL"
elif command -v getent >/dev/null 2>&1; then
    DEFAULT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: use dscl to get user shell
    DEFAULT_SHELL=$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')
else
    # Fallback to /bin/bash
    DEFAULT_SHELL="/bin/bash"
fi
SHELL_NAME=$(basename "$DEFAULT_SHELL")

echo "Detected default shell: $SHELL_NAME"

# Determine the appropriate config file based on shell
case "$SHELL_NAME" in
    bash)
        # Check for .bashrc (Linux) or .bash_profile (macOS)
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
        # Default to .bashrc for unknown shells
        CONFIG_FILE="$HOME/.bashrc"
        echo "Warning: Unknown shell type, defaulting to .bashrc"
        ;;
esac

echo "Config file: $CONFIG_FILE"

# Ask for AI system name
read "ai_name?What would you like to call your AI System? (default: Max): "
if [ -z "$ai_name" ]; then
    AI_SYSTEM_NAME="Max"
else
    AI_SYSTEM_NAME="$ai_name"
fi
echo "AI System name: $AI_SYSTEM_NAME"

# Ask for AI Agent System
echo ""
echo "Which AI Agent System would you like to use?"
echo "1) Claude Code"
echo "2) Open Code"
echo "3) Gemini"
echo "4) Other"
read "agent_choice?Enter your choice (1-4, default: 1): "

if [ -z "$agent_choice" ]; then
    agent_choice="1"
fi

case "$agent_choice" in
    1)
        AI_AGENT_COMMAND="claude"
        echo "Selected: Claude Code"
        ;;
    2)
        AI_AGENT_COMMAND="opencode"
        echo "Selected: Open Code"
        ;;
    3)
        AI_AGENT_COMMAND="gemini"
        echo "Selected: Gemini"
        ;;
    4)
        read "custom_command?Enter the command to invoke your AI Agent System: "
        if [ -z "$custom_command" ]; then
            echo "Error: Custom command cannot be empty."
            exit 1
        fi
        AI_AGENT_COMMAND="$custom_command"
        echo "Selected: Custom command ($AI_AGENT_COMMAND)"
        ;;
    *)
        echo "Invalid choice. Defaulting to Claude Code."
        AI_AGENT_COMMAND="claude"
        ;;
esac

# Configuration update tracking variables
NEEDS_CONFIG_UPDATE=false
CONFIG_MYAI_HOME=""
CONFIG_ADD_PATH=false

# Function to remove MyAI configuration section from config file
remove_myai_config() {
    local config_file="$1"
    # Create a temporary file without the MyAI section
    local temp_file=$(mktemp)
    local in_section=false
    
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" == "# MyAI configuration" ]] || [[ "$line" == "# Add MyAI bin directory to PATH" ]]; then
            in_section=true
            continue
        fi
        if [ "$in_section" = true ]; then
            # Check if this is still part of MyAI section (export MYAI_HOME or export PATH with MYAI_HOME)
            if [[ "$line" == export\ MYAI_HOME=* ]] || [[ "$line" == export\ PATH=*MYAI_HOME* ]]; then
                continue
            fi
            # If we hit a blank line or non-MyAI line, we're done with the section
            if [[ -z "$line" ]] || [[ "$line" != export\ * ]]; then
                in_section=false
                # Don't skip this line, include it
            fi
        fi
        if [ "$in_section" != true ]; then
            echo "$line" >> "$temp_file"
        fi
    done < "$config_file"
    
    mv "$temp_file" "$config_file"
}

# Function to apply all configuration updates at once
apply_config_updates() {
    if [ "$NEEDS_CONFIG_UPDATE" != "true" ]; then
        return
    fi
    
    # Remove existing MyAI configuration section if it exists
    if grep -q "# MyAI configuration" "$CONFIG_FILE" 2>/dev/null; then
        remove_myai_config "$CONFIG_FILE"
    fi
    
    # Add consolidated MyAI configuration section
    if [ -n "$CONFIG_MYAI_HOME" ]; then
        echo "" >> "$CONFIG_FILE"
        echo "# MyAI configuration" >> "$CONFIG_FILE"
        echo "export MYAI_HOME=\"$CONFIG_MYAI_HOME\"" >> "$CONFIG_FILE"
        if [ "$CONFIG_ADD_PATH" = "true" ]; then
            echo "export PATH=\"\$MYAI_HOME/bin:\$PATH\"" >> "$CONFIG_FILE"
        fi
        echo "Updated MyAI configuration in $CONFIG_FILE"
    fi
}

# Check for MYAI_HOME environment variable
if [ -z "$MYAI_HOME" ]; then
    echo "MYAI_HOME is not set."
    read "user_input?Enter MYAI_HOME path (default: ~/.myai): "
    
    # Use default if user input is empty
    if [ -z "$user_input" ]; then
        MYAI_HOME="$HOME/.myai"
    else
        # Expand ~ if user typed it (zsh handles this natively)
        MYAI_HOME="${user_input/#\~/$HOME}"
        # Additional zsh tilde expansion
        if [[ "$MYAI_HOME" == ~* ]]; then
            MYAI_HOME="${MYAI_HOME/#\~/$HOME}"
        fi
    fi
    
    echo "MYAI_HOME will be set to: $MYAI_HOME"
    
    # Check if MyAI configuration already exists in the config file
    if grep -q "# MyAI configuration" "$CONFIG_FILE" 2>/dev/null; then
        echo "MyAI configuration already exists in $CONFIG_FILE"
        read "update_choice?Do you want to update it? (y/n): "
        if [ "$update_choice" = "y" ] || [ "$update_choice" = "Y" ]; then
            # Track that we need to update the configuration
            NEEDS_CONFIG_UPDATE=true
            CONFIG_MYAI_HOME="$MYAI_HOME"
        else
            echo "Skipping update. Using existing MYAI_HOME from config file."
            # Extract MYAI_HOME from config file for use in rest of script
            MYAI_HOME=$(grep "^export MYAI_HOME=" "$CONFIG_FILE" 2>/dev/null | sed 's/^export MYAI_HOME="\(.*\)"/\1/' | sed "s|^~|$HOME|")
        fi
    else
        # No existing configuration, track that we need to add it
        NEEDS_CONFIG_UPDATE=true
        CONFIG_MYAI_HOME="$MYAI_HOME"
    fi
else
    echo "MYAI_HOME is already set to: $MYAI_HOME"
    # Check if it's in the config file, if not we should add it
    if ! grep -q "^export MYAI_HOME=" "$CONFIG_FILE" 2>/dev/null; then
        NEEDS_CONFIG_UPDATE=true
        CONFIG_MYAI_HOME="$MYAI_HOME"
    fi
fi

# Ensure we have MYAI_HOME value (either from env or just set)
if [ -z "$MYAI_HOME" ]; then
    # If still not set, try to get it from the config file
    MYAI_HOME=$(grep "^export MYAI_HOME=" "$CONFIG_FILE" 2>/dev/null | sed 's/^export MYAI_HOME="\(.*\)"/\1/' | sed "s|^~|$HOME|")
fi

# Check if MYAI_HOME directory exists
if [ -n "$MYAI_HOME" ]; then
    if [ ! -d "$MYAI_HOME" ]; then
        echo "MYAI_HOME directory does not exist: $MYAI_HOME"
        read "create_choice?Do you want to create it? (y/n): "
        if [ "$create_choice" = "y" ] || [ "$create_choice" = "Y" ]; then
            mkdir -p "$MYAI_HOME"
            echo "Created MYAI_HOME directory: $MYAI_HOME"
        else
            echo "Directory creation skipped."
            echo "Please create the MYAI_HOME directory ($MYAI_HOME) and run this setup script again."
            exit 1
        fi
    fi
    
    # Create bin subdirectory if MYAI_HOME exists
    if [ -d "$MYAI_HOME" ]; then
        BIN_DIR="$MYAI_HOME/bin"
        if [ ! -d "$BIN_DIR" ]; then
            mkdir -p "$BIN_DIR"
            echo "Created bin directory: $BIN_DIR"
        else
            echo "Bin directory already exists: $BIN_DIR"
        fi
        
        # Check if bin directory is already in PATH
        if grep -q "\$MYAI_HOME/bin" "$CONFIG_FILE" 2>/dev/null; then
            echo "MYAI_HOME/bin is already in PATH"
        else
            # PATH not in config - track that we need to add it
            if [ -z "$CONFIG_MYAI_HOME" ]; then
                # If we haven't set CONFIG_MYAI_HOME yet, use current MYAI_HOME value
                CONFIG_MYAI_HOME="$MYAI_HOME"
            fi
            CONFIG_ADD_PATH=true
            NEEDS_CONFIG_UPDATE=true
            echo "Will add MYAI_HOME/bin to PATH"
        fi
        
        # Ask for Context directory location before creating script
        DEFAULT_CONTEXT_DIR="$HOME/Documents/$AI_SYSTEM_NAME"
        read "context_dir?Where would you like to store the Context for $AI_SYSTEM_NAME? (default: $DEFAULT_CONTEXT_DIR): "
        
        if [ -z "$context_dir" ]; then
            CONTEXT_DIR="$DEFAULT_CONTEXT_DIR"
        else
            # Expand ~ if user typed it
            CONTEXT_DIR="${context_dir/#\~/$HOME}"
            # Additional zsh tilde expansion
            if [[ "$CONTEXT_DIR" == ~* ]]; then
                CONTEXT_DIR="${CONTEXT_DIR/#\~/$HOME}"
            fi
        fi
        
        echo "Context directory: $CONTEXT_DIR"
        
        # Check if context directory exists, create if needed
        if [ ! -d "$CONTEXT_DIR" ]; then
            echo "Context directory does not exist: $CONTEXT_DIR"
            read "create_context_choice?Do you want to create it? (y/n): "
            if [ "$create_context_choice" = "y" ] || [ "$create_context_choice" = "Y" ]; then
                mkdir -p "$CONTEXT_DIR"
                echo "Created context directory: $CONTEXT_DIR"
            else
                echo "Context directory creation skipped."
                echo "Please create the context directory ($CONTEXT_DIR) and run this setup script again."
                exit 1
            fi
        else
            echo "Context directory already exists: $CONTEXT_DIR"
        fi
        
        # Create the AI system script
        AI_SCRIPT_PATH="$BIN_DIR/$AI_SYSTEM_NAME"
        create_ai_script=false
        if [ -f "$AI_SCRIPT_PATH" ]; then
            echo "Script $AI_SYSTEM_NAME already exists in bin directory"
            read "overwrite_choice?Do you want to overwrite it? (y/n): "
            if [ "$overwrite_choice" = "y" ] || [ "$overwrite_choice" = "Y" ]; then
                create_ai_script=true
            else
                echo "Skipping script creation."
            fi
        else
            create_ai_script=true
        fi
        
        if [ "$create_ai_script" = "true" ]; then
            cat > "$AI_SCRIPT_PATH" << SCRIPT_EOF
#!/bin/zsh
# MyAI Agent System Launcher
# This script was generated by setup.sh
# AI System: $AI_SYSTEM_NAME
# Agent Command: $AI_AGENT_COMMAND
# Context Directory: $CONTEXT_DIR

# Change to context directory before starting the agent
cd "$CONTEXT_DIR" || {
    echo "Error: Could not change to context directory: $CONTEXT_DIR" >&2
    exit 1
}

exec $AI_AGENT_COMMAND "\$@"
SCRIPT_EOF
            chmod +x "$AI_SCRIPT_PATH"
            echo "Created AI system script: $AI_SCRIPT_PATH"
        fi
    fi
fi

# Apply all configuration updates at once
apply_config_updates

if [ "$NEEDS_CONFIG_UPDATE" = "true" ]; then
    echo "Please run 'source $CONFIG_FILE' or restart your terminal to apply changes."
fi

echo "Setup complete!"

