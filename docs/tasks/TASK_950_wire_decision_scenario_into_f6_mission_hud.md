# TASK_950 - Wire Decision Scenario Into F6 Mission HUD

## Ziel / Problem
TASK_949 liefert drei lesbare Move-Preview-Choices, aber der Spieler sieht sie im F6-Missionsfenster noch nicht. Dieser Task verdrahtet den read-only Scenario-Payload in den bestehenden Mission-Control-/Command-Feedback-Pfad.

## Sinnhaftigkeit / Ursache
Der naechste spielbare Griff ist nicht mehr Feuerpolitur, sondern Entscheidungslesbarkeit vor `GO`: Der Spieler soll SAFE/RISKY/SUICIDAL vor dem Commit sehen und verstehen, dass Ghost, Pfad und Threat-Line nur Preview sind.

## Umfang
- `MissionTacticalSandboxController` baut einen TASK_950-HUD-Snapshot aus dem TASK_948/TASK_949-Pfad.
- Mission Control bekommt eine kompakte Choice-Zeile mit `SAFE`, `RISKY` und `SUICIDAL`.
- `get_command_feedback_snapshot()` exportiert denselben Snapshot und dieselbe Choice-Zeile.
- Das Strategic-Status-Label erhaelt Metadaten fuer spaetere Sichtchecks.

## Nicht-Ziele
- Kein neuer Move-Commit.
- Kein Combat-, Damage- oder Fire-Event.
- Keine neue Multiplayer-Wahrheit.
- Kein neues grosses HUD-Panel; dieser Slice ist bewusst die Contract-/Readout-Verdrahtung.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_949_order_preview_threat_overlay_playtest_scenario.md`

## Akzeptanzkriterien
- Drei Choices sind im HUD-Snapshot sichtbar: `covered_push`, `exposed_crossing`, `kill_zone_dash`.
- Die Mission-Control-Zeile nennt `SAFE`, `RISKY` und `SUICIDAL`.
- Command Feedback exportiert `order_preview_threat_overlay_f6_hud` und `order_preview_threat_overlay_choice_line`.
- Snapshot und UI-Wiring bleiben read-only und erzeugen keine Commands, Movement-, Fire-, Damage- oder Multiplayer-State.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_950_wire_decision_scenario_into_f6_mission_hud.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_950_wire_decision_scenario_into_f6_mission_hud.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_949_order_preview_threat_overlay_playtest_scenario.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Slice macht die Decisions sichtbar, aber baut noch keine echte neue F6-Visualkarte. Der naechste sinnvolle Schritt ist ein realer Godot-F6-Sichtcheck fuer Position, Kontrast und Ergonomie der Choice-Zeile.
