#!/bin/zsh
wal="$1"
wal -i "$wal"
cp "$wal" ~/.cache/wal/wallpaper.jpg
swaync-client -rs
awww img "$HOME/.cache/wal/wallpaper.jpg" --transition-type=any --transition-fps 180
RGB_COLOR=$(sed -n '2p' ~/.cache/wal/colors | tr -d '#')
openrgb -c "$RGB_COLOR" > /dev/null 2>&1 &
