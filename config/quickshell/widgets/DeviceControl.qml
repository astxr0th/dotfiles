import QtQuick
import qs
import qs.components

// zenities' device-control widget.
Rectangle {
    id: root

    radius: 12
    color: Theme.background
    implicitHeight: col.implicitHeight + 24

    component SmallTile: Rectangle {
        id: tile
        property alias text: icon.text
        signal clicked
        width: 34
        height: 28
        radius: 8
        color: Theme.mix(Theme.background, Theme.color1, 0.9)

        Btn {
            id: icon
            anchors.fill: parent
            size: 16
            onClicked: tile.clicked()
        }
    }

    component BigTile: Rectangle {
        id: big
        property alias text: icon.text
        property alias tip: icon.tip
        signal clicked
        height: 46
        radius: 8
        color: Theme.mix(Theme.background, Theme.color1, icon.hovered ? 0.8 : 0.9)

        Behavior on color {
            ColorAnimation {
                duration: 300
            }
        }

        Btn {
            id: icon
            anchors.fill: parent
            size: 20
            tipRight: false
            onClicked: big.clicked()
        }
    }

    Column {
        id: col
        x: 12
        y: 12
        width: parent.width - 24
        spacing: 8

        Row {
            spacing: 10

            SmallTile {
                text: Sys.volumeIcon
                onClicked: Sys.toggle("mixer")
            }
            Slider {
                width: col.width - 44
                height: 28
                value: Sys.volume
                onMoved: v => Sys.setVolume(v)
            }
        }

        Row {
            spacing: 10
            visible: Sys.hasBacklight

            SmallTile {
                text: Icons.brightness
            }
            Slider {
                width: col.width - 44
                height: 28
                value: Sys.brightness
                onMoved: v => Sys.setBrightness(v)
            }
        }

        Row {
            id: tiles
            spacing: 8
            readonly property real tileWidth: (col.width - 5 * spacing) / 6

            BigTile {
                width: tiles.tileWidth
                text: Sys.netIcon
                tip: "Connected to " + Sys.netName
                onClicked: Sys.openNetwork("wifi")
            }
            BigTile {
                width: tiles.tileWidth
                text: Sys.bluetoothIcon
                tip: Sys.bluetoothOn ? "Bluetooth on" : "Bluetooth off"
                onClicked: Sys.openNetwork("bluetooth")
            }
            BigTile {
                width: tiles.tileWidth
                text: Sys.idleInhibited ? Icons.eyeSlash : Icons.eye
                tip: Sys.idleInhibited ? "idle disabled" : "idle enabled"
                onClicked: Sys.idleInhibited = !Sys.idleInhibited
            }
            BigTile {
                width: tiles.tileWidth
                text: Icons.image
                tip: "Wallpaper"
                onClicked: Sys.toggle("wallpaper")
            }
            BigTile {
                width: tiles.tileWidth
                text: Icons.camera
                tip: "Screenshot"
                onClicked: Sys.toggle("screenshot")
            }
            BigTile {
                width: tiles.tileWidth
                text: Gsr.recording ? Icons.circle : Icons.video
                tip: Gsr.recording ? "Recording " + Gsr.elapsedText : Gsr.replaying ? "Recorder · replay on" : "Recorder"
                onClicked: Sys.toggle("recorder")
            }
        }
    }
}
