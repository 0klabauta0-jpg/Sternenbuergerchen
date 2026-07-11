# TASK_1139 - Command Matrix Player Language and Icon Hierarchy Polish

## Ziel / Problem
Die Command Matrix steht direkt neben den inzwischen deutsch lesbaren Fireteam-Karten, zeigt aber weiter `Move`, `Take`, `Hold`, `Flank`, `Target`, `Clear` sowie kryptische Feuerregeln `HF/RF/FW/SUP`.

## Ursache / Sinn
Der Drop-Light-Presenter ueberschreibt Szenenlabels mit historischen englischen Kurztexten. Der Action-Catalog dokumentiert dieselben Anzeigenamen. Vorhandene CC0-Taktikicons werden bisher nur fuer Stances verwendet, obwohl sie die kleinen Matrix-Buttons schneller unterscheidbar machen koennen.

## Umfang
- Primaerbefehle und Bearbeitungsaktionen in deutsche Spielsprache uebersetzen.
- Sichtbare, mit Icons gekoppelte Matrixcodes `BW`, `HL`, `FL`, `NM`, `ZL` sowie `FH`, `AF`, `FF`, `UN` verwenden und im Tooltip vollstaendig deutsch erklaeren.
- Vorhandene kuratierte Kenney-Icons fuer Befehle und Feuerregeln wiederverwenden.
- Mission-Command-Hierarchy-Contract auf dieselben Anzeigenamen und Tooltips bringen.

## Nicht-Ziele
- Keine Aenderung an Command-IDs, Buttonnamen, NodePaths, Hotkeys oder Callbacks.
- Keine Aenderung an SimulationRoot, Fire-Rule-State, RPCs, Commands, Effects oder Snapshots.
- Kein neuer Icon-Download und kein Umbau des Bottom-Docks.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1138_selected_fireteam_member_card_name_priority_fit_polish.md`
- `docs/tasks/TASK_836_release_firefight_command_matrix_visual_polish.md`
- `scripts/ui/mission_command_hierarchy_contract.gd`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien
- Die sichtbaren Primaerbuttons sind deutsch und besitzen unterscheidbare Icons.
- Feuerregeln sind ohne englische Abkuerzung lesbar; Tooltips erklaeren die Folge.
- Genau eine Feuerregel bleibt aktiv und alle bestehenden Callbacks funktionieren.
- Action-Catalog und Runtime-Presenter verwenden dieselbe Sprache.
- Keine neue Framearbeit oder Gameplay-Mutation.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/ui/mission_command_hierarchy_contract.gd`
- `scenes/tests/mission_reactivity_test.tscn`
- `scripts/tests/task_1139_command_matrix_player_language_icon_hierarchy_polish.gd`
- Status, Roadmap und HTML-Arbeitsbericht

## Lokale Pruefung
- TASK_1139-Verifier
- TASK_191, TASK_513, TASK_572, TASK_836, TASK_1109, TASK_222
- echter Full-HD-Capture

## Risiken / offene Punkte
Die Matrix bleibt absichtlich kompakt. Falls Icon plus Langtext im echten Fenster nicht passt, haben Icon, eindeutiger Kurztext und deutscher Tooltip Vorrang.
