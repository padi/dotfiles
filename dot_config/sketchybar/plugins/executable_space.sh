#!/bin/bash

# The $SELECTED variable is available for space components and indicates if
# the space invoking this script (with name: $NAME) is currently selected:
# https://felixkratz.github.io/SketchyBar/config/components#space----associate-mission-control-spaces-with-an-item
source "$CONFIG_DIR/colors.sh"

# Fail gracefully if dependencies are missing
if ! command -v jq &>/dev/null || ! command -v yabai &>/dev/null; then
  sketchybar --set "$NAME" label.drawing=off
  exit 0
fi

get_app_icon() {
  case "$1" in
  "Calendar") echo "󰸗" ;;
  "Code" | "VS Code" | "Visual Studio Code") echo "󰨞" ;;
  "Discord") echo "󰙯" ;;
  "Docker" | "Docker Desktop") echo "󰡨" ;;
  "Finder") echo "󰀶" ;;
  "Firefox") echo "" ;;
  "Floorp") echo "󰯺" ;;
  "Google Chrome" | "Chrome") echo "" ;;
  "Keynote") echo "󰐨" ;;
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
  "Postman") echo "" ;;
  "Preview") echo "󰋩" ;;
  "Reminders") echo "󰉹" ;;
  "Safari") echo "" ;;
  "Signal") echo "󱋊" ;;
  "Slack") echo "" ;;
  "Spotify") echo "" ;;
  "Sublime Text") echo "󰅳" ;;
  "System Settings") echo "󰒓" ;;
  "Telegram") echo "" ;;
  "Terminal") echo "󰆍" ;;
  "VLC") echo "󰕼" ;;
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

# Query yabai for windows in the current space
# Note: We need to filter out windows that don't have an app name (e.g. system windows)
apps=$(yabai -m query --windows --space "$sid" | jq -r '.[].app' | sort -u)

label=""
if [ -n "$apps" ]; then
  while read -r app; do
    icon=$(get_app_icon "$app")
    label+="$icon "
  done <<<"$apps"
fi

# Trim trailing space
label=$(echo "$label" | sed 's/ $//')

sketchybar --set "$NAME" \
  icon.highlight="$SELECTED" \
  background.drawing="$SELECTED" \
  label="$label" \
  label.padding_left=4 \
  label.padding_right=8 \
  label.drawing=on
