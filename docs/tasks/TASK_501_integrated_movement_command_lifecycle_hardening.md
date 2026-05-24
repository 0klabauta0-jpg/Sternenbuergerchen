# TASK_501 - Integrated Movement Command Lifecycle Hardening

## Ziel / Problem
Der integrierte Missionsflow hat nach dem Gameflow-Spine-Check noch rote Bewegungs-Gates:

- `TASK_192` meldet unaufloesbare `SimulationRoot`-Move-Commands, verliert die kompakte Bounding-/Caterpillar-Readability im 2.5D-Flow und findet im Medic-Smoke nicht immer passende begehbare Nachbarpositionen.
- `TASK_127` baut HPA-Pfade korrekt, erreicht im festen Ausfuehrungsfenster aber nicht immer das Ziel.

## Sinnhaftigkeit / Ursache
Die Einzelgates fuer Pathfinding, LOS, Zielerkennung, Live-Fire, Deckung, gegnerische Taktik und Performance sind gruen. Der riskante Rest liegt im integrierten Command-Lifecycle: Move-Commands duerfen nicht still in der Queue bleiben, wenn ihre Unit nicht mehr zur aktuellen Registry-/Runtime-Wahrheit passt. Ausserdem muessen alte Verifier ihre Timing- und Map-Fixtures an die aktuellen Movement-/Terrain-Vertraege anpassen.

## Umfang
- Unaufloesbare Move-Commands im autoritativen `SimulationRoot`-Pfad sauber diagnostizieren und aus der Queue fallen lassen.
- Einen kleinen Verifier ergaenzen, der stale Move-Commands explizit abdeckt.
- Den integrierten `TASK_192`-Smoke so haerten, dass er aktuelle Fireteam-Movement-Contracts und vorhandene Walkable-Terrain-Fixtures prueft.
- Den `TASK_127`-HPA-Ausfuehrungscheck an den aktuellen Movement-Speed-/Surface-Vertrag anpassen.

## Nicht-Ziele
- Keine grosse Extraktion aus `MissionTacticalSandboxController` oder `MissionCombatLoopDriver`.
- Keine Aenderung an Combat-Damage, Zielerkennung, LOS-Regeln oder Enemy-Taktik.
- Keine neue Navigation-Architektur und keine neue zweite Bewegungsschicht.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/runtime_script_layout_contract.md`
- `docs/dev/tactical_command_doctrine_game_abstraction.md`
- `docs/dev/terrain_truth_visual_audit_contract.md`
- `docs/dev/combat_loop_authority_contract.md`

## Akzeptanzkriterien
- `SimulationRoot` dokumentiert stale Move-Commands read-only und requeued sie nicht.
- `task_501_integrated_movement_command_lifecycle_hardening.gd` deckt den stale-Move-Command-Fall ab.
- `task_192_mission_map_npc_behavior_playability_smoke.gd` laeuft wieder gruen.
- `task_127_verifier.gd` laeuft wieder gruen, ohne HPA-Pfadlogik zu lockern.
- Relevante Movement-/Combat-Regressions bleiben gruen.

## Betroffene Dateien
- `scripts/core/simulation_root.gd`
- `scripts/tests/task_127_verifier.gd`
- `scripts/tests/task_192_mission_map_npc_behavior_playability_smoke.gd`
- `scripts/tests/task_501_integrated_movement_command_lifecycle_hardening.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_501_integrated_movement_command_lifecycle_hardening.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_127_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_192_mission_map_npc_behavior_playability_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_475_fireteam_pathfinding_avoidance_stability_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_479_fireteam_runtime_hotpath_guards.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die grossen Legacy-Orchestratoren bleiben unter `scripts/tests/` und sollen nicht in diesem Task refaktoriert werden.
- Die Stale-Command-Diagnose ist bewusst read-only. Eine breitere UI-Anzeige fuer verworfene Commands waere ein eigener Feedback-Task.
