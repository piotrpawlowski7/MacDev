#!/bin/bash

# ============================================
# Dev Session - tmux layout for Claude Code workflow
# ============================================
# Creates a pre-configured tmux session with:
#   - Top-left (65% w, 80% h): Claude Code
#   - Bottom-left (65% w, 20% h): Claude Monitor
#   - Top-right: Dev server (npm run dev, etc.)
#   - Bottom-right: System monitor (btop/htop)
#
# Usage:
#   ./dev-session.sh [session-name] [project-path] [--monitor=CMD]
#
# Examples:
#   ./dev-session.sh                    # "dev" session in current dir
#   ./dev-session.sh myapp ~/projects/myapp
#   ./dev-session.sh myapp ~/projects/myapp --monitor=btop
# ============================================

SESSION_NAME="${1:-dev}"
PROJECT_DIR="${2:-$(pwd)}"

# Parse optional --monitor flag
MONITOR_OVERRIDE=""
for arg in "$@"; do
    case "$arg" in
        --monitor=*) MONITOR_OVERRIDE="${arg#--monitor=}" ;;
    esac
done

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo -e "${YELLOW}tmux is not installed. Run scripts/setup-tmux.sh first.${NC}"
    exit 1
fi

# If already inside tmux, warn
if [ -n "$TMUX" ]; then
    echo -e "${YELLOW}Already inside a tmux session.${NC}"
    echo "Use 'Ctrl+a d' to detach first, or run from outside tmux."
    exit 1
fi

# Kill existing session with same name (if any)
tmux has-session -t "$SESSION_NAME" 2>/dev/null && tmux kill-session -t "$SESSION_NAME"

# Determine monitor command (claude-monitor > btop > htop > top)
if [ -n "$MONITOR_OVERRIDE" ]; then
    MONITOR_CMD="$MONITOR_OVERRIDE"
elif command -v claude-monitor &> /dev/null; then
    MONITOR_CMD="claude-monitor"
elif command -v btop &> /dev/null; then
    MONITOR_CMD="btop"
elif command -v htop &> /dev/null; then
    MONITOR_CMD="htop"
else
    MONITOR_CMD="top"
fi

echo -e "${CYAN}Starting dev session: ${GREEN}$SESSION_NAME${NC}"
echo -e "${CYAN}Project directory:    ${GREEN}$PROJECT_DIR${NC}"
echo ""

# ┌────────────────────────┬──────────────────┐
# │                        │   Dev Server     │
# │    Claude Code         │   (npm run dev)  │
# │    (80% height)        ├──────────────────┤
# │                        │   Monitoring     │
# ├────────────────────────┤   (btop)         │
# │    Claude Monitor      │                  │
# │    (20% height)        │                  │
# └────────────────────────┴──────────────────┘
#         65% width              35% width

# Determine claude-monitor command for bottom-left pane
if command -v claude-monitor &> /dev/null; then
    CLAUDE_MONITOR_CMD="claude-monitor"
else
    CLAUDE_MONITOR_CMD=""
fi

# Create session with first window (this becomes the left/main pane)
tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_DIR" -x "$(tput cols)" -y "$(tput lines)"

# Split right sidebar (35% width)
tmux split-window -h -p 35 -c "$PROJECT_DIR"

# Split right pane top/bottom (50/50)
tmux split-window -v -p 50 -c "$PROJECT_DIR"

# Split left pane (pane 0) to add Claude Monitor at bottom (20% height)
tmux select-pane -t "$SESSION_NAME:1.0"
tmux split-window -v -p 20 -c "$PROJECT_DIR"

# Pane layout after splits:
#   pane 0 = top-left (Claude Code)
#   pane 1 = bottom-left (Claude Monitor)
#   pane 2 = top-right (dev server)
#   pane 3 = bottom-right (system monitor)

# Pane 0 (top-left): Claude Code
tmux send-keys -t "$SESSION_NAME:1.0" "cd '$PROJECT_DIR' && clear" C-m
tmux send-keys -t "$SESSION_NAME:1.0" "echo ''" C-m
tmux send-keys -t "$SESSION_NAME:1.0" "echo '  Ready for Claude Code - type: claude'" C-m
tmux send-keys -t "$SESSION_NAME:1.0" "echo ''" C-m
tmux send-keys -t "$SESSION_NAME:1.0" "echo '  Keybindings:'" C-m
tmux send-keys -t "$SESSION_NAME:1.0" "echo '    Ctrl+a |   Split vertical'" C-m
tmux send-keys -t "$SESSION_NAME:1.0" "echo '    Ctrl+a -   Split horizontal'" C-m
tmux send-keys -t "$SESSION_NAME:1.0" "echo '    Alt+arrows Navigate panes'" C-m
tmux send-keys -t "$SESSION_NAME:1.0" "echo '    Shift+arrows Switch windows'" C-m
tmux send-keys -t "$SESSION_NAME:1.0" "echo '    Ctrl+a d   Detach session'" C-m
tmux send-keys -t "$SESSION_NAME:1.0" "echo '    Ctrl+a z   Zoom pane'" C-m
tmux send-keys -t "$SESSION_NAME:1.0" "echo ''" C-m

# Pane 1 (bottom-left): Claude Monitor
if [ -n "$CLAUDE_MONITOR_CMD" ]; then
    tmux send-keys -t "$SESSION_NAME:1.1" "$CLAUDE_MONITOR_CMD --compact" C-m
else
    tmux send-keys -t "$SESSION_NAME:1.1" "cd '$PROJECT_DIR' && clear && echo 'Install claude-monitor for live dashboard here'" C-m
fi

# Pane 2 (top-right): dev server
tmux send-keys -t "$SESSION_NAME:1.2" "cd '$PROJECT_DIR' && clear && echo 'Dev server pane - run your server here (e.g., npm run dev)'" C-m

# Pane 3 (bottom-right): system monitor
tmux send-keys -t "$SESSION_NAME:1.3" "$MONITOR_CMD" C-m

# Select Claude Code pane (top-left)
tmux select-pane -t "$SESSION_NAME:1.0"

# Rename window
tmux rename-window -t "$SESSION_NAME:1" "workspace"

# Attach to session
echo -e "${GREEN}Attaching to session...${NC}"
tmux attach-session -t "$SESSION_NAME"
