#!/bin/bash
# Bridge: aerospace subscribe -> sketchybar --trigger aerospace_refresh
# This listens for AeroSpace events (workspace change, window move, focus change)
# and triggers SketchyBar to refresh space items.

# Fail gracefully if dependencies are missing
if ! command -v aerospace &>/dev/null || ! command -v sketchybar &>/dev/null; then
  exit 0
fi

# Run aerospace subscribe in a script with pseudo-TTY to ensure it works
/usr/bin/script -q -c "aerospace subscribe --all" /tmp/aerospace_events.log 2>&1 | while IFS= read -r line; do
  # Trigger SketchyBar to re-run all subscribed item scripts
  sketchybar --trigger aerospace_refresh
done