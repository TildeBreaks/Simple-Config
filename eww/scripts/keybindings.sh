#!/bin/bash

# Keybinding Management Script for EWW
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.config/niri/config.kdl"

# Default keybindings
declare -A DEFAULT_KEYBINDINGS=(
    ["Mod+Space"]="eww open keybinding-popup || eww close keybinding-popup"
    ["Mod+Return"]="foot"
    ["Mod+D"]="fuzzel"
    ["Mod+B"]="firefox"
    ["Mod+N"]="nautilus"
    ["Mod+Q"]="close-window"
    ["Mod+F"]="toggle-float"
    ["Mod+M"]="maximize-column"
    ["Mod+1"]="focus-workspace 1"
    ["Mod+2"]="focus-workspace 2"
    ["Mod+3"]="focus-workspace 3"
    ["Mod+4"]="focus-workspace 4"
    ["Mod+5"]="focus-workspace 5"
    ["Mod+6"]="focus-workspace 6"
    ["Mod+7"]="focus-workspace 7"
    ["Mod+8"]="focus-workspace 8"
    ["Mod+Shift+1"]="move-column-to-workspace 1"
    ["Mod+Shift+2"]="move-column-to-workspace 2"
    ["Mod+Shift+3"]="move-column-to-workspace 3"
    ["Mod+Shift+4"]="move-column-to-workspace 4"
    ["Mod+Shift+5"]="move-column-to-workspace 5"
    ["Mod+Shift+6"]="move-column-to-workspace 6"
    ["Mod+Shift+7"]="move-column-to-workspace 7"
    ["Mod+Shift+8"]="move-column-to-workspace 8"
    ["Mod+Shift+R"]="reload-config"
    ["Mod+P"]="playerctl play-pause"
    ["Mod+Shift+P"]="playerctl next"
)

# Function to extract keybindings from Niri config
extract_keybindings() {
    if [[ -f "$CONFIG_FILE" ]]; then
        awk '/^binds \{/ {
            in_binds = 1
            next
        }
        /^}/ && in_binds {
            in_binds = 0
            next
        }
        in_binds && /Mod\+/ {
            if (match($0, /([^ ]+)\s*\{[^}]+\}/, arr)) {
                key = arr[1]
                if (match($0, /\{([^}]+)\}/, cmd_arr)) {
                    cmd = cmd_arr[1]
                    cmd = gensub(/^[[:space:]]+|[[:space:]]+$/, "", "g", cmd)
                    print key "|" cmd
                }
            }
        }' "$CONFIG_FILE"
    else
        for key in "${!DEFAULT_KEYBINDINGS[@]}"; do
            echo "$key|${DEFAULT_KEYBINDINGS[$key]}"
        done
    fi
}

# Function to format keybindings for EWW
format_keybindings() {
    local bindings=()
    while IFS='|' read -r key command; do
        if [[ -n "$key" && -n "$command" ]]; then
            id=$(echo "$key" | tr -d '"+' ' ' | tr '[:upper:]' '[:lower:]' | sed 's/mod/super/g')
            display_key=$(echo "$key" | sed 's/Mod/Super/g' | sed 's/+/ + /g')
            action_name=$(get_action_name "$command")
            bindings+=("{\"id\":\"$id\",\"keys\":\"$display_key\",\"action\":\"$action_name\",\"command\":\"$command\"}")
        fi
    done
    echo "[${bindings[*]}]" | sed 's/]\[/],\[/g'
}

# Function to get descriptive action name
get_action_name() {
    local cmd="$1"
    case "$cmd" in
        *"eww open keybinding-popup"*) echo "Open Keybinding Manager" ;;
        *"foot"*) echo "Launch Terminal" ;;
        *"fuzzel"*) echo "Application Launcher" ;;
        *"firefox"*) echo "Launch Firefox" ;;
        *"nautilus"*) echo "File Manager" ;;
        *"close-window"*) echo "Close Window" ;;
        *"toggle-float"*) echo "Toggle Floating" ;;
        *"maximize-column"*) echo "Maximize Column" ;;
        *"focus-workspace"*) echo "Switch Workspace" ;;
        *"move-column-to-workspace"*) echo "Move to Workspace" ;;
        *"reload-config"*) echo "Reload Config" ;;
        *"playerctl play-pause"*) echo "Play/Pause" ;;
        *"playerctl next"*) echo "Next Track" ;;
        *pamixer*) echo "Volume Control" ;;
        *brightnessctl*) echo "Brightness Control" ;;
        *) echo "Custom Command" ;;
    esac
}

# Function to execute a keybinding command
execute_keybinding() {
    local command="$1"
    if [[ -n "$command" ]]; then
        nohup bash -c "$command" >/dev/null 2>&1 &
        echo "Executed: $command"
    else
        echo "Error: No command provided"
        exit 1
    fi
}

# Function to generate EWW variable
generate_eww_variable() {
    local keybindings_json
    keybindings_json=$(extract_keybindings | format_keybindings)
    echo "$keybindings_json"
}

# Function to update EWW with current keybindings
update_eww() {
    local keybindings_json
    keybindings_json=$(generate_eww_variable)
    if pgrep -x "eww" > /dev/null; then
        eww update keybindings="$keybindings_json"
        echo "Updated EWW with current keybindings"
    else
        echo "EWW is not running"
    fi
}

# Main script logic
case "${1:-}" in
    "extract")
        extract_keybindings
        ;;
    "format")
        extract_keybindings | format_keybindings
        ;;
    "execute")
        execute_keybinding "$2"
        ;;
    "update")
        update_eww
        ;;
    "json")
        generate_eww_variable
        ;;
    *)
        echo "Keybinding Management Script for EWW"
        echo "Usage: $0 {extract|format|execute|update|json}"
        echo ""
        echo "Commands:"
        echo "  extract              - Extract keybindings from Niri config"
        echo "  format               - Format keybindings for EWW display"
        echo "  execute <command>     - Execute a keybinding command"
        echo "  update               - Update EWW with current keybindings"
        echo "  json                 - Output keybindings as JSON for EWW"
        exit 1
        ;;
esac