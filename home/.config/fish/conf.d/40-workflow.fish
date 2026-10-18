set -gx ATUIN_CONFIG_DIR "$HOME/.config/atuin"

if not status is-interactive
    return
end

if command -q fzf
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --exclude .git'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --exclude .git'
    fzf --fish | FZF_CTRL_R_COMMAND= source
end

if command -q zoxide
    zoxide init fish | source
end

if command -q wt
    wt config shell init fish | source
end

if command -q atuin
    atuin init fish --disable-up-arrow --disable-ai | source
end
