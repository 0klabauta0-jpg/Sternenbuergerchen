# TASK_372 - Mission LOS Debug Overlay Toggle

## Ziel
Eine debug- oder optional freischaltbare LOS-Visualisierung bereitstellen, um Sichtlinien, Sichtkegel und blockierende Tiles in der Mission nachvollziehbar zu machen.

## Status: IMPLEMENTIERT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll fuer Debugging und spaetere Spielbarkeit, aber als Standard-HUD wahrscheinlich zu laut. Deshalb ist er als Toggle/Debug-Layer umgesetzt.

## Problem
Schuesse, Contact-Erkennung und verlorene Kontakte sind ohne sichtbare LOS-Hinweise schwer zu verstehen.

## Ursache
LOS wird in den Kampf-/Kontaktpfaden genutzt, aber nicht als dediziertes Visual auf der Mission Map ausgegeben.

## Umfang
- LOS-Debug-Toggle im Mission-Overlay.
- Sichtlinien fuer selected Fireteam oder explizit gefilterte Unit begrenzen.
- Blockierte Linien farblich von freien Linien unterscheiden.
- Daten aus vorhandenen LOS-/Terrain- und Contact-Pfaden lesen.
- Kein permanentes Gameplay-Hilfsmittel daraus machen, solange Design/FoW das nicht erlaubt.

## Akzeptanzkriterien
- [x] Toggle erzeugt nur bei aktivem Debug-/Overlay-Modus LOS-Visuals.
- [x] Freie und blockierte LOS unterscheiden sich.
- [x] Overlay respektiert ausgewaehlte Fireteams/Units und bleibt bei vielen Units bounded.
- [x] FoW/Last-Known-Regeln werden nicht umgangen.
- [x] Headless-Test prueft Snapshot-Zaehler fuer sichtbare/blockierte Linien.

## Erwartete Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_372_mission_los_debug_overlay_toggle.gd`

## Umsetzung
- `TerrainMap3DView` baut bei aktivem `los_debug_overlay_enabled` begrenzte LOS-Debug-Linien zwischen ausgewaehlten Friendly-Units und bekannten Contact-/Last-Known-Eintraegen.
- Die Linien nutzen den bestehenden Grid-LOS-Blockerpfad der Fire-Sector-Visuals, unterscheiden `clear`/`blocked`, markieren Blocker-Tiles und melden alle Zaehler im Render-Snapshot.
- `mission_tactical_sandbox_controller.gd` stellt den Toggle ueber `set_los_debug_overlay_enabled()`, Hotkey `L`, Command-Feedback und Primary3D-Payload bereit.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_372_mission_los_debug_overlay_toggle.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_202_enemy_security_direction_and_los_patch.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- LOS kann teuer sein. Der Task begrenzt Samples per `los_debug_sample_limit` und nutzt den vorhandenen LOS-Blocker-Cache.
- Das Overlay bleibt ein Debug-/Optional-Layer; permanente Spieleranzeige fuer LOS braucht spaeter eigenes Design/FoW-Balancing.
