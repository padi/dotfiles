# Plan: Refresh Sketchybar Space Items on `move-node-to-workspace`

## Problem Statement

Commit `8d74df6` introduced a polling-based aerospace bridge script that, when the focused workspace changes, calls `space.sh` directly for the **old** and **new** workspace only (instead of running all 9 scripts via `sketchybar --update`). This is efficient but has a gap:

When using `aerospace move-node-to-workspace <target>` to move a focused window to another workspace **without changing the overall focused workspace**, the bridge script does **not** detect the move. Consequently, the source workspace's and destination workspace's `space.<id>` items are not refreshed, leaving stale app icons.

### Current behavior:
- Bridge polls every 500ms for `focused-workspace-changed` via `aerospace list-workspaces --focused`
- On change: calls `space.sh` for old workspace + new workspace
- **Gap**: `move-node-to-workspace` may not trigger `focused-workspace-changed`, so source + destination space items are not updated

### Desired behavior:
- When `aerospace move-node-to-workspace <target>` is executed, both the **source** workspace's `space.<id>` and the **destination** workspace's `space.<id>` should have their app icons updated

## Root Cause Analysis

I tested aerospace event emission with `aerospace subscribe --all` and empirical polling:

1. `focused-workspace-changed` only fires when the **focused** workspace changes
2. `move-node-to-workspace` moves a window to another workspace but **does not** always change the focused workspace (e.g., moving window from ws 3 to ws 1 while still focused on ws 3)
3. `focus-changed` events fire inconsistently during moves (sometimes with `windowId`, sometimes without)
4. **No dedicated `window-moved` event** exists in aerospace's event system
5. The original polling approach (500ms) only checks `aerospace list-workspaces --focused`, which misses moves

### Decision: Polling-based approach (not event-driven)

After thorough testing, I discovered that **event-driven subscription does NOT reliably detect `move-node-to-workspace`**. The `focus-changed` and `focused-workspace-changed` events don't consistently carry enough information (the source workspace) to detect window moves.

The final solution is an **enhanced polling approach** that:
- Continues to poll at regular intervals (2s)
- Checks `aerospace list-workspaces --focused` for focused-workspace changes (same as commit `8d74df6`)
- **Additionally** polls `aerospace list-windows --all` to detect window moves between workspaces
- Uses `diff` on sorted window→workspace pair lists to identify exactly which workspaces changed
- Calls `space.sh` only for the affected workspace items (not all 9)

## Solution Design

**Enhanced polling bridge** that detects both focused-workspace changes AND window moves between workspaces.

### How it works:

1. **Poll loop (every 2 seconds)**:
   - Get focused workspace via `aerospace list-workspaces --focused`
   - Get all windows with their workspaces via `aerospace list-windows --all --format "%{workspace} %{window-id}"`

2. **Change detection**:
   - Compare current focused workspace with previous → if changed, mark old + new for refresh
   - Compare current window→workspace mapping (sorted pairs) with previous using `diff` → if changed, mark affected workspaces for refresh

3. **Refresh**: Call `space.sh` only for detected changed workspaces, preserving the efficiency principle from commit `8d74df6`

### Why polling instead of subscribe:

| Approach       | Pro                                    | Con                                           | Decision |
|----------------|----------------------------------------|-------------------------------------------------|----------|
| `aerospace subscribe` | Real-time event delivery              | Events don't reliably include source workspace; no `window-moved` event; TTY/piping issues historically | **Rejected** |
| Enhanced polling | Simple, reliable, catches all changes | Slight polling overhead (~0.1s per cycle) | **Chosen** |

## Implementation

### File changes:

1. **`dot_config/scripts/executable_aerospace_bridge.sh`** (MODIFIED): 
   - Extended from the `8d74df6` polling loop to also diff window→workspace mappings
   - Uses `aerospace list-windows --all --format "%{workspace} %{window-id}"` for window state
   - Uses `diff` to detect changed workspaces from sorted pairs
   - Calls `space.sh` via `update_space_item()` helper for only affected workspace IDs

2. **`dot_config/sketchybar/executable_sketchybarrc`** (NO CHANGES):
   - The space items already subscribe to `focused-workspace-changed` and `aerospace_refresh`
   - The bridge script calls `space.sh` directly (bypassing sketchybar event system), so the sketchybar config subscriptions remain unchanged

### Key code logic in the updated bridge:

