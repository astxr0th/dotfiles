import QtQuick

// Equivalent of eww's (revealer): animates its size to/from 0.
// transition: "slideup" | "slidedown" | "slideleft" | "slideright"
Item {
    id: root

    property bool reveal: false
    property string transition: "slideup"
    property int duration: 300
    default property alias content: inner.data

    readonly property bool vertical: transition === "slideup" || transition === "slidedown"

    clip: true
    implicitWidth: vertical ? inner.implicitWidth : (reveal ? inner.implicitWidth : 0)
    implicitHeight: vertical ? (reveal ? inner.implicitHeight : 0) : inner.implicitHeight
    visible: implicitWidth > 0 && implicitHeight > 0

    Behavior on implicitHeight {
        NumberAnimation {
            duration: root.duration
            easing.type: Easing.OutCubic
        }
    }
    Behavior on implicitWidth {
        NumberAnimation {
            duration: root.duration
            easing.type: Easing.OutCubic
        }
    }

    Column {
        id: inner
        // slideup grows from the bottom edge, slideleft from the right edge
        y: root.transition === "slideup" ? root.height - height : 0
        x: root.transition === "slideleft" ? root.width - width : 0
    }
}
