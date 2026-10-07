import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs
import qs.components

// wiremix-style mixer: Playback / Recording / Outputs / Inputs, with live
// peak meters, per-stream volume + mute, and default device selection.
Overlay {
    id: root

    name: "mixer"

    property string tab: "playback"

    readonly property var nodes: Pipewire.nodes.values.filter(n => n.audio)
    readonly property var shown: {
        switch (tab) {
        case "playback":
            return nodes.filter(n => n.isStream && n.isSink);
        case "recording":
            return nodes.filter(n => n.isStream && !n.isSink);
        case "outputs":
            return nodes.filter(n => !n.isStream && n.isSink);
        default:
            return nodes.filter(n => !n.isStream && !n.isSink);
        }
    }

    PwObjectTracker {
        objects: root.open ? root.shown : []
    }

    function title(n) {
        const p = n.properties ?? {};
        if (n.isStream)
            return p["application.name"] || n.description || n.name;
        return n.description || n.nickname || n.name;
    }
    function subtitle(n) {
        const p = n.properties ?? {};
        if (n.isStream)
            return p["media.name"] || "";
        return p["device.profile.description"] || p["api.alsa.pcm.card_name"] || "";
    }
    function iconFor(n) {
        const p = n.properties ?? {};
        const name = p["application.icon-name"] || p["application.process.binary"] || "";
        return name ? Quickshell.iconPath(name.toLowerCase(), true) : "";
    }

    Rectangle {
        id: panel
        width: 340
        height: Math.min(460, col.implicitHeight + 24)
        x: Math.round(root.screen.width * 0.005) + 33 + 10 + (root.open ? 0 : -16)
        y: root.height - height - Math.round(root.height * 0.01)
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
        Behavior on height {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Tabs (wiremix style: underlined text tabs)
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: [
                        { id: "playback", label: "Playback" },
                        { id: "recording", label: "Recording" },
                        { id: "outputs", label: "Outputs" },
                        { id: "inputs", label: "Inputs" }
                    ]

                    Item {
                        id: tabItem
                        required property var modelData
                        readonly property bool current: root.tab === modelData.id
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26

                        Text {
                            anchors.centerIn: parent
                            text: tabItem.modelData.label
                            color: tabItem.current ? Theme.color2 : Theme.mix(Theme.foreground, Theme.background, 0.55)
                            font.family: Theme.font
                            font.pixelSize: Theme.rem * 0.85
                            font.bold: true
                        }
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: tabItem.current ? parent.width - 12 : 0
                            height: 2
                            radius: 1
                            color: Theme.color2

                            Behavior on width {
                                NumberAnimation {
                                    duration: 200
                                }
                            }
                        }
                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                        }
                        TapHandler {
                            onTapped: root.tab = tabItem.modelData.id
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                visible: root.shown.length === 0
                horizontalAlignment: Text.AlignHCenter
                text: root.tab === "playback" ? "Nothing is playing" : root.tab === "recording" ? "Nothing is recording" : "No devices"
                color: Theme.mix(Theme.foreground, Theme.background, 0.5)
                font.family: Theme.font
                font.pixelSize: Theme.rem * 0.85
                font.bold: true
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: contentHeight
                visible: root.shown.length > 0
                clip: true
                spacing: 6
                model: root.shown

                delegate: Rectangle {
                    id: item
                    required property var modelData
                    readonly property bool isDefault: modelData === (modelData.isSink ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource)
                    readonly property bool muted: modelData.audio?.muted ?? false
                    readonly property int vol: Math.round((modelData.audio?.volume ?? 0) * 100)

                    width: list.width
                    implicitHeight: itemCol.implicitHeight + 16
                    radius: 10
                    color: isDefault && !modelData.isStream ? Theme.mix(Theme.background, Theme.color2, 0.85) : Theme.mix(Theme.background, Theme.color1, 0.93)

                    PwNodePeakMonitor {
                        id: peak
                        node: item.modelData
                        enabled: root.open
                    }

                    ColumnLayout {
                        id: itemCol
                        x: 8
                        y: 8
                        width: parent.width - 16
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            // app icon, falls back to a glyph
                            Item {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20

                                IconImage {
                                    id: appIcon
                                    anchors.fill: parent
                                    source: root.iconFor(item.modelData)
                                    visible: source != "" && status === Image.Ready
                                }
                                Icon {
                                    anchors.fill: parent
                                    visible: !appIcon.visible
                                    size: 14
                                    text: item.modelData.isStream ? (item.modelData.isSink ? Icons.music : Icons.mic) : item.modelData.isSink ? Icons.speaker : Icons.mic
                                    color: Theme.mix(Theme.color5, Theme.foreground, 0.9)
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: root.title(item.modelData)
                                    elide: Text.ElideRight
                                    color: Theme.foreground
                                    font.family: Theme.font
                                    font.pixelSize: Theme.rem * 0.85
                                    font.bold: true
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                    text: root.subtitle(item.modelData)
                                    elide: Text.ElideRight
                                    color: Theme.mix(Theme.foreground, Theme.background, 0.5)
                                    font.family: Theme.font
                                    font.pixelSize: Theme.rem * 0.7
                                    font.bold: true
                                }
                            }

                            // default device selector
                            Btn {
                                Layout.preferredWidth: 18
                                Layout.preferredHeight: 18
                                visible: !item.modelData.isStream
                                text: item.isDefault ? Icons.check : Icons.circleO
                                size: 12
                                tip: item.isDefault ? "Default" : "Set as default"
                                tipRight: false
                                color: item.isDefault ? Theme.color2 : Theme.mix(Theme.foreground, Theme.background, 0.5)
                                onClicked: {
                                    if (item.modelData.isSink)
                                        Pipewire.preferredDefaultAudioSink = item.modelData;
                                    else
                                        Pipewire.preferredDefaultAudioSource = item.modelData;
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Btn {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 16
                                text: item.muted ? Icons.volMute : (item.modelData.isSink ? Icons.volHigh : Icons.mic)
                                size: 13
                                color: item.muted ? Theme.color1 : Theme.mix(Theme.color5, Theme.foreground, 0.9)
                                onClicked: if (item.modelData.audio) item.modelData.audio.muted = !item.muted
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                Slider {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 10
                                    thickness: 6
                                    value: Math.min(100, item.vol)
                                    fillColor: item.muted ? Theme.mix(Theme.background, Theme.foreground, 0.6) : Theme.mix(Theme.color5, Theme.foreground, 0.9)
                                    onMoved: v => {
                                        if (item.modelData.audio)
                                            item.modelData.audio.volume = v / 100;
                                    }
                                }

                                // peak meter
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 3
                                    radius: 1.5
                                    color: Theme.mix(Theme.background, Theme.foreground, 0.88)

                                    Rectangle {
                                        height: parent.height
                                        radius: 1.5
                                        width: parent.width * Math.min(1, item.muted ? 0 : peak.peak)
                                        color: peak.peak > 0.9 ? Theme.color1 : Theme.color2

                                        Behavior on width {
                                            NumberAnimation {
                                                duration: 60
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.preferredWidth: 34
                                horizontalAlignment: Text.AlignRight
                                text: item.vol + "%"
                                color: Theme.foreground
                                font.family: Theme.font
                                font.pixelSize: Theme.rem * 0.75
                                font.bold: true
                            }
                        }
                    }
                }
            }
        }
    }
}
