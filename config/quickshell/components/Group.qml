import QtQuick
import qs

// Sidebar group box (.resource / .device / .time-vert in zenities).
Rectangle {
    id: root

    default property alias content: col.data
    property alias spacing: col.spacing

    radius: 8
    color: Theme.mix(Theme.background, Theme.color6, 0.95)
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight + 8

    Column {
        id: col
        y: 4
        width: parent.width
    }
}
