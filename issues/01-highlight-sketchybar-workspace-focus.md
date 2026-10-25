# Task 1: Highlight current aerospace workspace in sketchybar

## Goal
Modify the sketchybar space plugin to highlight the currently focused aerospace workspace.

## Current Issue
The `executable_space.sh` plugin currently uses commented-out yabai commands to determine workspace focus. We need to:
1. Use aerospace CLI to get the currently focused workspace
2. Compare it with the workspace ID being rendered in sketchybar
3. Set the appropriate visual indicator (e.g., show "●" for focused workspace)

## Steps
1. In `dot_config/sketchybar/plugins/executable_space.sh`:
   - Add code to get the currently focused workspace ID using `aerospace list-workspaces --all --format json`
   - Compare with the current workspace ID from the sketchybar space item
   - Set a visual indicator (like "●" or "●" with different color) when focused

2. Update the click_script in `dot_config/sketchybar/executable_sketchybarrc` to use the new highlighting logic

## Acceptance Criteria
- When a workspace is focused in aerospace, the corresponding sketchybar space item shows a clear visual indicator
- The plugin works without yabai (which is removed)
- The highlighting updates dynamically when switching workspaces

## Notes
- The `current_sid` variable should be compared with the workspace ID from the sketchybar space item
- Use `aerospace list-workspaces --all --format json | jq -r '.[] | select(.focused) | .id'` to get focused workspace
- The sketchybar space item name format is "space.N" where N is the workspace ID