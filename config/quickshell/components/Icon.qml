import QtQuick
import qs

// A glyph centered by its *ink* bounds rather than its advance width, so Nerd
// Font icons with uneven side bearings still line up on the same axis.
Item {
    id: root

    property string text
    property color color: Theme.foreground
    property real size: Theme.rem
    property string family: Theme.iconFont
    property int weight: Font.Bold

    implicitWidth: Math.ceil(metrics.tightBoundingRect.width)
    implicitHeight: Math.ceil(metrics.tightBoundingRect.height)

    TextMetrics {
        id: metrics
        font: glyph.font
        text: root.text
    }

    Text {
        id: glyph
        text: root.text
        color: root.color
        font.family: root.family
        font.pixelSize: root.size
        font.weight: root.weight
        x: Math.round(root.width / 2 - (metrics.tightBoundingRect.x + metrics.tightBoundingRect.width / 2))
        y: Math.round(root.height / 2 - (baselineOffset + metrics.tightBoundingRect.y + metrics.tightBoundingRect.height / 2))

        Behavior on color {
            ColorAnimation {
                duration: 300
            }
        }
    }
}
