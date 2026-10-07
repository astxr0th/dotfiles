import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.components

// Application launcher matching zenities' rofi theme (config.rasi):
// 350px window, 10px padding, 3 lines, Iosevka 14, "∂" prompt, "find the zen",
// selected row in color3. Apps are ordered by launch count, shared with rofi's
// own history file (~/.cache/rofi3.druncache).
Overlay {
    id: root

    name: "launcher"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property int lines: 3
    // element: 8px padding around one line of Iosevka 14
    readonly property int rowHeight: Math.ceil(metrics.height) + 16

    FontMetrics {
        id: metrics
        font.family: Theme.font
        font.pointSize: 14
    }
    property int current: 0

    // desktop id -> launch count
    property var usage: ({})
    function uses(a) {
        return usage[a.id + ".desktop"] ?? 0;
    }

    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => uses(b) - uses(a) || a.name.localeCompare(b.name))

    FileView {
        id: history
        path: Quickshell.env("HOME") + "/.cache/rofi3.druncache"
        printErrors: false
        onLoaded: {
            const u = {};
            for (const l of text().split("\n")) {
                const m = l.match(/^(\d+) (.+)$/);
                if (m)
                    u[m[2]] = Number(m[1]);
            }
            root.usage = u;
        }
    }

    readonly property var results: {
        const q = input.text.trim().toLowerCase();
        if (!q)
            return apps;
        const scored = [];
        for (const a of apps) {
            const name = a.name.toLowerCase();
            const extra = [a.genericName, a.comment, (a.keywords ?? []).join(" "), a.id].join(" ").toLowerCase();
            let score = -1;
            if (name.startsWith(q))
                score = 0;
            else if (name.split(/\s+/).some(w => w.startsWith(q)))
                score = 1;
            else if (name.includes(q))
                score = 2;
            else if (extra.includes(q))
                score = 3;
            else {
                // subsequence match ("ffx" -> "firefox")
                let i = 0;
                for (const ch of name)
                    if (ch === q[i])
                        i++;
                if (i === q.length)
                    score = 4;
            }
            if (score >= 0)
                scored.push({ a, score });
        }
        return scored.sort((x, y) => x.score - y.score || uses(y.a) - uses(x.a) || x.a.name.localeCompare(y.a.name)).map(x => x.a);
    }

    onResultsChanged: current = 0
    onOpenChanged: {
        if (open) {
            input.text = "";
            current = 0;
            input.forceActiveFocus();
        }
    }

    function launch(app) {
        if (!app)
            return;
        Sys.panel = "";
        const u = Object.assign({}, usage);
        u[app.id + ".desktop"] = (u[app.id + ".desktop"] ?? 0) + 1;
        usage = u;
        history.setText(Object.keys(u).sort((a, b) => u[b] - u[a]).map(k => u[k] + " " + k).join("\n") + "\n");
        if (app.runInTerminal)
            Quickshell.execDetached(["kitty", "-e", ...app.command]);
        else
            app.execute();
    }

    Rectangle {
        id: box
        width: 350
        height: col.implicitHeight + 20
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.open ? 0 : 12
        opacity: root.open ? 1 : 0
        radius: 12
        color: Theme.background

        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: col
            x: 10
            y: 10
            width: parent.width - 20
            spacing: 4

            // inputbar: prompt + entry (4px padding, entry 2px)
            Rectangle {
                width: parent.width
                height: Math.ceil(metrics.height) + 12
                radius: 8
                color: Theme.background

                Text {
                    id: prompt
                    x: 9
                    anchors.verticalCenter: parent.verticalCenter
                    text: "∂"
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pointSize: 14
                }

                TextInput {
                    id: input
                    anchors.left: prompt.right
                    anchors.leftMargin: 9
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.foreground
                    selectionColor: Theme.color3
                    selectedTextColor: Theme.background
                    font.family: Theme.font
                    font.pointSize: 14
                    focus: true
                    clip: true
                    cursorVisible: root.open
                    cursorDelegate: Rectangle {
                        width: 1
                        color: Theme.foreground
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text === ""
                        text: "find the zen"
                        color: Theme.mix(Theme.foreground, Theme.background, 0.4)
                        font: input.font
                    }

                    Keys.onEscapePressed: Sys.panel = ""
                    Keys.onReturnPressed: root.launch(root.results[root.current])
                    Keys.onEnterPressed: root.launch(root.results[root.current])
                    Keys.onUpPressed: root.current = Math.max(0, root.current - 1)
                    Keys.onDownPressed: root.current = Math.min(root.results.length - 1, root.current + 1)
                    Keys.onTabPressed: root.current = Math.min(root.results.length - 1, root.current + 1)
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_PageDown)
                            root.current = Math.min(root.results.length - 1, root.current + root.lines);
                        else if (event.key === Qt.Key_PageUp)
                            root.current = Math.max(0, root.current - root.lines);
                    }
                }
            }

            ListView {
                id: list
                width: parent.width
                // fixed-height like rofi: always room for `lines` rows
                height: root.lines * root.rowHeight + (root.lines - 1) * spacing + topMargin
                topMargin: 2   // listview padding: 2px 0 0
                clip: true
                spacing: 2
                model: root.results
                currentIndex: root.current
                highlightMoveDuration: 120
                boundsBehavior: Flickable.StopAtBounds
                interactive: true

                highlight: Rectangle {
                    radius: 3
                    color: Theme.color3
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool selected: index === root.current
                    width: list.width
                    height: root.rowHeight

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 8
                        width: parent.width - 16
                        elide: Text.ElideRight
                        text: row.modelData.name
                        color: row.selected ? Theme.background : Theme.foreground
                        font.family: Theme.font
                        font.pointSize: 14
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: root.current === row.index ? root.launch(row.modelData) : root.current = row.index
                        onDoubleTapped: root.launch(row.modelData)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.results.length === 0
                    text: "nothing found"
                    color: Theme.mix(Theme.foreground, Theme.background, 0.45)
                    font.family: Theme.font
                    font.pixelSize: 15
                }
            }
        }
    }
}
