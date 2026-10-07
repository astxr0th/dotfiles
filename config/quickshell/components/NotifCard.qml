import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs

// One notification, styled like zenities' .notif
Rectangle {
    id: root

    required property Notification notif
    property bool popup: false
    property bool compact: false
    signal closeRequested

    radius: 12
    color: Theme.mix(Theme.color1, Theme.background, 0.2)
    implicitHeight: body.implicitHeight + (compact ? 20 : 24)
    border.width: notif.urgency === NotificationUrgency.Critical ? 1 : 0
    border.color: Theme.color1

    readonly property string imageSource: {
        const img = notif.image || notif.appIcon;
        if (!img)
            return "";
        if (img.startsWith("/"))
            return "file://" + img;
        if (img.includes("://"))
            return img;
        return Quickshell.iconPath(img, true);
    }

    HoverHandler {
        id: hover
    }

    RowLayout {
        id: body
        x: root.compact ? 10 : 12
        y: root.compact ? 10 : 12
        width: parent.width - 2 * x
        spacing: root.compact ? 8 : 10

        ClippingRectangle {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: root.compact ? 30 : 42
            Layout.preferredHeight: root.compact ? 30 : 42
            visible: root.imageSource !== ""
            radius: 8
            color: "transparent"

            Image {
                anchors.fill: parent
                source: root.imageSource
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 84
                sourceSize.height: 84
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: root.notif.summary || root.notif.appName
                    color: Theme.color2
                    elide: Text.ElideRight
                    font.family: Theme.font
                    font.pixelSize: Theme.rem
                    font.bold: true
                }

                Text {
                    text: root.notif.appName
                    visible: !!root.notif.summary && !hover.hovered
                    color: Theme.mix(Theme.foreground, Theme.background, 0.5)
                    font.family: Theme.font
                    font.pixelSize: Theme.rem * 0.75
                    font.bold: true
                }

                Btn {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    visible: hover.hovered
                    text: Icons.close
                    size: Theme.rem * 0.8
                    color: Theme.mix(Theme.foreground, Theme.background, 0.6)
                    hoverColor: Theme.color1
                    onClicked: root.closeRequested()
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notif.body
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: root.popup || root.compact ? 3 : 6
                elide: Text.ElideRight
                color: Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.rem * 0.85
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: root.notif.actions.length > 0
                spacing: 6

                Repeater {
                    model: root.notif.actions

                    Rectangle {
                        id: action
                        required property NotificationAction modelData
                        implicitWidth: actionText.implicitWidth + 20
                        implicitHeight: 26
                        radius: 8
                        color: Theme.mix(Theme.background, Theme.color1, actionHover.hovered ? 0.7 : 0.85)

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: action.modelData.text
                            color: Theme.foreground
                            font.family: Theme.font
                            font.pixelSize: Theme.rem * 0.8
                            font.bold: true
                        }

                        HoverHandler {
                            id: actionHover
                            cursorShape: Qt.PointingHandCursor
                        }
                        TapHandler {
                            onTapped: action.modelData.invoke()
                        }
                    }
                }
            }
        }
    }
}
