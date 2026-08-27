# dotfiles

Personal macOS dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Install

```sh
chezmoi init --apply javinyx
```

During initialization, chezmoi asks which one-time macOS setup actions to run.
Destructive cleanup actions default to disabled.

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
