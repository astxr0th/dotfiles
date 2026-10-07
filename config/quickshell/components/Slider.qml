import QtQuick
import qs

// Equivalent of eww's (scale) with zenities' trough/highlight styling (no knob).
Item {
    id: root

    property real value: 0          // 0..100
    property bool vertical: false   // vertical sliders fill bottom-up (eww :flipped)
    property real thickness: 8
    property real radius: 5
    property color troughColor: Theme.mix(Theme.background, Theme.foreground, 0.8)
    property color fillColor: Theme.mix(Theme.color5, Theme.foreground, 0.9)
    property real step: 5

    signal moved(real value)

    property real _local: 0
    readonly property real shown: Math.max(0, Math.min(100, area.pressed ? _local : value))

    Rectangle {
        id: trough
        anchors.centerIn: parent
        width: root.vertical ? root.thickness : root.width
        height: root.vertical ? root.height : root.thickness
        radius: root.radius
        color: root.troughColor

        Rectangle {
            radius: root.radius
            color: root.fillColor
            x: 0
            y: root.vertical ? parent.height - height : 0
            width: root.vertical ? parent.width : parent.width * root.shown / 100
            height: root.vertical ? parent.height * root.shown / 100 : parent.height
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        function update(mouse) {
            const f = root.vertical ? 1 - mouse.y / height : mouse.x / width;
            root._local = Math.max(0, Math.min(100, f * 100));
            root.moved(root._local);
        }

        onPressed: mouse => update(mouse)
        onPositionChanged: mouse => {
            if (pressed)
                update(mouse);
        }
        onWheel: wheel => root.moved(Math.max(0, Math.min(100, root.value + (wheel.angleDelta.y > 0 ? root.step : -root.step))))
    }
}
