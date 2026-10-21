// shell-maison : shell de bureau entièrement en Quickshell, qui remplace Noctalia morceau par morceau.
// Chaque composant est un fichier à part, assemblé ici.
// Lancement : qs -c shell-maison (lien ~/.config/quickshell/shell-maison → ce dossier)
// Essai d'un onglet de l'île : ISLAND_TEST=<onglet> qs -c shell-maison

import Quickshell

ShellRoot {
    Island {}
    Bar {}
    Popups {}
    Osd {}
}
