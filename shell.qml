// shell-maison : shell de bureau entièrement en Quickshell (a remplacé Noctalia).
// modules/ : un dossier par élément visible ; services/ : données partagées ;
// components/ : briques d'interface ; assets/ : images et données.
// Lancement : qs -c shell-maison (lien ~/.config/quickshell/shell-maison → ce dossier)
// Essai d'un onglet de l'île : ISLAND_TEST=<onglet> qs -c shell-maison

import Quickshell
import qs.modules.bar
import qs.modules.emojis
import qs.modules.ile
import qs.modules.notifications
import qs.modules.osd
import qs.modules.polkit
import qs.modules.pressepapiers
import qs.modules.verrouillage
import qs.modules.wallhaven

ShellRoot {
    Island {}
    Bar {}
    Popups {}
    Osd {}
    Polkit {}
    Lock {}
    Emojis {}
    Clipboard {}
    Wallhaven {}
}
