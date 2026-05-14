# TASK_402 - NPC Animation Showcase Map

## Status: IMPLEMENTIERT IM ARBEITSSTAND

## Ziel / Problem
Die importierten Animated-Characters-Animationen sollen in einer kleinen Testszene sichtbar pruefbar sein. Auf der Facing-Testmap werden aktuell nur `idle`, `walk` und `shoot` ueber Runtime-Postures sichtbar; fuer die restlichen Clips fehlt ein direkter Sichtpruefstand.

## Sinnhaftigkeit / Ursache
Die Animationen sind als Asset-Clips vorhanden und sollen nicht durch handgebaute Ersatzposen ersetzt werden. Eine beschriftete Showcase-Map macht schnell sichtbar, welche Clips sauber importiert sind, wie sie auf dem Character-Skeleton laufen und welche Clips spaeter in Runtime-Postures oder Gesten eingebunden werden koennen.

## Umfang
- Eigene Testszene unter `scenes/tests/`.
- Ein NPC-Visual pro importiertem Animationclip.
- Zusaetzliche Combat-Prueffaelle fuer importierte Basisclips plus fallweise importierte `shoot`-Posespuren.
- Direkt sichtbare Beschriftung pro Clip.
- Datengetriebene Animationsliste im NPC-Visual-Mapping.
- Headless-Verifier fuer Szene, Ressourcen, Labels und AnimationPlayer.

## Nicht-Ziele
- Keine neuen Gameplay-Kommandos.
- Keine neue Runtime-Posture-Wahrheit.
- Keine direkte Verdrahtung aller Clips in Mission-Gameplay.
- Keine manuelle Ersatzpose aus Clipdaten ableiten.

## Relevante Contracts / Dokumente
- `docs/dev/unit_facing_visual_contract.md`
- `docs/tasks/TASK_401_facing_sightline_debug_map.md`
- `data/npc_unit_visual_mapping.json`

## Akzeptanzkriterien
- Die Testszene zeigt alle 17 importierten Clips: `attack`, `crouch`, `crouchIdle`, `crouchWalk`, `death`, `idle`, `interactGround`, `interactStanding`, `jump`, `kick`, `punch`, `racingIdle`, `racingLeft`, `racingRight`, `run`, `shoot`, `walk`.
- Jeder Showcase-NPC hat ein sichtbares Label mit dem Clipnamen.
- Jeder Showcase-NPC nutzt einen echten importierten AnimationPlayer-Clip aus dem FBX-Asset.
- Die Szene zeigt zusaetzlich die Combat-Cases `standShoot`, `walkShoot`, `runShoot`, `crouchShoot`, `crouchWalkShoot` und `crouchRunShoot`.
- Combat-Cases benutzen vorhandene importierte Basisclips und, wo noetig, die importierte `shoot`-Animation fuer passende Posespuren. `walkShoot`, `runShoot` und die Crouch-Shoot-Cases uebernehmen den Shoot-Oberkoerper, weil der rechte Waffenarm alleine im Crouch-Rig sichtbar nach hinten kippt. Handgebaute Zielposen duerfen diese Asset-Clips nicht ueberstimmen.
- Die Szene erzeugt keine SimulationRoot-Commands und keine Gameplay-State-Mutation.

## Betroffene Dateien
- `data/npc_unit_visual_mapping.json`
- `scenes/tests/npc_animation_showcase_map.tscn`
- `scripts/tests/npc_animation_showcase_map.gd`
- `scripts/tests/task_402_npc_animation_showcase_map.gd`
- `docs/dev/unit_facing_visual_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_402_npc_animation_showcase_map.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Szene ist ein Visual-Asset-Pruefstand. Ob ein Clip als Gameplay-Geste, Kampfpose oder Movement-Posture benutzt wird, bleibt ein separater Runtime-/Design-Schnitt.
- Das Asset-Bundle liefert keinen eigenen `crouchRun`-Clip. `crouchRunShoot` ist deshalb im Mapping bewusst als crouched movement auf Basis von `crouchWalk` plus importierten `shoot`-Oberkoerperspuren dokumentiert.
