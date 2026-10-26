#!/bin/bash
# Bridge: poll aerospace for workspace changes and trigger sketchybar updates
# This approach uses polling since aerospace subscribe has issues with piped output.

# Fail gracefully if dependencies are missing
if ! command -v aerospace &>/dev/null || ! command -v sketchybar &>/dev/null; then
  exit 0
fi

# Track the current focused workspace
current_workspace=$(aerospace list-workspaces --focused)

# Poll every 500ms for changes
while true; do
  sleep 0.5
  new_workspace=$(aerospace list-workspaces --focused 2>/dev/null)
  
  if [ "$new_workspace" != "$current_workspace" ]; then
    # Workspace changed - force all scripts to re-run
    sketchybar --update >/dev/null 2>&1
    current_workspace="$new_workspace"
  fi
done