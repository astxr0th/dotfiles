import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// Full-screen transparent layer that hosts a popup panel. Clicking outside
// the panel or pressing Escape closes it.
PanelWindow {
    id: root

    required property string name
    readonly property bool open: Sys.panel === name && !Sys.locked
    default property alias content: holder.data

    anchors {
        left: true
        top: true
        right: true
        bottom: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "zenities-" + name
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"
    visible: open || closing.running

    onOpenChanged: if (!open)
        closing.restart()

    Timer {
        id: closing
        interval: 260
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Sys.panel = ""
    }

    Item {
        id: holder
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Sys.panel = ""
    }
}
