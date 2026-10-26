# Code Review — Two-Axis Tasks (main...HEAD)

## Standards Axis
- [x] **Fix typo in `dot_config/sketchybar/executable_font.sh`** (line 8): Remove stray `o` after `ICON_FONT="Hack Nerd Font:Bold:17.0"` — will silently break font rendering on `cirrus`.
- [x] **Remove unused `aerospace_refresh` trigger subscription** from `dot_config/sketchybar/executable_sketchybarrc` — dead subscription introduced when bridge switched to direct `space.sh` calls.
- [ ] **Clean up debug logging** from `dot_config/sketchybar/plugins/executable_space.sh` — `echo "space.sh executed..." >/tmp/space.log` is unnecessary runtime logging.
- [ ] **Review `.chezmoiignore` redundancy**: `*.md` was too broad; replaced with explicit `issues/`, root-level `.md` files, and `AGENTS.md`. Keep both ignores in sync.

## Spec Axis
- [ ] **Remove orphan `default-config.toml`** from `~/.config/aerospace/` — not managed by chezmoi, left over from before yabai→aerospace migration. Per issue 02 acceptance: "`default-config.toml` is removed (or ignored) from the workspace."
- [ ] **Verify `.chezmoiignore` doesn't suppress AGENTS.md deployment** — currently excluded via explicit listing; ensure this is intentional since AGENTS.md is the coding-standards reference.
- [ ] **Confirm issues folder is tracked in git but excluded from chezmoi deployment** — `.chezmoiignore` has `issues/`, `.gitignore` now also has `issues/` (newly added). Verify both are consistent.

## Completed
- [x] Updated `.chezmoiignore` to explicitly exclude markdown files (issues/, root-level .md, AGENTS.md) from chezmoi deployment
- [x] Created `.gitignore` with `issues/` and root-level markdown files for git tracking hygiene
- [x] Both axes reviewed in parallel; findings documented under `## Standards` and `## Spec` in the original review

## Notes
- Standards hard violation (1): `ICON_FONT` typo — highest priority fix
- Spec missing housekeeping (1): orphan `default-config.toml` — clean up after confirming with issue 02 acceptance criteria
- Judgement-call smells (2): unused `aerospace_refresh` subscription + `*.md` redundancy in chezmoiignore