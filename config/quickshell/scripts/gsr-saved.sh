#!/bin/sh
# Run by gpu-screen-recorder (-sc) after it saves a file.
# $1 = file path, $2 = regular | replay | screenshot
f=$1
case $2 in
replay) title="Replay saved" ;;
regular) title="Recording saved" ;;
*) title="Saved" ;;
esac

(
    act=$(notify-send -a Recorder -i video-x-generic -A open=Open -A folder="Show folder" "$title" "$(basename "$f")")
    case $act in
    open) xdg-open "$f" ;;
    folder) xdg-open "$(dirname "$f")" ;;
    esac
) >/dev/null 2>&1 &
