set -g fish_greeting

# Anything that shells out to $EDITOR - gh, mise, brew edit - returns instantly
# with an empty buffer unless code is told to wait. Git needs no variable here:
# core.editor is set in the managed git config.
set -gx EDITOR "code --wait"
set -gx VISUAL "code --wait"
set -gx CODEX_HOME "$HOME/.config/codex"
set -gx CLAUDE_CONFIG_DIR "$HOME/.config/claude"
