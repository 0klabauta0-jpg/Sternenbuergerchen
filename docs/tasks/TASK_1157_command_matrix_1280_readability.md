# TASK_1157 - Command Matrix 1280 Readability

## Ziel / Problem

Die Befehlsmatrix ist im exportierten 1280x720-Fenster funktional, aber ihre
Kurztexte, Icons und technischen Slotmarker sind nach der Skalierung des
1920x1080-HUDs zu klein. Primaerbefehle und Feuerregeln lassen sich im
laufenden Gefecht nicht schnell genug unterscheiden.

## Ursache / Sinnhaftigkeit

Die Matrix verwendet 9-Pixel-Spieltext und sichtbare 6-Pixel-Marker. Bei der
1280er Fensterskalierung bleiben davon effektiv etwa 6 beziehungsweise 4
Pixel. Die festen fuenf Spalten sind fuer die vorhandenen 20 Slots notwendig;
der Fix muss deshalb innerhalb der stabilen Matrixgeometrie arbeiten.

## Umfang

- Lesbare Mindestschrift fuer Primaerbefehle, Feuerregeln und GO.
- Vorhandene kuratierte Icons innerhalb der quadratischen Buttons groesser
  und stabil zentrieren.
- Nur in der Command-Matrix die horizontalen Skin-Innenabstaende reduzieren,
  damit Icon und Zweibuchstaben-Code gemeinsam sichtbar bleiben.
- Technische `16.x`-Slotmarker im Spielerbild ausblenden, als Node/Metadatum
  fuer bestehende Vertraege und Diagnose aber erhalten.
- Read-only Layout-Snapshot fuer den 1280x720-Akzeptanzfall.

## Nicht-Ziele

- Keine Aenderung an Command-IDs, Slotreihenfolge, NodePaths, Hotkeys,
  Callbacks oder fuenfspaltiger Geometrie.
- Keine Aenderung an SimulationRoot, Command Queue, ROE, RPC oder
  Multiplayer-Ownership.
- Kein Umbau des gesamten Bottom-Docks.

## Relevante Contracts / Dokumente

- `docs/tasks/TASK_1139_command_matrix_player_language_icon_hierarchy_polish.md`
- `docs/tasks/TASK_836_release_firefight_command_matrix_visual_polish.md`
- `docs/dev/mission_command_feedback_contract.md`
- `scripts/meta/drop_light_layout_contract.gd`

## Akzeptanzkriterien

- Bei einem 1280x720-Viewport verwenden Primaerbefehle mindestens 12 Pixel
  interne Schriftgroesse und die vorhandenen Icons bleiben sichtbar.
- Feuerregeln verwenden mindestens 11 Pixel, GO mindestens 13 Pixel.
- Horizontale Matrix-Innenabstaende bleiben bei hoechstens 4 Pixeln pro Seite.
- Technische Slotmarker bleiben vorhanden, sind im Spielerbild aber nicht
  sichtbar.
- Fuenf Spalten, 20 Slots, Slot-IDs, Buttonnamen und Callbacks bleiben
  unveraendert.
- Der Styling-Pfad erzeugt keine Commands, Effects oder Multiplayer-Snapshots.

## Betroffene Dateien

- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1157_command_matrix_1280_readability.gd`
- `docs/tasks/TASK_1157_command_matrix_1280_readability.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- aktueller HTML-Arbeitsbericht

## Lokale Pruefung

- TASK_1157 bei 1280x720.
- TASK_1139, TASK_836, TASK_180 und Command-/Multiplayer-Regressionen.
- Echter exportierter 1280x720-Fensterblick.
- `git diff --check`.

## Risiken / offene Punkte

Die Matrix bleibt kompakt. Langtexte gehoeren weiterhin in Tooltips; die
Buttons priorisieren eindeutige Icons, kurze deutsche Codes und klare
Aktivzustaende.
