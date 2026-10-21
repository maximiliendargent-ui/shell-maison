// Notifications : serveur org.freedesktop.Notifications, bulles affichées, historique, Ne pas déranger.
// Noctalia tient le service au démarrage : on le lui reprend (il l'autorise), et il le récupère tout seul
// si shell-maison s'arrête.
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

    // Reprend le service à Noctalia : un appel RequestName avec « remplacer » le lui retire puis le libère
    // aussitôt (busctl se ferme). Le serveur ci-dessus et Noctalia se le disputent alors : on recommence
    // jusqu'à ce que ce soit nous (qs), 15 essais au plus
    Timer {
        running: true
        interval: 1500
        onTriggered: Quickshell.execDetached(["sh", "-c",
            "for i in $(seq 15); do " +
            "[ \"$(busctl --user status org.freedesktop.Notifications 2>/dev/null | sed -n 's/^Comm=//p')\" = qs ] && exit 0; " +
            "busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus " +
            "RequestName su org.freedesktop.Notifications 6 >/dev/null; sleep 1; done"])
    }

    function hide(n) { notifs.popups = notifs.popups.filter(p => p !== n) }
    function clearPopups() { for (const n of notifs.popups) n.dismiss(); notifs.popups = [] }
    function clearHistory() { notifs.history = []; store.save() }
    function invokeLatest() {
        const n = notifs.popups[0]
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
        function dnd(): void { notifs.dnd = !notifs.dnd }
        function latest(): void { notifs.invokeLatest() }
    }
}
