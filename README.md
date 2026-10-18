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
echo 'env = ["work"]' > ~/.config/mise/miserc.local.toml   # work Macs only
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
mise run check             # lint, validate and secret-scan before committing
git -C ~/Projects/Personal/javinyx/dotfiles pull && mise bootstrap
```

Most files in `~` are symlinks into `home/`, so editing them edits the
repository; commit from the checkout. The exceptions are rendered or copied
rather than linked, and are listed under [Dotfiles](#dotfiles).

## Checks

`mise run check` runs every check, continues past failures, and lists the ones
that failed at the end:

| Step | What it checks |
| --- | --- |
| `fish` | Every tracked `.fish` file parses (`fish --no-execute`). |
| `shellcheck` | Every task script. |
| `parse` | Every tracked TOML, JSON, VS Code profile and YAML file is valid, including the merge sources. |
| `ghostty` | `ghostty +validate-config` against the repository's config and themes. |
| `shaders` | Each shader compiles behind Ghostty's Shadertoy prefix, with errors reported at the shader's own line numbers. |
| `secrets` | `gitleaks` over the git history and the working tree, untracked files included. |

shellcheck, gitleaks and glslang are the task's own `tools`, so mise installs
them the first time the check runs and puts them on PATH only for it; they are
not in `[bootstrap.packages]`. Templates are not rendered, so the check never
calls 1Password. The shader prefix is copied from Ghostty 1.3 into
`tasks/check`; refresh it when a Ghostty release adds uniforms. Nothing runs it
automatically.

## Dotfiles

`home/` mirrors the home directory: `home/.config/fish/config.fish` deploys to
`~/.config/fish/config.fish`. Every file is linked individually, so files an
application creates beside them, such as `fish_variables` or the downloaded
shaders, stay local and untracked.

| Kind | Files | Why |
| --- | --- | --- |
| Template | `~/.config/git/{allowed_signers,personal.inc,work.inc}`, `~/.ssh/{config,*.pub}` | Contents come from 1Password. Rendered from `*.tera`. |
| Copy | `~/.config/vscode/profiles`, `~/.config/1Password/ssh/agent.toml` | VS Code replaces the file on export, which would break a link; 1Password's agent config stays a private regular file. |
| Merge | `~/.config/claude/settings.json`, `~/.config/codex/config.toml`, `~/.config/gh/config.yml` | The applications rewrite these files; see [Codex and Claude Code](#codex-and-claude-code) and [Git](#git). |

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

Rebases fold `fixup!` and `squash!` commits in automatically and move any
branches stacked inside the rebased range along with it. `rerere` records how
each conflict was resolved and replays that resolution the next time the same
conflict appears, so check `git diff` after a rebase that reports "Resolved
using previous resolution". `git branch` lists the most recently committed
branches first, moved lines are coloured separately from added and removed ones,
and the commit message editor shows the staged diff below the message.

Diffs are paged through [delta](https://github.com/dandavison/delta) side by
side, with `n` and `N` jumping between files. `git add -p` uses delta's
colouring only, since its prompts need the original line layout. delta follows
the terminal's light or dark background on its own.

The prompt runs `git status` on every render to decide whether to show the
dirty marker. `core.fsmonitor` and `core.untrackedCache` keep that fast in
large repositories: git starts a small file-watching daemon per repository the
first time it needs one and asks it what changed instead of scanning the whole
tree. The prompt passes `--no-optional-locks` so it never takes the index lock
while another git command is running.

GitHub uses the Development SSH key. The company-hosted Bitbucket instance uses
the Work SSH key, with its private hostname retrieved from 1Password.

The GitHub CLI's `git_protocol` is set to `ssh`, so `gh repo clone` and `gh pr
checkout` go through that same key rather than an HTTPS token. `gh` rewrites
`~/.config/gh/config.yml` whenever a setting or alias changes, so the file is a
merge entry owning only the keys in `home/.config/gh/config.yml`.
`~/.config/gh/hosts.yml` holds the auth token and stays local.

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

The `bu` abbreviation runs `mise bootstrap packages upgrade && mise upgrade`,
which upgrades the declared packages and the runtimes below without running the
rest of the bootstrap. Formulae installed by hand with `brew` are not touched;
upgrade those with `brew upgrade`.

Apps only a work Mac needs, Outlook, Teams and Zoom, are declared in
`config.work.toml`, which mise loads on top of `config.toml` only when the
`work` environment is selected. A machine selects it with an untracked
`~/.config/mise/miserc.local.toml`:

```toml
env = ["work"]
```

Without that file the bootstrap leaves the work apps out. It never uninstalls
them, so removing the file from a Mac that already has them changes nothing.

The `brew` manager only supports Apple Silicon.

mise provides the global Node.js 24, Temurin JDK 25, and latest Python 3
runtimes. Project-level `mise.toml` files can override these defaults.

## Ghostty

The terminal is styled after Pokémon Black and White on the Nintendo DS: a
pixel font, a palette in Unova's black, white and battle-menu colours, and
small animated pixel-art scenes drawn by shaders. The shell itself stays plain.

Departure Mono is drawn on an 11-unit em, so at 16.5pt on a 2x display every
font pixel is exactly 3x3 device pixels and every cell (21x42) is a whole number
of them. The shaders depend on that grid, so the font size, the 18pt padding and
`window-padding-balance = false` move together; balancing would shift the cells
by an amount a shader cannot see.

Themes in `~/.config/ghostty/themes` take precedence over the ones shipped
inside `Ghostty.app`. Ghostty follows the macOS appearance between two:

- **unova-black** (dark) is Pokémon Black: blue-black, with Zekrom's electric
  blue as the cursor.
- **unova-white** (light) is Pokémon White: cool white, with Reshiram's flame
  orange as the cursor.

The ANSI colours come from the touch-screen battle menu - FIGHT red, BAG
yellow, POKéMON green, RUN blue. Every channel is a multiple of 8, as in the
DS's 15-bit 2D output, and every colour except grey reaches 4.5:1 contrast
against its background. Fish uses the named ANSI colours rather than hex
values, so the shell follows whichever theme is active.

Shaders run in the order listed in the config, each receiving the previous
one's output:

- **castelia-skyline.glsl** draws Castelia City in the bottom padding: towers
  whose windows light up and go dark, blinking antenna beacons, the Nimbasa
  Ferris wheel turning, and a train crossing every 40 seconds. It only paints
  pixels that match `iBackgroundColor`, so text is never covered.
- **quick-attack.glsl** leaves dithered afterimages behind the cursor when it
  jumps rather than steps, such as onto a new prompt. Typing never sets it off.
- **shiny-sparkle.glsl** bursts pixel stars around the cursor when a new prompt
  appears. A prompt is recognised by the cursor changing line and landing two
  cells in, after the prompt's `► `; change `PROMPT_COLUMN` if that changes.
- **encounter.glsl** plays the wild-battle transition once when a window, tab or
  split opens: two flashes, then bars that slide away to reveal the terminal.
  Set `FLASHES` to 0 to keep the bars without the flash.
- **ds-lcd.glsl** darkens the gap between font pixels, like the DS Lite's
  screen. It runs last so everything above gets the grid too. On a 1x display
  the grid cannot align; set `GRID` to 0 there.

Every effect is a named constant at the top of its shader. The scenes animate
only while a window is focused, which is Ghostty's default for
`custom-shader-animation`.

The prompt ends in the game's `►` menu arrow, and the right prompt reports
results as battle messages ("But it failed!", "Got away safely!"). There is no
greeting. The Dock icon is Ghostty's custom style with a Pokémon Black screen.

Ghostty ignores a shader that fails to compile and reports it only in the log,
never as a config error, so `ghostty +validate-config` passing says nothing about
whether the shaders work. `mise run check` compiles each one behind the
Shadertoy prefix Ghostty prepends; see [Checks](#checks). At runtime, failures
appear only here:

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
effort level, per-project trust levels, plugin state — so these files are
`merge = true` entries: the bootstrap sets only the keys in
`home/.config/claude/settings.json` and `home/.config/codex/config.toml`,
and everything else in the live file stays the application's. Replacing the
files outright would discard that state on every bootstrap. TOML is edited in
place and JSON keeps its key order, so the tools' own formatting survives and
`mise dot status` only reports drift in the managed keys. Removing a key from a
source does not remove it from the live file.

For Claude Code the managed keys are the auto permission mode, the `rtk hook
claude` PreToolUse hook, the codex-image plugin with its marketplace, the
agents-md plugin's instruction-file option, and UI preferences. The model and
per-model effort level are left to `/model`, so the bootstrap never reverts a
change made there.

Each tool's global instructions file, `~/.config/claude/CLAUDE.md` and
`~/.config/codex/AGENTS.md`, only imports an `RTK.md` beside it that explains
RTK's condensed command output. All four files are linked from `home/`, so
rerunning `rtk init -g` after an rtk upgrade edits the repository copy of
Claude's `RTK.md`; review that diff before committing it.

Credentials, sessions, plugin caches, memories, logs, and caches remain local
and are intentionally excluded from the repository.

## Agent instructions

`~/AGENTS.md` holds the rules any coding agent should follow, with
`~/CLAUDE.md` as a symlink to it so Claude Code and Codex read the same file
rather than two copies that drift apart. Both sit at the top of the home
directory deliberately: agents search upwards from the working directory, so a
single file at `$HOME` covers every project beneath it.

It currently covers sole authorship on commits, when a comment is justified, and
which decisions need asking about first.
