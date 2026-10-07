import QtQuick
import Quickshell
import qs

// GTK-style delayed tooltip. Put inside an item and bind `show` to its hover.
Item {
    id: root

    property string text
    property bool show: false
    property bool sideways: true   // right of the target (sidebar), else below it

    anchors.fill: parent

    Timer {
        id: delay
        interval: 500
        running: root.show && root.text !== ""
    }

    LazyLoader {
        active: root.show && root.text !== "" && !delay.running

        PopupWindow {
            visible: true
            color: "transparent"
            anchor.item: root
            anchor.rect.x: root.sideways ? root.width + 8 : root.width / 2 - implicitWidth / 2
            anchor.rect.y: root.sideways ? root.height / 2 - implicitHeight / 2 : root.height + 6
            implicitWidth: label.implicitWidth + 16
            implicitHeight: label.implicitHeight + 10

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: Theme.background

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: root.text
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.rem * 0.9
                    font.bold: true
                }
            }
        }
    }
}
