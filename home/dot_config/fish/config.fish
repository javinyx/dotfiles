# Homebrew
fish_add_path /opt/homebrew/bin
set -gx HOMEBREW_NO_EMOJI 1
set -gx HOMEBREW_BUNDLE_FILE "~/.local/share/chezmoi/install/macos/Brewfile"

# Empty greeting
set -g fish_greeting