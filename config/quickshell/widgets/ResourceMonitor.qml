import QtQuick
import qs
import qs.components

// zenities' resource-monitor widget: five vertical bars.
Rectangle {
    id: root

    radius: 12
    color: Theme.background
    implicitHeight: row.implicitHeight + 16

    component Bar: Item {
        id: bar
        property string label
        property string valueText
        property real value
        property string tip
        property var fill  // color, or a Gradient

        implicitWidth: 44
        implicitHeight: barCol.implicitHeight

        HoverHandler {
            id: hover
            cursorShape: Qt.PointingHandCursor
        }

        Column {
            id: barCol
            width: parent.width
            spacing: 2

            Repeater {
                model: [bar.label, bar.valueText]

                Text {
                    required property string modelData
                    width: bar.width
                    height: 20
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: modelData
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.rem
                    font.bold: true
                }
            }

            Item {
                width: bar.width
                height: 112

                Rectangle {
                    anchors.centerIn: parent
                    width: 32
                    height: 100
                    radius: 8
                    color: Theme.mix(Theme.background, Theme.foreground, 0.7)

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(6, parent.height * Math.min(100, bar.value) / 100)
                        visible: bar.value > 0
                        radius: 6
                        color: bar.fill instanceof Gradient ? "transparent" : bar.fill
                        gradient: bar.fill instanceof Gradient ? bar.fill : null
                    }
                }
            }
        }

        Tip {
            text: bar.tip
            show: hover.hovered
            sideways: false
        }
    }

    Row {
        id: row
        x: 8
        y: 8

        Bar {
            label: "CPU"
            valueText: Sys.cpu + "%"
            value: Sys.cpu
            tip: "CPU usage: " + Sys.cpu + "%"
            fill: Theme.color4
        }
        Bar {
            label: "TMP"
            valueText: Sys.temperature + "°"
            value: Sys.temperature
            tip: "CPU Temperature: " + Sys.temperature + "°C"
            fill: Theme.color7
        }
        Bar {
            label: "MEM"
            valueText: Sys.memory + "%"
            value: Sys.memory
            tip: Sys.memoryFree + " free"
            fill: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: Theme.color6
                }
                GradientStop {
                    position: 1
                    color: Theme.lighten(Theme.color6, 0.2)
                }
            }
        }
        Bar {
            label: "DSK"
            valueText: Sys.disk + "%"
            value: Sys.disk
            tip: Sys.diskFree + " free"
            fill: Theme.mix(Theme.color3, Theme.foreground, 0.85)
        }
        Bar {
            label: "BAT"
            valueText: Sys.hasBattery ? Sys.battery + "%" : "AC"
            value: Sys.hasBattery ? Sys.battery : 0
            tip: Sys.hasBattery ? Sys.timeLeft : "No battery"
            fill: Theme.color5
        }
    }
}
