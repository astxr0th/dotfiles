#!/usr/bin/env bash
# Screenshot menu (zenities used hyprshot; this uses grim + slurp + wl-copy)

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

choice=$(printf "Fullscreen\nRegion\nActive Window\nClipboard (Region)" | rofi -dmenu -p "∂")

case "$choice" in
	"Fullscreen") sleep 0.3; grim "$file" ;;
	"Region") grim -g "$(slurp)" "$file" ;;
	"Active Window")
		geo=$(mmsg get focusing-client | python3 -c 'import json,sys; c=json.load(sys.stdin); print(f"{c[\"x\"]},{c[\"y\"]} {c[\"width\"]}x{c[\"height\"]}")')
		sleep 0.3; grim -g "$geo" "$file" ;;
	"Clipboard (Region)") grim -g "$(slurp)" - | wl-copy; notify-send "Screenshot" "Copied to clipboard"; exit ;;
	*) exit 0 ;;
esac

[[ -f "$file" ]] && wl-copy < "$file" && notify-send -i "$file" "Screenshot" "Saved to $file"
