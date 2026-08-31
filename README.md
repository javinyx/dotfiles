# dotfiles

Personal macOS dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Install

```sh
chezmoi init --apply javinyx
```

During initialization, chezmoi asks which one-time macOS setup actions to run.
Destructive cleanup actions default to disabled. `.chezmoiversion` pins the
chezmoi release this repository was verified against; an older binary refuses to
run rather than failing somewhere inside a template.

Private values are retrieved from 1Password and are never committed to this
public repository, so `op` must be signed in before applying.

## Daily use

```sh
chezmoi diff
chezmoi apply
chezmoi update
```

## Shell

Fish snippets in `~/.config/fish/conf.d` are sourced before `config.fish`, in
name order:

- `00-homebrew.fish` runs `brew shellenv`, which is what puts Homebrew on PATH.
  Nothing else does. It also moves `/opt/homebrew/bin` ahead of `/usr/bin`, so a
  formula can shadow the macOS copy of a tool, and sets `HOMEBREW_PREFIX`,
  `MANPATH`, and `INFOPATH`. An `/etc/paths.d` entry is not a substitute: it
  appends rather than prepends, and is not version controlled.
- `10-mise.fish` activates mise. Without it the runtimes below are installed but
  never reach PATH.

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
| `~/.local/share/chezmoi/` | Personal |

Repositories outside all three have no identity, and commits there fail because
signing is on by default. That is deliberate. The chezmoi source directory is
listed because it is a repository like any other and would otherwise need a
hand-written local identity that no other machine would have.

Commits and tags are signed with an SSH key through 1Password's `op-ssh-sign`.
`allowed_signers` is generated from the same 1Password entries as the
identities, so `git log --show-signature` verifies locally instead of reporting
"No signature" on correctly signed commits.

`~/.config/git/ignore` keeps macOS metadata out of every repository. git reads
that path automatically; no configuration points at it.

GitHub uses the Development SSH key. The company-hosted Bitbucket instance uses
the Work SSH key, with its private hostname retrieved from 1Password.

`known_hosts` is seeded once with GitHub's pinned key and then left alone, since
ssh appends to it as you connect to new hosts.

## macOS settings

Three scripts, deliberately separate because `run_once_` is keyed on script
contents and so re-runs whenever the script is edited:

| Script | Contents |
| --- | --- |
| `10-macos-settings` | Idempotent preference writes. Safe to re-run. |
| `11-macos-dock-reset` | Empties the Dock. Isolated so editing an unrelated default does not discard what is pinned there. |
| `12-macos-privileged-settings` | Sleep timings and the lock screen message. Asks for your password first. |

Script 12 needs a terminal that can prompt for a password. Running `chezmoi
apply` somewhere without one — a non-interactive shell, or through a tool that
does not allocate a tty — fails with `sudo: a terminal is required`.

Finder desktop, window, path/status bar, extension, hidden-file, and Trash
preferences are configured automatically. Hidden files are shown by default and
can be toggled in Finder with **Cmd-Shift-.**. Screenshots are stored in `~/Pictures/Screenshots`;
network and removable drives do not receive `.DS_Store` files. Keyboard repeat
and tap-to-click are also configured. On a new Mac, `Cmd-Shift-3/4` copies
screenshots to the clipboard and adding `Control` saves them to the screenshots
folder; `Cmd-Shift-5` retains the standard Screenshot toolbar.

The menu bar carries the VPN status extra, which shows the time connected once a
tunnel is up.

Set the Finder sidebar once in **Finder → Settings → Sidebar**: enable only
Applications, Desktop, Documents, Downloads, iCloud Drive, the user home folder,
External disks, AirDrop, and Trash. macOS stores this list in a machine-specific
private archive that is not suitable for version control.

## Packages

Homebrew packages are declared in `~/.config/homebrew/Brewfile`. Chezmoi
installs Homebrew when necessary and runs `brew bundle` whenever that file
changes.

Mise provides the global Node.js 24, Temurin JDK 25, and latest Python 3
runtimes. Project-level `mise.toml` files can override these defaults.

## Ghostty

Monocraft Nerd Font at 15pt, with a bespoke look rather than a stock one.

Themes in `~/.config/ghostty/themes` take precedence over the 463 shipped inside
`Ghostty.app`, so the palette is version-controlled here:

