# TASK_461 - Fireteam Engage Visual Stuck Hotfix

## Ziel / Problem
- Im manuellen Drill-Playtest bleibt ein Fireteam im `Engage` haengen, nimmt danach keine neuen GO-/Folgebefehle sauber an und dreht weiter sichtbar falsch.
- Gegner sind weiter teilweise nur als `IDLE`-/Base-Marker lesbar.
- Schuesse/Muzzleflash sind im Fenster nicht verlaesslich sichtbar.

## Sinnhaftigkeit / Ursache
- Fireteam-Bewegung speichert Formation-Zielslots. `SimulationRoot` kann blockierte Zielpositionen aber auf walkable Ersatzpositionen aufloesen. Wenn der MovementController weiter auf den urspruenglichen, blockierten Slot prueft, bleibt die Ausfuehrung aktiv.
- Der 3D-Muzzle-Pfad bricht aktuell ab, wenn keine Muzzle-Textur geladen ist; dann fehlen auch Bloom/Trace als sichtbare Minimalanzeige.
- Security-/Facing-Metadaten koennen weiterhin sichtbare Aim-/Body-Richtung ueberlagern, wenn kein FireEvent in der View anliegt.
- Hostile Readability-Fallbacks existieren, sind im Fenster aber noch zu klein/transparent, um die vier Gegner sicher zu lesen.

## Umfang
- Fireteam-Movement-Zielslots vor dem Enqueue auf walkable Runtime-Ziele normalisieren und dieselben Positionen fuer Completion nutzen.
- Aim-/Facing-Prioritaet fuer aktive Bewegung/Kontakt stabilisieren.
- Hostile Body-Readability-Core staerker sichtbar machen.
- Weapon-Fire-VFX auch ohne Textur als Bloom/Trace anzeigen.
- Headless-Verifier fuer die vier Regressionen ergaenzen.

## Nicht-Ziele
- Keine neue Gegner-KI.
- Keine neue Sequenzlogik fuer raupenartig/ueberschlagen.
- Keine neue Combat-Balance oder Ballistik.
- Keine grossflaechige Terrain-/LOS-Umbauarbeit.

## Relevante Contracts / Dokumente
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_459_fireteam_engage_orientation_enemy_proxy_fix.md`
- `docs/tasks/TASK_460_fireteam_movement_avoidance_stability.md`
- `docs/tasks/TASK_438_fireteam_contact_visibility_attack_visuals.md`

## Akzeptanzkriterien
- MovementController-Completion prueft auf dieselben walkable Zielpositionen, die als Runtime-Commands an `SimulationRoot` gehen.
- Ein aktives Engage-/Take-/Move-Ziel gewinnt fuer sichtbare Aim-/Facing-Visuals vor altem Security-Facing, solange kein echter Kontakt/FireEvent anliegt.
- Hostile Proxies zeigen einen gut sichtbaren Body-/Readability-Core.
- Weapon-Fire-Events erzeugen mindestens Bloom und Trace, auch wenn die Muzzle-Textur fehlt.
- Der Drill kann nach einem Engage-Zielslot-Fallback weiterlaufen, statt dauerhaft als aktive Ausfuehrung zu kleben.

## Betroffene Dateien
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_461_fireteam_engage_visual_stuck_hotfix.gd`
- Doku/Status/Roadmap

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_461_fireteam_engage_visual_stuck_hotfix.gd`
- Relevante Regressionen TASK_438/TASK_459/TASK_460.
- `git diff --check`.

## Risiken / offene Punkte
- Der Fix stabilisiert Slots, Lesbarkeit und sichtbare FireEvents. Wenn Einheiten danach noch in echten Terrain-Engstellen haengen, braucht das einen separaten Path-/Sequence-Diagnose-Slice.
- Der hostile Readability-Core ist eine Visual-Hilfe, keine finale Enemy-Art.
