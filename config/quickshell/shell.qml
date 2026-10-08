//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark

import QtQuick
import Quickshell
import Quickshell.Io

// zenities (github.com/hayyaoe/zenities) rebuilt in Quickshell for mango.
ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens

        SideBar {}
    }

    Lock {}

    NetworkPanel {
        screen: Quickshell.screens[0]
    }

    ControlCenter {
        screen: Quickshell.screens[0]
    }

    NotifPopups {
        screen: Quickshell.screens[0]
    }

    MixerPanel {
        screen: Quickshell.screens[0]
    }

    WallpaperPanel {
        screen: Quickshell.screens[0]
    }

    Launcher {
        screen: Quickshell.screens[0]
    }

    ScreenshotTool {
        screen: Quickshell.screens[0]
    }

    RecorderPanel {
        screen: Quickshell.screens[0]
    }

    // `qs ipc call recorder toggle|record|region|pause|replay|save`
    // `qs ipc call recorder saveLast 60` (10, 30, 60, 300, 600, 1800 seconds)
    IpcHandler {
        target: "recorder"

        function toggle(): void {
            Sys.toggle("recorder");
        }
        function record(): void {
            Gsr.toggleRecord(false);
        }
        function region(): void {
            Gsr.toggleRecord(true);
        }
        function pause(): void {
            Gsr.togglePause();
        }
        function replay(): void {
            Gsr.toggleReplay();
        }
        function save(): void {
            Gsr.saveReplay(0);
        }
        function saveLast(seconds: int): void {
            Gsr.saveReplay(seconds);
        }
    }

    // `qs ipc call widgets toggle` — SUPER+SHIFT+Space, opens the center
    IpcHandler {
        target: "widgets"

        function toggle(): void {
            Sys.toggle("center");
        }
    }

    // `qs ipc call panel toggle center|wifi|bluetooth|mixer|wallpaper|launcher|screenshot|recorder`
    IpcHandler {
        target: "panel"

        function toggle(name: string): void {
            Sys.toggle(name);
        }
    }
}
