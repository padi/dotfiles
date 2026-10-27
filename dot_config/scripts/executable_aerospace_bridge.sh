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

# -----------------------------------------------------------------------------
# Prevent multiple instances (lock file guard)
# -----------------------------------------------------------------------------
LOCK_FILE="$HOME/.cache/aerospace_bridge.pid"
mkdir -p "$(dirname "$LOCK_FILE")" 2>/dev/null

# Function to clean up and exit
cleanup_and_exit() {
  pkill -f "aerospace subscribe.*focus-changed.*focused-workspace-changed.*window-detected" 2>/dev/null
  pkill -f "aerospace_workspace_debounce" 2>/dev/null
  rm -f "$LOCK_FILE"
  exit "$1"
}

# Check if already running
if [ -f "$LOCK_FILE" ]; then
  old_pid=$(cat "$LOCK_FILE" 2>/dev/null)
  if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
    # Process exists, exit silently
    exit 0
  else
    # Stale lock file, remove it
    rm -f "$LOCK_FILE"
  fi
fi

# -----------------------------------------------------------------------------
# Argument parsing (management options bypass lock check)
# -----------------------------------------------------------------------------
case "$1" in
  --help)
    cat <<EOF
Usage: $(basename "$0") [OPTION]

Options:
  --help     Show this help message
  --stop     Stop the aerospace bridge
  --restart  Restart the aerospace bridge

Without an option, starts the aerospace bridge (event-driven + 3s safety poll).
EOF
    cleanup_and_exit 0
    ;;
  --stop)
    pkill -f "aerospace_bridge.sh" 2>/dev/null
    rm -f "$LOCK_FILE" 2>/dev/null
    echo "Aerospace bridge stopped"
    cleanup_and_exit 0
    ;;
  --restart)
    pkill -f "aerospace_bridge.sh" 2>/dev/null
    sleep 0.3
    rm -f "$LOCK_FILE" 2>/dev/null
    nohup "$0" &
    echo "Aerospace bridge restarted (PID: $(pgrep -f aerospace_bridge.sh | head -1))"
    cleanup_and_exit 0
    ;;
  -*)
    echo "Error: Unknown option '$1'" >&2
    echo >&2
    cat <<EOF >&2
Usage: $(basename "$0") [OPTION]

Options:
  --help     Show this help message
  --stop     Stop the aerospace bridge
  --restart  Restart the aerospace bridge

Without an option, starts the aerospace bridge (event-driven + 3s safety poll).
EOF
    cleanup_and_exit 1
    ;;
esac

# Write our PID to the lock file
echo $$ > "$LOCK_FILE"

# Fail gracefully if dependencies are missing
if ! command -v aerospace &>/dev/null || ! command -v sketchybar &>/dev/null; then
  cleanup_and_exit 0
fi

# -----------------------------------------------------------------------------
# Clean up any leftover background processes from previous bridge instances.
# This prevents accumulation of orphaned `aerospace subscribe` processes that
# can cause CPU spikes when launchd restarts the bridge (SIGKILL can't be
# trapped, so the EXIT trap doesn't run on kill).
# -----------------------------------------------------------------------------
# Kill any existing aerospace subscribe processes (leftover from previous runs)
pkill -f "aerospace subscribe.*focus-changed.*focused-workspace-changed.*window-detected" 2>/dev/null
sleep 0.1
# Also kill any leftover workspace debounce sleepers
pkill -f "aerospace_workspace_debounce" 2>/dev/null

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

# Cleanup: kill the event listener and remove lock file if main loop exits
# Also kill any leftover aerospace subscribe processes as a safety net
cleanup_bg_processes() {
  kill "$EVENT_PID" 2>/dev/null
  pkill -f "aerospace subscribe.*focus-changed.*focused-workspace-changed.*window-detected" 2>/dev/null
  pkill -f "aerospace_workspace_debounce" 2>/dev/null
  rm -f "$LOCK_FILE"
}
trap 'cleanup_bg_processes' EXIT

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