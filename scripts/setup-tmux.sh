#!/bin/bash

# ============================================
# Terminal Multiplexer Setup (tmux)
# ============================================
# Installs and configures tmux with:
# - Catppuccin Mocha theme
# - TPM (Tmux Plugin Manager)
# - tmux-resurrect (session persistence)
# - btop (beautiful system monitor)
# - Ergonomic keybindings (Ctrl+a prefix)
# - Pre-built dev session layout
#
# Usage: bash setup-tmux.sh
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

CHECK="✅"
ROCKET="🚀"
WRENCH="🔧"
PACKAGE="📦"
SPARKLES="✨"

print_header() {
    echo -e "${PURPLE}"
    echo "╔═══════════════════════════════════════════╗"
    echo "║    🖥️  TERMINAL MULTIPLEXER SETUP 🖥️       ║"
    echo "╚═══════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${CYAN}${ROCKET} $1${NC}"
}

print_success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}${WRENCH} $1${NC}"
}

# Check macOS
check_os() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only."
        exit 1
    fi
    print_success "Running on macOS"
}

# Ensure Homebrew is available
ensure_homebrew() {
    print_step "Checking Homebrew..."
    if command -v brew &> /dev/null; then
        print_success "Homebrew available"
    elif [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        print_success "Homebrew available (Apple Silicon)"
    elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
        print_success "Homebrew available (Intel)"
    else
        print_error "Homebrew not found. Run setup-macos.sh first or install from https://brew.sh"
        exit 1
    fi
}

# Install tmux
install_tmux() {
    print_step "Installing tmux..."
    if command -v tmux &> /dev/null; then
        local version=$(tmux -V 2>&1)
        print_success "tmux already installed ($version)"
    else
        print_info "Installing tmux via Homebrew..."
        brew install tmux
        print_success "tmux installed ($(tmux -V))"
    fi
}

# Install btop (beautiful system monitor)
install_btop() {
    print_step "Installing btop (system monitor)..."
    if command -v btop &> /dev/null; then
        print_success "btop already installed"
    else
        print_info "Installing btop via Homebrew..."
        brew install btop
        print_success "btop installed"
    fi
}

# Install TPM (Tmux Plugin Manager)
install_tpm() {
    print_step "Installing TPM (Tmux Plugin Manager)..."
    local tpm_dir="$HOME/.tmux/plugins/tpm"

    if [ -d "$tpm_dir" ]; then
        print_success "TPM already installed"
    else
        print_info "Cloning TPM..."
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
        print_success "TPM installed"
    fi
}

# Deploy tmux configuration
deploy_config() {
    print_step "Deploying tmux configuration..."

    local config_dest="$HOME/.tmux.conf"
    local script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    local config_src="$script_dir/../configs/tmux.conf"

    # Backup existing config
    if [ -f "$config_dest" ]; then
        local backup="$config_dest.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backing up existing config to $backup"
        cp "$config_dest" "$backup"
    fi

    if [ -f "$config_src" ]; then
        cp "$config_src" "$config_dest"
        print_success "tmux.conf deployed to $config_dest"
    else
        print_error "Config file not found at $config_src"
        print_info "Creating config directly..."
        # Fallback: download from repo or create minimal config
        print_error "Please copy configs/tmux.conf to ~/.tmux.conf manually"
        return 1
    fi
}

# Install tmux plugins via TPM
install_plugins() {
    print_step "Installing tmux plugins..."

    if [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
        print_info "Running TPM plugin installer..."
        "$HOME/.tmux/plugins/tpm/bin/install_plugins"
        print_success "Plugins installed"
    else
        print_info "Plugins will be installed on first tmux launch."
        print_info "Press Ctrl+a then I (capital i) inside tmux to install plugins."
    fi
}

# Deploy dev session script
deploy_dev_session() {
    print_step "Setting up dev session launcher..."

    local script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    local session_src="$script_dir/../configs/dev-session.sh"
    local session_dest="$HOME/.local/bin/dev-session"

    # Ensure ~/.local/bin exists
    mkdir -p "$HOME/.local/bin"

    if [ -f "$session_src" ]; then
        cp "$session_src" "$session_dest"
        chmod +x "$session_dest"
        print_success "dev-session command installed to $session_dest"
    else
        print_error "dev-session.sh not found at $session_src"
    fi
}

# Add tmux aliases/config to .zshrc
configure_shell() {
    print_step "Adding tmux configuration to shell..."

    local zshrc="$HOME/.zshrc"

    if ! grep -q "# === tmux Configuration ===" "$zshrc" 2>/dev/null; then
        cat >> "$zshrc" << 'TMUX_EOF'

# === tmux Configuration ===
# Added by MacDev tmux setup

# tmux aliases
alias t='tmux'
alias ta='tmux attach -t'
alias tl='tmux list-sessions'
alias tn='tmux new-session -s'
alias tk='tmux kill-session -t'
alias td='tmux detach'

# Dev session launcher (creates Claude Code workflow layout)
# cd into any project folder and type 'sc' to start coding
alias dev='dev-session'
alias sc='dev-session'

# === End tmux Configuration ===
TMUX_EOF
        print_success "Shell aliases added to .zshrc"
    else
        print_success "tmux shell config already exists in .zshrc"
    fi
}

# Print completion message
print_completion() {
    echo -e "\n${GREEN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║     ${SPARKLES}  TERMINAL MULTIPLEXER SETUP COMPLETE! ${SPARKLES}            ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo -e "${CYAN}${SPARKLES} What's installed:${NC}"
    echo "  • tmux          - Terminal multiplexer"
    echo "  • btop          - Beautiful system monitor"
    echo "  • TPM           - Tmux Plugin Manager"
    echo "  • tmux-resurrect - Session persistence (survives restarts)"
    echo "  • tmux-continuum - Auto-save sessions"
    echo "  • Catppuccin     - Beautiful Mocha color theme"

    echo -e "\n${YELLOW}${ROCKET} Quick Start:${NC}"
    echo "  Start a dev session:     dev myproject ~/path/to/project"
    echo "  Start tmux manually:     tmux new -s work"
    echo "  Reattach to session:     tmux attach -t work"
    echo "  List sessions:           tmux ls"

    echo -e "\n${PURPLE}Keybindings (prefix = Ctrl+a):${NC}"
    echo "  ┌────────────────────────────────────────────────────┐"
    echo "  │  Ctrl+a |       Split pane vertically              │"
    echo "  │  Ctrl+a -       Split pane horizontally            │"
    echo "  │  Alt+arrows     Navigate between panes             │"
    echo "  │  Shift+arrows   Switch between windows             │"
    echo "  │  Ctrl+a z       Zoom/unzoom current pane           │"
    echo "  │  Ctrl+a d       Detach from session                │"
    echo "  │  Ctrl+a c       Create new window                  │"
    echo "  │  Ctrl+a r       Reload tmux config                 │"
    echo "  │  Ctrl+a I       Install plugins (capital I)        │"
    echo "  └────────────────────────────────────────────────────┘"

    echo -e "\n${CYAN}Dev Session Layout:${NC}"
    echo "  ┌────────────────────────┬──────────────────┐"
    echo "  │                        │   Dev Server     │"
    echo "  │                        │   (npm run dev)  │"
    echo "  │    Claude Code         ├──────────────────┤"
    echo "  │    (full height)       │   Monitoring     │"
    echo "  │                        │   (btop)         │"
    echo "  │                        │                  │"
    echo "  └────────────────────────┴──────────────────┘"

    echo -e "\n${GREEN}Restart your terminal or run: source ~/.zshrc${NC}"
    echo -e "${GREEN}Then try: dev myproject ~/path/to/project${NC}\n"
}

# Main
main() {
    print_header

    check_os
    ensure_homebrew
    install_tmux
    install_btop
    install_tpm
    deploy_config
    install_plugins
    deploy_dev_session
    configure_shell

    print_completion
}

main
