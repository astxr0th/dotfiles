import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.components

// zenities' wallpaper switcher: a scrolling column of previews beside the
// sidebar. Picking one sets it with awww and regenerates colors with pywal.
Overlay {
    id: root

    name: "wallpaper"

    readonly property string dir: Sys.wallpaperDir
    readonly property string thumbs: Quickshell.env("HOME") + "/.cache/zenities/thumbs"
    property var items: []   // [{ path, thumb }]
    property var pending: []
    property string applying: ""

    // Build (cached) 300x200 previews whenever the panel opens
    onOpenChanged: if (open)
        scan.running = true

    Process {
        id: scan
        command: ["bash", "-c", "mkdir -p \"$2\"; for f in \"$1\"/*; do case \"${f,,}\" in *.jpg|*.jpeg|*.png|*.webp|*.gif) ;; *) continue;; esac; " + "t=\"$2/$(basename \"$f\").jpg\"; [ \"$t\" -nt \"$f\" ] || magick \"$f[0]\" -thumbnail 600x400^ -gravity center -extent 600x400 -quality 85 \"$t\" 2>/dev/null; echo \"$f|$t\"; done", "bash", root.dir, root.thumbs]
        // stream entries in as each preview is ready
        onStarted: root.pending = []
        stdout: SplitParser {
            onRead: line => {
                const [path, thumb] = line.split("|");
                if (!path)
                    return;
                root.pending.push({ path, thumb });
                if (root.items.length === 0 || root.pending.length % 4 === 0)
                    root.items = root.pending.slice();
            }
        }
        onExited: root.items = root.pending.slice()
    }

    Process {
        id: apply
        property string path
        command: ["sh", "-c", "awww img \"$1\" --transition-type grow --transition-pos 0.05,0.5 --transition-duration 1.2 --transition-fps 120; wal -n -q -i \"$1\"", "sh", path]
        onExited: root.applying = ""
    }

    function pick(path) {
        applying = path;
        apply.path = path;
        apply.running = true;
    }

    Rectangle {
        id: panel
        width: 310
        height: root.height - 2 * Math.round(root.height * 0.01)
        x: Math.round(root.screen.width * 0.005) + 33 + 10 + (root.open ? 0 : -20)
        y: Math.round(root.height * 0.01)
        opacity: root.open ? 1 : 0
        radius: 12
        color: Theme.background

        Behavior on x {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 250
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        Text {
            anchors.centerIn: parent
            visible: root.items.length === 0
            text: scan.running ? "Loading previews…" : "No images in " + root.dir
            color: Theme.mix(Theme.foreground, Theme.background, 0.5)
            font.family: Theme.font
            font.pixelSize: Theme.rem * 0.85
            font.bold: true
        }

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 8
            clip: true
            spacing: 0
            model: root.items
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: entry
                required property var modelData
                readonly property bool current: modelData.path === Theme.wallpaper
                width: list.width
                height: 208

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 6
                    color: "transparent"
                    border.width: entry.current || hover.hovered ? 3 : 0
                    border.color: entry.current ? Theme.color2 : Theme.mix(Theme.foreground, Theme.background, 0.5)
                    z: 2
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 4
                    clip: true
                    color: Theme.mix(Theme.background, Theme.foreground, 0.85)

                    Image {
                        anchors.fill: parent
                        source: "file://" + entry.modelData.thumb
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 600
                        sourceSize.height: 400
                        scale: hover.hovered ? 1.04 : 1

                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: root.applying === entry.modelData.path
                        color: Theme.alpha(Theme.background, 0.55)

                        Icon {
                            anchors.centerIn: parent
                            width: 28
                            height: 28
                            text: Icons.refresh
                            size: 22
                            color: Theme.foreground

                            RotationAnimation on rotation {
                                running: root.applying !== ""
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 1000
                            }
                        }
                    }
                }

                HoverHandler {
                    id: hover
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    onTapped: root.pick(entry.modelData.path)
                }
            }
        }
    }
}
