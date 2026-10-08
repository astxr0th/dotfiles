import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components
import qs.widgets

// zenities' right-hand widget stack (device control, resources, music) plus a
// notifications section. Opened by clicking the sidebar clock or SUPER+SHIFT+Space.
Overlay {
    id: root

    name: "center"

    readonly property int cardWidth: 236

    // Each card slides in from the right, slightly staggered like eww revealers
    component Card: Item {
        id: card
        property int index: 0
        default property alias content: holder.data
        width: root.cardWidth
        implicitHeight: holder.childrenRect.height
        opacity: root.open ? 1 : 0
        transform: Translate {
            x: root.open ? 0 : 40

            Behavior on x {
                NumberAnimation {
                    duration: 260 + card.index * 50
                    easing.type: Easing.OutCubic
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 200 + card.index * 50
            }
        }

        // swallow clicks so they don't close the overlay
        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: holder
            width: parent.width
            height: card.height
        }
    }

    ColumnLayout {
        id: stack
        width: root.cardWidth
        x: root.width - width - Math.round(root.screen.width * 0.008)
        y: 12
        height: root.height - 24
        spacing: 10

        Card {
            index: 0
            DeviceControl {
                width: root.cardWidth
            }
        }
        Card {
            index: 1
            ResourceMonitor {
                width: root.cardWidth
            }
        }
        Card {
            index: 2
            MusicWidget {
                width: root.cardWidth
            }
        }

        // ---- Notifications ----
        Card {
            id: notifCard
            index: 3
            // grows with its content, up to the remaining height
            readonly property real wanted: 12 + 20 + 8 + (Notifs.list.length > 0 ? notifList.contentHeight : 64) + 12
            Layout.fillHeight: true
            Layout.preferredHeight: wanted
            Layout.maximumHeight: wanted

            Rectangle {
                width: root.cardWidth
                height: parent.height
                radius: 12
                color: Theme.background

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "Notifications"
                            color: Theme.color1
                            font.family: Theme.font
                            font.pixelSize: Theme.rem * 1.05
                            font.bold: true
                        }
                        Rectangle {
                            visible: Notifs.list.length > 0
                            implicitWidth: countText.implicitWidth + 10
                            implicitHeight: 18
                            radius: 9
                            color: Theme.color2

                            Text {
                                id: countText
                                anchors.centerIn: parent
                                text: Notifs.list.length
                                color: Theme.background
                                font.family: Theme.font
                                font.pixelSize: Theme.rem * 0.7
                                font.bold: true
                            }
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        Btn {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            text: Sys.dnd ? Icons.bellSlash : Icons.bell
                            size: 13
                            tip: Sys.dnd ? "Do not disturb: on" : "Do not disturb: off"
                            tipRight: false
                            color: Sys.dnd ? Theme.color1 : Theme.mix(Theme.foreground, Theme.background, 0.6)
                            onClicked: Sys.dnd = !Sys.dnd
                        }
                        Btn {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            visible: Notifs.list.length > 0
                            text: Icons.trash
                            size: 13
                            tip: "Clear all"
                            tipRight: false
                            color: Theme.mix(Theme.foreground, Theme.background, 0.6)
                            hoverColor: Theme.color1
                            onClicked: Notifs.clearAll()
                        }
                    }

                    ListView {
                        id: notifList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 8
                        model: Notifs.list

                        add: Transition {
                            NumberAnimation {
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 200
                            }
                        }
                        removeDisplaced: Transition {
                            NumberAnimation {
                                property: "y"
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }

                        delegate: NotifCard {
                            required property var modelData
                            width: notifList.width
                            notif: modelData
                            compact: true
                            onCloseRequested: Notifs.dismiss(modelData)
                        }

                        Column {
                            anchors.centerIn: parent
                            visible: Notifs.list.length === 0
                            spacing: 8

                            Icon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 34
                                height: 30
                                text: Icons.bellSlash
                                size: 26
                                color: Theme.mix(Theme.foreground, Theme.background, 0.3)
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No notifications"
                                color: Theme.mix(Theme.foreground, Theme.background, 0.45)
                                font.family: Theme.font
                                font.pixelSize: Theme.rem * 0.85
                                font.bold: true
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
