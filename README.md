# dotfiles

Personal macOS dotfiles, applied with [`mise bootstrap`](https://mise.jdx.dev/bootstrap.html).

This repository is the global mise configuration. It is checked out at
`~/Projects/Personal/javinyx/dotfiles`, and `~/.config/mise` is a symlink to it, so
`config.toml` at its root is the file every mise command reads. The config
refers to itself only through `~/.config/mise`, so moving the checkout means
repointing that one link. That one file declares the packages, dotfiles, macOS preferences, login
shell, and runtimes; `home/` holds the files deployed into `~`; `tasks/` holds
the setup steps nothing declarative covers.

## Install

```sh
curl -fsSL https://mise.run | sh
git clone https://github.com/javinyx/dotfiles.git ~/Projects/Personal/javinyx/dotfiles
mkdir -p ~/.config && ln -s ~/Projects/Personal/javinyx/dotfiles ~/.config/mise
~/.local/bin/mise bootstrap
```

On a new Mac the first `git` call offers to install the Xcode Command Line
Tools. `mise bootstrap --adopt` is not used because it always clones into
`~/.config/mise` itself. Afterwards, point the checkout at
`git@github.com:javinyx/dotfiles.git` to push over SSH. `min_version` in `config.toml` pins the mise release this repository was
verified against; an older binary refuses to run rather than failing somewhere
inside the bootstrap.

Private values are retrieved from 1Password and are never committed to this
public repository. Templates call `op read` when they render, which includes
`mise dot status` and `mise dot diff`, so 1Password must be installed, unlocked,
and have CLI integration turned on first. On a new Mac, run the bootstrap once
with `--skip dotfiles`, sign in to the 1Password app it installed, and run it
again.

The bootstrap sets the power and lock screen settings with `sudo` when they
differ, and writes `/etc/pam.d/sudo_local` as root, so run it from a terminal
that can prompt for a password. Elsewhere it fails with `sudo: a terminal is
required`. That file enables Touch ID for `sudo`; it is used instead of editing
`/etc/pam.d/sudo` because macOS updates leave it alone.

## Daily use

```sh
mise bootstrap --dry-run   # preview every part
mise bootstrap             # apply every part
mise dot status            # dotfile drift only
git -C ~/Projects/Personal/javinyx/dotfiles pull && mise bootstrap
```

Most files in `~` are symlinks into `home/`, so editing them edits the
repository; commit from the checkout. The exceptions are rendered or copied
rather than linked, and are listed under [Dotfiles](#dotfiles).

## Dotfiles

`home/` mirrors the home directory: `home/.config/fish/config.fish` deploys to
`~/.config/fish/config.fish`. Every file is linked individually, so files an
application creates beside them, such as `fish_variables` or the downloaded
shaders, stay local and untracked.

| Kind | Files | Why |
| --- | --- | --- |
| Template | `~/.config/git/{allowed_signers,personal.inc,work.inc}`, `~/.ssh/{config,*.pub}` | Contents come from 1Password. Rendered from `*.tera`. |
| Copy | `~/.config/vscode/profiles`, `~/.config/1Password/ssh/agent.toml` | VS Code replaces the file on export, which would break a link; 1Password's agent config stays a private regular file. |
| Merge | `~/.config/claude/settings.json`, `~/.config/codex/config.toml` | The applications rewrite these files; see [Codex and Claude Code](#codex-and-claude-code). |

Files that should no longer exist anywhere are declared `mode = "absent"`, and
are removed on the next bootstrap.

## Shell

Fish snippets in `~/.config/fish/conf.d` are sourced before `config.fish`, in
name order:

- `00-homebrew.fish` runs `brew shellenv`, which is what puts Homebrew on PATH.
  Nothing else does. It also moves `/opt/homebrew/bin` ahead of `/usr/bin`, so a
  formula can shadow the macOS copy of a tool, and sets `HOMEBREW_PREFIX`,
  `MANPATH`, and `INFOPATH`. An `/etc/paths.d` entry is not a substitute: it
  appends rather than prepends, and is not version controlled.
- `10-mise.fish` puts `~/.local/bin`, where the mise installer puts mise, on
  PATH and activates mise. Interactive shells get full activation; scripts and
  editor-spawned shells get shims. Without it the runtimes below are installed
  but never reach PATH. `[bootstrap.mise_shell_activate]` is not used because it
  writes into `config.fish`, which is a link into this repository.

The login shell is set to Homebrew's fish by `[bootstrap.user]`, which also adds
it to `/etc/shells`.

`$EDITOR` and `$VISUAL` are `code --wait`. Without `--wait`, `code` returns
before the file is edited and anything that reads the result back sees an empty
buffer.

## Git

The configuration lives at `~/.config/git/config`, alongside everything else
under `~/.config`. Identity is selected by directory:

| Repository location | Identity |
| --- | --- |
| `~/Projects/Work/` | Work |
| `~/Projects/Personal/` | Personal |

Repositories outside both have no identity, and commits there fail because
signing is on by default. That is deliberate. This repository is checked out
under `~/Projects/Personal/` so that it needs no rule of its own; git matches
the checkout's real path, so the identity also applies when working through
`~/.config/mise`.

Commits and tags are signed with an SSH key through 1Password's `op-ssh-sign`.
`allowed_signers` is generated from the same 1Password entries as the
identities, so `git log --show-signature` verifies locally instead of reporting
"No signature" on correctly signed commits.

`~/.config/git/ignore` keeps macOS metadata out of every repository. git reads
that path automatically; no configuration points at it.

GitHub uses the Development SSH key. The company-hosted Bitbucket instance uses
the Work SSH key, with its private hostname retrieved from 1Password.

`known_hosts` always contains GitHub's pinned key: the bootstrap adds that one
line when it is missing and leaves every other line alone, since ssh appends to
the file as you connect to new hosts.

## macOS settings

Preferences are declared in `config.toml` under `[bootstrap.macos.*]`, and the
bootstrap writes only the ones that differ. It does not restart Dock, Finder, or
SystemUIServer afterwards; when it changed something it ends with a reminder to
relaunch them. Three preferences embed the home directory, which declared
defaults cannot, so the `post-defaults` hook writes them.

What declarations cannot express runs as the `bootstrap` task, on every
bootstrap. Each step checks before it changes anything:

| Task | Contents |
| --- | --- |
| `bootstrap:power-and-login-window` | Sleep timings and the lock screen message. Asks for your password only when one differs. |
| `bootstrap:finder-sidebar` | Adds Pictures to the Finder sidebar favourites. Additive, so entries added by hand survive. |
| `bootstrap:default-apps` | Dia for web links and HTML, Obsidian for Markdown, VS Code for code and config files. Sets only what differs. |
| `bootstrap:spotify-autostart` | Stops Spotify from opening at login, when it is installed. |

One-off actions that discard state are never run by the bootstrap. Run them by
hand on a new Mac, if wanted; each asks for confirmation:

| Task | Contents |
| --- | --- |
| `mise run macos:dock-reset` | Removes every pinned app and folder from the Dock. |
| `mise run macos:clear-text-replacements` | Deletes every text replacement, including the iCloud copies. |
| `mise run macos:remove-stock-apps` | Deletes Keynote, Numbers, Pages, iMovie, and GarageBand. |

The tasks are global, because this is the global config, so they are hidden from
`mise tasks` in every project; `mise tasks --hidden` lists them.

Finder desktop, window, path/status bar, extension, hidden-file, and Trash
preferences are configured automatically. Hidden files are shown by default and
can be toggled in Finder with **Cmd-Shift-.**. Screenshots are stored in `~/Pictures/Screenshots`;
network and removable drives do not receive `.DS_Store` files. Keyboard repeat
and tap-to-click are also configured. On a new Mac, `Cmd-Shift-3/4` copies
screenshots to the clipboard and adding `Control` saves them to the screenshots
folder; `Cmd-Shift-5` retains the standard Screenshot toolbar.

The menu bar carries the VPN status extra, which shows the time connected once a
tunnel is up.

`bootstrap:finder-sidebar` adds Pictures to the sidebar favourites. macOS keeps that list in a
machine-specific private archive with no preferences domain, so it is written
through `LSSharedFileList` rather than checked in. The API has been deprecated
since 10.11 and remains the only public one; `mysides`, the usual wrapper, was
disabled in Homebrew in October 2025.

Set the remaining entries once in **Finder → Settings → Sidebar**: enable
Applications, Desktop, Documents, Downloads, iCloud Drive, the user home folder,
External disks, AirDrop, and Trash.

## Packages

Formulae and casks are declared in `[bootstrap.packages]` as `brew:` and
`brew-cask:` entries. mise installs them itself, from Homebrew's API, into
`/opt/homebrew`, and `mise bootstrap status` reports any that are missing.
Homebrew is still installed, by the `pre-packages` hook, so `brew` remains
available for one-off installs and sees everything mise installed. mise is not
in the list: it has to exist before the bootstrap can run, and `mise
self-update` updates the copy the installer put in `~/.local/bin`.

The `brew` manager only supports Apple Silicon.

mise provides the global Node.js 24, Temurin JDK 25, and latest Python 3
runtimes. Project-level `mise.toml` files can override these defaults.

## Ghostty

The terminal is styled after Pokémon Emerald on the Game Boy Advance: a pixel
font, a palette the GBA could actually display, and a few small effects from
the game.

Departure Mono is drawn on an 11-unit em, so at 16.5pt on a 2x display every
font pixel is exactly 3x3 device pixels and every cell (21x42) is a whole number
of them. The shaders depend on that grid, so the font size, the 18pt padding and
`window-padding-balance = false` move together; balancing would shift the cells
by an amount a shader cannot see.

Themes in `~/.config/ghostty/themes` take precedence over the ones shipped
inside `Ghostty.app`. Ghostty follows the macOS appearance between two:

- **emerald-battle** (dark) is the slate of the battle message box.
- **emerald-dialog** (light) is the sand of a route path, so the white dialog
  panel stands out.

The ANSI colours are Pokémon type colours - Fire red, Grass green, Electric
yellow, Water blue, Psychic pink, Ice cyan - with the HP-bar mint as bright
green. Every channel is a multiple of 8, as on the GBA's 15-bit screen, and
every colour except grey reaches 4.5:1 contrast against its background. Fish
uses the named ANSI colours rather than hex values, so the shell follows
whichever theme is active.

Shaders run in the order listed in the config, each receiving the previous
one's output:

- **tall-grass.glsl** draws swaying Hoenn tall grass in the bottom padding. It
  only paints pixels that match `iBackgroundColor`, so text is never covered.
- **shiny-sparkle.glsl** bursts pixel stars around the cursor when a new prompt
  appears. A prompt is recognised by the cursor changing line and landing two
  cells in, after the prompt's `► `; change `PROMPT_COLUMN` if that changes.
- **gba-lcd.glsl** darkens the gap between font pixels, like the unlit GBA
  screen. It runs last so the grass and stars get the grid too. On a 1x display
  the grid cannot align; set `GRID` to 0 there.

Every effect is a named constant at the top of its shader.

The shell completes the look: `fish_greeting` opens each session with a dialog
panel, the prompt ends in the game's `►` menu arrow, and the right prompt
reports results as battle messages ("But it failed!", "Got away safely!"). The
Dock icon is Ghostty's custom style with an Emerald-green screen.

Ghostty ignores a shader that fails to compile and reports it only in the log,
never as a config error, so `ghostty +validate-config` passing says nothing about
whether the shaders work. To check one before committing it, wrap it in the
Shadertoy preamble Ghostty injects and compile that. This needs `glslang`, which
is deliberately not in the package list - install it for the occasion with `brew
install glslang` and remove it and its `spirv-*` dependencies afterwards:

```sh
{ printf '#version 450\n'
  printf 'uniform vec3 iResolution; uniform float iTime, iTimeCursorChange;\n'
  printf 'uniform vec4 iCurrentCursor, iPreviousCursor;\n'
  printf 'uniform vec3 iBackgroundColor, iForegroundColor, iCursorColor;\n'
  printf 'uniform sampler2D iChannel0;\n'
  printf 'out vec4 fc;\n'
  cat shaders/gba-lcd.glsl
  printf 'void main(){ mainImage(fc, gl_FragCoord.xy); }\n'
} > /tmp/t.frag && glslangValidator -S frag /tmp/t.frag
```

At runtime, failures appear only here:

```sh
log show --last 5m --predicate 'process == "ghostty"' --style compact | grep -i shader
```

## VS Code profiles

Version-controlled VS Code profile exports live in `~/.config/vscode/profiles`.
Import them from **Profiles: New Profile...** → **Import Profile...** in the
Command Palette. The Default export captures the shared base UI preferences.
Personal adds the Oxc extension and the Light 2026 theme; Work adds Flow Icons
with its Flow Dim icon theme and the Dark 2026 color theme. Flow Icons license
information is private and must not be added to the profile export.

After changing a profile in VS Code, export it to the same local file and run
`mise dot add ~/.config/vscode/profiles/<name>.code-profile` to update the
source copy. Settings Sync is not required for these profiles.

## Codex and Claude Code

Codex uses `~/.config/codex` as `CODEX_HOME` and Claude Code uses
`~/.config/claude` as `CLAUDE_CONFIG_DIR`, both set by Fish. Apps started from
the Dock or at login, such as CodexBar, never start a shell, so the
`agent-config-env` LaunchAgent also sets both with `launchctl setenv` at login;
without it they fall back to `~/.codex` and `~/.claude`. Claude Code is
installed from Homebrew's `claude-code@latest` cask.

Both tools rewrite their own configuration at runtime — the selected model and
effort level, the approval mode, per-project trust levels — so these files are
`merge = true` entries: the bootstrap sets only the keys in
`home/.config/claude/settings.json` and `home/.config/codex/config.toml`,
and everything else in the live file stays the application's. Replacing the
files outright would discard that state on every bootstrap. TOML is edited in
place and JSON keeps its key order, so the tools' own formatting survives and
`mise dot status` only reports drift in the managed keys. Removing a key from a
source does not remove it from the live file.

Credentials, sessions, plugins, memories, logs, and caches remain local and are
intentionally excluded from the repository.

## Agent instructions

`~/AGENTS.md` holds the rules any coding agent should follow, with
`~/CLAUDE.md` as a symlink to it so Claude Code and Codex read the same file
rather than two copies that drift apart. Both sit at the top of the home
directory deliberately: agents search upwards from the working directory, so a
single file at `$HOME` covers every project beneath it.

It currently covers sole authorship on commits, when a comment is justified, and
which decisions need asking about first.
