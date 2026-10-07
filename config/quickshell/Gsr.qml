pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// GPU Screen Recorder backend (replaces gsr-ui). Recorder processes run
// detached so a shell reload never kills a recording; their state is read
// back from the process list. Saved files trigger scripts/gsr-saved.sh.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string runDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property string saveScript: Quickshell.shellDir + "/scripts/gsr-saved.sh"

    // ---- Settings (recorder.json next to shell.qml) ----
    property alias settings: cfg

    FileView {
        path: Quickshell.shellDir + "/recorder.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: cfg
            property string source: ""          // monitor name | portal | region ("" = first monitor)
            property int fps: 60
            property string quality: "cbr"      // medium | high | very_high | ultra | cbr
            property int bitrate: 40000         // kbps, used with cbr
            property string codec: "auto"
            property string container: "mp4"
            property bool cursor: true
            property var audio: ["alsa_output.usb-Logitech_G_series_G435_Wireless_Gaming_Headset_202105190004-00.analog-stereo.monitor", "alsa_input.usb-Logitech_G_series_G435_Wireless_Gaming_Headset_202105190004-00.mono-fallback"]
            property int replaySeconds: 60
            property string replayStorage: "ram"
            property bool replayOnStartup: true
            property bool notifications: true
            property string folder: Quickshell.env("HOME") + "/Videos"
        }
    }

    // ---- Per-boot runtime state (survives shell reloads, not reboots) ----
    FileView {
        path: root.runDir + "/zenities-recorder.json"
        blockLoading: true
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: rt
            property bool autoStarted: false
            property string replayArgs: ""      // command the running replay was started with
            property real replayRecStart: 0     // epoch secs of a recording made from the replay session
            property bool paused: false
            property real pausedAt: 0
            property real pausedTotal: 0
        }
    }

    // ---- Devices ----
    property var sources: []        // [{ id, label }]
    property var audioDevices: []   // [{ id, label, input }]
    property bool listed: false

    function refreshDevices() {
        capList.running = true;
        audioList.running = true;
    }

    Process {
        id: capList
        running: true
        command: ["gpu-screen-recorder", "--list-capture-options"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const l of text.trim().split("\n").filter(l => l)) {
                    const [id, size] = l.split("|");
                    if (id === "portal")
                        out.push({ id, label: "Window" });
                    else if (id === "region")
                        out.push({ id, label: "Region" });
                    else if (id !== "screen" && id !== "focused")
                        out.push({ id, label: id + (size ? " · " + size : "") });
                }
                root.sources = out;
                root.listed = true;
            }
        }
    }

    Process {
        id: audioList
        running: true
        command: ["gpu-screen-recorder", "--list-audio-devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.audioDevices = text.trim().split("\n").filter(l => l.includes("|")).map(l => {
                    const i = l.indexOf("|");
                    const id = l.slice(0, i);
                    const input = id === "default_input" || !id.endsWith(".monitor") && id !== "default_output";
                    const label = l.slice(i + 1).replace(/^Monitor of /, "");
                    return { id, label, input };
                });
            }
        }
    }

    function audioOn(id) {
        return (cfg.audio ?? []).includes(id);
    }
    function setAudio(id, on) {
        const a = (cfg.audio ?? []).filter(x => x !== id);
        if (on)
            a.push(id);
        cfg.audio = a;
    }
    function set(key, value) {
        cfg[key] = value;
    }

    // ---- Running processes ----
    property int replayPid: 0
    property int recordPid: 0
    property real recordAge: 0       // seconds since the standalone recorder started
    property string runningReplayArgs: ""
    property bool polled: false
    property real now: Date.now() / 1000

    readonly property bool replaying: replayPid > 0
    readonly property bool recordingViaReplay: replaying && rt.replayRecStart > 0
    readonly property bool recording: recordPid > 0 || recordingViaReplay
    readonly property bool paused: recording && rt.paused
    readonly property bool canPause: recordPid > 0
    // settings changed since the replay was started
    readonly property bool replayStale: replaying && rt.replayArgs !== replayArgs().join(" ")

    readonly property int elapsed: {
        if (!recording)
            return 0;
        const raw = recordPid > 0 ? recordAge : now - rt.replayRecStart;
        const p = rt.pausedTotal + (rt.paused ? now - rt.pausedAt : 0);
        return Math.max(0, Math.floor(raw - p));
    }
    readonly property string elapsedText: {
        const s = elapsed, h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60);
        const pad = v => String(v).padStart(2, "0");
        return (h > 0 ? h + ":" : "") + pad(m) + ":" + pad(s % 60);
    }

    Process {
        id: poll
        command: ["sh", "-c", "for p in $(pgrep -f '^gpu-screen-recorder -w '); do " + "printf '%s\\t%s\\t' \"$p\" \"$(ps -o etimes= -p \"$p\" | tr -d ' ')\"; tr '\\0' ' ' < /proc/$p/cmdline; echo; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                let rp = 0, rec = 0, age = 0, rargs = "";
                for (const l of text.split("\n").filter(l => l)) {
                    const [pid, et, args] = l.split("\t");
                    if (/ -r \d+/.test(args)) {
                        rp = Number(pid);
                        rargs = args.trim();
                    } else if (!/ -o (rtmp|srt|https?):/.test(args)) {
                        rec = Number(pid);
                        age = Number(et) || 0;
                    }
                }
                const wasRecording = root.recording;
                root.replayPid = rp;
                root.recordPid = rec;
                root.recordAge = age;
                root.runningReplayArgs = rargs;
                if (!rp && rt.replayRecStart > 0)
                    rt.replayRecStart = 0;
                if (wasRecording && !root.recording)
                    root.resetPause();
                root.polled = true;
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.now = Date.now() / 1000;
            poll.running = true;
        }
    }

    // Start the replay buffer once per boot (gsr-ui's "turn on at system startup")
    readonly property bool readyToAutostart: polled && listed && audioDevices.length > 0
    onReadyToAutostartChanged: {
        if (!readyToAutostart || rt.autoStarted)
            return;
        rt.autoStarted = true;
        if (cfg.replayOnStartup && !replaying)
            startReplay(true);
    }

    // ---- Command building ----
    function captureSource() {
        const s = cfg.source;
        if (s === "portal" || s === "region")
            return s;
        if (sources.some(x => x.id === s))
            return s;
        return sources.find(x => x.id !== "portal" && x.id !== "region")?.id ?? "screen";
    }

    function common(source, region) {
        const a = ["gpu-screen-recorder", "-w", source];
        if (source === "region")
            a.push("-region", region);
        a.push("-c", cfg.container, "-f", String(cfg.fps), "-k", cfg.codec, "-ac", "opus", "-fm", "vfr", "-cr", "limited", "-encoder", "gpu", "-cursor", cfg.cursor ? "yes" : "no");
        if (cfg.quality === "cbr")
            a.push("-bm", "cbr", "-q", String(cfg.bitrate));
        else
            a.push("-q", cfg.quality);
        // only devices that exist right now, merged into one track like gsr-ui
        const devs = (cfg.audio ?? []).filter(id => audioDevices.some(d => d.id === id));
        if (devs.length)
            a.push("-a", devs.map(d => "device:" + d).join("|"));
        a.push("-restore-portal-session", "yes", "-v", "no", "-sc", saveScript);
        return a;
    }

    function replayArgs() {
        // replay can't use a one-off region; fall back to the monitor
        const src = captureSource() === "region" ? (sources.find(x => x.id !== "portal" && x.id !== "region")?.id ?? "screen") : captureSource();
        return common(src, "").concat(["-r", String(cfg.replaySeconds), "-replay-storage", cfg.replayStorage, "-restart-replay-on-save", "yes", "-o", cfg.folder, "-ro", cfg.folder]);
    }

    // Spawn detached, logging to $XDG_RUNTIME_DIR so failures can be reported
    function spawn(kind, args) {
        const log = runDir + "/zenities-gsr-" + kind + ".log";
        Quickshell.execDetached(["sh", "-c", "log=$1; dir=$2; shift 2; mkdir -p \"$dir\"; exec \"$@\" >\"$log\" 2>&1", "sh", log, cfg.folder].concat(args));
        failCheck.kind = kind;
        failCheck.log = log;
        failCheck.restart();
    }

    function notify(title, body, icon) {
        if (!cfg.notifications)
            return;
        Quickshell.execDetached(["notify-send", "-a", "Recorder", "-i", icon || "media-record", title, body || ""]);
    }

    // Report a recorder that died right after launch
    Timer {
        id: failCheck
        property string kind
        property string log
        interval: 3000
        onTriggered: {
            const alive = kind === "replay" ? root.replaying : root.recordPid > 0;
            if (!alive)
                failRead.running = true;
        }
    }
    Process {
        id: failRead
        command: ["sh", "-c", "grep -iE 'error|fail|invalid' \"$1\" | tail -1", "sh", failCheck.log]
        stdout: StdioCollector {
            onStreamFinished: Quickshell.execDetached(["notify-send", "-a", "Recorder", "-u", "critical", "-i", "dialog-error", failCheck.kind === "replay" ? "Replay failed to start" : "Recording failed to start", text.trim() || "See " + failCheck.log])
        }
    }

    function sendSignal(pid, sig) {
        if (pid > 0)
            Quickshell.execDetached(["kill", "-s", sig, String(pid)]);
    }

    function resetPause() {
        rt.paused = false;
        rt.pausedAt = 0;
        rt.pausedTotal = 0;
    }

    // ---- Actions ----
    function startReplay(quiet) {
        if (replaying)
            return;
        const args = replayArgs();
        rt.replayArgs = args.join(" ");
        rt.replayRecStart = 0;
        spawn("replay", args);
        if (!quiet)
            notify("Instant replay on", "Keeping the last " + secondsLabel(cfg.replaySeconds), "media-playlist-repeat");
    }

    function stopReplay() {
        if (!replaying)
            return;
        sendSignal(replayPid, "INT");
        replayPid = 0;
        rt.replayRecStart = 0;
        notify("Instant replay off", "", "media-playback-stop");
    }

    function toggleReplay() {
        replaying ? stopReplay() : startReplay(false);
    }

    function restartReplay() {
        if (!replaying)
            return startReplay(false);
        sendSignal(replayPid, "INT");
        replayPid = 0;
        rt.replayRecStart = 0;
        restartLater.restart();
    }
    Timer {
        id: restartLater
        interval: 1200
        onTriggered: root.startReplay(false)
    }

    // util-linux kill only knows bare RTMIN by name, so real-time signals are numeric
    readonly property int sigRtMin: 34
    readonly property var saveSignals: ({ "10": 1, "30": 2, "60": 3, "300": 4, "600": 5, "1800": 6 })

    function saveReplay(seconds) {
        if (!replaying) {
            Quickshell.execDetached(["notify-send", "-a", "Recorder", "-i", "dialog-information", "Instant replay is off", "Turn it on to save clips"]);
            return;
        }
        sendSignal(replayPid, seconds > 0 && saveSignals[seconds] ? String(sigRtMin + saveSignals[seconds]) : "USR1");
    }

    function startRecord(region) {
        if (recording)
            return;
        resetPause();
        const src = captureSource();
        if (region || src === "region") {
            regionPick.running = true;
            return;
        }
        // reuse the replay's capture session, like gsr-ui does
        if (replaying && src === replayArgs()[2]) {
            sendSignal(replayPid, String(sigRtMin));
            rt.replayRecStart = Date.now() / 1000;
            notify("Recording started", "", "media-record");
            return;
        }
        recordWith(src, "");
    }

    function recordWith(src, region) {
        const file = cfg.folder + "/Recording_" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + "." + cfg.container;
        spawn("record", common(src, region).concat(["-o", file]));
        notify("Recording started", "", "media-record");
    }

    Process {
        id: regionPick
        command: ["slurp", "-f", "%wx%h+%x+%y"]
        stdout: StdioCollector {
            onStreamFinished: {
                const g = text.trim();
                if (/^\d+x\d+\+-?\d+\+-?\d+$/.test(g))
                    root.recordWith("region", g);
            }
        }
    }

    function stopRecord() {
        if (!recording)
            return;
        if (recordPid > 0) {
            sendSignal(recordPid, "INT");
            recordPid = 0;
        } else {
            sendSignal(replayPid, String(sigRtMin));
            rt.replayRecStart = 0;
        }
        resetPause();
    }

    function toggleRecord(region) {
        recording ? stopRecord() : startRecord(region);
    }

    function togglePause() {
        if (!canPause)
            return;
        sendSignal(recordPid, "USR2");
        const t = Date.now() / 1000;
        if (rt.paused) {
            rt.pausedTotal += t - rt.pausedAt;
            rt.paused = false;
            notify("Recording resumed", "", "media-record");
        } else {
            rt.pausedAt = t;
            rt.paused = true;
            notify("Recording paused", "", "media-playback-pause");
        }
    }

    function secondsLabel(s) {
        return s >= 60 ? s / 60 + (s === 60 ? " minute" : " minutes") : s + " seconds";
    }
}
