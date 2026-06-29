# TASK_603 - Mission HUD Density Interaction Polish

## Ziel / Problem
TASK_602 definiert Pacing-Budgets, aber der Missionsteil kann im echten Interaktionsmoment noch zu textlastig werden: Objective, Cargo, Contact/Combat, ROE und SUP erscheinen als mehrere nebeneinander konkurrierende HUD-Informationen.

Ziel ist ein kleiner HUD-Dichte-Slice fuer Mission Control: vorhandene Objective-/Cargo-/Contact-/ROE-/Combat-Daten werden in eine kompakte `ACT`-Zeile verdichtet, ohne Gameplay-Wahrheit ins HUD zu verschieben.

## Sinnhaftigkeit / Ursache
Der Spieler soll im Missionsteil schnell erkennen, was jetzt wichtig ist: Zielstatus, Cargo/Objective-Gate, aktuelle Feuerregel und Kampfkontakt. Mehr Textzeilen machen den Core-Loop langsamer, obwohl die Daten bereits vorhanden sind.

## Umfang
- `MissionTacticalSandboxController` erzeugt einen read-only Mission-HUD-Interaction-Density-Snapshot.
- Mission Control nutzt eine kompakte `ACT`-Zeile fuer Objective, Cargo, ROE und Contact/Combat.
- `get_command_feedback_snapshot()` exportiert den neuen Density-Snapshot fuer Tests und spaetere UI-Verbraucher.
- Ein Verifier prueft den integrierten Frontier-Probe-Kontext mit Objective, Cargo, SUP-ROE und Combat-Kontakt.

## Nicht-Ziele
- Kein neues Missionssystem.
- Kein Combat-, Cargo- oder Objective-Rewrite.
- Keine neue UI-seitige Gameplay-Wahrheit.
- Kein finaler menschlicher F6-Sichttest in diesem Task.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_602_core_loop_transition_pacing_polish.md`
- `docs/tasks/TASK_554_frontier_probe_integrated_objective_playthrough_smoke.md`
- `docs/tasks/TASK_581_suppress_fire_intent_outcome_smoke.md`

## Akzeptanzkriterien
- `get_mission_hud_density_interaction_polish_snapshot()` ist read-only und setzt `ui_sets_gameplay_truth = false`.
- Mission Control enthaelt eine kompakte `ACT`-Zeile.
- Objective, Cargo, ROE und Contact/Combat bleiben trotz Verdichtung auffindbar.
- SUP ist sichtbar, wenn die ausgewaehlte Feuerregel `suppress` ist.
- Der sichtbare Stack bleibt bei maximal einer Zusatzzeile und innerhalb des Zeichenbudgets.
- Der TASK_603-Verifier laeuft gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_603_mission_hud_density_interaction_polish.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_603_mission_hud_density_interaction_polish.gd`
- Regression: `task_554_frontier_probe_integrated_objective_playthrough_smoke.gd`
- Regression: `task_581_suppress_fire_intent_outcome_smoke.gd`
- Regression: `task_546_mission_combat_feedback_hud_density_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Task prueft Headless-Snapshots, keinen finalen menschlichen Pixel-Sichttest.
- Die `ACT`-Zeile ist bewusst dicht. Falls sie im echten FullHD-Spielbild zu lang wirkt, sollte TASK_604 oder ein spaeterer Sichttest die Segmentlaengen anhand echter Screenshots kalibrieren.
- Objective/Cargo/Combat bleiben read-only Quellen; spaetere Runtime-Aenderungen brauchen eigene Tasks.