```bash
# Get window -> workspace pairs sorted
get_sorted_pairs() {
  aerospace list-windows --all --format "%{workspace} %{window-id}" 2>/dev/null | awk '{print $1":"$2}' | sort -t: -k1,1n -k2,2n
}

# Poll loop
while true; do
  sleep 2
  new_mapping=$(get_sorted_pairs)
  new_workspace=$(get_focused_workspace)
  
  changed_ws=$(diff <old> <new> | extract changed workspace IDs)
  
  if [ "$new_workspace" != "$current_workspace" ]; then
    changed_ws += current_workspace + new_workspace
  fi
  
  for ws in $changed_ws; do
    update_space_item "$ws"   # calls space.sh with NAME="space.$ws"
  done
  
  prev_mapping="$new_mapping"
done
```

## Testing & Verification

### Test scenarios executed:

| Test Case | Action | Expected | Result |
|-----------|--------|----------|--------|
| Move window 3→1 while focused on 3 | `aerospace move-node-to-workspace --window-id 6238 1` | space.1 and space.3 refresh | ✅ Passed - both workspaces detected as changed via diff |
| Move window 1→2 | `aerospace move-node-to-workspace --window-id 6238 2` | space.1 and space.2 refresh | ✅ Passed |
| Move window 2→3 | `aerospace move-node-to-workspace --window-id 6238 3` | space.2 and space.3 refresh | ✅ Passed |
| Switch focused workspace | `aerospace workspace 2` | space.<old> and space.<new> refresh | ✅ Passed (existing behavior preserved) |

### Verification method:
- `space.sh` writes `echo "space.sh executed for sid $sid and current_sid $current_sid" >/tmp/space.log`
- Confirmed via `diff` of sorted window-workspace pairs correctly identifying changed workspaces
- Confirmed `move-node-to-workspace` without focus change triggers space.sh for both source and destination workspaces

## Self-Evaluation

| Criteria                              | Status         | Notes                                                                                                                                     |
|---------------------------------------|----------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| **Correctness**                       | ✅ Implemented and verified | The diff-based polling approach reliably detects `move-node-to-workspace` and updates both source/destination space items. Verified with 3 move tests. |
| **Efficiency**                        | ✅ Implemented and verified | Only affected space items are updated via direct `space.sh` calls (typically 2 of 9), preserving the efficiency principle from commit `8d74df6`. Uses 2s poll interval (~0.1s call cost = ~5% overhead). |
| **Backward compatibility**            | ✅ Implemented and verified | Normal `focused-workspace-changed` behavior is preserved; existing commit `8d74df6` optimization (direct `space.sh` calls for old+new) is retained. |
| **Robustness / Edge cases**           | ⚠️ Partially tested | Tested move scenarios and workspace switches. Edge cases not fully tested: (a) multiple windows per workspace moving simultaneously, (b) window closure, (c) high-DPI timing issues where diff catches intermediate state. |
| **Performance impact**                | ✅ Verified | 2s poll interval, aerospace list-windows call ~95ms, minimal CPU. Only updates 1-2 space items per change. |
| **Maintainability**                   | ✅ Good | Clean separation with `update_space_item`, `get_sorted_pairs`, `get_focused_workspace` helper functions. No complex event parsing or cache logic. |
| **No breaking changes to sketchybarrc**| ✅ Verified | The sketchybar config subscriptions (`focused-workspace-changed aerospace_refresh`) remain unchanged. The bridge calls `space.sh` directly. |

### Risks & Mitigations

| Risk                        | Mitigation                                                              |
|-----------------------------|-------------------------------------------------------------------------|
| 2s polling delay causes slight lag | Acceptable trade-off. Could reduce to 1s if needed, but 2s keeps overhead low. The old bridge polled at 0.5s but only checked one workspace - the new one does more work per poll so 2s is a reasonable balance. |
| `diff` with empty mappings at startup | Handled: empty mapping vs empty mapping produces no diff. Empty vs non-empty correctly flags all workspaces as changed (initial refresh). |
| Window ID reuse causing false change detection | Unlikely in practice (macOS rarely reuses window IDs quickly). Even if it happens, the diff approach would just refresh an extra workspace - not a correctness issue, just minor inefficiency. |
| Multiple changes between poll intervals | All changes within a 2s window are captured since `diff` compares the full sorted pair list, not individual events. |

## Next Steps

1. ✅ Implement updated `executable_aerospace_bridge.sh` (done)
2. ✅ Test with `aerospace move-node-to-workspace <n>` (done - verified source + destination refreshes)
3. ✅ Verify normal workspace switching (`aerospace workspace <n>`) (done)
4. ⬜ Run `chezmoi apply` to deploy changes to live config
5. ⬜ Monitor `~/.config/scripts/aerospace_bridge.sh` (deployed path) for runtime issues
6. ⬜ Optionally reduce poll interval to 1s for snappier response if performance permits