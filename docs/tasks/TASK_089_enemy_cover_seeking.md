# TASK_089 – Enemy Cover-Seeking

## Ziel
Gegner-Units suchen aktiv Cover-Tiles in ihrer Naehe, statt sich nur nach Treffer zufaellig zu repositionieren.

## Status: ERLEDIGT

## Kontext
- `_try_reposition_enemy_on_damage()` in `mission_combat_loop_driver.gd` (Zeile ~980) repositioniert Gegner nach Treffer
- `_build_enemy_reposition_target()` waehlt aktuell ein zufaelliges Ziel im Umkreis `enemy_reposition_min/max_distance`
- `TerrainRegistry` kennt Cover-Werte pro Tile (`get_cover_score()`)
- `SimulationRoot` nutzt `_extract_effective_cover_score()` aus Terrain + Phase-Cover

## Mechanik
- Bei Reposition: Tiles im Umkreis abfragen, nach Cover-Score sortieren
- Praeferenz fuer Tiles mit hoeherem Cover-Score
- Fallback auf bestehende Zufalls-Reposition wenn keine Cover-Tiles vorhanden
- Optional: Auch bei initialem Enemy-Advance Cover-Tiles als Zwischenziele waehlen

## Implementierung
1. `mission_combat_loop_driver.gd`:
   - `_build_enemy_reposition_target()` erweitern: `TerrainRegistry` nach Cover-Tiles im Radius abfragen
   - Tiles nach Cover-Score gewichten, bestes verfuegbares waehlen
   - Bestehendes Cooldown-System bleibt erhalten

2. Abhaengigkeit: `TerrainRegistry` muss Tiles-in-Radius-Abfrage unterstuetzen (ggf. kleine Hilfsmethode)

## Dateien (voraussichtlich betroffen)
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/registries/terrain_registry.gd` (ggf. kleine Erweiterung)

## Akzeptanzkriterien
- [ ] Gegner repositionieren sich bevorzugt zu Cover-Tiles
- [ ] Ohne Cover-Tiles faellt Verhalten auf bisherige Zufalls-Reposition zurueck
- [ ] Reposition-Cooldown bleibt erhalten
- [ ] Performance: keine Vollscans pro Frame, nur bei Reposition-Trigger
