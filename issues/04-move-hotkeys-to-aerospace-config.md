# Priority: Move aerospace hotkeys into aerospace config

## Goal

Per the latest AeroSpace docs (https://nikitabobko.github.io/AeroSpace/guide#configuring-aerospace), key bindings can and should be defined in the `aerospace.toml` config file itself using the `mode.*.binding` syntax, rather than in `skhdrc`. This reduces duplication and makes the hotkeys AeroSpace-native.

## What needs to happen

### 1. Update `dot_config/aerospace/aerospace.toml`

Move these key bindings from `dot_config/skhd/skhdrc` into the aerospace config, using the new binding mode syntax per the website guide:

```toml
# Key bindings for normal mode (default)
[mode.normal]
binding = {
    # Focus within current workspace
    "focus_down"    = "alt + j"
    "focus_up"      = "alt + k"
    "focus_left"    = "alt + h"
    "focus_right"   = "alt + l"

    # Layout
    "layout_bsp"    = "alt + b"

    # Swap windows
    "swap_down"     = "shift + alt + j"
    "swap_up"       = "shift + alt + k"
    "swap_left"     = "shift + alt + h"
    "swap_right"    = "shift + alt + l"

    # Workspace switching
    "workspace_1"   = "ctrl + 1"
    "workspace_2"   = "ctrl + 2"
    "workspace_3"   = "ctrl + 3"
    "workspace_4"   = "ctrl + 4"
    "workspace_5"   = "ctrl + 5"
    "workspace_6"   = "ctrl + 6"
    "workspace_7"   = "ctrl + 7"
    "workspace_8"   = "ctrl + 8"
    "workspace_9"   = "ctrl + 9"

    # These would normally be here, but the reload+sketchybar shortcut is
    # unique to our setup, so we keep it in skhdrc (see step 3)
    # "recent_window" = "cmd + tab"
}
```

### 2. Prune `dot_config/skhd/skhdrc`

Remove all the aerospace-related bindings from `skhdrc` that have been moved to the config above. Keep only:

- **Reload + sketchybar**: `ctrl + alt - r : skhd --restart-service && sketchybar --reload`
  (unique to our setup, cannot be expressed in aerospace config alone)

### 3. Benefits

- AeroSpace natively handles its own key bindings, reducing dependency on skhd for window management
- Config is self-contained in one file
- Fewer moving parts: `skhd --restart-service` becomes unnecessary after reloading (though can remain for sketchybar reload)

## Acceptance Criteria

- `dot_config/aerospace/aerospace.toml` contains all focus/swap/layout/workspace bindings in TOML mode syntax
- `dot_config/skhd/skhdrc` retains only the reload+sketchybar and command-tab bindings
- After `skhd --restart-service` (or just `sketchybar --reload`), aerospace hotkeys work without skhd managing them
- Testing: `aerospace focus down` works both from hotkey and CLI

## Notes

- The AeroSpace website mentions that non-trivial config keys should be explicitly set in your custom config; binding definitions fall into this category
- Bootstrap your config: `cp /Applications/AeroSpace.app/Contents/Resources/default-config.toml ~/.config/aerospace/aerospace.toml`
- The `mode.normal` binding format may vary — verify the exact TOML shape from the latest guide before committing the final file format
