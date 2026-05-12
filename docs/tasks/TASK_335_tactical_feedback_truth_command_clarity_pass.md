# TASK_335 - Tactical Feedback Truth Command Clarity Pass

## Ziel
Taktische Befehle sollen fuer den Spieler klarer werden, ohne dass UI-Skripte Gameplay-Zustand verwalten. Der Task schaerft Disabled-Reasons, Tooltips, Command-Matrix-Feedback und sichtbare Fehlerfaelle ueber die bestehende Snapshot-Wahrheit.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_331 - Mission Tactical Controller Adapter Split First Slice
- TASK_275 - Command Button Hierarchy Arrangement Overhaul
- TASK_286 - UI Feedback Truth Regression Review

## Kontext
Die UI besitzt bereits Mechanismen fuer Command-Feedback. Das Risiko liegt darin, dass Panels bei neuen Sonderfaellen eigene Auswahl- oder Befehlslogik duplizieren. Dieser Task verbessert Verstaendlichkeit fuer Ziele, LZs, Fireteams, GO/Ready und blockierte Aktionen, ohne die Zustandswahrheit aus `SimulationRoot`/Runtime herauszuziehen.

## Umfang
1. Disabled-Reasons:
   - Unspezifische oder fehlende Gruende fuer blockierte Mission-Kommandos inventarisieren.
   - Pro Grund eine kurze, spielbare UI-Formulierung festlegen.
2. Tooltips und Statuszeile:
   - Command-Matrix, LZ/GO, Fire-Sector und Tile-Auswahl bekommen konsistente Hinweise aus dem Snapshot.
   - Keine langen Erklaertexte im Spielbild, nur konkrete Handlungshinweise.
3. Visual Feedback:
   - Fehlende Auswahl, ungueltiges Tile, fehlende LZ, kein Fireteam und blockierte Air Lane sichtbar unterscheiden.
4. Regression:
   - Test prueft, dass UI-Komponenten keine eigene Gameplay-Entscheidung speichern.

## Nicht-Ziele
- Keine neuen Befehle.
- Keine neue Tutorialstrecke.
- Keine Balance-Aenderungen.
- Kein Redesign der kompletten Mission-HUD-Anordnung.

## Akzeptanzkriterien
- [x] Blockierte Kernaktionen haben konkrete Disabled-Reasons.
- [x] Command-Matrix und Statuszeile zeigen konsistente Snapshots.
- [x] Kein neues UI-Skript fuehrt eine zweite Selection- oder Command-Wahrheit.
- [x] Mission-Command-Visual- und UI-Feedback-Gates bleiben gruen.
- [x] Ein kurzer Report nennt verbleibende Playtest-Fragen.

## Erwartete Dateien
- `scripts/mission/**`
- betroffene Mission-HUD-/Command-UI-Skripte
- `scripts/tests/task_335_tactical_feedback_truth_command_clarity_pass.gd`
- `docs/reports/tactical_feedback_truth_command_clarity_pass.md`
- `docs/tasks/TASK_335_tactical_feedback_truth_command_clarity_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_335_tactical_feedback_truth_command_clarity_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_315_mission_grid_tile_selection_command_gate.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_mission_right_click_order_flow.gd`
- [x] `git diff --check`

## Risiken
- Mehr Feedback kann auch mehr Laerm bedeuten. Der Task muss Klarheit verbessern, nicht jede interne Regel im HUD erklaeren.

## Naechster Schritt
Danach kann ein manueller Playtest entscheiden, welche Hinweise zu dominant oder zu leise sind.
