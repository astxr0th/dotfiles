import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.components

// Screenshot picker: freezes the screen, then lets you select a region, a
// window, or the whole screen. Saves to ~/Pictures/Screenshots and copies it.
PanelWindow {
    id: root

    readonly property bool wanted: Sys.panel === "screenshot"
    property bool ready: false            // frozen frame captured
    property string mode: "region"        // region | window | screen
    property var clients: []
    readonly property string frame: Quickshell.env("XDG_RUNTIME_DIR") + "/zenities-shot.png"
    readonly property string outDir: Quickshell.env("HOME") + "/Pictures/Screenshots"

    anchors {
        left: true
        top: true
        right: true
        bottom: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "zenities-screenshot"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "black"
    visible: wanted && ready

    onWantedChanged: {
        ready = false;
        sel.active = false;
        if (wanted)
            freezeDelay.restart();   // let other panels fade out first
    }

    function close() {
        Sys.panel = "";
    }

    Timer {
        id: freezeDelay
        interval: 300
        onTriggered: {
            freeze.running = true;
            clientsProc.running = true;
        }
    }

    Process {
        id: freeze
        command: ["grim", "-o", root.screen.name, root.frame]
        onExited: code => {
            if (code === 0) {
                frozen.source = "";
                frozen.source = "file://" + root.frame;
                root.ready = true;
            } else
                root.close();
        }
    }

    Process {
        id: clientsProc
        command: ["mmsg", "get", "all-clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.clients = JSON.parse(text).clients.filter(c => c.is_visible && !c.is_minimized && c.monitor === root.screen.name);
                } catch (e) {
                    root.clients = [];
                }
            }
        }
    }

    Process {
        id: save
        property string geometry
        property string file
        command: ["sh", "-c", "mkdir -p \"$(dirname \"$2\")\" && magick \"$3\" -crop \"$1\" +repage \"$2\" && wl-copy < \"$2\" && notify-send -a Screenshot -i \"$2\" \"Screenshot saved\" \"$(basename \"$2\") · copied to clipboard\"", "sh", geometry, file, root.frame]
    }

    // Crop the frozen frame (screen-local logical coords -> image pixels)
    function capture(x, y, w, h) {
        if (w < 4 || h < 4)
            return;
        const s = frozen.sourceSize.width > 0 ? frozen.sourceSize.width / root.width : 1;
        save.geometry = Math.round(w * s) + "x" + Math.round(h * s) + "+" + Math.round(x * s) + "+" + Math.round(y * s);
        save.file = root.outDir + "/" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".png";
        save.running = true;
        root.close();
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.close()
        Keys.onPressed: event => {
            if (event.key === Qt.Key_R)
                root.mode = "region";
            else if (event.key === Qt.Key_W)
                root.mode = "window";
            else if (event.key === Qt.Key_S || event.key === Qt.Key_Return)
                root.capture(0, 0, root.width, root.height);
        }

        Image {
            id: frozen
            anchors.fill: parent
            cache: false
            fillMode: Image.Stretch
        }

        // Dim everything except the selection / hovered window
        readonly property rect hole: root.mode === "region" && sel.active ? sel.rect : root.mode === "window" && winHover.target ? Qt.rect(winHover.target.x - root.screen.x, winHover.target.y - root.screen.y, winHover.target.width, winHover.target.height) : Qt.rect(0, 0, 0, 0)
        readonly property color dim: Qt.rgba(0, 0, 0, 0.45)

        Rectangle { x: 0; y: 0; width: parent.width; height: parent.hole.y; color: parent.dim }
        Rectangle { x: 0; y: parent.hole.y + parent.hole.height; width: parent.width; height: parent.height - y; color: parent.dim }
        Rectangle { x: 0; y: parent.hole.y; width: parent.hole.x; height: parent.hole.height; color: parent.dim }
        Rectangle { x: parent.hole.x + parent.hole.width; y: parent.hole.y; width: parent.width - x; height: parent.hole.height; color: parent.dim }

        // selection outline
        Rectangle {
            x: parent.hole.x - 2
            y: parent.hole.y - 2
            width: parent.hole.width + 4
            height: parent.hole.height + 4
            visible: parent.hole.width > 0
            color: "transparent"
            radius: root.mode === "window" ? 16 : 4
            border.width: 2
            border.color: Theme.color2

            Rectangle {
                anchors.top: parent.bottom
                anchors.topMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                width: sizeText.implicitWidth + 14
                height: 22
                radius: 6
                color: Theme.background

                Text {
                    id: sizeText
                    anchors.centerIn: parent
                    text: Math.round(parent.parent.width - 4) + " × " + Math.round(parent.parent.height - 4)
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.rem * 0.75
                    font.bold: true
                }
            }
        }

        // ---- Region: drag to select ----
        MouseArea {
            id: sel
            anchors.fill: parent
            enabled: root.mode === "region"
            cursorShape: Qt.CrossCursor
            property bool active: false
            property point start
            property rect rect

            onPressed: mouse => {
                start = Qt.point(mouse.x, mouse.y);
                rect = Qt.rect(mouse.x, mouse.y, 0, 0);
                active = true;
            }
            onPositionChanged: mouse => {
                if (!pressed)
                    return;
                rect = Qt.rect(Math.min(start.x, mouse.x), Math.min(start.y, mouse.y), Math.abs(mouse.x - start.x), Math.abs(mouse.y - start.y));
            }
            onReleased: {
                if (rect.width >= 4 && rect.height >= 4)
                    root.capture(rect.x, rect.y, rect.width, rect.height);
                else
                    active = false;
            }
        }

        // ---- Window: hover + click ----
        MouseArea {
            id: winHover
            anchors.fill: parent
            enabled: root.mode === "window"
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            property var target: null

            onPositionChanged: mouse => {
                const gx = mouse.x + root.screen.x, gy = mouse.y + root.screen.y;
                // floating windows first, they sit on top
                const sorted = root.clients.slice().sort((a, b) => b.is_floating - a.is_floating);
                target = sorted.find(c => gx >= c.x && gx < c.x + c.width && gy >= c.y && gy < c.y + c.height) ?? null;
            }
            onClicked: if (target)
                root.capture(target.x - root.screen.x, target.y - root.screen.y, target.width, target.height)
        }

        // ---- Toolbar ----
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 24
            width: bar.implicitWidth + 16
            height: 48
            radius: 12
            color: Theme.background
            opacity: sel.pressed ? 0.25 : 1

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            MouseArea {
                anchors.fill: parent
            }

            Row {
                id: bar
                anchors.centerIn: parent
                spacing: 6

                Repeater {
                    model: [
                        { mode: "region", icon: Icons.crop, label: "Region", key: "R" },
                        { mode: "window", icon: Icons.windowIcon, label: "Window", key: "W" },
                        { mode: "screen", icon: Icons.desktop, label: "Screen", key: "S" }
                    ]

                    Rectangle {
                        id: modeBtn
                        required property var modelData
                        readonly property bool current: root.mode === modelData.mode
                        width: modeRow.implicitWidth + 20
                        height: 34
                        radius: 8
                        color: current ? Theme.color2 : Theme.mix(Theme.background, Theme.color1, modeHover.hovered ? 0.8 : 0.9)

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        Row {
                            id: modeRow
                            anchors.centerIn: parent
                            spacing: 7

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16
                                height: 16
                                text: modeBtn.modelData.icon
                                size: 14
                                color: modeBtn.current ? Theme.background : Theme.foreground
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modeBtn.modelData.label
                                color: modeBtn.current ? Theme.background : Theme.foreground
                                font.family: Theme.font
                                font.pixelSize: Theme.rem * 0.85
                                font.bold: true
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modeBtn.modelData.key
                                color: modeBtn.current ? Theme.alpha(Theme.background, 0.6) : Theme.mix(Theme.foreground, Theme.background, 0.45)
                                font.family: Theme.font
                                font.pixelSize: Theme.rem * 0.7
                                font.bold: true
                            }
                        }

                        HoverHandler {
                            id: modeHover
                            cursorShape: Qt.PointingHandCursor
                        }
                        TapHandler {
                            onTapped: {
                                if (modeBtn.modelData.mode === "screen")
                                    root.capture(0, 0, root.width, root.height);
                                else
                                    root.mode = modeBtn.modelData.mode;
                            }
                        }
                    }
                }

                Rectangle {
                    width: 1
                    height: 24
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.mix(Theme.background, Theme.foreground, 0.8)
                }

                Btn {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 34
                    text: Icons.close
                    size: 14
                    color: Theme.mix(Theme.foreground, Theme.background, 0.6)
                    hoverColor: Theme.color1
                    onClicked: root.close()
                }
            }
        }

        // hint
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24
            width: hint.implicitWidth + 20
            height: 28
            radius: 8
            color: Theme.alpha(Theme.background, 0.85)
            visible: !sel.pressed

            Text {
                id: hint
                anchors.centerIn: parent
                text: root.mode === "region" ? "Drag to select an area · Esc to cancel" : "Click a window · Esc to cancel"
                color: Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.rem * 0.8
                font.bold: true
            }
        }
    }
}
