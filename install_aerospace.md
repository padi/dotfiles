# Minimal Plan: Install & Integrate AeroSpace with skhd & sketchybar

> **Goal**: Replace yabai with aerospace as the window manager, and integrate
> it with the existing skhd hotkey daemon and sketchybar status bar. This plan
> assumes aerospace is already installed (v0.21.3-Beta) and yabai has been
> removed (see commit `d15ecb4`).

---

## 1. Verify aerospace installation
```bash
aerospace --version   # → should output version 0.21.3-Beta or newer
aerospace list-workspaces --all # → should list workspaces (server may need to start)
```

---

## 2. Set up default aerospace config
Create `~/.config/aerospace/default-config.toml` (chezmoi source:
`dot_config/aerospace/default-config.toml`) with:

```toml
# Window gap (equivalent to yabai's window_gap)
gap = 2

# Sketchybar height: the bar is 24px high at the top (per sketchybarrc).
# AeroSpace does not have an explicit `external_bar` like yabai, but windows
# will naturally avoid the area covered by sketchybar since it sits on top of
# the display. The gap above defaults to 2px; if you need more space or want
# to reserve the exact 24px for the bar, you can increase it:
# gap = 24   # uncomment to reserve top area for sketchybar

# Mouse settings (same modifier as original yabai/skhd)
[mouse]
modifier = "alt"
action1 = "move"
action2 = "resize"

# Layout: bsp is default; no need to set unless changing
# layout = "bsp"
```

This config replaces the removed `dot_config/yabai/executable_yabairc`.
No `manage=off` rules are needed — aerospace manages all windows by default.
The `gap` setting controls the padding between windows; adjusting it to 24
will reserve the full height of the sketchybar at the top of the screen.

---

## 3. Update skhd hotkey bindings (`dot_config/skhd/skhdrc`)

Replace the removed yabai bindings with aerospace CLI equivalents.
Only the essential, minimal set is included below:

### Within Current Workspace — Focus
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

### Move Window between Workspaces
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

### Restart skhd / reload sketchybar
```sh
ctrl + alt - r : skhd --restart-service \
&& sketchybar --reload
```

### Command-Tab → Recent Workspace/Window (requires jq)
```sh
cmd - tab : recent_space=`aerospace list-windows --all --format json | jq -r '.[] | select(.focused) | .workspace'` && \
  recent_window=`aerospace list-windows --all --format json | jq -r '.[] | select(.focused) | .id'` && \
  aerospace focus --window-id "${recent_window}" && aerospace workspace "${recent_space}"
```

> **After editing**: `skhd --restart-service`

---

## 4. Update sketchybar space plugin
Edit `dot_config/sketchybar/plugins/executable_space.sh` to replace the
commented-out yabai queries with aerospace CLI commands.

**Key changes**:

1. **Remove the yabai guard** (lines 5–7 commented). The plugin should now
   always attempt to query aerospace:

```bash
# Determine if this workspace is selected using aerospace as the source of truth.
# Note: AeroSpace uses "workspaces" (like virtual desktops), not native macOS Spaces.
# Each sketchybar space item (e.g., "space.1") maps to an AeroSpace workspace ID.
current_sid=$(aerospace list-workspaces --all --format json | jq -r '.[] | select(.focused) | .id')
SELECTED_LOCAL="off"
if [ "$sid" -eq "$current_sid" ]; then
  SELECTED_LOCAL="on"
fi
```

2. **Replace yabai window query** (lines 77–77 commented). Get app list for
   the current workspace:

```bash
# Query aerospace for windows in the current workspace (not "space")
# Note: Use --workspace "$sid" to query the specific workspace the plugin is rendering
apps=$(aerospace list-windows --workspace "$sid" --format json | jq -r '.[].app' | sort -u)
```

3. **Keep `get_app_icon()` unchanged** — it already maps app names to icons,
   which works the same with aerospace output.

**Note on $NAME → $sid mapping**:
The `$NAME` variable from the sketchybar space item will contain the workspace ID
(as defined in the sketchybarrc space loop, e.g., "space.1" → 1). The script
extracts this with `${NAME#*.}` into the `$sid` variable for the above comparison.

After editing: `sketchybar --reload` (or let it reload on event).

---

## 5. Minor: Update sketchybar bar config (optional)
`dot_config/sketchybar/executable_sketchybarrc` has a commented-out space
loop and a `YABAI` variable reference. For minimal setup these can remain
as-is; the space plugin now uses `aerospace` directly. If you want to enable
the space items, uncomment the space loop in the bar config and adapt the
`click_script` to use `aerospace list-workspaces` / `aerospace focus --window-id`.

---

## 6. Full reload / verify

```bash
# Reload all services
skhd --restart-service
sketchybar --reload

# Verify window management works:
aerospace focus down           # should focus the window south
aerospace workspace 1            # should focus workspace 1

# Verify sketchybar shows workspace icons:
sketchybar --cli --set space label=" "
```

---

## 7. Cleanup: Remove yabai remnants (already done in commit d15ecb4)

- `yabai` uninstalled
- `dot_config/yabai/` removed
- `dot_config/skhd/skhdrc` cleared of yabai bindings
- `dot_config/sketchybar/plugins/executable_space.sh` yabai code commented out

No further action needed.

---

## Summary of file changes

| File | Change |
|---|---|
| `dot_config/aerospace/default-config.toml` | **Create** — gap, mouse, layout config |
| `dot_config/skhd/skhdrc` | **Edit** — aerospace keybindings (replace yabai) |
| `dot_config/sketchybar/plugins/executable_space.sh` | **Edit** — aerospace workspace queries (replace yabai) |
| `dot_config/sketchybar/executable_sketchybarrc` | Optional — enable space items loop |
| No changes needed to `dot_config/sketchybar/plugins/executable_front_app.sh` |