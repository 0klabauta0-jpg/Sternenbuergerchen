# TASK_653 - Frontier Probe One-Screen Playability Pass

## Ziel / Problem
Nach TASK_651/TASK_652 ist die Host/Client-Evidence wieder sauber, aber der naechste Fortschritt soll sich wieder wie Spiel anfuehlen. Die Frontier-Probe-Route hat bereits LZ, AA, Computer-Hold, Cargo und Debrief-Handoff, aber der Spieler braucht im Missionsbild eine kompakte Leselinie: Was ist der Plan, was ist jetzt als Naechstes dran, und welche Alternativen sind sinnvoll?

## Sinnhaftigkeit / Ursache
Viele bestehende Verifier beweisen Teilvertraege. Fuer Spielbarkeit reicht das nicht: Der Ablauf muss auf einem Bildschirm als kleine Mission lesbar sein, ohne dass man die Task-Historie kennt.

## Umfang
- Leichten Mission-Control-Readout fuer Frontier Probe ergaenzen: `PLAN AA -> COM 18s -> CARGO | NEXT ...`.
- Read-only Snapshot `get_frontier_probe_one_screen_playability_snapshot()` bauen.
- Snapshot prueft Route, Callouts, aktuelle Naechstaktion, zwei Planoptionen, Debrief-Handoff und UI-/Runtime-Grenzen.
- Command-Feedback-Snapshot exportiert den neuen Playability-Readout fuer HUD/Tests.
- Aktuellen HTML-Handbuchbericht auf TASK_653/TASK_654 aktualisieren.

## Nicht-Ziele
- Kein neues Objective-System.
- Kein Combat- oder Balance-Rewrite.
- Kein automatischer Debrief-/Homebase-Wechsel.
- Kein neues Missionsszenario und keine neue Gameplay-Wahrheit im HUD.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_630_frontier_probe_mini_scenario_feel_route.md`
- `docs/tasks/TASK_637_frontier_probe_playfeel_next_interaction.md`
- `docs/tasks/TASK_638_frontier_probe_debrief_handoff_feel.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien
- Mission Control kann eine kompakte `PLAN AA -> COM 18s -> CARGO | NEXT ...`-Zeile anzeigen.
- Snapshot nennt mindestens zwei sinnvolle Planoptionen fuer den One-Screen-Playtest.
- Snapshot bleibt read-only und setzt keine Gameplay-Wahrheit.
- Abgeschlossene Frontier-Probe-Route fuehrt weiterhin sichtbar zu Debrief/Homebase.
- Bestehende TASK_630/TASK_637/TASK_638-Vertraege bleiben anschlussfaehig.

## Betroffene Dateien
- `docs/tasks/TASK_653_frontier_probe_one_screen_playability_pass.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_652_current_state_handbook_refresh.gd`
- `scripts/tests/task_653_frontier_probe_one_screen_playability_pass.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_653_frontier_probe_one_screen_playability_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_630_frontier_probe_mini_scenario_feel_route.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_637_frontier_probe_playfeel_next_interaction.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_638_frontier_probe_debrief_handoff_feel.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_652_current_state_handbook_refresh.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_653 macht den One-Screen-Ablauf lesbarer, ersetzt aber keinen echten menschlichen F6-Playtest.
- Die Planoptionen sind Orientierung, keine neuen Buttons und keine neuen Commands.
