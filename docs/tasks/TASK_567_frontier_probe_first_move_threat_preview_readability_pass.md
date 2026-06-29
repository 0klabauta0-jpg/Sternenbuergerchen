# TASK_567 - Frontier Probe First Move Threat Preview Readability Pass

## Ziel / Problem
Nach TASK_566 ist der MP-F6-HUD-Pfad kompakter, aber die erste Move-Entscheidung bleibt inhaltlich noch zu duenn: Der Spieler sieht Ghost/Pfad/ETA, muss aber im HUD nicht klar genug lesen, ob die Preview `safe`, `risky`, `suicidal` oder mangels Kontaktlage `unknown` ist.

## Sinnhaftigkeit / Ursache
TASK_506 bis TASK_509 haben den Tactical-Decision-Clarity-Vertrag, Ghosts, ThreatAnalyzer und Combined Overlay aufgebaut. TASK_540 prueft im integrierten Missionsflow bisher nur, dass die erste Move-Preview existiert. Der fehlende Schritt ist die spielbare Lesbarkeit vor `GO`: Risiko, Grund, Exposure und Render-Preview muessen zusammen im First-Move-Snapshot auftauchen.

## Umfang
- Bestehenden Waypoint-Intent-Preview-Text um eine kurze Risikozeile erweitern.
- Read-only Snapshot `get_frontier_probe_first_move_threat_preview_readability_snapshot()` fuer den Frontier-Probe-First-Move-Pfad.
- Der Snapshot fasst TASK_540, Waypoint-Preview, Command-Feedback und Primary3D-Render-Zahlen zusammen.
- HTML-Zwischenbericht, Status, Roadmap und Contract auf TASK_567 weiterziehen.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen Kontakte erzeugen.
- Kein perfektes Gegnerwissen vor Sichtkontakt.
- Kein Command-Point-System.
- Keine GO-Ausfuehrung.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_506_tactical_decision_clarity_contract.md`
- `docs/tasks/TASK_540_mission_first_move_decision_readability_pass.md`
- `docs/tasks/TASK_566_frontier_probe_multiplayer_f6_hover_panel_polish_pass.md`

## Akzeptanzkriterien
- Der First-Move-Snapshot nennt den Risk-State vor `GO`.
- Der HUD-/Order-Text nennt eine kurze Risikozeile (`SAFE`, `RISKY`, `SUICIDAL` oder `RISK ?`).
- `unknown` ist erlaubt, muss aber mit einem klaren Grund wie `no_threat_context`/`no contact intel` erklaert werden.
- Primary3D meldet Ghost- und Pfad-Preview-Zahlen; Threat-Lines werden bei vorhandenen Line-of-Fire-Daten gezaehlt.
- Snapshot bleibt read-only und fuehrt keinen Befehl aus.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_567_frontier_probe_first_move_threat_preview_readability_pass.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_567_frontier_probe_first_move_threat_preview_readability_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_506_tactical_decision_clarity_contract.gd`
- `git diff --check`

## Risiken / offene Punkte
- Ohne bekannte Kontakte bleibt der erste Move bewusst `unknown`; das ist spielerisch ehrlicher als perfektes Gegnerwissen.
- Der alte TASK_540-Meta-Homebase-Flow haengt in diesem Arbeitslauf nach der Doku-Pruefung im integrierten Homebase/Mission-Startpfad. TASK_567 prueft den First-Move-Snapshot deshalb ueber die stabile Mission-Fixture; die Meta-Flow-Testhygiene bleibt separat.
- Der naechste sichtbare Schritt waere ein manueller F6-Sichttest oder ein kleiner Contact-Setup-Slice, der riskante/suizidale Preview-Ziele direkt im Frontier-Probe-Flow erzeugt.
