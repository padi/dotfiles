# Task 5: Enable space items in sketchybar bar config

## Goal
Update `dot_config/sketchybar/executable_sketchybarrc` to enable the space item loop and adapt `click_script` to use aerospace instead of yabai.

## Steps
1. Review `dot_config/sketchybar/executable_sketchybarrc` for:
   - Commented-out space loop (spaces 1–9)
   - `YABAI` variable references
2. Uncomment/enable the space loop in the bar config
3. Adapt `click_script` for each space item to use `aerospace list-workspaces` / `aerospace focus --window-id` instead of yabai commands
4. Ensure the space items integrate with the updated `executable_space.sh` plugin (Task 1)

## Acceptance Criteria
- Space items (1–9) are enabled in sketchybar bar config
- `click_script` uses aerospace CLI, not yabai
- Clicking a space item switches to that workspace in aerospace

## Notes
- This is marked as optional in install_aerospace.md step 5
- The space plugin now uses `aerospace` directly, so the bar config just needs to wire up the space items