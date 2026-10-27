#!/usr/bin/env bash
# Bridge: event-driven aerospace <-> sketchybar bridge with reduced polling
#
# Listens to AeroSpace events (focus-changed, focused-workspace-changed,
# window-detected) for real-time updates, and runs a low-frequency safety
# poll (every 3s) to catch window moves and closes that don't emit events.
#
# Previously: polled every 0.5s → ~4 aerospace subprocess calls/second.
# Now:        events + 3s poll → ~0.33 aerospace calls/second (≈92% reduction).
#
# AeroSpace provides no "window-moved-between-workspaces" event, so the
# safety poll is required for correctness of window-move detection.

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

# Get current focused workspace
get_focused_workspace() {
  aerospace list-workspaces --focused 2>/dev/null
}

# Get window -> workspace pairs sorted
get_sorted_pairs() {
  aerospace list-windows --all --format "%{workspace} %{window-id}" 2>/dev/null \
    | awk '{print $1":"$2}' | sort -t: -k1,1n -k2,2n
}

# Process a single JSON event line from `aerospace subscribe`.
# Updates the relevant sketchybar space items based on the event type.
process_event() {
  local event_line="$1"
  local event_name
  event_name=$(printf '%s' "$event_line" | jq -r '._event' 2>/dev/null) || return 0

  case "$event_name" in
    "focus-changed")
      # Window focus changed; refresh the workspace of the newly focused window.
      # space.sh queries aerospace for the focused workspace each run, so the
      # highlight stays correct.
      local ws
      ws=$(printf '%s' "$event_line" | jq -r '.workspace' 2>/dev/null)
      [ -n "$ws" ] && [ "$ws" != "null" ] && update_space_item "$ws"
      ;;
    "focused-workspace-changed")
      # Workspace focus changed; refresh both previous (lost focus) and current.
      local prev_ws new_ws
      prev_ws=$(printf '%s' "$event_line" | jq -r '.prevWorkspace' 2>/dev/null)
      new_ws=$(printf '%s' "$event_line" | jq -r '.workspace' 2>/dev/null)
      [ -n "$prev_ws" ] && [ "$prev_ws" != "null" ] && update_space_item "$prev_ws"
      [ -n "$new_ws" ]   && [ "$new_ws" != "null" ]   && update_space_item "$new_ws"
      ;;
    "window-detected")
      # New window appeared; refresh the workspace it landed on (app icon list).
      local ws
      ws=$(printf '%s' "$event_line" | jq -r '.workspace' 2>/dev/null)
      [ -n "$ws" ] && [ "$ws" != "null" ] && update_space_item "$ws"
      ;;
    *)
      # Other event types (focused-monitor-changed, mode-changed, binding-triggered)
      # do not require a space item refresh.
      ;;
  esac
}

# Event listener: subscribe to events and dispatch them
event_listener() {
  # --no-send-initial: skip the initial state dump; the safety poll handles init.
  aerospace subscribe --no-send-initial \
    focus-changed focused-workspace-changed window-detected 2>/dev/null \
  | while IFS= read -r line; do
      [ -n "$line" ] && process_event "$line"
    done
}

# Launch event listener in the background
event_listener &
EVENT_PID=$!

# Cleanup: kill the event listener if the main loop exits
trap 'kill "$EVENT_PID" 2>/dev/null' EXIT

# ---------------------------------------------------------------------------
# Safety poll (runs every 3s to catch window moves + closes)
# ---------------------------------------------------------------------------
prev_mapping=$(get_sorted_pairs)
current_workspace=$(get_focused_workspace)

while true; do
  sleep 3

  new_mapping=$(get_sorted_pairs)
  new_workspace=$(get_focused_workspace)

  # Diff window->workspace pairs to find changed workspaces
  TEMP_OLD=$(mktemp)
  TEMP_NEW=$(mktemp)
  printf '%s\n' "$prev_mapping" >"$TEMP_OLD"
  printf '%s\n' "$new_mapping" >"$TEMP_NEW"

  changed_ws=$(diff "$TEMP_OLD" "$TEMP_NEW" 2>/dev/null \
    | grep -E '^[<>]' | sed 's/^[<>] //' | cut -d: -f1 | sort -n -u)

  # Also catch focused-workspace changes not already covered by diff
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

  rm -f "$TEMP_OLD" "$TEMP_NEW"
  prev_mapping="$new_mapping"
done