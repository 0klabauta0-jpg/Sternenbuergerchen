# TASK_068c – Gitternetz-Overlay und Himmelsrichtungen

- Phase: 14 – Map-Editor-Workflow und Politur
- Status: offen
- Abhaengigkeiten: TASK_068b (Drag-Painting und Hover-Preview)

## Ziel
Die Iso-Ausrichtung der Karte soll im Editor leichter lesbar werden, ohne die Szene mit vielen zusaetzlichen Debug-Linien zu ueberladen.

## Anforderungen
1. Die Kartenflaeche soll ein leichtes Grid-/Checkerboard-Signal erhalten, damit Tile-Grenzen lesbar bleiben.
2. Die vier Himmelsrichtungen sollen an den Kartenextremen sichtbar gemacht werden.
3. Das Richtungsmapping der Iso-Karte soll im Editor klar sein.

## Akzeptanzkriterien
- Die Kartenorientierung ist ueber `N/O/S/W` direkt erkennbar.
- Die Tile-Struktur bleibt lesbar, ohne dass ein schweres Linien-Gitter pro Tile noetig ist.

## Nicht in diesem Task
- komplex konfigurierbares Debug-Gitter
- frei ein- und ausblendbare Editor-HUD-Systeme
- Gameplay-Wirkung der Himmelsrichtungen
