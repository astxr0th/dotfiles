import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components

// Toast popups, top-right (zenities' notifications window: overlay, top right).
PanelWindow {
    id: win

    anchors {
        top: true
        right: true
    }
    margins {
        top: Math.round(screen.height * 0.02)
        right: Math.round(screen.width * 0.02)
    }
    implicitWidth: 360
    implicitHeight: Math.max(1, col.implicitHeight)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "zenities-notifications"
    color: "transparent"
    visible: Notifs.popups.length > 0 && Sys.panel !== "center" && !Sys.locked
    mask: Region {
        item: col
    }

    Column {
        id: col
        width: parent.width
        spacing: 10

        Repeater {
            model: Notifs.popups

            NotifCard {
                id: card
                required property var modelData
                notif: modelData
                popup: true
                width: col.width
                onCloseRequested: Notifs.hidePopup(modelData)

                Timer {
                    running: !cardHover.hovered
                    interval: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout : 5000
                    onTriggered: Notifs.hidePopup(card.modelData)
                }

                HoverHandler {
                    id: cardHover
                }
            }
        }
    }
}
