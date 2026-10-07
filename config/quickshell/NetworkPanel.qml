import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import qs
import qs.components

// Wi-Fi + Bluetooth panel (the internet center), opened from the sidebar
// network icon (right-click it for Bluetooth) or the device-control tiles.
// Docked beside the sidebar, vertically centered on the wifi icon.
Overlay {
    id: root

    name: "network"

    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    readonly property var adapter: Bluetooth.defaultAdapter

    function strength(n) {
        const s = n.signalStrength > 1 ? n.signalStrength / 100 : n.signalStrength;
        return s > 0.8 ? Icons.wifi4 : s > 0.6 ? Icons.wifi3 : s > 0.4 ? Icons.wifi2 : s > 0.2 ? Icons.wifi1 : Icons.wifi0;
    }

    function btIcon(icon) {
        if (!icon)
            return Icons.btOn;
        if (icon.includes("headset") || icon.includes("headphone"))
            return Icons.headphones;
        if (icon.includes("audio"))
            return Icons.speaker;
        if (icon.includes("keyboard"))
            return Icons.keyboard;
        if (icon.includes("mouse") || icon.includes("tablet"))
            return Icons.mouse;
        if (icon.includes("gaming"))
            return Icons.gamepad;
        if (icon.includes("phone"))
            return Icons.phone;
        if (icon.includes("computer"))
            return Icons.laptop;
        return Icons.btOn;
    }

    // Keep scanning while the panel is open
    Binding {
        target: root.wifiDevice
        property: "scannerEnabled"
        value: root.open && Sys.networkTab === "wifi"
        when: root.wifiDevice !== null
    }
    // Scan for Bluetooth devices only while the Bluetooth tab is visible
    readonly property bool btScan: open && Sys.networkTab === "bluetooth" && (adapter?.enabled ?? false)
    onBtScanChanged: if (adapter && adapter.enabled && adapter.discovering !== btScan)
        adapter.discovering = btScan

    component SectionTitle: Text {
        color: Theme.color1
        font.family: Theme.font
        font.pixelSize: 13
        font.bold: true
    }

    component Muted: Text {
        color: Theme.mix(Theme.foreground, Theme.background, 0.55)
        font.family: Theme.font
        font.pixelSize: Theme.rem * 0.62
        font.bold: true
        elide: Text.ElideRight
    }

    component Pill: Rectangle {
        id: pill
        property string label
        property bool primary: false
        signal clicked
        implicitWidth: pillText.implicitWidth + 12
        implicitHeight: 19
        radius: 7
        color: primary ? (pillHover.hovered ? Theme.lighten(Theme.color2, 0.08) : Theme.color2) : Theme.mix(Theme.background, Theme.color1, pillHover.hovered ? 0.7 : 0.85)

        Text {
            id: pillText
            anchors.centerIn: parent
            text: pill.label
            color: pill.primary ? Theme.background : Theme.foreground
            font.family: Theme.font
            font.pixelSize: Theme.rem * 0.65
            font.bold: true
        }
        HoverHandler {
            id: pillHover
            cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
            onTapped: pill.clicked()
        }
    }

    // A list row: icon tile, title/subtitle, trailing content
    component Row_: Rectangle {
        id: row
        property string icon
        property string title
        property string subtitle
        property bool highlighted: false
        property bool expanded: false
        default property alias extra: extraCol.data
        property alias trailing: trailingRow.data
        signal clicked

        implicitHeight: rowLayout.implicitHeight + 8
        radius: 7
        color: highlighted ? Theme.mix(Theme.background, Theme.color2, 0.8) : rowHover.hovered ? Theme.mix(Theme.background, Theme.color1, 0.85) : Theme.mix(Theme.background, Theme.color1, 0.93)

        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }

        HoverHandler {
            id: rowHover
            cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
            onTapped: row.clicked()
        }

        ColumnLayout {
            id: rowLayout
            x: 4
            y: 4
            width: parent.width - 8
            spacing: 4

            RowLayout {
                spacing: 6
                Layout.fillWidth: true

                Rectangle {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    radius: 6
                    color: row.highlighted ? Theme.color2 : Theme.mix(Theme.background, Theme.color1, 0.8)

                    Icon {
                        anchors.fill: parent
                        text: row.icon
                        size: 11
                        color: row.highlighted ? Theme.background : Theme.foreground
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: row.title
                        elide: Text.ElideRight
                        color: Theme.foreground
                        font.family: Theme.font
                        font.pixelSize: Theme.rem * 0.75
                        font.bold: true
                    }
                    Muted {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: row.subtitle
                    }
                }

                RowLayout {
                    id: trailingRow
                    spacing: 6
                }
            }

            ColumnLayout {
                id: extraCol
                Layout.fillWidth: true
                visible: row.expanded
                spacing: 8
            }
        }
    }

    Rectangle {
        id: panel
        readonly property int margin: Math.round(root.height * 0.01)
        width: 240
        height: Math.min(300, col.implicitHeight + 16)
        x: Math.round(root.screen.width * 0.005) + 33 + 10 + (root.open ? 0 : -16)
        // centered on the wifi icon, kept on screen
        y: Sys.netIconY < 0 ? root.height - height - margin : Math.round(Math.max(margin, Math.min(root.height - height - margin, Sys.netIconY - height / 2)))
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

        // swallow clicks so they don't close the overlay
        MouseArea {
            anchors.fill: parent
        }

        Behavior on height {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            // Tabs
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                radius: 8
                color: Theme.mix(Theme.background, Theme.color1, 0.9)

                Rectangle {
                    width: parent.width / 2 - 4
                    height: parent.height - 4
                    y: 2
                    x: Sys.networkTab === "wifi" ? 2 : parent.width / 2
                    radius: 6
                    color: Theme.color2

                    Behavior on x {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Row {
                    anchors.fill: parent

                    Repeater {
                        model: [
                            { tab: "wifi", icon: Sys.netIcon, label: "Network" },
                            { tab: "bluetooth", icon: Sys.bluetoothIcon, label: "Bluetooth" }
                        ]

                        Item {
                            id: tabItem
                            required property var modelData
                            readonly property bool current: Sys.networkTab === modelData.tab
                            width: parent.width / 2
                            height: parent.height

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Icon {
                                    width: 12
                                    height: 12
                                    text: tabItem.modelData.icon
                                    size: 11
                                    color: tabItem.current ? Theme.background : Theme.foreground
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: tabItem.modelData.label
                                    color: tabItem.current ? Theme.background : Theme.foreground
                                    font.family: Theme.font
                                    font.pixelSize: Theme.rem * 0.75
                                    font.bold: true
                                }
                            }
                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }
                            TapHandler {
                                onTapped: Sys.networkTab = tabItem.modelData.tab
                            }
                        }
                    }
                }
            }

            // ================= Wi-Fi / network =================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: Sys.networkTab === "wifi"
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    SectionTitle {
                        Layout.fillWidth: true
                        text: "Wi-Fi"
                    }
                    Toggle {
                        implicitWidth: 30
                        implicitHeight: 17
                        active: Networking.wifiHardwareEnabled && root.wifiDevice !== null
                        checked: Networking.wifiEnabled
                        onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                }

                // Wired connection card
                Row_ {
                    Layout.fillWidth: true
                    visible: root.wiredDevice !== null
                    icon: Icons.ethernet
                    title: root.wiredDevice?.network?.name || "Ethernet"
                    subtitle: root.wiredDevice?.connected ? "Wired · " + (root.wiredDevice.linkSpeed > 0 ? root.wiredDevice.linkSpeed + " Mb/s" : "connected") : root.wiredDevice?.hasLink ? "Cable plugged in" : "Cable unplugged"
                    highlighted: root.wiredDevice?.connected ?? false
                }

                Muted {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    visible: !root.wifiDevice || !Networking.wifiHardwareEnabled || !Networking.wifiEnabled
                    text: !root.wifiDevice ? "No Wi-Fi adapter found" : !Networking.wifiHardwareEnabled ? "Wi-Fi is blocked by a hardware switch" : "Wi-Fi is off"
                }

                ListView {
                    id: wifiList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: count > 0 ? contentHeight : 28
                    visible: root.wifiDevice !== null && Networking.wifiEnabled
                    clip: true
                    spacing: 4
                    model: root.wifiDevice ? root.wifiDevice.networks.values.filter(n => n.name).sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength)) : []

                    property string expandedName: ""

                    Muted {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 12
                        visible: wifiList.count === 0
                        text: "Searching for networks…"
                    }

                    delegate: Row_ {
                        id: net
                        required property var modelData
                        readonly property bool secured: modelData.security !== WifiSecurityType.Open
                        property string error: ""
                        width: wifiList.width
                        icon: root.strength(modelData)
                        title: modelData.name
                        subtitle: modelData.stateChanging ? "Connecting…" : modelData.connected ? "Connected" : error !== "" ? error : modelData.known ? "Saved" : secured ? "Secured" : "Open"
                        highlighted: modelData.connected
                        expanded: wifiList.expandedName === modelData.name
                        trailing: Icon {
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            visible: net.secured
                            text: Icons.lock
                            size: 12
                            color: Theme.mix(Theme.foreground, Theme.background, 0.55)
                        }

                        onClicked: {
                            if (!modelData.connected && (modelData.known || !secured)) {
                                error = "";
                                modelData.connect();
                                wifiList.expandedName = "";
                            } else {
                                wifiList.expandedName = expanded ? "" : modelData.name;
                            }
                        }

                        Connections {
                            target: net.modelData
                            function onConnectionFailed(reason) {
                                net.error = reason === ConnectionFailReason.NoSecrets ? "Wrong password" : "Couldn't connect";
                                if (net.secured)
                                    wifiList.expandedName = net.modelData.name;
                            }
                        }

                        // Expanded: password entry for new secured networks
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            visible: !net.modelData.connected && net.secured
                            radius: 8
                            color: Theme.mix(Theme.background, Theme.foreground, 0.9)

                            TextInput {
                                id: psk
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                echoMode: TextInput.Password
                                color: Theme.foreground
                                selectionColor: Theme.color2
                                font.family: Theme.font
                                font.pixelSize: Theme.rem
                                focus: net.expanded
                                onAccepted: {
                                    net.error = "";
                                    net.modelData.connectWithPsk(text);
                                    text = "";
                                    wifiList.expandedName = "";
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: psk.text === ""
                                    text: "Password"
                                    color: Theme.mix(Theme.foreground, Theme.background, 0.45)
                                    font: psk.font
                                }
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            spacing: 6

                            Pill {
                                visible: net.modelData.known
                                label: "Forget"
                                onClicked: {
                                    net.modelData.forget();
                                    wifiList.expandedName = "";
                                }
                            }
                            Pill {
                                visible: net.modelData.connected
                                label: "Disconnect"
                                onClicked: {
                                    net.modelData.disconnect();
                                    wifiList.expandedName = "";
                                }
                            }
                            Pill {
                                visible: !net.modelData.connected
                                primary: true
                                label: "Connect"
                                onClicked: psk.accepted()
                            }
                        }
                    }
                }
            }

            // ================= Bluetooth =================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: Sys.networkTab === "bluetooth"
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    SectionTitle {
                        text: "Bluetooth"
                    }
                    Btn {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        visible: root.adapter?.enabled ?? false
                        text: Icons.refresh
                        size: 13
                        tip: root.adapter?.discovering ? "Scanning…" : "Scan"
                        tipRight: false
                        color: root.adapter?.discovering ? Theme.color2 : Theme.mix(Theme.foreground, Theme.background, 0.55)
                        onClicked: if (root.adapter) root.adapter.discovering = !root.adapter.discovering

                        RotationAnimation on rotation {
                            running: root.adapter?.discovering ?? false
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 1500
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Toggle {
                        implicitWidth: 30
                        implicitHeight: 17
                        active: root.adapter !== null
                        checked: root.adapter?.enabled ?? false
                        onToggled: root.adapter.enabled = !root.adapter.enabled
                    }
                }

                Muted {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    horizontalAlignment: Text.AlignHCenter
                    visible: !root.adapter || !root.adapter.enabled
                    text: !root.adapter ? "No Bluetooth adapter found" : "Bluetooth is off"
                }

                ListView {
                    id: btList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: count > 0 ? contentHeight : 28
                    visible: root.adapter?.enabled ?? false
                    clip: true
                    spacing: 4
                    property string expandedAddr: ""

                    model: root.adapter ? root.adapter.devices.values.filter(d => d.paired || d.connected || (d.name && d.name.replace(/[-:]/g, "") !== d.address.replace(/:/g, ""))).sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name)) : []

                    Muted {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 12
                        visible: btList.count === 0
                        text: root.adapter?.discovering ? "Searching for devices…" : "No devices found"
                    }

                    delegate: Row_ {
                        id: dev
                        required property var modelData
                        width: btList.width
                        icon: root.btIcon(modelData.icon)
                        title: modelData.name || modelData.address
                        subtitle: {
                            const d = modelData;
                            if (d.pairing)
                                return "Pairing…";
                            if (d.state === BluetoothDeviceState.Connecting)
                                return "Connecting…";
                            if (d.state === BluetoothDeviceState.Disconnecting)
                                return "Disconnecting…";
                            if (d.connected)
                                return "Connected" + (d.batteryAvailable ? " · " + Math.round(d.battery * 100) + "%" : "");
                            return d.paired ? "Paired" : "Available";
                        }
                        highlighted: modelData.connected
                        expanded: btList.expandedAddr === modelData.address

                        onClicked: {
                            const d = modelData;
                            if (!d.paired) {
                                d.trusted = true;
                                d.pair();
                            } else if (!d.connected)
                                d.connect();
                            else
                                btList.expandedAddr = expanded ? "" : d.address;
                        }
                        onRightClicked: btList.expandedAddr = expanded ? "" : modelData.address

                        signal rightClicked

                        // connect right after a successful pairing
                        Connections {
                            target: dev.modelData
                            function onPairedChanged() {
                                if (dev.modelData.paired && !dev.modelData.connected)
                                    dev.modelData.connect();
                            }
                        }

                        TapHandler {
                            acceptedButtons: Qt.RightButton
                            onTapped: dev.rightClicked()
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            spacing: 6

                            Pill {
                                visible: dev.modelData.paired
                                label: "Forget"
                                onClicked: {
                                    dev.modelData.forget();
                                    btList.expandedAddr = "";
                                }
                            }
                            Pill {
                                visible: dev.modelData.connected
                                primary: true
                                label: "Disconnect"
                                onClicked: {
                                    dev.modelData.disconnect();
                                    btList.expandedAddr = "";
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
