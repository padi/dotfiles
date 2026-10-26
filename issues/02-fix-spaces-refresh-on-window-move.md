# Fix: SketchyBar space items don't refresh when windows move between AeroSpace workspaces

## Problem

When a window is moved from one AeroSpace workspace to another (e.g. via `aerospace move-node-to-workspace 2`), SketchyBar space indicators show stale app icons on the source workspace and fail to show new ones on the destination. The `sketchybar --update` in the click_script only forces a redraw — it does not re-run the `script=` commands on space items.

## Root Cause

1. **Insufficient event subscription:** Space items only subscribe to `focused-workspace-changed`, which fires when *focus* switches, not when windows are *moved* between aerospace workspaces without a focus change.
2. **No event bridge:** `aerospace subscribe` emits events (`workspace-change`, `window-change`, `focused-window-change`) that SketchyBar has no visibility into without a bridge.
3. **Misuse of `sketchybar --update`:** `--update` redraws but does not re-run `script=` commands.

## Investigation

### AeroSpace subscribe

`aerospace subscribe` listens for AeroSpace events and emits them via stdout/socket:

```
USAGE: subscribe [-h|--help] [--all] [--no-send-initial] [<event>...]
```

Relevant events:
- `workspace-change` — focused workspace changed
- `window-change` — window created, destroyed, or moved between workspaces
- `focused-window-change` — focus moved to a different window

### SketchyBar events & triggers

SketchyBar supports custom triggers via:
- `sketchybar --trigger <name>` — causes items subscribed to that trigger to re-run their `script=` commands
- `--subscribe <item> <event>` — subscribe an item to a SketchyBar event or custom trigger

### Current sketchybarrc subscription (insufficient)

```bash
--subscribe space.$sid focused-workspace-changed
```

Only listens for SketchyBar's native `focused-workspace-changed` event.

## Plan

1. **Start `aerospace subscribe` as a background daemon** listening for `workspace-change`, `window-change`, and `focused-window-change` events (via `launchd` or a sketchybar background process).

2. **Bridge AeroSpace events to SketchyBar triggers:** pipe `aerospace subscribe` output to `sketchybar --trigger aerospace_refresh`. This lightweight trigger causes all subscribed items to re-run their scripts.

3. **Subscribe space items to the `aerospace_refresh` trigger** — add `--subscribe space.$sid aerospace_refresh` so any AeroSpace workspace/window event causes all space items to re-run `space.sh`, refreshing both app icons and the focus highlight.

4. **Keep `sketchybar --update` in click_script** for the manual focus-switch case (clicking a space item), since that's an explicit user action that should refresh immediately.

## Acceptance Criteria

- [ ] Moving a window to another AeroSpace workspace (without changing focus) immediately updates app icons on both source and destination space items
- [ ] Focus highlight (`●` indicator) still updates correctly after moving windows
- [ ] No stale icons remain on the source workspace after a window is moved away
- [ ] AeroSpace subscribe daemon survives SketchyBar restarts
- [ ] Graceful degradation if `aerospace subscribe` is unavailable

## Notes

- This issue arises after the yabai → AeroSpace migration; the original yabai integration used `yabai --signal` to emit events that SketchyBar subscribed to. AeroSpace's `subscribe` command is the equivalent that needs bridging.
