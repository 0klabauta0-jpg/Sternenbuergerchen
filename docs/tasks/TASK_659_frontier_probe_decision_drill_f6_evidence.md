# TASK_659 - Frontier Probe Decision Drill F6 Evidence

## Ziel / Problem
TASK_658 prueft den ersten kleinen Frontier-Probe-Spielerzug bereits headless: `NEXT AA` lesen, Move Richtung AA planen, Risiko/Path/GO-Readiness lesen und GO ueber den bestehenden Ausfuehrungspfad bestaetigen. Jetzt braucht dieser Drill ein sichtbares F6-/Evidence-Paket, damit der Mini-Loop auch ausserhalb der Konsolenausgabe beurteilt werden kann.

## Sinnhaftigkeit / Ursache
Der Spielpfad ist nur dann wirklich hilfreich, wenn man ihn sehen und diskutieren kann. Ein PNG/JSON-Paket macht den gleichen Drill reviewbar, ohne neue Gameplay-Wahrheit in UI, Report oder Testartefakt zu verschieben.

## Umfang
- Neuer Verifier erzeugt `tmp/frontier_probe_decision_drill_f6_evidence.png` und `.json`.
- Der Verifier nutzt den bestehenden TASK_658-Drillpfad mit `issue_right_click_command_for_test()` und `execute_selected_fireteam_orders()`.
- Das Manifest trennt Vor-GO-Preview und Nach-GO-Execution.
- Headless-Laeufe erzeugen ein markiertes Evidence-Board; nicht-headless Laeufe duerfen einen echten Viewport-Readback speichern.
- Das Manifest enthaelt ab TASK_660 Performance-Budget-Metadaten und eine Recapture-Policy.
- Der aktuelle HTML-Handbuchbericht wird auf TASK_659 aktualisiert.

## Nicht-Ziele
- Kein neues Command-System.
- Kein neues Pathfinding, LOS, Combat, Objective, Cargo oder Multiplayer-Verhalten.
- Kein finaler Sichtentscheid; der menschliche Fensterblick bleibt explizit offen.
- Keine UI-seitige Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_658_frontier_probe_one_screen_player_decision_drill.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- Der Verifier schreibt ein FullHD-PNG und ein Manifest unter `tmp/`.
- Das Manifest enthaelt TASK_659, Quelle TASK_658, Preview-Stage, Execution-Stage, NEXT AA, GO-Readiness, Execution-Feedback und manuelle Review-Flags.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben gesetzt.
- Headless-Evidence wird klar als Review-Artefakt markiert.
- Bestehender TASK_658-Drill bleibt gruen.

## Betroffene Dateien
- `docs/tasks/TASK_659_frontier_probe_decision_drill_f6_evidence.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `scripts/tests/task_658_frontier_probe_one_screen_player_decision_drill.gd`
- `scripts/tests/task_659_frontier_probe_decision_drill_f6_evidence.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_659_frontier_probe_decision_drill_f6_evidence.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_658_frontier_probe_one_screen_player_decision_drill.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_657_frontier_probe_f6_visual_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Verifier ist wegen Szenenstart und GO-Ausfuehrung relativ schwergewichtig.
- Fuer Standard-Regressionen soll ab TASK_660 der schnelle Budget-Guard reichen; TASK_659 bleibt fuer visuellen/Command-Pfad-Recapture.
- Der menschliche F6-Fensterblick ist weiterhin nicht automatisch erledigt.
- Der naechste sinnvolle Schritt ist ein kleines Performance-Budget fuer den Decision-Drill oder ein echter Host/Client-Klicklauf mit demselben sichtbaren Entscheidungsfokus.
