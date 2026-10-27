#!/usr/bin/env bash
# Mock aerospace command for testing the bridge script.
# Usage: source this file, then call mock_aerospace_init with a scenario name.
# Then run the bridge script (with PATH set to include this mock).

MOCK_STATE_DIR="${MOCK_STATE_DIR:-/tmp/mock_aerospace_test}"
MOCK_SCENARIO="${MOCK_SCENARIO:-}"

# Initialize mock with a named scenario
mock_aerospace_init() {
  local scenario="$1"
  MOCK_SCENARIO="$scenario"
  mkdir -p "$MOCK_STATE_DIR"

  case "$scenario" in
    initial)
      echo "1" > "$MOCK_STATE_DIR/focused_workspace"
      echo "1:4333" > "$MOCK_STATE_DIR/window_pairs"
      echo "2:4316" >> "$MOCK_STATE_DIR/window_pairs"
      echo "3:6238" >> "$MOCK_STATE_DIR/window_pairs"
      ;;
    move_3_to_1)
      echo "1" > "$MOCK_STATE_DIR/focused_workspace"
      echo "1:4333" > "$MOCK_STATE_DIR/window_pairs"
      echo "1:6238" >> "$MOCK_STATE_DIR/window_pairs"
      echo "2:4316" >> "$MOCK_STATE_DIR/window_pairs"
      ;;
    move_1_to_2)
      echo "1" > "$MOCK_STATE_DIR/focused_workspace"
      echo "1:4333" > "$MOCK_STATE_DIR/window_pairs"
      echo "2:4316" >> "$MOCK_STATE_DIR/window_pairs"
      echo "2:6238" >> "$MOCK_STATE_DIR/window_pairs"
      ;;
    move_2_to_3)
      echo "1" > "$MOCK_STATE_DIR/focused_workspace"
      echo "1:4333" > "$MOCK_STATE_DIR/window_pairs"
      echo "2:4316" >> "$MOCK_STATE_DIR/window_pairs"
      echo "3:6238" >> "$MOCK_STATE_DIR/window_pairs"
      ;;
    workspace_switch_2_to_3)
      echo "3" > "$MOCK_STATE_DIR/focused_workspace"
      echo "1:4333" > "$MOCK_STATE_DIR/window_pairs"
      echo "2:4316" >> "$MOCK_STATE_DIR/window_pairs"
      echo "3:6238" >> "$MOCK_STATE_DIR/window_pairs"
      ;;
    empty)
      echo "1" > "$MOCK_STATE_DIR/focused_workspace"
      : > "$MOCK_STATE_DIR/window_pairs"
      ;;
    *)
      echo "Unknown scenario: $scenario" >&2
      return 1
      ;;
  esac
}

# Mock aerospace workspace query functions
mock_aerospace_list_workspaces() {
  cat "$MOCK_STATE_DIR/focused_workspace" 2>/dev/null || echo "1"
}

mock_aerospace_list_windows() {
  cat "$MOCK_STATE_DIR/window_pairs" 2>/dev/null || echo ""
}

# Export for use in test scripts
export -f mock_aerospace_init
export -f mock_aerospace_list_workspaces
export -f mock_aerospace_list_windows
