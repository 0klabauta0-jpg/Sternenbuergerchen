# TASK_655 - Frontier Probe One-Screen Visual Tuning Findings

## Ziel / Problem
TASK_654 hat ein F6-Playtest-Notizpaket erzeugt. Beim Durchlauf fallen zwei konkrete Reibungen auf: Im sichtbaren Mission-Control-Text kann die neue `PLAN ... | NEXT ...`-Zeile durch die alte detaillierte `NEXT ...`-Zeile redundant wirken, und das TASK_654-Manifest liest `one_screen_line_within_limit` aus der falschen Snapshot-Ebene.

## Sinnhaftigkeit / Ursache
Der Spieler soll im Missionsbild schneller erkennen, was als Naechstes passiert. Doppelte NEXT-Sprache macht das HUD dichter, ohne mehr Entscheidungsklarheit zu geben. Gleichzeitig muessen Evidence-Artefakte widerspruchsfrei bleiben, sonst fuehren Review-Notizen in die Irre.

## Umfang
- Sichtbaren Mission-Control-Text fuer Frontier Probe verdichten: Wenn `PLAN ... | NEXT ...` aktiv ist, wird die alte detaillierte NEXT-Zeile im sichtbaren Panel unterdrueckt.
- Detaillierter NEXT-Snapshot und `get_command_feedback_snapshot().frontier_probe_next_interaction_line` bleiben erhalten.
- TASK_654-Manifestfeld `one_screen_line_within_limit` auf die korrekte Readout-Ebene korrigieren.
- Read-only Snapshot `get_frontier_probe_one_screen_visual_tuning_snapshot()` fuer den Befund ergaenzen.
- Aktuellen HTML-Handbuchbericht auf TASK_655 aktualisieren.

## Nicht-Ziele
- Kein neues Objective-, Cargo-, Combat- oder Command-System.
- Kein automatischer GO-/Debrief-/Homebase-Flow.
- Kein neuer HUD-Baum und keine zweite Gameplay-Wahrheit im UI.
- Kein Ersatz fuer einen echten menschlichen F6-Screenshot.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_653_frontier_probe_one_screen_playability_pass.md`
- `docs/tasks/TASK_654_frontier_probe_one_screen_f6_playtest_notes.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- Mission Control enthaelt die kompakte `PLAN LZ -> AA -> COM 18s -> CARGO | NEXT AA`-Zeile.
- Mission Control zeigt im Startzustand nicht zusaetzlich die alte `NEXT AA ausschalten | Cargo blockiert`-Zeile.
- `get_command_feedback_snapshot()` exportiert die detaillierte NEXT-Zeile weiter fuer bestehende Contracts.
- TASK_654-Manifest meldet `one_screen_line_within_limit = true` fuer die kompakte Zeile.
- Snapshot und Manifest bleiben read-only und setzen keine Gameplay-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_655_frontier_probe_one_screen_visual_tuning_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_654_frontier_probe_one_screen_f6_playtest_notes.gd`
- `scripts/tests/task_655_frontier_probe_one_screen_visual_tuning_findings.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_655_frontier_probe_one_screen_visual_tuning_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_654_frontier_probe_one_screen_f6_playtest_notes.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_653_frontier_probe_one_screen_playability_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_637_frontier_probe_playfeel_next_interaction.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_652_current_state_handbook_refresh.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der echte F6-Fensterblick bleibt offen; TASK_655 reduziert eine belegte Textredundanz, bewertet aber keine finale Optik.
- Wenn der detaillierte NEXT-Text spaeter bewusst sichtbar gebraucht wird, sollte er als Tooltip/Detail statt als zweite Mission-Control-Zeile zurueckkommen.
