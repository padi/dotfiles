#!/usr/bin/env bash
# Bridge: poll aerospace for workspace changes AND window moves
# Detects both focused-workspace changes and move-node-to-workspace (window moves).
# Uses polling at 0.5-second intervals to catch all changes reliably.

# Handle --restart flag
if [[ "$1" == "--restart" ]]; then
  pkill -f "aerospace_bridge.sh" 2>/dev/null
  sleep 0.3
  nohup "$0" &
  echo "Aerospace bridge restarted (PID: $(pgrep -f aerospace_bridge.sh))"
  exit 0
fi

# Fail gracefully if dependencies are missing
if ! command -v aerospace &>/dev/null || ! command -v sketchybar &>/dev/null; then
  exit 0
fi

SPACE_SH="$HOME/.config/sketchybar/plugins/space.sh"
CONFIG_DIR="$HOME/.config/sketchybar"

# Helper: call space.sh for a given workspace item
update_space_item() {
  local sid="$1"
  if [ -n "$sid" ]; then
    NAME="space.$sid" CONFIG_DIR="$CONFIG_DIR" bash "$SPACE_SH" >/dev/null 2>&1
  fi
}

# Get focused workspace
get_focused_workspace() {
  aerospace list-workspaces --focused 2>/dev/null
}

# Get window -> workspace pairs sorted
get_sorted_pairs() {
  aerospace list-windows --all --format "%{workspace} %{window-id}" 2>/dev/null | awk '{print $1":"$2}' | sort -t: -k1,1n -k2,2n
}

# Track current state
prev_mapping=$(get_sorted_pairs)
current_workspace=$(get_focused_workspace)

# Poll every 0.5 seconds
while true; do
  sleep 0.5

  # Get current state
  new_mapping=$(get_sorted_pairs)
  new_workspace=$(get_focused_workspace)

  # Use temporary files for diff
  TEMP_OLD=$(mktemp)
  TEMP_NEW=$(mktemp)
  echo "$prev_mapping" >"$TEMP_OLD"
  echo "$new_mapping" >"$TEMP_NEW"

  # Find changed workspaces
  changed_ws=$(diff "$TEMP_OLD" "$TEMP_NEW" 2>/dev/null | grep -E '^[<>]' | sed 's/^[<>] //' | cut -d: -f1 | sort -n -u)

  # Check focused workspace change
  if [ "$new_workspace" != "$current_workspace" ]; then
    if [ -n "$changed_ws" ]; then
      changed_ws="$changed_ws $current_workspace $new_workspace"
    else
      changed_ws="$current_workspace $new_workspace"
    fi
    current_workspace="$new_workspace"
  fi

  # Update affected space items
  for ws in $changed_ws; do
    [ -n "$ws" ] && update_space_item "$ws"
  done

  # Clean up
  rm -f "$TEMP_OLD" "$TEMP_NEW"
  prev_mapping="$new_mapping"
done
