_is_full_terminal_mock() {
    local TERM="xterm-256color"
    local TERM_PROGRAM="vscode"

    # Logic from terminal.sh
    [[ "$TERM" =~ (kitty|wezterm|alacritty|ghostty|vscode|xterm-256color) ]] &&
        [[ "$TERM_PROGRAM" =~ (iTerm\.app|WezTerm|Alacritty|ghostty|kitty|vscode|Apple_Terminal) ]] && return 0

    [[ "$TERM_PROGRAM" == "vscode" ]] && return 0
    return 1
}

if _is_full_terminal_mock; then echo "OK"; else echo "FAIL"; fi
