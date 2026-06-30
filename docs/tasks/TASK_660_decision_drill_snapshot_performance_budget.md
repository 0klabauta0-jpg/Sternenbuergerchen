# TASK_660 - Decision Drill Snapshot Performance Budget

## Ziel / Problem
TASK_658 und TASK_659 machen den Frontier-Probe-Decision-Drill spielbar und sichtbar, aber der volle Szene-/GO-/Evidence-Lauf ist schwergewichtig. Er soll nicht als Standard-Smoke fuer jeden kleinen Report- oder UI-Folgeschritt dienen.

## Sinnhaftigkeit / Ursache
Der Drill bleibt wertvoll als Recapture, wenn sich Szene, UI oder Command-Pfad wirklich aendern. Fuer normale Folgearbeit brauchen wir aber eine schnelle Budget-/Contract-Pruefung, die erkennt, ob der schwere Drill budgetiert ist und ob das Evidence-Paket weiter als read-only Review-Artefakt verstanden wird.

## Umfang
- TASK_659-Manifest um Performance-Budget-Metadaten erweitern.
- Schnellen TASK_660-Verifier ohne Missionsszenenstart anlegen.
- TASK_660 schreibt `tmp/decision_drill_snapshot_performance_budget.json`.
- Der aktuelle HTML-Handbuchbericht bekommt Budget-Felder und empfiehlt danach den Host/Client-Klicklauf.

## Nicht-Ziele
- Kein neues Movement, LOS, Combat, Objective oder Multiplayer-Verhalten.
- Kein Versuch, den schweren TASK_659-Lauf in diesem Slice umzubauen.
- Kein Ersatz fuer den menschlichen F6-Fensterblick.
- Keine UI-seitige Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_659_frontier_probe_decision_drill_f6_evidence.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- Der schnelle TASK_660-Verifier laedt keine Mission-Testscene.
- TASK_659 enthaelt ein explizites Full-Drill-Recapture-Budget und schreibt es ins Manifest.
- TASK_660 erzeugt ein eigenes Budget-Manifest mit Heavy-/Fast-Gate, Recapture-Policy und naechstem Multiplayer-Schritt.
- HTML-Report exportiert TASK_660-Status, Budget-Policy und naechsten Host/Client-Klicklauf.
- Bestehende TASK_659-Evidence bleibt read-only.

## Betroffene Dateien
- `docs/tasks/TASK_660_decision_drill_snapshot_performance_budget.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `scripts/tests/task_659_frontier_probe_decision_drill_f6_evidence.gd`
- `scripts/tests/task_660_decision_drill_snapshot_performance_budget.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_660_decision_drill_snapshot_performance_budget.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_659_frontier_probe_decision_drill_f6_evidence.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_652_current_state_handbook_refresh.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_660 misst nicht die echte Spieler-FPS und ersetzt keinen Profiler.
- Der schwere TASK_659-Recapture bleibt absichtlich vorhanden, soll aber nur bei visuellen/Command-Pfad-Aenderungen laufen.
- Naechster sinnvoller Spielbarkeits-Schritt ist `TASK_661 - Host Client Decision Drill Click Evidence`.
