# Task 3: Update skhd hotkey bindings for aerospace

## Goal
Replace yabai skhd bindings with aerospace CLI equivalents in `dot_config/skhd/skhdrc`.

## Steps
1. Edit `dot_config/skhd/skhdrc` to add aerospace keybindings:

### Focus within workspace (WASD / HJKL)
```sh
alt - j : aerospace focus down
alt - k : aerospace focus up
alt - h : aerospace focus left
alt - l : aerospace focus right
```

### Layout Changes
```sh
alt - b : aerospace layout bsp          # Binary Space Partitioning (default)
```

### Swap Windows
```sh
shift + alt - j : aerospace swap down
shift + alt - k : aerospace swap up
shift + alt - h : aerospace swap left
shift + alt - l : aerospace swap right
```

### Move window between workspaces (Ctrl+Number)
```sh
ctrl - 1 : aerospace workspace 1
ctrl - 2 : aerospace workspace 2
ctrl - 3 : aerospace workspace 3
ctrl - 4 : aerospace workspace 4
ctrl - 5 : aerospace workspace 5
ctrl - 6 : aerospace workspace 6
ctrl - 7 : aerospace workspace 7
ctrl - 8 : aerospace workspace 8
ctrl - 9 : aerospace workspace 9
```

### Reload services
```sh
ctrl + alt - r : skhd --restart-service \
&& sketchybar --reload
```

### Command-Tab → Recent window (requires jq)
```sh
cmd - tab : recent_space=`aerospace list-windows --all --format json | jq -r '.[] | select(.focused) | .workspace'` && \
  recent_window=`aerospace list-windows --all --format json | jq -r '.[] | select(.focused) | .id'` && \
  aerospace focus --window-id "${recent_window}" && aerospace workspace "${recent_space}"
```

2. After editing: `skhd --restart-service`

## Acceptance Criteria
- yabai keybindings removed (or replaced with aerospace equivalents)
- All focus, swap, layout, workspace-switching bindings work with aerospace
- Reload/restart binding functional

## Notes
- Currently `dot_config/skhd/skhdrc` is noted as "currently empty" in the repo — verify current content and either populate or replace accordingly