# TASK_438 - Fireteam Contact Visibility Attack Visuals

## Ziel / Problem

- Im manuellen Drill-Playtest wirken Feindkontakte noch stumm: Fireteams laufen neben Gegner, ohne sichtbar zu zielen oder zu feuern, Muzzleflash bleibt aus, nur ein gegnerischer 3D-Body ist klar sichtbar, und Busch-Objekte wirken unter statt auf den Bodentiles.

## Sinnhaftigkeit / Ursache

- TASK_437 hat die Baseline-Gates headless abgesichert, der sichtbare Fenstertest zeigt aber noch Luecken in Diagnose und Darstellung. Kontakt, Feuerlinie, Enemy-Proxies und Terrain-Objekte muessen im bestehenden Mission-Tactical-/CombatLoop-/Terrain3D-Pfad korrigiert werden, ohne eine zweite UI-Gameplay-Wahrheit einzubauen.

## Umfang

- Kontaktlinien/Feuerlinien bei bestaetigtem Gegnerkontakt klar rot faerben und im Snapshot diagnostizieren.
- Sicherstellen, dass sichtbarer Feindkontakt auch einen Feuer-Event/Muzzleflash ausloest, sofern LOS, Reichweite und Feuerstatus passen.
- Drill-Gegner als vier sichtbare 3D-Modelle mit getrennten Patrol-/Kontaktzustanden absichern.
- Busch-/Nature-Prop-Anker so pruefen und korrigieren, dass sie auf dem Bodentile liegen.

## Nicht-Ziele

- Kein neues Combat-System.
- Kein vollstaendiges neues Enemy-AI-Verhalten.
- Kein Flank-/Skill-Balancing.
- Kein Redesign der Drillkarte ausser notwendigen Prop-/Patrol-Korrekturen.

## Relevante Contracts / Dokumente

- `AGENTS.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_437_fireteam_selection_patrol_contact_pass.md`

## Akzeptanzkriterien

- [x] Bestaetigter Feindkontakt faerbt die sichtbare Schuss-/Kontaktlinie rot.
- [x] Kontakt in Waffenreichweite erzeugt einen `weapon_fire`-Event und sichtbaren Muzzleflash.
- [x] Alle vier Drill-Gegner liefern sichtbare 3D-Modelle statt nur Base-/Idle-Marker.
- [x] Gegnerpatrol bleibt aktiv, solange kein Kontakt-Hold/Cover greift.
- [x] Busch-Objekte sind `object_type_id` auf Ground-Tiles und ihre sichtbare Prop-Hoehe liegt auf/ueber der Tile-Oberflaeche.

## Betroffene Dateien

- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `data/terrain_3d_asset_mapping.json`
- `scripts/tests/task_438_fireteam_contact_visibility_attack_visuals.gd`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_438_fireteam_contact_visibility_attack_visuals.gd`
- relevante Regressionen: TASK_424, TASK_435, TASK_436, TASK_437
- `git diff --check`

## Risiken / offene Punkte

- Headless-Snapshots koennen die finale Lesbarkeit im Godot-Fenster nur naehern; nach dem Fix bleibt ein kurzer manueller Sichtcheck noetig.
- Wenn Kontakt nicht feuert, muss der Diagnosegrund explizit sichtbar sein statt still weiterzulaufen.
