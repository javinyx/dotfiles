# dotfiles

Personal macOS dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Install

```sh
chezmoi init --apply javinyx
```

During initialization, chezmoi asks which one-time macOS setup actions to run.
Destructive cleanup actions default to disabled.

Finder desktop, window, path/status bar, extension, and Trash preferences are
configured automatically. Hidden files stay hidden by default and can be
toggled in Finder with **Cmd-Shift-.**. Screenshots are stored in
`~/Pictures/Screenshots`; network and removable drives do not receive
`.DS_Store` files. Keyboard repeat and tap-to-click are also configured. On a
new Mac, `Cmd-Shift-3/4` copies screenshots to the clipboard and adding
`Control` saves them to the screenshots folder; `Cmd-Shift-5` retains the
standard Screenshot toolbar. Set the Finder sidebar once in **Finder → Settings
→ Sidebar**: enable only Applications, Desktop, Documents, Downloads, iCloud
Drive, the user home folder, External disks, AirDrop, and Trash. macOS stores
this list in a machine-specific private archive that is not suitable for
version control.

Homebrew packages are declared in `~/.config/homebrew/Brewfile`. Chezmoi
installs Homebrew when necessary and runs `brew bundle` whenever that file
changes.

## Daily use

```sh
chezmoi diff
chezmoi apply
chezmoi update
```

Private values are retrieved from 1Password and are never committed to this
public repository.

GitHub uses the Development SSH key. The company-hosted Bitbucket instance uses
the Work SSH key, with its private hostname retrieved from 1Password.

Ghostty uses Monocraft Nerd Font, the built-in Banana Blueberry theme, and a
pinned cursor shader. Remove or comment the `custom-shader` line if the shader
causes rendering problems.

Mise provides the global Node.js 24, Temurin JDK 25, and latest Python 3
runtimes. Project-level `mise.toml` files can override these defaults.

## VS Code profiles

Version-controlled VS Code profile exports live in
`~/.config/vscode/profiles`. Import them from **Profiles: New Profile...** →
**Import Profile...** in the Command Palette. The Default export captures the
shared base UI preferences. Personal adds the Oxc extension and the Light 2026
theme; Work adds Flow Icons with its Flow Dim icon theme and the Dark 2026
color theme. Flow Icons license information is private and must not be added to
the profile export.

After changing a profile in VS Code, export it to the same local file and run
`chezmoi re-add ~/.config/vscode/profiles/<name>.code-profile` to update the
source copy. Settings Sync is not required for these profiles.

## Codex

Codex uses `~/.config/codex` as `CODEX_HOME`, configured by Fish. Portable
preferences such as the TUI status line are version-controlled there, while
authentication, sessions, memories, logs, caches, and other generated state
remain local and are intentionally excluded from the repository.

Claude Code is installed from Homebrew's `claude-code@latest` cask and uses
`~/.config/claude` as `CLAUDE_CONFIG_DIR`. Only portable settings are managed;
credentials, sessions, plugins, and generated state remain local.
