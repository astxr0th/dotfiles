import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.components

// Screen recorder toolbar (replaces gsr-ui's overlay). Sits at the top of the
// screen like the screenshot tool; settings drop down beneath it.
// Backend lives in Gsr.qml.
Overlay {
    id: root

    name: "recorder"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool showSettings: false

    onOpenChanged: {
        if (open) {
            Gsr.refreshDevices();
            keys.forceActiveFocus();
        } else
            showSettings = false;
    }

    function close() {
        Sys.panel = "";
    }

    // Region needs the panel gone before slurp grabs the screen
    function recordRegion() {
        close();
        regionDelay.restart();
    }
    Timer {
        id: regionDelay
        interval: 300
        onTriggered: Gsr.startRecord(true)
    }

    readonly property color tile: Theme.mix(Theme.background, Theme.color1, 0.93)
    readonly property color muted: Theme.mix(Theme.foreground, Theme.background, 0.55)

    component SectionTitle: Text {
        color: Theme.color1
        font.family: Theme.font
        font.pixelSize: 13
        font.bold: true
    }

    component Muted: Text {
        color: root.muted
        font.family: Theme.font
        font.pixelSize: Theme.rem * 0.62
        font.bold: true
        elide: Text.ElideRight
    }

    component Pill: Rectangle {
        id: pill
        property string label
        property string icon: ""
        property bool primary: false
        property bool danger: false
        signal clicked
        implicitWidth: pillRow.implicitWidth + 16
        implicitHeight: 24
        radius: 7
        color: danger ? (pillHover.hovered ? Theme.lighten(Theme.color1, 0.08) : Theme.color1) : primary ? (pillHover.hovered ? Theme.lighten(Theme.color2, 0.08) : Theme.color2) : Theme.mix(Theme.background, Theme.color1, pillHover.hovered ? 0.7 : 0.85)

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 5

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: pill.icon !== ""
                width: 11
                height: 11
                text: pill.icon
                size: 10
                color: pill.primary || pill.danger ? Theme.background : Theme.foreground
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: pill.label
                color: pill.primary || pill.danger ? Theme.background : Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.rem * 0.7
                font.bold: true
            }
        }
        HoverHandler {
            id: pillHover
            cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
            onTapped: pill.clicked()
        }
    }

    // Selectable option chip
    component Chip: Rectangle {
        id: chip
        property string label
        property bool selected: false
        signal clicked
        implicitWidth: chipText.implicitWidth + 14
        implicitHeight: 22
        radius: 7
        color: selected ? Theme.color2 : Theme.mix(Theme.background, Theme.color1, chipHover.hovered ? 0.8 : 0.9)

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        Text {
            id: chipText
            anchors.centerIn: parent
            text: chip.label
            color: chip.selected ? Theme.background : Theme.foreground
            font.family: Theme.font
            font.pixelSize: Theme.rem * 0.68
            font.bold: true
        }
        HoverHandler {
            id: chipHover
            cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
            onTapped: chip.clicked()
        }
    }

    // Label on the left, chips flowing on the right
    component Setting: RowLayout {
        id: setting
        property string label
        default property alias chips: flow.data
        Layout.fillWidth: true
        spacing: 8

        Muted {
            Layout.preferredWidth: 62
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 5
            text: setting.label
            font.pixelSize: Theme.rem * 0.68
        }
        Flow {
            id: flow
            Layout.fillWidth: true
            spacing: 4
        }
    }

    component SwitchRow: RowLayout {
        id: sw
        property string label
        property bool checked
        signal toggled
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: sw.label
            color: Theme.foreground
            font.family: Theme.font
            font.pixelSize: Theme.rem * 0.72
            font.bold: true
            elide: Text.ElideRight
        }
        Toggle {
            implicitWidth: 30
            implicitHeight: 17
            checked: sw.checked
            onToggled: sw.toggled()
        }
    }

    // Toolbar button, same look as the screenshot tool's mode buttons
    component ToolBtn: Rectangle {
        id: tb
        property string icon
        property string label
        property string key: ""
        property bool active: false
        property color accent: Theme.color2
        signal clicked
        width: tbRow.implicitWidth + 20
        height: 34
        radius: 8
        color: active ? accent : Theme.mix(Theme.background, Theme.color1, tbHover.hovered ? 0.8 : 0.9)

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        Row {
            id: tbRow
            anchors.centerIn: parent
            spacing: 7

            Icon {
                id: tbIcon
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 16
                text: tb.icon
                size: 14
                color: tb.active ? Theme.background : Theme.foreground
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: tb.label !== ""
                text: tb.label
                color: tb.active ? Theme.background : Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.rem * 0.85
                font.bold: true
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: tb.key !== ""
                text: tb.key
                color: tb.active ? Theme.alpha(Theme.background, 0.6) : Theme.mix(Theme.foreground, Theme.background, 0.45)
                font.family: Theme.font
                font.pixelSize: Theme.rem * 0.7
                font.bold: true
            }
        }

        HoverHandler {
            id: tbHover
            cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
            onTapped: tb.clicked()
        }
    }

    component Divider: Rectangle {
        width: 1
        height: 24
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.mix(Theme.background, Theme.foreground, 0.8)
    }

    Column {
        id: stack
        anchors.horizontalCenter: parent.horizontalCenter
        y: 24
        spacing: 8
        opacity: root.open ? 1 : 0

        transform: Translate {
            y: root.open ? 0 : -12

            Behavior on y {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        // keyboard shortcuts while the toolbar is open
        Item {
            id: keys
            width: 0
            height: 0
            focus: true
            Keys.onEscapePressed: root.close()
            Keys.onPressed: event => {
                if (event.key === Qt.Key_R)
                    Gsr.toggleRecord(false);
                else if (event.key === Qt.Key_G && !Gsr.recording)
                    root.recordRegion();
                else if (event.key === Qt.Key_P)
                    Gsr.togglePause();
                else if (event.key === Qt.Key_I)
                    Gsr.toggleReplay();
                else if (event.key === Qt.Key_S)
                    Gsr.saveReplay(0);
            }
        }

        // ---- Toolbar ----
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: bar.implicitWidth + 16
            height: 48
            radius: 12
            color: Theme.background

            MouseArea {
                anchors.fill: parent
            }

            Row {
                id: bar
                anchors.centerIn: parent
                spacing: 6

                ToolBtn {
                    icon: Icons.replay
                    label: "Replay"
                    key: "I"
                    active: Gsr.replaying
                    onClicked: Gsr.toggleReplay()
                }
                ToolBtn {
                    visible: Gsr.replaying
                    icon: Icons.save
                    label: "Save"
                    key: "S"
                    onClicked: Gsr.saveReplay(0)
                }

                Divider {}

                ToolBtn {
                    icon: Gsr.recording ? Icons.stop : Icons.circle
                    label: Gsr.recording ? Gsr.elapsedText : "Record"
                    key: "R"
                    active: Gsr.recording
                    accent: Theme.color1
                    onClicked: Gsr.toggleRecord(false)
                }
                ToolBtn {
                    visible: Gsr.canPause
                    icon: Gsr.paused ? Icons.play : Icons.pause
                    label: Gsr.paused ? "Resume" : "Pause"
                    key: "P"
                    active: Gsr.paused
                    onClicked: Gsr.togglePause()
                }
                ToolBtn {
                    visible: !Gsr.recording
                    icon: Icons.region
                    label: "Region"
                    key: "G"
                    onClicked: root.recordRegion()
                }

                Divider {}

                ToolBtn {
                    icon: Icons.cog
                    label: ""
                    active: root.showSettings
                    onClicked: root.showSettings = !root.showSettings
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

        // ---- Replay strip: save a clip of a given length / stale settings ----
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Gsr.replaying
            width: strip.implicitWidth + 20
            height: 34
            radius: 10
            color: Theme.background

            MouseArea {
                anchors.fill: parent
            }

            Row {
                id: strip
                anchors.centerIn: parent
                spacing: 4

                Muted {
                    anchors.verticalCenter: parent.verticalCenter
                    rightPadding: 4
                    text: "save last"
                    font.pixelSize: Theme.rem * 0.7
                }
                Repeater {
                    model: [10, 30, 60, 300, 600, 1800].filter(s => s <= Gsr.settings.replaySeconds)

                    Chip {
                        required property int modelData
                        anchors.verticalCenter: parent.verticalCenter
                        label: modelData >= 60 ? modelData / 60 + "m" : modelData + "s"
                        onClicked: Gsr.saveReplay(modelData)
                    }
                }
                Item {
                    visible: Gsr.replayStale
                    width: 8
                    height: 1
                }
                Pill {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Gsr.replayStale
                    icon: Icons.refresh
                    label: "Apply settings"
                    primary: true
                    onClicked: Gsr.restartReplay()
                }
            }
        }

        // ---- Settings dropdown ----
        Rectangle {
            id: settingsCard
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.showSettings
            width: 380
            height: Math.min(root.height - y - 48, settingsCol.implicitHeight + 24)
            radius: 12
            color: Theme.background
            clip: true

            MouseArea {
                anchors.fill: parent
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: 12
                contentHeight: settingsCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                ColumnLayout {
                    id: settingsCol
                    width: parent.width
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Setting {
                            label: "Source"
                            Repeater {
                                model: Gsr.sources
                                Chip {
                                    required property var modelData
                                    label: modelData.label
                                    selected: Gsr.captureSource() === modelData.id
                                    onClicked: Gsr.set("source", modelData.id)
                                }
                            }
                        }

                        Setting {
                            label: "FPS"
                            Repeater {
                                model: [30, 60, 120, 144, 240]
                                Chip {
                                    required property int modelData
                                    label: modelData
                                    selected: Gsr.settings.fps === modelData
                                    onClicked: Gsr.set("fps", modelData)
                                }
                            }
                        }

                        Setting {
                            label: "Quality"
                            Repeater {
                                model: [
                                    { id: "medium", label: "Medium" },
                                    { id: "high", label: "High" },
                                    { id: "very_high", label: "Very high" },
                                    { id: "ultra", label: "Ultra" },
                                    { id: "cbr", label: "Bitrate" }
                                ]
                                Chip {
                                    required property var modelData
                                    label: modelData.label
                                    selected: Gsr.settings.quality === modelData.id
                                    onClicked: Gsr.set("quality", modelData.id)
                                }
                            }
                        }

                        Setting {
                            label: "Bitrate"
                            visible: Gsr.settings.quality === "cbr"
                            Repeater {
                                model: [8000, 15000, 25000, 40000, 60000, 80000]
                                Chip {
                                    required property int modelData
                                    label: modelData / 1000 + " Mb/s"
                                    selected: Gsr.settings.bitrate === modelData
                                    onClicked: Gsr.set("bitrate", modelData)
                                }
                            }
                        }

                        Setting {
                            label: "Codec"
                            Repeater {
                                model: ["auto", "h264", "hevc", "av1"]
                                Chip {
                                    required property string modelData
                                    label: modelData
                                    selected: Gsr.settings.codec === modelData
                                    onClicked: Gsr.set("codec", modelData)
                                }
                            }
                        }

                        Setting {
                            label: "Format"
                            Repeater {
                                model: ["mp4", "mkv"]
                                Chip {
                                    required property string modelData
                                    label: modelData
                                    selected: Gsr.settings.container === modelData
                                    onClicked: Gsr.set("container", modelData)
                                }
                            }
                        }

                        Setting {
                            label: "Replay"
                            Repeater {
                                model: [30, 60, 120, 300, 600, 1800]
                                Chip {
                                    required property int modelData
                                    label: modelData >= 60 ? modelData / 60 + " min" : modelData + " s"
                                    selected: Gsr.settings.replaySeconds === modelData
                                    onClicked: Gsr.set("replaySeconds", modelData)
                                }
                            }
                        }

                        Setting {
                            label: "Buffer"
                            Repeater {
                                model: [
                                    { id: "ram", label: "RAM" },
                                    { id: "disk", label: "Disk" }
                                ]
                                Chip {
                                    required property var modelData
                                    label: modelData.label
                                    selected: Gsr.settings.replayStorage === modelData.id
                                    onClicked: Gsr.set("replayStorage", modelData.id)
                                }
                            }
                        }

                        // ---- Audio ----
                        SectionTitle {
                            Layout.topMargin: 4
                            text: "Audio"
                        }
                        Repeater {
                            model: Gsr.audioDevices

                            RowLayout {
                                id: dev
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    radius: 6
                                    color: Gsr.audioOn(dev.modelData.id) ? Theme.color2 : Theme.mix(Theme.background, Theme.color1, 0.85)

                                    Icon {
                                        anchors.fill: parent
                                        text: dev.modelData.input ? Icons.mic : Icons.volHigh
                                        size: 11
                                        color: Gsr.audioOn(dev.modelData.id) ? Theme.background : Theme.foreground
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: dev.modelData.label
                                    color: Theme.foreground
                                    font.family: Theme.font
                                    font.pixelSize: Theme.rem * 0.7
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Toggle {
                                    implicitWidth: 30
                                    implicitHeight: 17
                                    checked: Gsr.audioOn(dev.modelData.id)
                                    onToggled: Gsr.setAudio(dev.modelData.id, !checked)
                                }
                            }
                        }

                        // ---- General ----
                        SectionTitle {
                            Layout.topMargin: 4
                            text: "General"
                        }
                        SwitchRow {
                            label: "Record cursor"
                            checked: Gsr.settings.cursor
                            onToggled: Gsr.set("cursor", !checked)
                        }
                        SwitchRow {
                            label: "Start instant replay on login"
                            checked: Gsr.settings.replayOnStartup
                            onToggled: Gsr.set("replayOnStartup", !checked)
                        }
                        SwitchRow {
                            label: "Notifications"
                            checked: Gsr.settings.notifications
                            onToggled: Gsr.set("notifications", !checked)
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Icon {
                                Layout.preferredWidth: 14
                                Layout.preferredHeight: 14
                                text: Icons.folder
                                size: 12
                                color: Theme.color3
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24
                                radius: 8
                                color: Theme.mix(Theme.background, Theme.foreground, 0.9)

                                TextInput {
                                    id: folderInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: Gsr.settings.folder
                                    color: Theme.foreground
                                    selectionColor: Theme.color2
                                    selectedTextColor: Theme.background
                                    font.family: Theme.font
                                    font.pixelSize: Theme.rem * 0.75
                                    font.bold: true
                                    clip: true
                                    onEditingFinished: {
                                        const v = text.trim().replace(/^~(?=\/|$)/, Gsr.home).replace(/\/+$/, "");
                                        if (v)
                                            Gsr.set("folder", v);
                                        text = Qt.binding(() => Gsr.settings.folder);
                                    }
                                }
                            }
                            Pill {
                                label: "Open"
                                onClicked: Quickshell.execDetached(["xdg-open", Gsr.settings.folder])
                            }
                        }
                    }

                    Muted {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        elide: Text.ElideNone
                        text: "Alt+Z toolbar · Alt+F9 record · Alt+F7 pause · Alt+F10 save replay · Alt+Shift+F10 replay on/off"
                    }
                }
            }
        }
    }
}
