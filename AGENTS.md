# Dotfiles (managed by `chezmoi`)

This is a personal dotfile repository for macOS, managed by [chezmoi](https://www.chezmoi.io/). It is intended to be read by coding agents (opencode, pi, claude) to understand the machine's shell environment, window-manager setup, terminal emulator config, and status bar.

**Canonical remote:** `git@github.com:padi/dotfiles.git` (branch `main`)

**Local source of truth:** `~/.local/share/chezmoi`

---

## Repository layout

```
.dots/
├── .chezmoi.toml.tmpl        # chezmoi config template (prompts for `data.email`)
├── .chezmoiexternal.toml     # external repos managed by chezmoi
├── .chezmoiignore            # ignore rules (hostname-gated)
├── dot_amethyst.yml          # ~/.amethyst.yml (Amethyst tiling WM config)
├── dot_zshrc.tmpl            # ~/.zshrc (chezmoi template with hostname/os conditionals)
└── dot_config/
    ├── scripts/
    │   └── executable_mise-gh-auth     # exports MISE_GITHUB_TOKEN from gh auth
    ├── sketchybar/
    │   ├── executable_colors.sh         # color scheme vars (vacuous2 / hal)
    │   ├── executable_font.sh           # icon + label font vars
    │   ├── executable_sketchybarrc      # bar + items + plugins wiring
    │   └── plugins/
    │       ├── executable_battery.sh    # pmset battery % + icon
    │       ├── executable_clock.sh      # date label
    │       ├── executable_front_app.sh  # front app label
    │       ├── executable_space.sh      # per-space app icons via native space_windows_change + jq
    │       └── executable_volume.sh     # volume % + icon
    ├── skhd/
    │   └── skhdrc                       # skhd.zig bindings + HID remap (rctrl -> rcmd)
    └── wezterm/
        ├── wezterm.lua                  # terminal config (DepartureMono Nerd Font)
        └── toggle_color_scheme.lua      # leader-triggered dark/light toggle
```

> **Note:** chezmoi strips the `dot_` prefix and `executable_` prefix (and adds the executable bit) when deploying. `dot_zshrc.tmpl` → `~/.zshrc`; `dot_config/sketchybar/executable_sketchybarrc` → `~/.config/sketchybar/sketchybarrc` (executable).

---

## Host-specific behavior

The repo targets two macOS hostnames, gated via chezmoi template conditionals:

| Hostname  | OS        | Notes                                                                                                                                               |
| --------- | --------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `stratus` | macOS     | Adds `~/.spicetify` and `smcFanControl` to PATH                                                                                                     |
| `cirrus`  | macOS     | Adds `~/.spicetify`, `~/scripts`, `~/.config/scripts`, `bat` MANPAGER, Antigravity IDE, Obsidian CLI to PATH; includes sketchybar/skhd/Amethyst config |
| _other_   | non-macOS | `.chezmoiignore` excludes `.config/skhd`, `.amethyst.yml`, `.config/sketchybar`                                                                    |

OS-gated: `darwin`-only alias `nobrew` (brew with `HOMEBREW_NO_AUTO_UPDATE=1`).

---

## Software stack / dependencies

**Shell (`zsh`)**

- zsh >= 5.9, zinit 3.13 (plugin manager)
- powerlevel10k prompt, zsh-syntax-highlighting, zsh-completions, zsh-autosuggestions, fzf-tab, omz-plugin-pnpm
- zoxide, fzf, git, brew (macOS), command-not-found (optional)
- pnpm, mise-en-place (>= 2025.9.10), devbox, bun (optional)
- `~/.zsh.after/` sourced for per-machine customizations

**Terminal emulator**

- WezTerm (`wezterm.lua`): DepartureMono Nerd Font, opacity 1 / blur 20, CMD+W no-confirm, tab move hotkeys, leader = CTRL+W
- `toggle_color_scheme.lua`: toggles between `FunForrest` (default) and `Builtin Solarized Light`, persisted to `~/.color-scheme`

**Window management (macOS, `cirrus` only)**

- Amethyst (`~/.amethyst.yml`: tall/wide/fullscreen/column/bsp layouts, 2px margins, 25pt top padding for sketchybar); shortcuts live in Amethyst's preferences UI, not the YAML
- skhd.zig >= 0.2.3 (installed as brew cask `jackielii/tap/skhd-zig`, not the old formula; `.remap` needs it plus the root `skhd-grabber`, set up via `skhd --start-service`)
- skhd remap: `rctrl` -> `rcmd` via `.remap` rules, guarded per `.device` (vendor/product IDs from `skhd --list-devices`); reason: the external keyboard has a right ctrl but no right cmd key
- Amethyst `floating` list (bundle IDs): System Settings, Calculator, Raycast, mpv, etc.
- Mission Control "Switch to Desktop 1–9" (⌃1…⌃9) must be enabled; sketchybar space clicks send those keystrokes

**Status bar**

- sketchybar (top bar, 24pt, blur 20): spaces 1–9, front_app, clock, volume, battery
- Per-space app icons (Claude, Code, Chrome, Obsidian, Spotify, Steam, etc.)
- Color scheme: "vacuous2" (orange accent, light text on dark bar)

**External chezmoi-managed repo**

- `~/.config/lazyvim` → `git@github.com:padi/lazyvim.git` (refresh every 1h)

**Other PATH additions**

- `~/.local/bin`, `~/claude-or/`, `~/.bun/bin`, `~/Library/pnpm/bin`, `~/.devrelay/bin`, `~/.backboard/bin`, Antigravity IDE
- `~/go/bin` (added if the directory exists)
- Host-gated additions (see **Host-specific behavior** above): `~/.spicetify`, `~/scripts`, `~/.config/scripts`, `~/Library/pnpm/bin`, Antigravity IDE, Obsidian CLI, `smcFanControl` (stratus only), `bat` MANPAGER (cirrus only)

---

## Key aliases / shortcuts

| Alias                         | Meaning                                |
| ----------------------------- | -------------------------------------- |
| `cm`                          | chezmoi                                |
| `nobrew`                      | brew with auto-update disabled         |
| `lgit`                        | lazygit                                |
| `f`                           | `open "$(fzf)"`                        |
| `ffa`                         | fuzzy-find aliases                     |
| `avim`/`astrovim`             | Astronvim                              |
| `kvim`                        | kickstart.nvim                         |
| `lvim`/`lazyvim`              | LazyVim (with `-t <filetype>` support) |
| `chrome`/`chroment`/`chromei` | cirrus-only Google Chrome launchers    |
| `db`                          | cirrus-only defaultbrowser             |

---

## Agent guidance

### Reading configs

- All files are chezmoi source templates; `{{- if eq .chezmoi.hostname "..." }}` blocks are host-gated.
- `executable_*` files are deployed with the executable bit set.
- `.chezmoiexternal.toml` means `~/.config/lazyvim` is a separate git repo, not part of this one.

### Editing conventions

- Shell files use `#!/usr/bin/env bash` or `#!/bin/zsh` shebangs; sketchybar plugins use `#!/bin/sh` or `#!/bin/bash`.
- sketchybar space items rely on sketchybar's native space tracking (`$SELECTED`, `space_windows_change` `$INFO`), not a WM query API.
- sketchybar plugins source `$CONFIG_DIR/colors.sh` and `$CONFIG_DIR/font.sh` for theme vars.
- WezTerm color scheme is toggled via leader `CTRL+W` then `CTRL+C`; state lives in `~/.color-scheme`.
- `skhdrc`, `.amethyst.yml` and sketchybar only apply on `cirrus`; do not add new sketchybar/Amethyst/skhd entries without updating `.chezmoiignore` if they should be host-excluded.

### Branches

- `main` is the deployed branch. `feature/replace-yabai-with-aerospace`, `feature/replace-yabai-with-aerospace-squashed`, `feature/highlight-aerospace-workspace`, and `pi-feature/replace-yabai-with-aerospace` exist as experiments (not merged). `kitty` also exists as an experiment.

### Common tasks

- Apply changes: `chezmoi apply`
- Dry-run: `chezmoi diff`
- Re-add a file: `chezmoi add <path>`
- Edit source: `chezmoi edit <path>` (opens template in `$EDITOR`)
