// Onglet Bluetooth : interrupteur, recherche, appareils ; clic = connecter / déconnecter (ou appairer)
import QtQuick
import Quickshell.Bluetooth
import qs.services
import qs.components

Column {
    spacing: 8
    readonly property var adapter: Bluetooth.defaultAdapter
    // Appairés d'abord, puis par nom
    readonly property var devices: Bluetooth.devices.values.filter(d => d.paired || d.name)
        .sort((a, b) => b.connected - a.connected || b.paired - a.paired || a.name.localeCompare(b.name))

    Row {
        width: parent.width
        spacing: 10
        Tile {
            width: (parent.width - 10) / 2; height: 48
            icon: adapter && adapter.enabled ? "\u{f00af}" : "\u{f00b2}"
            label: adapter && adapter.enabled ? "Bluetooth activé" : "Bluetooth désactivé"
            on: !!adapter && adapter.enabled
            onClicked: if (adapter) adapter.enabled = !adapter.enabled
        }
        Tile {
            width: (parent.width - 10) / 2; height: 48
            icon: "\u{f0349}"
            label: adapter && adapter.discovering ? "Recherche…" : "Rechercher"
            on: !!adapter && adapter.discovering
            onClicked: if (adapter && adapter.enabled) adapter.discovering = !adapter.discovering
        }
    }

    Text {
        visible: !!adapter && adapter.enabled && devices.length === 0
        text: "Aucun appareil : lance une recherche"
        color: Theme.c.on_surface_variant
        font { family: Theme.font; pixelSize: 12 }
    }

    Repeater {
        model: adapter && adapter.enabled ? devices : []
        ListRow {
            required property var modelData
            width: parent.width
            icon: modelData.icon && modelData.icon.indexOf("audio") >= 0 ? "\u{f02cb}"
                : modelData.icon && modelData.icon.indexOf("input") >= 0 ? "\u{f037d}" : "\u{f00af}"
            label: modelData.name
            detail: modelData.pairing ? "Appairage…" : modelData.connected
                ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + " % · " : "") + "Connecté"
                : modelData.paired ? "Appairé" : "Nouveau"
            active: modelData.connected
            onClicked: {
                if (modelData.connected) modelData.disconnect()
                else if (modelData.paired) modelData.connect()
                else { modelData.trusted = true; modelData.pair() }
            }
        }
    }
}
