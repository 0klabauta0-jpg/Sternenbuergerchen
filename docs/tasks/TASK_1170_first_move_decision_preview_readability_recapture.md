# TASK_1170 - First Move Decision Preview Readability Recapture

## Ziel / Problem
Nach TASK_1169 ist der linke taktische Stack im Release akzeptiert. Der naechste spielerische Griff ist wieder die erste Move-Entscheidung nach dem Deboarding: Vor `GO` muss sichtbar bleiben, wohin das Fireteam geht, welche Preview-/Threat-Daten gelten und dass noch nichts committed wurde.

## Sinnhaftigkeit / Ursache
Die Einzelvertraege fuer First-Move-Preview, Threat-Preview und F6-Decision-Overlay existieren bereits. Offen ist ein kleiner Release-Recapture-Vertrag, der diese Quellen mit dem aktuellen Export-/Host-/Client-Kontext verbindet, ohne daraus neue Gameplay-Wahrheit zu machen.

## Umfang
- Neuen read-only Snapshot `get_mission_first_move_decision_preview_release_recapture_snapshot()` bereitstellen.
- Bestehende Quellen buendeln: TASK_540 First-Move, TASK_567 Threat-Preview, TASK_950 F6-Overlay und TASK_1169 Release-Acceptance.
- Pruefen, dass geplante Waypoints, Ghost/Path, Risikozeile und `GO`-Bereitschaft vor Commit sichtbar sind.
- TASK_1169-Handoff, Release-Provenance, FirstContact-Manifest und getrennte Host-/Client-Fensterartefakte als Kontext lesen.

## Nicht-Ziele
- Kein neues Pathfinding, kein neuer Threat Analyzer.
- Kein automatischer `GO`, keine Command-/Effect-Queue-Mutation.
- Kein neuer Screenshot-Capture-Flow und kein UI-Layout-Polish.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_540_mission_first_move_decision_readability_pass.md`
- `docs/tasks/TASK_567_frontier_probe_first_move_threat_preview_readability_pass.md`
- `docs/tasks/TASK_950_wire_decision_scenario_into_f6_mission_hud.md`
- `docs/tasks/TASK_1169_left_stack_air_anchor_release_acceptance.md`

## Akzeptanzkriterien
- Der Snapshot liefert `schema = sternenbuergerchen.mission_first_move_decision_preview_release_recapture.v1` und `task_id = TASK_1170`.
- TASK_540 und TASK_567 bleiben `pass`.
- TASK_950 bleibt sichtbar und read-only.
- Geplanter Waypoint, Waypoint-Intent-Preview, Ghost/Path und Risikozeile sind vor `GO` vorhanden.
- `go_ready = true`, aber der Snapshot fuehrt `GO` nicht aus und veraendert weder Command- noch Effect-Queue.
- TASK_1169 wird als Handoff-Quelle gelesen; Release-Provenance passt zu Git-HEAD; FirstContact-Capture und getrennte Host-/Client-Artefakte sind vorhanden.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1170_first_move_decision_preview_readability_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_1170_first_move_decision_preview_readability_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_567_frontier_probe_first_move_threat_preview_readability_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_950_wire_decision_scenario_into_f6_mission_hud.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_1169_left_stack_air_anchor_release_acceptance.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Snapshot ist ein Recapture-/Readability-Gate, kein visueller neuer Screenshot-Review.
- Wenn der Release-Export hinter Git-HEAD zurueckliegt, blockiert der Task zurecht bis zum frischen Export.
