# TASK_951 - Decision Overlay Real F6 Visual Review

## Ziel / Problem
TASK_950 macht die drei Decision-Preview-Choices im F6-HUD sichtbar. Die erste Verdrahtung war aber noch technisch formuliert und nutzte rohe Choice-IDs wie `covered_push` oder `kill_zone_dash`. Fuer ein angenehmes Spielgefuehl muss die Anzeige wie ein Spielerhinweis wirken, nicht wie Debug-Daten.

## Sinnhaftigkeit / Ursache
Der Spieler entscheidet vor `GO`. Diese Entscheidung muss schnell lesbar sein: sicher, riskant oder suizidal, ohne interne IDs entschluesseln zu muessen. Gleichzeitig darf der Review keine manuelle Sichtabnahme vortaeuschen.

## Umfang
- Mission-Control-Choice-Line nutzt menschliche Labels statt roher Choice-IDs.
- Choice-Cards erhalten `display_title`, `display_text` und `line_label`.
- `get_decision_overlay_real_f6_visual_review_snapshot()` bewertet automatisiert Lesbarkeit, Textlaenge und Read-only-Grenzen.
- `get_command_feedback_snapshot()` exportiert den TASK_951-Review-Snapshot.

## Nicht-Ziele
- Keine manuelle Sichtabnahme vortaeuschen.
- Kein neues HUD-Panel.
- Kein Command-, Movement-, Fire-, Damage- oder Multiplayer-State.
- Kein Combat- oder Pathfinding-Rewrite.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_950_wire_decision_scenario_into_f6_mission_hud.md`

## Akzeptanzkriterien
- Die HUD-Zeile nennt weiter `SAFE`, `RISKY` und `SUICIDAL`, enthaelt aber keine rohen IDs `covered_push`, `exposed_crossing` oder `kill_zone_dash`.
- Die Choice-Line bleibt unter 96 Zeichen.
- Alle drei Choice-Cards haben spielernahe Display-Texte.
- TASK_951 meldet `ready_for_real_f6_sight_check`, verlangt aber weiter `manual_review_required`.
- Snapshot bleibt read-only und erzeugt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_951_decision_overlay_real_f6_visual_review.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_951_decision_overlay_real_f6_visual_review.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_950_wire_decision_scenario_into_f6_mission_hud.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die automatisierte Pruefung ersetzt keinen echten Screenshot-/F6-Sichtcheck. Sie stellt nur sicher, dass der sichtbare Text nicht mehr wie Debug-Material wirkt und kurz genug fuer die bestehende HUD-Flaeche ist.
