#!/usr/bin/env bash
# rofi Wi-Fi picker (adapted from zenities' wifi_settings.sh)

if [[ "$(nmcli -t -f WIFI g)" == "enabled" ]]; then
	toggle="󰖪  Disable Wi-Fi"
else
	toggle="󰖩  Enable Wi-Fi"
fi

lock=$'\uf023'
open=$'\uf09c'
wifi_list=$(nmcli -t -f SECURITY,SSID device wifi list | awk -F: -v l="$lock" -v o="$open" '$2 != "" { printf "%s  %s\n", ($1 == "" || $1 == "--") ? o : l, $2 }' | sort -u)

chosen=$(printf '%s\n%s\n' "$toggle" "$wifi_list" | rofi -dmenu -i -selected-row 1 -p "Wi-Fi SSID: ")
[[ -z "$chosen" ]] && exit 0

case "$chosen" in
	"󰖩  Enable Wi-Fi") nmcli radio wifi on; exit ;;
	"󰖪  Disable Wi-Fi") nmcli radio wifi off; exit ;;
esac

ssid="${chosen:3}"
msg="Connected to \"$ssid\""
if nmcli -g NAME connection | grep -Fxq "$ssid"; then
	nmcli connection up id "$ssid" | grep -q successfully && notify-send "Network" "$msg"
else
	pass=""
	[[ "$chosen" == "$lock"* ]] && pass=$(rofi -dmenu -password -p "Password: ")
	nmcli device wifi connect "$ssid" ${pass:+password "$pass"} | grep -q successfully && notify-send "Network" "$msg"
fi
