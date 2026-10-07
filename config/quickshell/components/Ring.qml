import QtQuick
import qs

// Equivalent of eww's (circular-progress): starts at 3 o'clock, clockwise.
Canvas {
    id: root

    property real value: 0  // 0..100
    property real thickness: 4
    property color color: Theme.mix(Theme.color3, Theme.foreground, 0.9)
    property color troughColor: Theme.mix(Theme.background, Theme.foreground, 0.8)

    implicitWidth: 14
    implicitHeight: 14

    onValueChanged: requestPaint()
    onColorChanged: requestPaint()
    onTroughColorChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const r = Math.min(width, height) / 2 - thickness / 2;
        ctx.lineWidth = thickness;
        ctx.strokeStyle = troughColor;
        ctx.beginPath();
        ctx.arc(width / 2, height / 2, r, 0, 2 * Math.PI);
        ctx.stroke();
        ctx.strokeStyle = color;
        ctx.beginPath();
        ctx.arc(width / 2, height / 2, r, 0, 2 * Math.PI * Math.max(0, Math.min(100, value)) / 100);
        ctx.stroke();
    }
}
