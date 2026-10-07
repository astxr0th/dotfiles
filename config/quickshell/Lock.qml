import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs
import qs.components

// Lock screen in zenities style. Uses ext-session-lock, so the compositor
// keeps the session locked even if the shell dies.
Scope {
    id: root

    property string buffer: ""
    property bool failed: false
    property bool checking: false

    function submit() {
        if (checking || buffer === "")
            return;
        checking = true;
        failed = false;
        pam.start();
    }

    Connections {
        target: Sys
        function onLockedChanged() {
            root.buffer = "";
            root.failed = false;
        }
    }

    PamContext {
        id: pam
        configDirectory: Quickshell.shellDir + "/pam"
        config: "password.conf"

        onPamMessage: {
            if (responseRequired)
                respond(root.buffer);
        }
        onCompleted: result => {
            root.checking = false;
            if (result === PamResult.Success) {
                Sys.locked = false;
            } else {
                root.failed = true;
                root.buffer = "";
            }
        }
        onError: {
            root.checking = false;
            root.failed = true;
            root.buffer = "";
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    WlSessionLock {
        locked: Sys.locked

        WlSessionLockSurface {
            id: surface
            color: Theme.background

            // Wallpaper, blurred and dimmed
            Image {
                id: wall
                anchors.fill: parent
                source: Theme.wallpaper ? "file://" + Theme.wallpaper : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }
            MultiEffect {
                anchors.fill: parent
                source: wall
                blurEnabled: true
                blur: 1
                blurMax: 48
                autoPaddingEnabled: false
            }
            Rectangle {
                anchors.fill: parent
                color: Theme.alpha(Theme.background, Theme.light ? 0.35 : 0.5)
            }

            // Fade in
            Item {
                id: content
                anchors.fill: parent
                opacity: 0
                Component.onCompleted: opacity = 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: 400
                    }
                }

                // ---- Card ----
                Rectangle {
                    id: card
                    anchors.centerIn: parent
                    width: 380
                    height: cardCol.implicitHeight + 48
                    radius: 12
                    color: Theme.background

                    SequentialAnimation {
                        id: shake
                        loops: 1
                        NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -12; duration: 50 }
                        NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 12; duration: 70 }
                        NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -8; duration: 70 }
                        NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 6; duration: 60 }
                        NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50 }
                    }
                    Connections {
                        target: root
                        function onFailedChanged() {
                            if (root.failed)
                                shake.restart();
                        }
                    }

                    Column {
                        id: cardCol
                        anchors.centerIn: parent
                        width: parent.width - 48
                        spacing: 16

                        Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 40
                            height: 40
                            text: Icons.artix
                            size: 38
                            color: Theme.foreground
                        }

                        // Stacked HH / mm like the sidebar clock
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 170
                            height: clockCol.implicitHeight + 16
                            radius: 12
                            color: Theme.mix(Theme.background, Theme.color6, 0.95)

                            Column {
                                id: clockCol
                                anchors.centerIn: parent
                                spacing: -18

                                Repeater {
                                    model: ["HH", "mm"]

                                    Text {
                                        required property string modelData
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: Qt.formatDateTime(clock.date, modelData)
                                        color: Theme.color6
                                        font.family: Theme.font
                                        font.pixelSize: 96
                                        font.bold: true
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                            color: Theme.color2
                            font.family: Theme.font
                            font.pixelSize: Theme.rem * 1.2
                            font.bold: true
                        }

                        // Password field
                        Rectangle {
                            width: parent.width
                            height: 46
                            radius: 10
                            color: Theme.mix(Theme.background, Theme.color1, 0.9)
                            border.width: root.failed || input.activeFocus ? 2 : 0
                            border.color: root.failed ? Theme.color1 : Theme.color2

                            Icon {
                                id: lockIcon
                                x: 14
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18
                                height: 18
                                text: root.checking ? Icons.refresh : Icons.lock
                                size: 15
                                color: root.failed ? Theme.color1 : Theme.mix(Theme.color6, Theme.foreground, 0.9)

                                RotationAnimation on rotation {
                                    running: root.checking
                                    loops: Animation.Infinite
                                    from: 0
                                    to: 360
                                    duration: 1000
                                    onRunningChanged: if (!running) lockIcon.rotation = 0
                                }
                            }

                            // dots
                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                visible: root.buffer.length > 0

                                Repeater {
                                    model: Math.min(root.buffer.length, 24)

                                    Rectangle {
                                        width: 9
                                        height: 9
                                        radius: 4.5
                                        color: Theme.foreground
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: root.buffer.length === 0
                                text: root.failed ? "Wrong password" : root.checking ? "Checking…" : "Enter password"
                                color: root.failed ? Theme.color1 : Theme.mix(Theme.foreground, Theme.background, 0.5)
                                font.family: Theme.font
                                font.pixelSize: Theme.rem
                                font.bold: true
                            }

                            TextInput {
                                id: input
                                anchors.fill: parent
                                opacity: 0
                                focus: true
                                echoMode: TextInput.Password
                                text: root.buffer
                                enabled: !root.checking
                                onTextEdited: {
                                    root.buffer = text;
                                    root.failed = false;
                                }
                                onAccepted: root.submit()
                                Keys.onEscapePressed: root.buffer = ""
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Quickshell.env("USER") + "@" + Sys.hostname
                            color: Theme.mix(Theme.foreground, Theme.background, 0.55)
                            font.family: Theme.font
                            font.pixelSize: Theme.rem * 0.85
                            font.bold: true
                        }
                    }
                }

                // ---- Bottom-left: now playing ----
                Rectangle {
                    x: 24
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 24
                    visible: Sys.hasMusic
                    width: 300
                    height: 64
                    radius: 12
                    color: Theme.background

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Rectangle {
                            width: 44
                            height: 44
                            radius: 6
                            clip: true
                            color: Theme.mix(Theme.background, Theme.foreground, 0.7)

                            Image {
                                anchors.fill: parent
                                source: Sys.artUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }
                        Column {
                            width: parent.width - 44 - 10 - 30
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: Sys.title
                                color: Theme.foreground
                                font.family: Theme.font
                                font.pixelSize: Theme.rem * 0.9
                                font.bold: true
                            }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: Sys.artist
                                color: Theme.color2
                                font.family: Theme.font
                                font.pixelSize: Theme.rem * 0.75
                                font.bold: true
                            }
                        }
                        Btn {
                            width: 20
                            height: 44
                            text: Sys.playing ? Icons.pause : Icons.play
                            onClicked: Sys.player?.togglePlaying()
                        }
                    }
                }

                // ---- Bottom-right: power ----
                Row {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 24
                    spacing: 8

                    Repeater {
                        model: [
                            { icon: Icons.suspend, tip: "Suspend", cmd: Sys.suspendCmd },
                            { icon: Icons.reboot, tip: "Reboot", cmd: Sys.rebootCmd },
                            { icon: Icons.power, tip: "Power Off", cmd: Sys.shutdownCmd }
                        ]

                        Rectangle {
                            id: pwr
                            required property var modelData
                            width: 44
                            height: 44
                            radius: 10
                            color: Theme.mix(Theme.background, Theme.color1, pwrBtn.hovered ? 0.8 : 1)

                            Btn {
                                id: pwrBtn
                                anchors.fill: parent
                                text: pwr.modelData.icon
                                size: 17
                                color: Theme.mix(Theme.color6, Theme.foreground, 0.9)
                                onClicked: Sys.run(pwr.modelData.cmd)
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            Sys.lock();
        }
    }
}
