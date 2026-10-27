# Debounce script for AeroSpace workspace change events
# Saves the last workspace to a file and triggers sketchybar after a delay
# Only triggers if the workspace hasn't changed during the delay period

#!/usr/bin/env bash
# Path to the debounce file
DEBOUNCE_FILE="$HOME/.cache/aerospace_workspace_debounce"

# Create directory if it doesn't exist
mkdir -p "$(dirname "$DEBOUNCE_FILE")"

# If this script is called with a workspace, set the debounce file and schedule the trigger
if [ $# -eq 1 ]; then
  echo "$1" > "$DEBOUNCE_FILE"
  # Kill any existing debounce sleeper
  pkill -f "aerospace_workspace_debounce" 2>/dev/null
  # Start a new debounced trigger (150ms delay)
  (sleep 0.15; 
   if [ -f "$DEBOUNCE_FILE" ] && [ "$(cat "$DEBOUNCE_FILE" 2>/dev/null)" = "$1" ]; then
     sketchybar --trigger aerospace_workspace_change FOCUSED="$1"
   fi
  ) &
fi