// État du système partagé par les onglets : musique, son, tuiles, météo, moniteurs.
// Les lectures coûteuses (processus) ne tournent que pendant que l'île est ouverte (active).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

Singleton {
    id: sys

    property bool active: false
    onActiveChanged: if (active) refresh()

    readonly property date now: clock.date
    SystemClock { id: clock; precision: SystemClock.Minutes }

    // Musique : le lecteur choisi dans l'onglet Musique, sinon celui qui joue, sinon le premier chargé
    readonly property var players: Mpris.players.values.filter(p => p.trackTitle)
    property var chosen: null
    readonly property var player:
        (players.includes(chosen) && chosen) || players.find(p => p.isPlaying) || players[0] || null

    // Son
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isSink && n.isStream && n.audio)
    PwObjectTracker { objects: [sys.sink, sys.source].concat(sys.sinks).concat(sys.streams) }

    // Wi-Fi et Bluetooth lus auprès de Noctalia. La lumière nocturne n'a pas de lecture d'état : retenue ici.
    // ponytail: état local, faux si on la bascule ailleurs (barre, raccourci) ; lire Noctalia s'il expose un jour son état
    property bool wifi: false
    property bool bluetooth: false
    property bool nightlight: false

    Process {
        id: status
        command: ["sh", "-c", "noctalia msg wifi-status; noctalia msg bluetooth-status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n")
                sys.wifi = l[0] === "on"
                sys.bluetooth = l[1] === "on"
            }
        }
    }

    function run(args) {
        Quickshell.execDetached(args)
        later.restart()
    }
    Timer { id: later; interval: 700; onTriggered: sys.refresh() }

    function refresh() {
        status.running = true
        uptime.reload()
        wifiScan.running = true
    }

    // Réseaux Wi-Fi (nmcli) : [{ ssid, signal, secure, inUse, known }]
    property var networks: []
    Process {
        id: wifiScan
        command: ["sh", "-c", "nmcli -t -f NAME connection show; echo ---; nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("---\n")
                const known = parts[0].trim().split("\n")
                const seen = {}
                sys.networks = (parts[1] || "").trim().split("\n").map(l => {
                    const f = l.split(":")
                    return { inUse: f[0] === "*", ssid: f[1], signal: +f[2], secure: !!f[3] && f[3] !== "--", known: known.includes(f[1]) }
                }).filter(n => n.ssid && !seen[n.ssid] && (seen[n.ssid] = true))
                  .sort((a, b) => b.inUse - a.inUse || b.signal - a.signal)
            }
        }
    }

    // Allumé depuis…
    property string uptimeText: ""
    FileView {
        id: uptime
        path: "/proc/uptime"
        onLoaded: {
            const s = Math.floor(parseFloat(text()))
            const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60)
            sys.uptimeText = (h ? h + " h " : "") + m + " min"
        }
    }

    // Météo : cache de Noctalia (même source que son centre de contrôle)
    property var weather: null
    FileView {
        path: Quickshell.env("HOME") + "/.cache/noctalia/weather.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { sys.weather = JSON.parse(text()).snapshot } catch (e) {}
        }
    }

    // Moniteurs (onglet Système) : processeur, mémoire, carte graphique, disque
    property bool monitoring: false
    property real cpu: 0
    property real cpuTemp: 0
    property real ram: 0
    property string ramText: ""
    property real gpu: 0
    property real gpuTemp: 0
    property string vramText: ""
    property real disk: 0
    property string diskText: ""
    property var lastCpu: null

    Timer {
        running: sys.active && sys.monitoring
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: { stat.reload(); mem.reload(); probe.running = true }
    }
    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
            const idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0)
            if (sys.lastCpu) sys.cpu = 1 - (idle - sys.lastCpu.idle) / Math.max(1, total - sys.lastCpu.total)
            sys.lastCpu = { idle: idle, total: total }
        }
    }
    FileView {
        id: mem
        path: "/proc/meminfo"
        onLoaded: {
            const get = k => +(text().match(new RegExp(k + ":\\s+(\\d+)")) || [0, 0])[1]
            const total = get("MemTotal"), used = total - get("MemAvailable")
            sys.ram = used / total
            sys.ramText = (used / 1048576).toFixed(1) + " / " + (total / 1048576).toFixed(1) + " Go"
        }
    }
    Process {
        id: probe
        command: ["sh", "-c", "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits; sensors -u coretemp-isa-0000 2>/dev/null | awk '/temp1_input/{print $2; exit}'; df -B1 --output=used,size / | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n")
                const g = (l[0] || "").split(",").map(Number)
                sys.gpu = (g[0] || 0) / 100
                sys.gpuTemp = g[1] || 0
                sys.vramText = ((g[2] || 0) / 1024).toFixed(1) + " / " + ((g[3] || 0) / 1024).toFixed(0) + " Go"
                sys.cpuTemp = parseFloat(l[1]) || 0
                const d = (l[2] || "").trim().split(/\s+/).map(Number)
                sys.disk = d[0] / d[1] || 0
                sys.diskText = (d[0] / 1e9).toFixed(0) + " / " + (d[1] / 1e9).toFixed(0) + " Go"
            }
        }
    }
}
