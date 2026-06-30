# TASK_658 - Frontier Probe One-Screen Player Decision Drill

## Ziel / Problem
Nach TASK_657 ist die Frontier-Probe-F6-Anzeige lesbarer. Jetzt muss der naechste kleine Spielerzug pruefbar werden: Der Spieler soll `NEXT AA` sehen, einen sinnvollen Move Richtung AA vorplanen, Risiko/Path/Preview lesen und GO ueber den bestehenden Ausfuehrungspfad bestaetigen koennen.

## Sinnhaftigkeit / Ursache
Schoene Anzeige allein macht das Spiel nicht spielbar. Der naechste Schritt muss beweisen, dass die Anzeige in eine echte, kurze Entscheidung fuehrt, ohne neue Mission-Control-Wahrheit oder neue Bewegungslogik zu bauen.

## Umfang
- Read-only Snapshot `get_frontier_probe_one_screen_player_decision_drill_snapshot()` ergaenzen.
- Snapshot kombiniert bestehende One-Screen-/F6-Polish-, First-Move-, Threat-Preview- und Execution-Feedback-Vertraege.
- Verifier spielt einen kleinen Ablauf: Fireteam blue aktivieren, Move Richtung AA planen, Preview lesen, GO ausfuehren, Execution-Feedback pruefen.
- Aktuellen HTML-Handbuchbericht auf TASK_658 aktualisieren.

## Nicht-Ziele
- Kein neues Command-System.
- Kein neues Pathfinding, Combat, Objective oder Cargo-Verhalten.
- Kein automatischer Debrief-/Homebase-Wechsel.
- Kein neuer HUD-Baum und keine UI-seitige Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_657_frontier_probe_f6_visual_polish_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- `NEXT AA` ist im Drill-Snapshot sichtbar.
- Der empfohlene Plan nennt AA als ersten Schritt und endet in `GO`.
- Vor GO sind Move-Preview, Threat/Risk-Preview und GO-Bereitschaft lesbar.
- Nach GO meldet der bestehende First-Move-Execution-Snapshot sichtbare Ausfuehrung.
- Snapshot und Manifest bleiben read-only; nur der Verifier fuehrt den echten GO-Spielzug aus.

## Betroffene Dateien
- `docs/tasks/TASK_658_frontier_probe_one_screen_player_decision_drill.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_658_frontier_probe_one_screen_player_decision_drill.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_658_frontier_probe_one_screen_player_decision_drill.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_657_frontier_probe_f6_visual_polish_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_567_frontier_probe_first_move_threat_preview_readability_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_658 prueft einen kurzen Drill, kein vollstaendiges Szenariobalancing.
- Der naechste sinnvolle Schritt ist ein sichtbares F6-Evidence-Paket oder ein echter Host/Client-Klicklauf mit demselben Entscheidungsfokus.
