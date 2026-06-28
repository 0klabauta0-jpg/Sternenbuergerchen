# TASK_513 - Mission Combat Resolution Boundary

## Ziel / Problem
Der Review hat den `MissionCombatLoopDriver` als zu breiten Missions-Orchestrator markiert. Nach TASK_512 ist der naechste kleine Schnitt die Objective-/Mission-Result-Aufloesung: Zeitlimit, Siegbedingung, Friendly-Defeat und MissionResult-Payload liegen noch als fachliche Logik direkt im Driver.

## Sinnhaftigkeit / Ursache
Objective- und Result-Entscheidung sind klein genug fuer einen fruehen Boundary-Slice. Das verbessert Multiplayer-Faehigkeit und Lesbarkeit, weil MissionResult-Vertraege kompakter und testbarer werden, ohne Combat-Balancing, Damage oder Enemy-KI anzufassen.

## Umfang
- `MissionCombatResolutionResolver` unter `scripts/mission/` anlegen.
- Driver bleibt Tick-Orchestrator, delegiert aber Resolution-Entscheidung, Victory-Condition-Check, Countdown-Source und MissionResult-Payload an den Resolver.
- Bestehende Snapshot-Keys und MissionResult-Keys bleiben unveraendert.
- Fokussierten Verifier fuer Resolver und Driver-Anbindung anlegen.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue Objective-Mechanik.
- Keine Snapshot-Key-Umbenennung.
- Keine UI-/Presenter-Extraktion.
- Keine Enemy-Behavior-Extraktion.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/dev/runtime_script_layout_contract.md`
- `docs/dev/combat_loop_authority_contract.md`
- `docs/tasks/TASK_495_mission_combat_driver_boundary_review.md`
- `docs/reviews/mission_combat_driver_boundary_review_2026_05_24.md`
- `docs/tasks/TASK_496_mission_combat_registry_and_elimination_hotfix.md`
- `docs/tasks/TASK_512_mission_controller_boundary_slice.md`

## Akzeptanzkriterien
- Objective-/Mission-Result-Entscheidung liegt in einem Mission-Resolver, nicht mehr nur inline im Driver.
- Der Resolver enqueued keine Commands/Effects und hat keine UI-/SceneTree-Abhaengigkeit.
- Zeitlimit-Defeat, Objective-Capture-Victory, Objective-Defense-Hold, Elimination-Fallback und Friendly-Defeat bleiben kompatibel.
- MissionResult-Payload enthaelt weiter `fireteam_tactical_debrief`.
- Bestehende Gameflow- und Combat-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/mission/mission_combat_resolution_resolver.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/task_513_mission_combat_resolution_boundary.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_513_mission_combat_resolution_boundary.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_496_mission_combat_registry_and_elimination_hotfix.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_500_gameflow_spine_hardening.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Driver bleibt gross und haelt weiter Tick-Reihenfolge, Readability-UI, Enemy-Behavior und Remote-Event-Ausgabe.
- Naechste sinnvolle Review-Slices bleiben Enemy-Behavior-Orchestrator und Combat Readability Presenter.
