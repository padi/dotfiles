### What remains after this plan

| Component | Status |
|-----------|--------|
| **yabai** | ❌ Uninstalled |
| **skhd** | ✅ Still installed, running, with empty config (ready for new bindings) |
| **sketchybar** | ✅ Still installed, running (bar, clock, volume, battery, front_app) |
| **sketchybar space items** | ❌ Removed from `executable_sketchybarrc` (were yabai-dependent) |
| **sketchybar plugins** | ✅ clock, battery, volume, front_app remain active; **space plugin preserved but commented out** |
| **chezmoi source** | ✅ `dot_config/yabai/` removed; `dot_config/skhd/skhdrc` emptied; `dot_config/sketchybar/plugins/executable_space.sh` commented out |