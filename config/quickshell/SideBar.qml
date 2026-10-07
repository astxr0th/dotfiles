import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.components

// zenities' eww side-bar, ported to Quickshell.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    readonly property real inner: 25   // content column width (33px bar - 2*4px padding)

    anchors {
        left: true
        top: true
        bottom: true
    }
    margins {
        left: Math.round(screen.width * 0.005)
        top: Math.round(screen.height * 0.01)
        bottom: Math.round(screen.height * 0.01)
    }
    implicitWidth: inner + 8
    exclusiveZone: implicitWidth
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "zenities-sidebar"
    color: "transparent"

    IdleInhibitor {
        window: bar
        enabled: Sys.idleInhibited
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.background

        // ---------- Top: launcher + power menu + workspaces ----------
        Column {
            id: top
            x: 4
            y: 4
            width: bar.inner

            Item {
                id: launcher
                width: parent.width
                implicitHeight: launcherCol.implicitHeight

                HoverHandler {
                    id: launcherHover
                }

                Column {
                    id: launcherCol
                    width: parent.width

                    Btn {
                        width: parent.width
                        height: 26
                        text: Icons.artix
                        size: Theme.rem * 1.22
                        color: Theme.foreground
                        hoverColor: Theme.mix(Theme.background, Theme.foreground, 0.95)
                        onClicked: Sys.toggle("launcher")
                    }

                    Reveal {
                        reveal: launcherHover.hovered
                        transition: "slideup"

                        Column {
                            width: bar.inner
                            topPadding: 2
                            bottomPadding: 4
                            spacing: 4

                            Repeater {
                                model: [
                                    { icon: Icons.power, tip: "Power Off", cmd: Sys.shutdownCmd },
                                    { icon: Icons.lock, tip: "Lock", cmd: "@lock" },
                                    { icon: Icons.reboot, tip: "Reboot", cmd: Sys.rebootCmd },
                                    { icon: Icons.suspend, tip: "Suspend", cmd: Sys.suspendCmd },
                                    { icon: Icons.exit, tip: "Exit mango", cmd: Sys.exitCmd }
                                ]

                                Btn {
                                    required property var modelData
                                    width: bar.inner
                                    height: 18
                                    text: modelData.icon
                                    tip: modelData.tip
                                    color: Theme.mix(Theme.color6, Theme.background, 0.95)
                                    hoverColor: Theme.mix(Theme.background, Theme.color6, 0.65)
                                    onClicked: modelData.cmd === "@lock" ? Sys.lock() : Sys.run(modelData.cmd)
                                }
                            }
                        }
                    }
                }
            }

            // Workspaces (mango tags)
            Column {
                width: parent.width
                bottomPadding: 12

                Repeater {
                    model: Sys.tagsFor(bar.screen.name)

                    Btn {
                        required property var modelData
                        width: bar.inner
                        height: 16
                        size: Theme.rem * 0.75
                        weight: Font.Black
                        text: modelData.is_active ? Icons.wsActive : Icons.wsInactive
                        color: modelData.is_active ? Theme.color2 : Theme.color3
                        hoverColor: Theme.mix(Theme.foreground, Theme.color2, 0.7)
                        onClicked: Sys.viewTag(modelData.index)
                    }
                }

                WheelHandler {
                    onWheel: event => Sys.run("mmsg dispatch " + (event.angleDelta.y > 0 ? "viewtoleft" : "viewtoright") + ",0")
                }
            }
        }

        // ---------- Middle: vertical music ----------
        Reveal {
            id: musicReveal
            x: 4
            anchors.verticalCenter: parent.verticalCenter
            reveal: Sys.hasMusic
            transition: "slidedown"
            duration: 500

            Item {
                width: bar.inner
                implicitHeight: musicCol.implicitHeight

                HoverHandler {
                    id: musicHover
                    cursorShape: Qt.PointingHandCursor
                }

                Column {
                    id: musicCol
                    width: parent.width

                    Reveal {
                        reveal: musicHover.hovered
                        transition: "slideup"

                        Column {
                            width: bar.inner
                            topPadding: 4
                            bottomPadding: 4
                            spacing: 8

                            Btn {
                                width: bar.inner
                                height: 10
                                size: Theme.rem * 0.6
                                text: Icons.prev
                                onClicked: Sys.player?.previous()
                            }
                            Btn {
                                width: bar.inner
                                height: 10
                                size: Theme.rem * 0.6
                                text: Sys.playing ? Icons.pause : Icons.play
                                onClicked: Sys.player?.togglePlaying()
                            }
                            Btn {
                                width: bar.inner
                                height: 10
                                size: Theme.rem * 0.6
                                text: Icons.next
                                onClicked: Sys.player?.next()
                            }
                        }
                    }

                    // rotated title + vertical seek bar
                    Item {
                        width: bar.inner
                        height: 80

                        Text {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: -5
                            rotation: -90
                            width: 80
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: Sys.title.length > 8 ? Sys.title.slice(0, 8) + "…" : Sys.title
                            color: Theme.foreground
                            font.family: Theme.font
                            font.pixelSize: Theme.rem * 0.6
                            font.bold: true
                        }

                        Slider {
                            x: parent.width / 2 + 3
                            width: 3
                            height: parent.height
                            vertical: true
                            thickness: 3
                            radius: 2
                            fillColor: Theme.mix(Theme.color6, Theme.foreground, 0.9)
                            value: Sys.seek
                            onMoved: v => Sys.setSeek(v)
                        }
                    }

                    Item {
                        width: bar.inner
                        height: 25 + 16

                        ClippingRectangle {
                            anchors.centerIn: parent
                            width: 20
                            height: 25
                            radius: 4
                            color: Theme.mix(Theme.background, Theme.foreground, 0.7)

                            Image {
                                anchors.fill: parent
                                source: Sys.artUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 64
                                sourceSize.height: 64
                            }
                        }
                    }
                }
            }
        }

        // ---------- Bottom: tray, device, resources, clock ----------
        Column {
            x: 4
            width: bar.inner
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            spacing: 4

            // System tray
            Group {
                width: parent.width
                visible: SystemTray.items.values.length > 0

                Repeater {
                    model: SystemTray.items

                    Item {
                        id: trayItem
                        required property SystemTrayItem modelData
                        width: bar.inner
                        height: 24

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 16
                            source: {
                                const icon = trayItem.modelData.icon;
                                // Some apps send "name?path=/dir"; resolve to a file
                                if (icon.includes("?path=")) {
                                    const [name, path] = icon.split("?path=");
                                    return "file://" + path + "/" + name.slice(name.lastIndexOf("/") + 1);
                                }
                                return icon;
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                const item = trayItem.modelData;
                                if (mouse.button === Qt.MiddleButton)
                                    item.secondaryActivate();
                                else if (mouse.button === Qt.RightButton || item.onlyMenu) {
                                    if (item.hasMenu) {
                                        const p = trayItem.mapToItem(null, trayItem.width + 8, 0);
                                        item.display(bar, p.x, p.y);
                                    }
                                } else
                                    item.activate();
                            }
                            onWheel: wheel => trayItem.modelData.scroll(wheel.angleDelta.y, false)
                        }

                        HoverHandler {
                            id: trayHover
                        }

                        Tip {
                            text: trayItem.modelData.tooltipTitle || trayItem.modelData.title || trayItem.modelData.id
                            show: trayHover.hovered
                        }
                    }
                }
            }

            // Device: recorder, idle, wifi, volume, brightness
            Group {
                width: parent.width

                // only while recording or instant replay is on
                Btn {
                    id: recBtn
                    width: bar.inner
                    height: 24
                    visible: Gsr.recording || Gsr.replaying
                    size: Gsr.recording ? Theme.rem * 0.75 : Theme.rem * 0.95
                    text: Gsr.recording ? Icons.circle : Icons.replay
                    tip: Gsr.paused ? "Paused " + Gsr.elapsedText : Gsr.recording ? "Recording " + Gsr.elapsedText : "Instant replay on · right-click to save"
                    color: Gsr.recording ? Theme.color1 : Theme.mix(Theme.color2, Theme.foreground, 0.9)
                    onClicked: Sys.toggle("recorder")
                    onRightClicked: Gsr.recording ? Gsr.stopRecord() : Gsr.saveReplay(0)

                    SequentialAnimation on opacity {
                        running: Gsr.recording && !Gsr.paused
                        loops: Animation.Infinite
                        onRunningChanged: if (!running)
                            recBtn.opacity = 1
                        NumberAnimation {
                            to: 0.35
                            duration: 700
                        }
                        NumberAnimation {
                            to: 1
                            duration: 700
                        }
                    }
                }

                Btn {
                    width: bar.inner
                    height: 24
                    size: Theme.rem * 0.9
                    text: Sys.idleInhibited ? Icons.eyeSlash : Icons.eye
                    tip: Sys.idleInhibited ? "idle disabled" : "idle enabled"
                    color: Theme.mix(Theme.color2, Theme.foreground, 0.9)
                    onClicked: Sys.idleInhibited = !Sys.idleInhibited
                }

                Btn {
                    id: netBtn
                    width: bar.inner
                    height: 24
                    text: Sys.netIcon
                    tip: "Connected to " + Sys.netName
                    color: Theme.mix(Theme.color2, Theme.foreground, 0.9)
                    onClicked: Sys.openNetwork("wifi")
                    onRightClicked: Sys.openNetwork("bluetooth")
                }

                Item {
                    width: bar.inner
                    implicitHeight: volCol.implicitHeight

                    HoverHandler {
                        id: volHover
                    }

                    Column {
                        id: volCol
                        width: parent.width

                        Reveal {
                            reveal: volHover.hovered
                            transition: "slideup"

                            Item {
                                width: bar.inner
                                height: 38

                                Slider {
                                    anchors.centerIn: parent
                                    width: 8
                                    height: 30
                                    vertical: true
                                    fillColor: Theme.mix(Theme.color5, Theme.foreground, 0.9)
                                    value: Sys.volume
                                    onMoved: v => Sys.setVolume(v)
                                }
                            }
                        }

                        Btn {
                            width: bar.inner
                            height: 24
                            text: Sys.volumeIcon
                            tip: "Volume: " + Sys.volume + "%"
                            color: Theme.mix(Theme.color5, Theme.foreground, 0.9)
                            onClicked: Sys.toggle("mixer")
                            onRightClicked: if (Sys.sink?.audio) Sys.sink.audio.muted = !Sys.sink.audio.muted
                            onScrolled: d => Sys.setVolume(Sys.volume + (d > 0 ? 5 : -5))
                        }
                    }
                }

                Item {
                    width: bar.inner
                    visible: Sys.hasBacklight
                    implicitHeight: briCol.implicitHeight

                    HoverHandler {
                        id: briHover
                    }

                    Column {
                        id: briCol
                        width: parent.width

                        Reveal {
                            reveal: briHover.hovered
                            transition: "slideup"

                            Item {
                                width: bar.inner
                                height: 38

                                Slider {
                                    anchors.centerIn: parent
                                    width: 8
                                    height: 30
                                    vertical: true
                                    fillColor: Theme.mix(Theme.color6, Theme.foreground, 0.9)
                                    value: Sys.brightness
                                    onMoved: v => Sys.setBrightness(v)
                                }
                            }
                        }

                        Btn {
                            width: bar.inner
                            height: 24
                            text: Icons.brightness
                            tip: "Brightness: " + Sys.brightness + "%"
                            color: Theme.mix(Theme.color6, Theme.foreground, 0.9)
                            onScrolled: d => Sys.setBrightness(Sys.brightness + (d > 0 ? 5 : -5))
                        }
                    }
                }
            }

            // Resources: memory + battery rings
            Group {
                width: parent.width

                Repeater {
                    model: [
                        { kind: "memory" },
                        { kind: "battery" }
                    ]

                    Item {
                        id: res
                        required property var modelData
                        readonly property bool isMem: modelData.kind === "memory"
                        readonly property int value: isMem ? Sys.memory : Sys.battery
                        width: bar.inner
                        visible: isMem || Sys.hasBattery
                        implicitHeight: resCol.implicitHeight

                        HoverHandler {
                            id: resHover
                        }

                        Column {
                            id: resCol
                            width: parent.width
                            topPadding: 4
                            bottomPadding: 4

                            Reveal {
                                reveal: resHover.hovered
                                transition: "slideup"

                                Text {
                                    width: bar.inner
                                    height: 18
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: res.value
                                    color: Theme.mix(Theme.color3, Theme.foreground, 0.9)
                                    font.family: Theme.font
                                    font.pixelSize: Theme.rem
                                    font.bold: true
                                }
                            }

                            Item {
                                width: bar.inner
                                height: 22

                                Ring {
                                    anchors.centerIn: parent
                                    width: 15
                                    height: 15
                                    value: res.value
                                }
                            }
                        }

                        Tip {
                            text: res.isMem ? "memory used: " + Sys.memory + "%" : Sys.timeLeft
                            show: resHover.hovered
                        }
                    }
                }
            }

            // Clock — opens the control / notification center
            Group {
                id: clockGroup
                width: parent.width
                color: clockHover.hovered || Sys.panel === "center" ? Theme.mix(Theme.background, Theme.color6, 0.85) : Theme.mix(Theme.background, Theme.color6, 0.95)

                Behavior on color {
                    ColorAnimation {
                        duration: 300
                    }
                }

                HoverHandler {
                    id: clockHover
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    onTapped: Sys.toggle("center")
                }

                // unread notifications dot
                Rectangle {
                    parent: clockGroup
                    x: clockGroup.width - 9
                    y: 3
                    width: 6
                    height: 6
                    radius: 3
                    color: Theme.color1
                    visible: Notifs.unread > 0
                }

                Repeater {
                    model: ["HH", "mm"]

                    Text {
                        required property string modelData
                        width: bar.inner
                        height: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: Qt.formatDateTime(clock.date, modelData)
                        color: Theme.color6
                        font.family: Theme.font
                        font.pixelSize: Theme.rem
                        font.bold: true
                    }
                }
            }
        }
    }

    // Tell the internet center where the wifi icon is so it opens beside it
    function updateNetIconY() {
        if (bar.screen !== Quickshell.screens[0])
            return;
        Sys.netIconY = bar.margins.top + netBtn.mapToItem(null, 0, netBtn.height / 2).y;
    }
    Connections {
        target: Sys
        function onPanelChanged() {
            if (Sys.panel === "network")
                bar.updateNetIconY();
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
