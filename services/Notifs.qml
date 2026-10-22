// Notifications : serveur org.freedesktop.Notifications, bulles affichées, historique, Ne pas déranger.
// Historique enregistré dans ~/.local/state/shell-maison/notifications.json (50 dernières).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: notifs

    property bool dnd: false
    property var popups: []    // notifications affichées en bulle (objets Notification)
    property var history: []   // { app, icon, summary, body, time } — la plus récente en premier

    NotificationServer {
        id: server
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: false
        onNotification: n => {
            n.tracked = true
            notifs.history = [{
                app: n.appName, icon: n.appIcon, summary: n.summary, body: n.body, time: Date.now()
            }].concat(notifs.history).slice(0, 50)
            store.save()
            // Ne pas déranger : seules les urgences s'affichent
            if (!notifs.dnd || n.urgency === NotificationUrgency.Critical) notifs.popups = [n].concat(notifs.popups)
            n.closed.connect(() => notifs.popups = notifs.popups.filter(p => p !== n))
        }
    }

    // Message bref affiché par Popups.qml (ex. Ne pas déranger activé)
    property string toast: ""
    Timer { id: toastTimer; interval: 1800; onTriggered: notifs.toast = "" }
    function say(text) { notifs.toast = text; toastTimer.restart() }

    function toggleDnd() {
        notifs.dnd = !notifs.dnd
        say(notifs.dnd ? "\u{f009b}  Ne pas déranger activé" : "\u{f009a}  Ne pas déranger désactivé")
    }

    function hide(n) { notifs.popups = notifs.popups.filter(p => p !== n) }
    function clearPopups() { for (const n of notifs.popups) n.dismiss(); notifs.popups = [] }
    function clearHistory() { notifs.history = []; store.save() }
    // La dernière notification encore ouverte côté appli, même si sa bulle a disparu
    function invokeLatest() {
        const tracked = server.trackedNotifications.values
        const n = notifs.popups[0] || tracked[tracked.length - 1]
        if (!n) return
        const def = n.actions.find(a => a.identifier === "default")
        if (def) def.invoke()
        n.dismiss()
    }

    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.local/state/shell-maison/notifications.json"
        printErrors: false
        onLoaded: {
            try { notifs.history = JSON.parse(text()) } catch (e) {}
        }
        function save() {
            Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/shell-maison"])
            setText(JSON.stringify(notifs.history))
        }
    }

    // Raccourcis : qs -c shell-maison ipc call notifs <clear|dnd|latest|history>
    IpcHandler {
        target: "notifs"
        function clear(): void { notifs.clearPopups() }
        function dnd(): void { notifs.toggleDnd() }
        function latest(): void { notifs.invokeLatest() }
    }
}
