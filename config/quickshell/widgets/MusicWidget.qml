import QtQuick
import Quickshell.Widgets
import qs
import qs.components

// zenities' music-window widget (any MPRIS player, not just ncspot).
Rectangle {
    id: root

    radius: 12
    color: Theme.background
    implicitHeight: Math.max(cover.height + 8, info.implicitHeight) + 24

    function clip(s, n) {
        return s.length > n ? s.slice(0, n) + "…" : s;
    }

    ClippingRectangle {
        id: cover
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        width: 75
        height: 70
        radius: 4
        color: Theme.mix(Theme.background, Theme.foreground, 0.7)

        Icon {
            anchors.fill: parent
            visible: art.status !== Image.Ready
            text: Icons.music
            size: 30
            color: Theme.background
        }

        Image {
            id: art
            anchors.fill: parent
            source: Sys.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 150
            sourceSize.height: 150
        }
    }

    Column {
        id: info
        anchors.left: cover.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: Sys.title !== "" ? root.clip(Sys.title, 25) : "No music playing"
            color: Theme.foreground
            font.family: Theme.font
            font.pixelSize: Theme.rem
            font.bold: true
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: Sys.artist !== "" ? root.clip(Sys.artist, 25) : "No artist"
            color: Theme.color2
            font.family: Theme.font
            font.pixelSize: Theme.rem * 0.8
            font.bold: true
        }

        Slider {
            x: 4
            width: parent.width - 8
            height: 16
            thickness: 6
            fillColor: Theme.mix(Theme.color6, Theme.foreground, 0.9)
            value: Sys.seek
            onMoved: v => Sys.setSeek(v)
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 24

            Btn {
                width: 18
                height: 20
                text: Icons.prev
                onClicked: Sys.player?.previous()
            }
            Btn {
                width: 18
                height: 20
                text: Sys.playing ? Icons.pause : Icons.play
                onClicked: Sys.player?.togglePlaying()
            }
            Btn {
                width: 18
                height: 20
                text: Icons.next
                onClicked: Sys.player?.next()
            }
        }
    }
}
