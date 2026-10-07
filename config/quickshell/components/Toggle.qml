import QtQuick
import qs

// Pill switch
Rectangle {
    id: root

    property bool checked: false
    property bool active: true
    signal toggled

    implicitWidth: 38
    implicitHeight: 22
    radius: height / 2
    opacity: active ? 1 : 0.4
    color: checked ? Theme.color2 : Theme.mix(Theme.background, Theme.foreground, 0.8)

    Behavior on color {
        ColorAnimation {
            duration: 200
        }
    }

    Rectangle {
        width: parent.height - 6
        height: width
        radius: width / 2
        y: 3
        x: root.checked ? parent.width - width - 3 : 3
        color: root.checked ? Theme.background : Theme.foreground

        Behavior on x {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }

    HoverHandler {
        cursorShape: root.active ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
    TapHandler {
        enabled: root.active
        onTapped: root.toggled()
    }
}
