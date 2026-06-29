# TASK_542 - Mission First Contact Readability Pass

## Status: IMPLEMENTIERT

## Ziel / Problem
Nach der ersten Bewegung muss ein erster Feindkontakt lesbar sein. Der Spieler soll erkennen, dass ein Kontakt existiert, fuer welches Fireteam er gilt, wie sicher/alt die Meldung ist und ob Overlay, Status-/Event-Feedback und Threat-/Cover-Kontext dazu passen.

## Sinnhaftigkeit / Ursache
TASK_541 macht GO und Bewegung lesbar. Der naechste taktische Reibungspunkt ist der Moment, in dem die Bewegung auf Feindkontakt trifft. Wenn Kontakt, Bedrohung und Reaktion nicht klar sind, wirkt Combat zufaellig.

## Umfang
- `MissionTacticalSandboxController` expose't einen read-only `get_mission_first_contact_readability_snapshot()`.
- Der Snapshot fasst bestehende Contact-, FireteamContact-, Communication/Eventlog-, Cover-, Security-, LOS-/Heatmap- und Command-Feedback-Snapshots zusammen.
- Ein Smoke startet eine Homebase-Direktmission, dropped/deboarded ein Fireteam, plant/fuehrt den ersten Move aus, setzt einen Gegner in Kontaktreichweite und prueft Contact-Readability.
- Der laufende HTML-Arbeitsbericht wird aktualisiert.

## Nicht-Ziele
- Kein neues Combat-System.
- Keine Aenderung an LOS, Pathfinding oder Damage.
- Kein neues HUD-System und kein per-frame UI-Rebuild.
- Kein manueller Pixel-/F6-Sichttest in diesem Task.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_541_mission_first_move_execution_feedback_pass.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/runtime_script_layout_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Der Snapshot setzt `ui_sets_gameplay_truth = false`.
- Mindestens ein Contact-Eintrag fuer das ausgewaehlte Fireteam ist sichtbar.
- Der Contact-Eintrag enthaelt Detection-State, Position, Confidence und Report-Text.
- Contact-Overlay oder Primary3D-Contact-Snapshot spiegelt die Kontakte.
- Tactical-Communication/Eventlog oder Command-Feedback zeigt den Kontakt an.
- Cover-/Threat-/Security-Kontext ist mit dem Contact verknuepft oder als unknown klar markiert.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_542_mission_first_contact_readability_pass.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_542_mission_first_contact_readability_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_541_mission_first_move_execution_feedback_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Task prueft Headless-Snapshots und keine menschliche Pixelwirkung.
- Der Kontakt wird im Smoke bewusst positioniert, damit die Lesbarkeit reproduzierbar ist; echte Missionsbalance und Patrouillenfuehrung bleiben Folgearbeit.
