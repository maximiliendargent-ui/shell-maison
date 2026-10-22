// Écran de verrouillage : fond d'écran flouté, grande horloge, date et météo, musique, mot de passe (PAM).
// Verrouiller : qs -c shell-maison ipc call lock lock (Super + Ctrl + L, onglet Session de l'île).
// Essai sans risque : qs -c shell-maison ipc call lock test → même écran dans une fenêtre ordinaire
// (pas de vrai verrou), qui se ferme avec le bon mot de passe ou Échap.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

Scope {
    id: lock

    property bool locked: false   // vrai verrou de session
    property bool testing: false  // essai dans une fenêtre ordinaire
    readonly property bool active: locked || testing
    property string wallpaper: ""
    property string error: ""

    function start(test) {
        if (active) return
        wallpaperProc.running = true
        error = ""
        if (test) testing = true
        else locked = true
    }
    function unlock() { locked = false; testing = false }

    Process {
        id: wallpaperProc
        command: [Quickshell.shellDir + "/bin/fond", "get"]
        stdout: StdioCollector { onStreamFinished: lock.wallpaper = text.trim() }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { lock.start(false) }
        function test(): void { lock.start(true) }
        function stopTest(): void { lock.testing = false }
    }

    // Vérification du mot de passe (pile PAM pam/lock du dépôt : celle de la console, sans délai après un échec)
    property string typed: ""
    PamContext {
        id: pam
        configDirectory: Quickshell.shellDir + "/pam"
        config: "lock"
        onResponseRequiredChanged: if (responseRequired) respond(lock.typed)
        onCompleted: result => {
            lock.typed = ""
            if (result === PamResult.Success) lock.unlock()
            else lock.error = "Mot de passe incorrect"
        }
        onError: lock.error = "Erreur d'authentification"
    }
    function submit(password) {
        if (pam.active || !password) return
        typed = password
        error = ""
        pam.start()
    }

    WlSessionLock {
        locked: lock.locked
        WlSessionLockSurface {
            color: "black"
            LockContent { anchors.fill: parent; host: lock }
        }
    }

    // Essai : même contenu dans une fenêtre plein écran ordinaire
    PanelWindow {
        visible: lock.testing
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "black"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shell-maison-lock-test"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        LockContent { anchors.fill: parent; host: lock }
    }
}
