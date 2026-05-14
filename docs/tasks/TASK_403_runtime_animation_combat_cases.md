# TASK 403 - Runtime-NPC-Animationen und Kampf-Cases

## Ziel / Problem

Die Animationen aus der NPC-Showcase-Map sollen nicht nur dort sichtbar sein, sondern im bestehenden Spiel-Visualpfad fuer Units verfuegbar sein. `weapon_posture = aimed` bedeutet dabei: Waffe wie beim importierten `shoot`-Clip im Anschlag halten, aber ohne Schuss-Gameplay oder Muzzle-/Treffer-Effekt.

## Ursache / Sinn

Facing, Sichtlinie und Waffenanker laufen inzwischen ueber den bestehenden Runtime-Pfad. Die importierten Raw-Clips und die geprueften Kampf-Kombinationen aus `animation_combat_cases` muessen dort ebenfalls tief verankert werden, damit spaetere Taktik-, Wegfindungs- und Fireteam-Verhalten nur noch autoritative Postures/Commands setzen muessen.

## Umfang

- Runtime-AnimationPlayer laedt die importierten NPC-Clips aus dem bestehenden Visual-Mapping.
- Runtime baut `walkShoot`, `runShoot`, `crouchShoot`, `crouchWalkShoot` und `crouchRunShoot` aus importierten Basisclips plus importierter `shoot`-Pose.
- `UnitRuntimeStatus` und `UnitCommand` akzeptieren Crouch-Postures fuer spaetere Taktiken.
- `TerrainMap3DView` waehlt die passenden Animationen aus Movement- und Weapon-Posture.
- Snapshot-/Verifier-Abdeckung fuer Spielintegration.

## Nicht-Ziele

- Keine neue Animationsarchitektur.
- Keine neue Gameplay-Wahrheit in UI oder Visuals.
- Kein neues Taktiksystem in diesem Task.

## Relevante Contracts / Dokumente

- `docs/ARCHITECTURE.md`
- `docs/dev/unit_facing_visual_contract.md`
- `docs/tasks/TASK_402_npc_animation_showcase_map.md`

## Akzeptanzkriterien

- Alle 17 importierten Clips und sechs Combat-Cases sind im Runtime-AnimationPlayer eines Unit-Proxys verfuegbar.
- `aimed` ohne aktives Fire-Event haelt die importierte Shoot-Pose, schiesst aber nicht.
- Bewegte `aimed`-Units verwenden Walk-/Run-Shoot-Cases, ohne Facing/Sichtlinie/Waffe zu entkoppeln.
- Crouch-Postures normalisieren ueber `UnitCommand` und `UnitRuntimeStatus`.
- Bestehende Facing-/Sightline-Regressionen bleiben gruen.

## Betroffene Dateien

- `data/npc_unit_visual_mapping.json`
- `scripts/npc/unit_command.gd`
- `scripts/npc/unit_runtime_status.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_403_runtime_animation_combat_cases.gd`
- `docs/dev/unit_facing_visual_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tests/task_403_runtime_animation_combat_cases.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_401_facing_sightline_debug_map.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_402_npc_animation_showcase_map.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_345_npc_standard_movement_posture_policy.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_344_ground_mission_default_enemy_visuals.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- Crouch-Run nutzt weiterhin `crouchWalk` als Basis, weil das Asset-Bundle keinen dedizierten Crouch-Run-Clip liefert.
- Taktische Regeln, wann eine Unit Crouch/Run/Walk nutzt, folgen in einem separaten Task.
