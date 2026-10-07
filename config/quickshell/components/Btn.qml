import QtQuick
import qs

// Icon button: ink-centered glyph + hover color + click + tooltip.
Item {
    id: root

    property alias text: icon.text
    property color color: Theme.foreground
    property color hoverColor: color
    property real size: Theme.rem
    property string family: Theme.iconFont
    property int weight: Font.Bold
    property string tip: ""
    property bool tipRight: true
    readonly property bool hovered: hover.hovered

    signal clicked
    signal rightClicked
    signal scrolled(int delta)

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Icon {
        id: icon
        anchors.fill: parent
        size: root.size
        family: root.family
        weight: root.weight
        color: hover.hovered ? root.hoverColor : root.color
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.clicked()
        onWheel: wheel => root.scrolled(wheel.angleDelta.y)
    }

    Tip {
        text: root.tip
        show: hover.hovered
        sideways: root.tipRight
    }
}
