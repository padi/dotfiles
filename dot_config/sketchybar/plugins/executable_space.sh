#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Fail gracefully if dependencies are missing
if ! command -v jq &>/dev/null; then
  sketchybar --set "$NAME" label.drawing=off
  exit 0
fi

get_app_icon() {
  case "$1" in
  "1Password") echo "" ;;
  "Antigravity") echo "" ;;
  "Antigravity IDE") echo "" ;;
  "Backblaze") echo "󰈸" ;;
  "Bitwarden") echo "" ;;
  "Calendar") echo "󰸗" ;;
  "Claude") echo "" ;;
  "Code" | "VS Code" | "Visual Studio Code" | "VSCodium") echo "󰨞" ;;
  "Discord") echo "󰙯" ;;
  "Docker" | "Docker Desktop") echo "󰡨" ;;
  "Finder") echo "󰀶" ;;
  "Firefox") echo "" ;;
  "Floorp") echo "󰯺" ;;
  "Google Chrome" | "Chrome") echo "" ;;
  "KeePassXC") echo "" ;;
  "Keynote") echo "󰐨" ;;
  "LastPass") echo "" ;;
  "MacYTDL") echo "" ;;
  "Mail") echo "" ;;
  "Messages") echo "󰭹" ;;
  "Microsoft Excel") echo "󱎏" ;;
  "Microsoft OneNote") echo "󰝇" ;;
  "Microsoft Teams") echo "󰊻" ;;
  "Microsoft Word") echo "" ;;
  "Notes") echo "󱓧" ;;
  "Numbers") echo "" ;;
  "Obsidian") echo "󰇈" ;;
  "Pages") echo "󱓧" ;;
  "Paseo") echo "" ;;
  "Postman") echo "" ;;
  "Preview") echo "󰋩" ;;
  "Reminders") echo "󰉹" ;;
  "Safari") echo "" ;;
  "Signal") echo "󱋊" ;;
  "Slack") echo "" ;;
  "Spotify") echo "" ;;
  "Steam") echo "" ;;
  "Sublime Text") echo "󰅳" ;;
  "System Settings") echo "󰒓" ;;
  "Telegram") echo "" ;;
  "Terminal") echo "󰆍" ;;
  "VLC") echo "󰕼" ;;
  "Viber") echo "" ;;
  "WezTerm") echo "󰆍" ;;
  "WhatsApp") echo "󰭹" ;;
  "Zoom") echo "󰬡" ;;
  "iTerm") echo "󰆍" ;;
  "mpv") echo "" ;;
  *) echo "󰘔" ;;
  esac
}

# Get the space ID from the name (e.g., space.1 -> 1)
sid="${NAME#*.}"

# Last known labels, restored on reload/login (nothing can list every
# space's windows on demand without yabai)
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/sketchybar/spaces"
CACHE_FILE="$CACHE_DIR/$sid"

case "$SENDER" in
space_windows_change)
  # sketchybar's native event; $INFO = {"space": N, "apps": {"App": count, ...}}
  # It fires once per affected space, so ignore events for other spaces.
  [ "$(echo "$INFO" | jq -r '.space')" = "$sid" ] || exit 0

  label=""
  while read -r app; do
    [ -n "$app" ] && label+="$(get_app_icon "$app") "
  done < <(echo "$INFO" | jq -r '.apps | keys[]')
  label="${label% }"

  mkdir -p "$CACHE_DIR" && printf '%s' "$label" >"$CACHE_FILE"

  sketchybar --set "$NAME" \
    label="$label" \
    label.padding_left=4 \
    label.padding_right=8 \
    label.drawing=on
  ;;
forced)
  # Startup/reload: restore the cached label, then set the highlight
  [ -f "$CACHE_FILE" ] && label="$(cat "$CACHE_FILE")" || label=""
  sketchybar --set "$NAME" \
    label="$label" \
    label.padding_left=4 \
    label.padding_right=8 \
    label.drawing=on \
    icon.highlight="$SELECTED" \
    background.drawing="$SELECTED"
  ;;
*)
  # space_change / forced / etc: $SELECTED is provided by sketchybar for space items
  sketchybar --set "$NAME" \
    icon.highlight="$SELECTED" \
    background.drawing="$SELECTED"
  ;;
esac
