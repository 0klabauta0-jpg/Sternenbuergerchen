# TASK_372 - Mission LOS Debug Overlay Toggle

## Ziel
Eine debug- oder optional freischaltbare LOS-Visualisierung bereitstellen, um Sichtlinien, Sichtkegel und blockierende Tiles in der Mission nachvollziehbar zu machen.

## Status: GEPLANT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll fuer Debugging und spaetere Spielbarkeit, aber als Standard-HUD wahrscheinlich zu laut. Deshalb soll er als Toggle/Debug-Layer entstehen.

## Problem
Schuesse, Contact-Erkennung und verlorene Kontakte sind ohne sichtbare LOS-Hinweise schwer zu verstehen.

## Ursache
LOS wird in den Kampf-/Kontaktpfaden genutzt, aber nicht als dediziertes Visual auf der Mission Map ausgegeben.

## Umfang
- LOS-Debug-Toggle im Mission-Overlay oder Debug-Menue.
- Sichtlinien fuer selected Fireteam oder hovered Unit begrenzen.
- Blockierte Linien farblich von freien Linien unterscheiden.
- Daten aus vorhandenen LOS-/Terrain- und Contact-Pfaden lesen.
- Kein permanentes Gameplay-Hilfsmittel daraus machen, solange Design/FoW das nicht erlaubt.

## Akzeptanzkriterien
- [ ] Toggle erzeugt nur bei aktivem Debug-/Overlay-Modus LOS-Visuals.
- [ ] Freie und blockierte LOS unterscheiden sich.
- [ ] Overlay respektiert ausgewählte Fireteams/Units und bleibt bei vielen Units bounded.
- [ ] FoW/Last-Known-Regeln werden nicht umgangen.
- [ ] Headless-Test prueft Snapshot-Zaehler fuer sichtbare/blockierte Linien.

## Erwartete Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- ggf. `scripts/tactical/visuals/mission_los_debug_overlay.gd`
- `scripts/tests/task_372_mission_los_debug_overlay_toggle.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_372_mission_los_debug_overlay_toggle.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_202_enemy_security_direction_and_los_patch.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- LOS kann teuer sein. Der Task muss Caching oder Sampling begrenzen und darf nicht pro Frame alle Unit-Paare pruefen.

