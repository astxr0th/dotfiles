pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Bluetooth

Singleton {
    id: root

    // ---- Commands (edit these to taste) ----
    readonly property string launcherCmd: "rofi -show drun"
    readonly property string shutdownCmd: "loginctl poweroff"
    readonly property string rebootCmd: "loginctl reboot"
    readonly property string suspendCmd: "loginctl suspend"
    readonly property string exitCmd: "mmsg dispatch quit"
    readonly property string wallpaperDir: Quickshell.env("HOME") + "/wal"
    readonly property string scriptDir: Quickshell.shellDir + "/scripts"
    readonly property string wifiCmd: "bash " + scriptDir + "/wifi-menu.sh"
    readonly property string screenshotCmd: "bash " + scriptDir + "/screenshot.sh"
    readonly property string bluetoothCmd: "kitty -e bluetoothctl"
    readonly property string mixerCmd: "pavucontrol"

    // ---- Panels & lock ----
    property string panel: ""      // "", center, network, mixer, wallpaper, launcher, screenshot, recorder
    property string networkTab: "wifi"
    property real netIconY: -1     // screen y of the sidebar wifi icon's center (set by SideBar)
    property bool locked: false
    property bool dnd: false
    property string hostname: ""

    Process {
        command: ["cat", "/etc/hostname"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.hostname = text.trim()
        }
    }

    function toggle(name) {
        if (name === "wifi" || name === "bluetooth")
            return openNetwork(name);
        panel = panel === name ? "" : name;
    }
    function openNetwork(tab) {
        networkTab = tab;
        panel = panel === "network" && networkTab === tab ? "" : "network";
    }
    function lock() {
        panel = "";
        locked = true;
    }

    function run(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    // ---- Mango tags (workspaces) ----
    // monitor name -> { tags: [...], active: [...] }
    property var monitors: ({})

    function tagsFor(name) {
        const m = monitors[name] ?? Object.values(monitors)[0];
        if (!m)
            return [];
        // Like the Hyprland original: only show tags that exist (occupied or active)
        return m.tags.filter(t => t.is_active || t.client_count > 0);
    }

    function viewTag(i) {
        run("mmsg dispatch view," + i + ",0");
    }

    Process {
        id: tagWatch
        command: ["mmsg", "watch", "all-monitors"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const j = JSON.parse(line);
                    const out = {};
                    for (const m of j.monitors)
                        out[m.name] = {
                            tags: m.tags,
                            active: m.active_tags
                        };
                    root.monitors = out;
                } catch (e) {}
            }
        }
        onExited: tagRestart.start()
    }
    Timer {
        id: tagRestart
        interval: 1000
        onTriggered: tagWatch.running = true
    }

    // ---- Resources ----
    property int cpu: 0
    property int memory: 0
    property string memoryFree: ""
    property int temperature: 0
    property int disk: 0
    property string diskFree: ""
    property var _lastCpu: null

    function human(kb) {
        const units = ["Ki", "Mi", "Gi", "Ti"];
        let v = kb, u = 0;
        while (v >= 1024 && u < units.length - 1) {
            v /= 1024;
            u++;
        }
        return (v >= 10 ? v.toFixed(0) : v.toFixed(1)) + units[u];
    }

    Process {
        id: statProc
        command: ["sh", "-c", "head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const f = lines[0].split(/\s+/).slice(1).map(Number);
                const idle = f[3] + f[4];
                const total = f.reduce((a, b) => a + b, 0);
                if (root._lastCpu) {
                    const dt = total - root._lastCpu.total;
                    const di = idle - root._lastCpu.idle;
                    if (dt > 0)
                        root.cpu = Math.round(100 * (dt - di) / dt);
                }
                root._lastCpu = { total, idle };
                const mem = {};
                for (const l of lines.slice(1)) {
                    const p = l.split(/\s+/);
                    mem[p[0]] = Number(p[1]);
                }
                root.memory = Math.round(100 * (mem["MemTotal:"] - mem["MemAvailable:"]) / mem["MemTotal:"]);
                root.memoryFree = root.human(mem["MemAvailable:"]);
            }
        }
    }

    Process {
        id: tempProc
        command: ["sh", "-c", "sensors 2>/dev/null | grep -m1 -E '^(Core 0|Tctl|Package id 0):' | grep -oE '[+-][0-9]+' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: root.temperature = parseInt(text) || 0
        }
    }

    Process {
        id: diskProc
        command: ["sh", "-c", "df -h --output=pcent,avail / | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(/\s+/);
                root.disk = parseInt(p[0]) || 0;
                root.diskFree = p[1] ?? "";
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statProc.running = true;
            tempProc.running = true;
        }
    }
    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: diskProc.running = true
    }

    // ---- Battery ----
    property bool hasBattery: false
    property int battery: 0
    property string timeLeft: "Battery status: Time information not available."

    Process {
        id: batProc
        command: ["sh", "-c", "for b in /sys/class/power_supply/BAT*; do [ -e \"$b\" ] || exit 0; cat \"$b/capacity\"; upower -i /org/freedesktop/UPower/devices/battery_$(basename $b) 2>/dev/null | grep -E 'time to (empty|full)'; exit 0; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l);
                root.hasBattery = lines.length > 0;
                if (!root.hasBattery)
                    return;
                root.battery = parseInt(lines[0]) || 0;
                const m = (lines[1] ?? "").match(/time to (empty|full):\s+([\d.]+)\s+(\w+)/);
                if (!m) {
                    root.timeLeft = "Battery status: Time information not available.";
                    return;
                }
                const v = parseFloat(m[2]);
                const mins = m[3].startsWith("hour") ? Math.round(v * 60) : Math.round(v);
                root.timeLeft = Math.floor(mins / 60) + " h " + (mins % 60) + " min to " + m[1];
            }
        }
    }
    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: batProc.running = true
    }

    // ---- Brightness ----
    property bool hasBacklight: false
    property int brightness: 0

    function setBrightness(v) {
        brightness = Math.round(v);
        run("brightnessctl -q s " + Math.round(v) + "%");
    }

    Process {
        id: blProc
        command: ["sh", "-c", "ls /sys/class/backlight 2>/dev/null | grep -q . && command -v brightnessctl >/dev/null && brightnessctl -m | cut -d, -f4"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.hasBacklight = text.trim() !== "";
                root.brightness = parseInt(text) || 0;
            }
        }
    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: blProc.running = true
    }

    // ---- Network ----
    property string netIcon: Icons.wifiOff
    property string netName: "None"

    Process {
        id: netProc
        command: ["sh", "-c", "t=$(nmcli -t -f TYPE,STATE device | grep -E '^(ethernet|wifi):connected$' | head -1 | cut -d: -f1); " + "if [ \"$t\" = wifi ]; then nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi | awk -F: '$1==\"yes\"{print \"wifi|\"$2\"|\"$3; exit}'; " + "elif [ \"$t\" = ethernet ]; then echo \"ethernet||$(nmcli -t -f NAME,TYPE connection show --active | grep ethernet | head -1 | cut -d: -f1)\"; " + "else echo 'none||None'; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [type, sig, name] = text.trim().split("|");
                root.netName = name || "None";
                if (type === "ethernet")
                    root.netIcon = Icons.ethernet;
                else if (type === "wifi") {
                    const s = parseInt(sig) || 0;
                    root.netIcon = s > 80 ? Icons.wifi4 : s > 60 ? Icons.wifi3 : s > 40 ? Icons.wifi2 : s > 20 ? Icons.wifi1 : Icons.wifi0;
                } else
                    root.netIcon = Icons.wifiOff;
            }
        }
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }

    // ---- Bluetooth ----
    readonly property bool bluetoothOn: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property string bluetoothIcon: bluetoothOn ? Icons.btOn : Icons.btOff

    // ---- Audio ----
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int volume: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property string volumeIcon: muted ? Icons.volMute : volume > 50 ? Icons.volHigh : volume > 0 ? Icons.volLow : Icons.volMute

    function setVolume(v) {
        if (sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(100, v)) / 100;
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    // ---- Idle inhibit (replaces the hypridle toggle) ----
    property bool idleInhibited: false

    // ---- Media ----
    readonly property MprisPlayer player: {
        const ps = Mpris.players.values;
        return ps.find(p => p.isPlaying) ?? ps.find(p => p.trackTitle) ?? ps[0] ?? null;
    }
    readonly property bool hasMusic: (player?.trackTitle ?? "") !== ""
    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string artUrl: player?.trackArtUrl ?? ""
    readonly property bool playing: player?.isPlaying ?? false
    readonly property real seek: player && player.length > 0 ? Math.min(100, 100 * player.position / player.length) : 0

    function setSeek(pct) {
        if (player?.canSeek && player.length > 0)
            player.position = pct / 100 * player.length;
    }

    Timer {
        interval: 1000
        running: root.playing
        repeat: true
        onTriggered: root.player?.positionChanged()
    }
}
