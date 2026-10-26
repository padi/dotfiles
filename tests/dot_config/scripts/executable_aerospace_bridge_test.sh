#!/usr/bin/env bash
# Test suite for executable_aerospace_bridge.sh
# Tests that the bridge correctly detects:
# 1. Focused workspace changes
# 2. Window moves between workspaces (move-node-to-workspace)
# 3. Correct refresh of affected space items only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TESTS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$TESTS_DIR/helpers/mock_aerospace.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS=0
FAIL=0

test_bridge_detection() {
  local test_name="$1"
  local initial_scenario="$2"
  local final_scenario="$3"
  local expected_workspaces="$4"

  mock_aerospace_init "$initial_scenario"
  local prev_mapping=$(mock_aerospace_list_windows | sort -t: -k1,1n -k2,2n)
  local current_workspace=$(mock_aerospace_list_workspaces)

  mock_aerospace_init "$final_scenario"
  local new_mapping=$(mock_aerospace_list_windows | sort -t: -k1,1n -k2,2n)
  local new_workspace=$(mock_aerospace_list_workspaces)

  local TEMP_OLD=$(mktemp)
  local TEMP_NEW=$(mktemp)
  echo "$prev_mapping" > "$TEMP_OLD"
  echo "$new_mapping" > "$TEMP_NEW"

  local changed_ws=$(diff "$TEMP_OLD" "$TEMP_NEW" 2>/dev/null | grep -E '^[<>]' | sed 's/^[<>] //' | cut -d: -f1 | sort -n -u)

  if [ "$new_workspace" != "$current_workspace" ]; then
    if [ -n "$changed_ws" ]; then
      changed_ws="$changed_ws $current_workspace $new_workspace"
    else
      changed_ws="$current_workspace $new_workspace"
    fi
  fi

  rm -f "$TEMP_OLD" "$TEMP_NEW"

  local expected_normalized=$(echo "$expected_workspaces" | tr ' ' '\n' | sort -n | tr '\n' ' ' | xargs)
  local actual_normalized=$(echo "$changed_ws" | tr ' ' '\n' | sort -n | tr '\n' ' ' | xargs)

  if [ "$expected_normalized" = "$actual_normalized" ]; then
    echo -e "${GREEN}PASS${NC}: $test_name"
    PASS=$((PASS+1))
  else
    echo -e "${RED}FAIL${NC}: $test_name"
    echo "  Expected refreshed workspaces: $(echo "$expected_workspaces" | tr ' ' '\n' | sort)"
    echo "  Got:                                $(echo "$changed_ws" | tr ' ' '\n' | sort)"
    FAIL=$((FAIL+1))
  fi
}

echo -e "${YELLOW}=== Aerospace Bridge Change Detection Tests ===${NC}"
echo ""

echo "--- move-node-to-workspace (source + dest refresh) ---"

test_bridge_detection \
  "Move window 6238 from workspace 3 to workspace 1" \
  "initial" "move_3_to_1" "1 3"

test_bridge_detection \
  "Move window 6238 from workspace 1 to workspace 2" \
  "move_3_to_1" "move_1_to_2" "1 2"

test_bridge_detection \
  "Move window 6238 from workspace 2 to workspace 3" \
  "move_1_to_2" "move_2_to_3" "2 3"

test_bridge_detection \
  "Focused workspace change from 2 to 3 (same window set)" \
  "empty" "initial" "1 2 3"

test_bridge_detection \
  "No change (steady state)" \
  "move_2_to_3" "move_2_to_3" ""

test_bridge_detection \
  "From empty workspace to window appears" \
  "empty" "initial" "1 2 3"

echo ""
echo -e "${YELLOW}=== Summary ===${NC}"
echo "Passed: $PASS"
echo "Failed: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed.${NC}"
  exit 1
fi
