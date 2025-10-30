#!/bin/bash

# Advanced Niri Desktop Environment - Installer
# This script sets up the complete environment from the structured project.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                Advanced Niri Desktop Environment                ║${NC}"
    echo -e "${BLUE}║                          Installer                           ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if running in Niri
check_niri() {
    if [ "$XDG_SESSION_DESKTOP" = "niri" ]; then
        print_success "Running in Niri session"
        return 0
    else
        print_warning "Not running in Niri session"
        print_info "You can still install, but restart Niri to apply changes"
        return 1
    fi
}

# Create backup
create_backup() {
    print_info "Creating backups..."
    BACKUP_DIR="$HOME/.config/niri-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    if [ -f "$HOME/.config/niri/config.kdl" ]; then
        cp "$HOME/.config/niri/config.kdl" "$BACKUP_DIR/"
        print_success "Backed up Niri config"
    fi

    if [ -d "$HOME/.config/waybar" ]; then
        cp -r "$HOME/.config/waybar" "$BACKUP_DIR/"
        print_success "Backed up Waybar config"
    fi

    if [ -d "$HOME/.config/eww" ]; then
        cp -r "$HOME/.config/eww" "$BACKUP_DIR/"
        print_success "Backed up EWW config"
    fi

    print_info "Backups stored in: $BACKUP_DIR"
}

# Install dependencies
install_dependencies() {
    print_info "Installing dependencies..."

    if command -v pacman &> /dev/null; then
        print_info "Detected Arch Linux - installing with pacman..."
        sudo pacman -S --needed waybar eww playerctl brightnessctl pamixer jq
    elif command -v apt &> /dev/null; then
        print_info "Detected Debian/Ubuntu - installing with apt..."
        sudo apt update
        sudo apt install -y waybar eww playerctl brightnessctl pamixer jq
    elif command -v dnf &> /dev/null; then
        print_info "Detected Fedora - installing with dnf..."
        sudo dnf install -y waybar eww playerctl brightnessctl pamixer jq
    else
        print_warning "Could not detect package manager"
        print_info "Please install manually: waybar, eww, playerctl, brightnessctl, pamixer, jq"
    fi
}

# Create directories
create_directories() {
    print_info "Creating configuration directories..."
    mkdir -p "$HOME/.config/niri"
    mkdir -p "$HOME/.config/waybar"
    mkdir -p "$HOME/.config/eww"
    mkdir -p "$HOME/.config/eww/scripts"
    mkdir -p "$HOME/.local/share/applications"
    mkdir -p "$HOME/.config/autostart"
}

# Copy configuration files
copy_files() {
    print_info "Copying configuration files..."

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    cp -v "$SCRIPT_DIR/niri/config.kdl" "$HOME/.config/niri/"
    print_success "Copied Niri configuration."

    cp -vr "$SCRIPT_DIR/waybar/." "$HOME/.config/waybar/"
    print_success "Copied Waybar configuration."

    cp -vr "$SCRIPT_DIR/eww/." "$HOME/.config/eww/"
    print_success "Copied EWW configuration."

    cp -v "$SCRIPT_DIR/applications/eww.desktop" "$HOME/.local/share/applications/"
    print_success "Copied application desktop entry."

    cp -v "$SCRIPT_DIR/autostart/eww-autostart.desktop" "$HOME/.config/autostart/"
    print_success "Copied autostart desktop entry."
}

# Main installation
main() {
    print_header

    # Parse command line arguments
    SKIP_DEPS=false
    SKIP_BACKUP=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            --skip-backup)
                SKIP_BACKUP=true
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --skip-deps     Skip dependency installation"
                echo "  --skip-backup   Skip backup creation"
                echo "  --help          Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    check_niri

    if [ "$SKIP_BACKUP" = false ]; then
        create_backup
    fi

    if [ "$SKIP_DEPS" = false ]; then
        install_dependencies
    fi

    create_directories
    copy_files

    # Make scripts executable
    chmod +x "$HOME/.config/eww/scripts"/*.sh
    print_success "Made scripts executable"

    # Kill existing processes
    print_info "Restarting services..."
    pkill waybar 2>/dev/null || true
    pkill eww 2>/dev/null || true

    sleep 2

    # Start services
    print_info "Starting services..."
    eww daemon &
    sleep 2
    waybar &
    eww open bar &

    print_success "Installation completed!"
    echo ""
    print_info "🎯 What was installed:"
    echo "   • Advanced Niri configuration"
    echo "   • Waybar status bar with system monitoring"
    echo "   • EWW widgets for keybinding management"
    echo "   • System monitoring scripts"
    echo "   • Autostart configuration"
    echo ""
    print_info "🔄 To apply changes:"
    if [ "$XDG_SESSION_DESKTOP" = "niri" ]; then
        echo "   • Press Super+Shift+R to reload Niri configuration"
        echo "   • Services have been restarted automatically"
    else
        echo "   • Log out and log back into Niri"
        echo "   • Or restart your display manager"
    fi
    echo ""
    print_info "🎯 Key features now available:"
    echo "   • Super+Space: Open keybinding manager"
    echo "   • Super+Enter: Launch terminal"
    echo "   • Super+Shift+Q: Close focused window"
    echo "   • System monitoring in top bar"
    echo "   • Interactive widgets"
    echo ""
    print_success "✨ Enjoy your advanced Niri desktop!"
}

# Run main function with all arguments
main "$@"
