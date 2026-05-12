# TASK_344 - Ground Mission Default Enemy Visuals

## Ziel
`Ground_Mission01_32x32.json` wird zur Standard-Missionskarte fuer Einzelspieler und Meta-Flow. Die Karte bekommt ein spielbares Gegnersetup aus zwei feindlichen Vierergruppen: eine Patrouille und eine Verteidigungsgruppe am Objective.

## Status: IMPLEMENTIERT

## Umfang
1. Ground-Mission als Default:
   - Meta-Flow und Mission-Test-Setup verwenden `res://maps/Ground_Mission01_32x32.json`.
   - Die Standard-Mission referenziert ein Szenario mit acht Gegnern.
2. Gegner-Autorenschaft:
   - Zwei Enemy-Groups zu je vier NPCs.
   - Patrol-Bindings fuer die Patrouillengruppe.
   - Defensive Tactics fuer die Objective-Gruppe.
3. Sicht/Facing/Schussvisuals:
   - NPC-Facing wird beim Schuss auf das Ziel ausgerichtet.
   - LOS/Attack-Gates bleiben ueber bestehende Resolver/LOS-Systeme autoritativ.
   - Schiessende Units nehmen eine sichtbare Aim-Pose ein.
   - Muzzle-Flash nutzt das bestehende Kenney-Muzzle-Subset.
4. FoW:
   - Fog-of-War-Dim-Layer wird dunkler, ohne Unknown-FoW-Verhalten umzubauen.
5. Portrait-Mitnahme:
   - Neue PNGs in `Assets/Char` werden importierbar gemacht und im Portrait-Inventar mitgezaehlt.

## Nicht-Ziele
- Kein neuer Combat-Resolver.
- Kein neues KI-System ausserhalb der bestehenden Enemy-Team-Tactics.
- Kein Massenimport des kompletten Kenney Particle Packs.
- Kein Umbau der Mission-UI oder des Homebase/FOB-Flows.

## Akzeptanzkriterien
- [x] Standard-Mission nutzt Ground_Mission01_32x32.
- [x] Szenario validiert mit zwei Enemy-Groups zu je vier Gegnern.
- [x] Mission-Szene stellt acht feindliche Runtime-Nodes bereit.
- [x] Patrouillen- und Verteidigungsgruppe bekommen unterschiedliche Tactics.
- [x] FoW-Dim-Werte sind dunkler als vorher.
- [x] Fire-Events richten Angreifer-Facing aus und erzeugen Aim-Pose + Muzzle-Flash.
- [x] Neue Portrait-Dateien sind importiert und Inventar/Katalogzaehlung ist aktuell.

## Erwartete Dateien
- `maps/Ground_Mission01_32x32.json`
- `data/mission_scenarios/ground_mission01_default.json`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/fob_screen.gd`
- `scripts/tests/mission_test_setup.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `data/portrait_identity_catalog.json`
- `docs/assets/portrait_identity_inventory.md`
- `scripts/tests/task_344_ground_mission_default_enemy_visuals.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_344_ground_mission_default_enemy_visuals.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_233_portrait_identity_catalog_and_roster_presentation.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_205_weapon_fire_vfx_muzzle_flash_particles.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_201_weapon_range_scale_and_tile_distance_patch.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_186_mission_map_unit_presence_registry_audit.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_202_enemy_security_direction_and_los_patch.gd`
- [x] `git diff --check`
