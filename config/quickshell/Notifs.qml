pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon (replaces swaync). Popups show top-right; history lives
// in the control center opened from the sidebar clock.
Singleton {
    id: root

    readonly property var list: server.trackedNotifications.values.slice().reverse()
    property var popups: []
    property int unread: 0

    function dismiss(n) {
        n.dismiss();
    }
    function clearAll() {
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
        popups = [];
        unread = 0;
    }
    function hidePopup(n) {
        popups = popups.filter(p => p !== n);
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            if (Sys.panel !== "center")
                root.unread++;
            if (!Sys.dnd || n.urgency === NotificationUrgency.Critical)
                root.popups = [n, ...root.popups].slice(0, 5);
            n.closed.connect(() => root.hidePopup(n));
        }
    }

    Connections {
        target: Sys
        function onPanelChanged() {
            if (Sys.panel === "center")
                root.unread = 0;
        }
    }
}
