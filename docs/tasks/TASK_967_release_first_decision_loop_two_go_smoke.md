# TASK_967 - Release First Decision Loop Two GO Smoke

## Ziel / Problem
TASK_966 verbindet die zweite sichtbare Entscheidung mit vorhandenen Controller-Pfaden, aber der Anschluss ist nur ein Command-Draft. TASK_967 legt fest, welche Evidence beweist, dass Confirm und GO fuer diesen zweiten Griff wirklich getrennt durch die vorhandene Bedienkette laufen.

## Sinnhaftigkeit / Ursache
Der zweite Decision-Loop soll sich wie ein kleiner spielbarer Griff anfuehlen: Entscheidung lesen, bestaetigen, GO druecken, Feedback sehen. Ohne Smoke kann der UI-Pfad so aussehen, als waere er angeschlossen, obwohl Confirm, GO oder Post-GO-Feedback nicht wirklich belegt sind.

## Umfang
- Neuer read-only Service `ReleaseFirstDecisionLoopTwoGoSmoke`.
- Controller-Snapshot `get_release_first_decision_loop_two_go_smoke_snapshot()`.
- Command-Feedback exportiert Smoke-Zeile, Gate und Status.
- Smoke-Evidence prueft vorhandene Confirm-/GO-Pfade, getrennte Schritte, Resultate und Post-GO-Feedback.

## Nicht-Ziele
- Kein neuer Runtime-Button.
- Kein automatisches GO.
- Kein neuer Order-Ausfuehrer.
- Keine Mutation von Commands, Movement, Damage, Combat oder Multiplayer-Wahrheit im Smoke-Service.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_966_release_first_decision_loop_two_execution_hook.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- Fehlende oder nicht bereite TASK_966-Source blockiert TASK_967.
- Ein bereiter Hook ohne Smoke-Trace meldet `needs_loop_two_go_smoke`.
- Ein bestandener Trace benoetigt getrennte Confirm- und GO-Schritte.
- Confirm- und GO-Pfade muessen existieren, aufgerufen worden sein und Erfolg melden.
- Post-GO-Feedback muss sichtbar sein.
- Snapshot bleibt read-only und erzeugt keine neue Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_go_smoke.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_967_release_first_decision_loop_two_go_smoke.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_967_release_first_decision_loop_two_go_smoke.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_966_release_first_decision_loop_two_execution_hook.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_965_release_first_decision_loop_two_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_967 ist noch keine echte UI-Bedienung des zweiten Buttons. Der naechste sinnvolle Schritt ist `TASK_968 - Release First Decision Loop Two Runtime Button`, damit der im Smoke belegte Pfad aus der sichtbaren Runtime-Bedienung erreichbar wird.
