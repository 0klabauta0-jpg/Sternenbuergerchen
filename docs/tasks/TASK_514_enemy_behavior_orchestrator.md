# TASK_514 - Enemy Behavior Orchestrator

## Ziel / Problem
Der Review hat den `MissionCombatLoopDriver` weiter als zu breiten Missions-Orchestrator markiert. Nach TASK_513 ist die naechste sinnvolle Grenze das Gegnerverhalten: Team-Taktik, Patrouille, Limbo-Cover/Hold, Fallback-Advance und Damage-Reposition bauen ihre Command-Payloads noch direkt im Driver.

## Sinnhaftigkeit / Ursache
Gegnerverhalten ist multiplayer-relevant, weil Host/Server klar nachvollziehbar entscheiden muss, warum ein Gegner haelt, patrouilliert, Deckung sucht oder nach Schaden repositioniert. Die Entscheidung darf aber keine zweite Gameplay-Wahrheit werden: Commands werden weiterhin ueber `SimulationRoot.enqueue_command()` committed.

## Umfang
- `EnemyBehaviorOrchestrator` unter `scripts/tactical/` anlegen.
- Command-Payloads fuer Team-Taktik, Patrouille, Fallback-Advance, Limbo-Cover/Hold und Damage-Reposition aus dem Driver herausziehen.
- Driver behaelt Tick-Reihenfolge, Cooldowns, Patrol-Indizes, LimboAI-Auswertung und den eigentlichen `enqueue_command()`-Aufruf.
- Fokussierten Verifier fuer Payload-Vertraege und Driver-Anbindung anlegen.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue Gegner-KI.
- Keine Aenderung an Damage-, LOS- oder Trefferlogik.
- Keine Snapshot-Key-Umbenennung.
- Keine Verschiebung autoritativer Mutationen aus `SimulationRoot`.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/dev/runtime_script_layout_contract.md`
- `docs/dev/combat_loop_authority_contract.md`
- `docs/tasks/TASK_495_mission_combat_driver_boundary_review.md`
- `docs/tasks/TASK_513_mission_combat_resolution_boundary.md`

## Akzeptanzkriterien
- Enemy-Behavior-Command-Payloads liegen in einem taktischen Orchestrator unter `scripts/tactical/`.
- Der Orchestrator enqueued keine Commands/Effects und hat keine SceneTree-Abhaengigkeit.
- Bestehende Patrol-, Team-Tactics-, Limbo- und Damage-Reposition-Command-Felder bleiben kompatibel.
- Driver delegiert Payload-Building, bleibt aber Authority-Orchestrator fuer Cooldowns und SimulationRoot-Enqueue.
- Bestehende Gameflow- und Combat-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/tactical/enemy_behavior_orchestrator.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/task_514_enemy_behavior_orchestrator.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_514_enemy_behavior_orchestrator.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_513_mission_combat_resolution_boundary.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_500_gameflow_spine_hardening.gd`
- `git diff --check`

## Risiken / offene Punkte
- LimboAI-Auswahl, Security-Snapshots und Team-Tactics-State-Building bleiben bewusst im Driver. Ein spaeterer Slice kann diese State-Aufbereitung weiter herausziehen.
- Friendly-Standard-Cover-Behavior ist ein eigener Pfad und nicht Teil dieses Enemy-Slices.
