# Task 2: Set up the loaded aerospace config

> **⚠️ Outdated:** This issue was originally written to create
> `default-config.toml`. That file is NOT loaded by AeroSpace — it is the
> bundled default that ships inside the app bundle
> (`/Applications/AeroSpace.app/Contents/Resources/default-config.toml`).
> AeroSpace only loads one of these custom config locations:
> 1. `~/.aerospace.toml`
> 2. `${XDG_CONFIG_HOME}/aerospace/aerospace.toml` (falls back to
>    `~/.config/aerospace/aerospace.toml`)

## Goal
Ensure `~/.config/aerospace/aerospace.toml` (chezmoi source:
`dot_config/aerospace/aerospace.toml`) has window gap, mouse, layout, and
window rules. This replaces the removed yabai config.

## Steps
1. Confirm the deployed config is `~/.config/aerospace/aerospace.toml` (not
   `default-config.toml`). The source for chezmoi is
   `dot_config/aerospace/aerospace.toml`.
2. Verify the live config has:
   - `layout = "bsp"`
   - Mouse settings (`modifier = "alt"`, `action1 = "move"`, `action2 = "resize"`)
   - Gaps (`gaps.outer.top`, optionally `gaps.outer.bottom`)
   - Window rules (`manage = false` for System Settings, Calculator,
     Raycast, mpv, etc.)
3. Apply: `chezmoi apply` (so source and deployed config stay in sync).

## Acceptance Criteria
- `dot_config/aerospace/aerospace.toml` is the chezmoi source for
  `~/.config/aerospace/aerospace.toml` and contains layout, mouse, gaps,
  and rule settings.
- `default-config.toml` is removed (or ignored) from the workspace since
  Aerospace does not load it.
- Aerospace config loads without errors on startup.

## Notes
- This config replaces the removed `dot_config/yabai/executable_yabairc`.
- Bootstrap a custom config by copying the default:
  `cp /Applications/AeroSpace.app/Contents/Resources/default-config.toml ~/.aerospace.toml`
- The live config already exists at `~/.config/aerospace/aerospace.toml` with
  the settings above. Ensure the chezmoi source mirrors it.