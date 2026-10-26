#!/bin/bash
# Bridge: aerospace subscribe -> sketchybar --trigger aerospace_refresh
# This listens for AeroSpace events (workspace change, window move, focus change)
# and triggers SketchyBar to refresh space items.

# Fail gracefully if dependencies are missing
if ! command -v aerospace &>/dev/null || ! command -v sketchybar &>/dev/null; then
  exit 0
fi

# Run aerospace subscribe and pipe each event to sketchybar trigger
aerospace subscribe --all | while IFS= read -r line; do
  # Trigger SketchyBar to re-run all subscribed item scripts
  sketchybar --trigger aerospace_refresh
done