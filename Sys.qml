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

    // Touches multimédia : qs -c shell-maison ipc call media <toggle|next|previous>
    IpcHandler {
        target: "media"
        function toggle(): void { if (sys.player) sys.player.togglePlaying() }
        function next(): void { if (sys.player) sys.player.next() }
        function previous(): void { if (sys.player) sys.player.previous() }
    }

    // Son
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isSink && n.isStream && n.audio)
    PwObjectTracker { objects: [sys.sink, sys.source].concat(sys.sinks).concat(sys.streams) }

    // Wi-Fi lu auprès de NetworkManager (Bluetooth : module Quickshell, dans Appareils.qml).
    property bool wifi: false

    // Lumière nocturne (hyprsunset) et veille bloquée (systemd-inhibit, respecté par hypridle) : processus
    // lancés par le shell, allumés tant qu'ils tournent.
    // qs -c shell-maison ipc call system <nightlight|caffeine> (Super + Ctrl + N, Super + Ctrl + I)
    readonly property bool nightlight: sunset.running
    readonly property bool caffeine: inhibit.running
    function toggleNightlight() { sunset.running = !sunset.running }
    function toggleCaffeine() { inhibit.running = !inhibit.running }
    Process { id: sunset; command: ["hyprsunset", "-t", "4000"] }
    Process {
        id: inhibit
        command: ["systemd-inhibit", "--what=idle", "--who=shell-maison", "--why=Veille bloquée", "sleep", "infinity"]
    }
    IpcHandler {
        target: "system"
        function nightlight(): void { sys.toggleNightlight() }
        function caffeine(): void { sys.toggleCaffeine() }
    }

    Process {
        id: status
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: sys.wifi = text.trim() === "enabled" }
    }
    function toggleWifi() { run(["nmcli", "radio", "wifi", sys.wifi ? "off" : "on"]) }

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

    // Météo : Open-Meteo (gratuit, sans clé, la source de Noctalia), relue toutes les 30 min.
    // Mise en forme { location_name, current: {…}, forecast_days: [{…}] } pour Accueil, Météo et le verrouillage.
    readonly property var place: ({ name: "Bruxelles", lat: 50.85, lon: 4.38 })
    property var weather: null
    Process {
        id: weatherProc
        command: ["curl", "-sf", "--max-time", "15", "https://api.open-meteo.com/v1/forecast?latitude=" + sys.place.lat
            + "&longitude=" + sys.place.lon + "&timezone=auto&forecast_days=7"
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,is_day,weather_code,wind_speed_10m"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text), c = r.current, d = r.daily
                    sys.weather = {
                        location_name: sys.place.name,
                        current: {
                            temperature_c: c.temperature_2m, apparent_temperature_c: c.apparent_temperature,
                            relative_humidity_percent: c.relative_humidity_2m, is_day: !!c.is_day,
                            weather_code: c.weather_code, wind_speed_kmh: c.wind_speed_10m
                        },
                        forecast_days: d.time.map((t, i) => ({
                            date_iso: t, weather_code: d.weather_code[i],
                            temperature_max_c: d.temperature_2m_max[i], temperature_min_c: d.temperature_2m_min[i]
                        }))
                    }
                } catch (e) {}  // hors ligne : on garde la dernière météo
            }
        }
    }
    Timer { interval: 30 * 60 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: weatherProc.running = true }

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