- **arcade-cabinet** is the default. Saturated, well-separated hues on a
  near-black background with a faint violet cast, chosen because a pixel font
  has no anti-aliasing to soften colour edges. All 16 palette slots are
  distinct, so syntax highlighting and diffs still carry information - unlike
  the built-in "Retro", where every slot is the same green.
- **game-boy** is the authentic four-shade DMG-01 palette. A novelty: with four
  greens there is no colour information left to highlight with.

Shaders run in the order listed in the config, each receiving the previous
one's output, so order matters:

- **starfield.glsl** drifts parallax stars behind the text. A shader only ever
  receives the finished image, so there is no "behind" to draw into: it compares
  each pixel against `iBackgroundColor` and adds stars only where the terminal
  is showing background, leaving text and selections untouched. It must run
  before any CRT pass, which would alter those background pixels.
- **cursor_blaze.glsl** is the upstream cursor trail, placed before the CRT pass
  so the trail gets scanlined along with everything else.
- **arcade-crt.glsl** does scanlines, an aperture-grille phosphor mask, a
  vignette and slight chromatic aberration. Flat by default - barrel distortion
  is what makes most CRT shaders tiring to work in, since it bends text near the
  edges - but `CURVATURE` at the top turns it on.
- **coin-flash.glsl** expands a gold ring on every cursor move, driven by
  `iTimeCursorChange`. It runs alongside `cursor_blaze`; either can be dropped
  if four passes is too busy.
- **dot-matrix.glsl** is a heavier upstream CRT with glow and a dot mask.
- **gameboy.glsl** quantises the screen to the four DMG greens with a 2x2
  ordered dither. Pairs with the game-boy theme.

Every effect is a named constant at the top of its shader; they are meant to be
edited. Upstream shaders are pinned to a commit and checksummed, so they are
downloaded once rather than on every apply and a changed download fails loudly.

Ghostty ignores a shader that fails to compile and reports it only in the log,
never as a config error, so `ghostty +validate-config` passing says nothing about
whether the shaders work. To check one before committing it, wrap it in the
Shadertoy preamble Ghostty injects and compile that. This needs `glslang`, which
is deliberately not in the Brewfile - install it for the occasion with `brew
install glslang` and remove it afterwards:

```sh
{ printf '#version 450\n'
  printf 'uniform vec3 iResolution; uniform float iTime, iTimeCursorChange;\n'
  printf 'uniform vec4 iCurrentCursor, iPreviousCursor;\n'
  printf 'uniform vec3 iBackgroundColor, iForegroundColor, iCursorColor;\n'
  printf 'uniform sampler2D iChannel0;\n'
  printf 'out vec4 fc;\n'
  cat shaders/arcade-crt.glsl
  printf 'void main(){ mainImage(fc, gl_FragCoord.xy); }\n'
} > /tmp/t.frag && glslangValidator -S frag /tmp/t.frag
```

Validate a known-good upstream shader the same way first: if that fails too, the
preamble is wrong rather than the shader. At runtime, failures appear only here:

```sh
log show --last 5m --predicate 'process == "ghostty"' --style compact | grep -i shader
```

Remove or comment the `custom-shader` lines if they cause rendering problems.

## VS Code profiles

Version-controlled VS Code profile exports live in `~/.config/vscode/profiles`.
Import them from **Profiles: New Profile...** → **Import Profile...** in the
Command Palette. The Default export captures the shared base UI preferences.
Personal adds the Oxc extension and the Light 2026 theme; Work adds Flow Icons
with its Flow Dim icon theme and the Dark 2026 color theme. Flow Icons license
information is private and must not be added to the profile export.

After changing a profile in VS Code, export it to the same local file and run
`chezmoi re-add ~/.config/vscode/profiles/<name>.code-profile` to update the
source copy. Settings Sync is not required for these profiles.

## Codex and Claude Code

Codex uses `~/.config/codex` as `CODEX_HOME` and Claude Code uses
`~/.config/claude` as `CLAUDE_CONFIG_DIR`, both set by Fish. Claude Code is
installed from Homebrew's `claude-code@latest` cask.

Both tools rewrite their own configuration at runtime — the selected model and
effort level, the approval mode, per-project trust levels — so these files are
managed by `modify_` scripts that merge the version-controlled keys into
whatever is already on disk. Replacing the files outright would discard that
state on every apply. The merge round-trips through chezmoi's JSON and TOML
encoders, so expect the formatting to be normalised and a cosmetic diff to
reappear whenever either tool writes its own.

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
