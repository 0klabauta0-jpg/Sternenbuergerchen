# TASK_497 - Mission TestSetup Reference Cleanup

## Status: IMPLEMENTIERT

## Ziel / Problem
`MissionTestSetup` nutzt an einzelnen Stellen noch harte relative SceneTree-Pfade wie `../SimulationRoot` und enthaelt alte Fallback-/Hilfsfunktionen fuer hartkodierte Terrainwerte. Das ist fuer kleine Testkarten noch handhabbar, wird aber bei groesseren 64x64-Maps und umgebauten Szenen fragil.

Ziel ist, `MissionTestSetup` als Setup-/Authoring-Bruecke stabiler zu machen, ohne Gameplay-Wahrheit aus `SimulationRoot`, `TerrainRegistry` oder `TerrainMapData` herauszuziehen.

## Sinnhaftigkeit / Ursache
Die meisten Referenzen laufen bereits ueber exportierte `NodePath`s. Die verbliebenen relativen Pfade und Hardcodes sind Ausreisser und koennen bei Szenenumbau oder neuen Karten unauffaellig brechen.

## Umfang
- `SimulationRoot`-Lookup in `MissionTestSetup` auf exportierten NodePath oder klaren Setup-Contract umstellen.
- Hartkodierte Terrain-Fallbacks sichtbar als Legacy-Fallback markieren oder in eine kleine Fixture-/Fallback-Datenstruktur ziehen.
- Toten oder ungenutzten Tile-Sprite-Suchcode pruefen und entfernen, falls keine Szene/kein Verifier ihn mehr nutzt.
- Sicherstellen, dass JSON-geladene TerrainMapData weiter der primaere Pfad bleibt.

## Nicht-Ziele
- keine neue Terrain-Architektur
- kein Map-Editor-Umbau
- kein 2.5D-/3D-Rendering-Pass
- keine Aenderung an Terrain-Wahrheit oder LOS-Regeln

## Relevante Contracts / Dokumente
- `docs/ARCHITECTURE.md`
- `docs/tasks/TASK_064_mission_terrain_aus_json.md`
- `docs/tasks/TASK_159_2_5d_editor_and_mission_primary_view.md`
- `docs/tasks/TASK_494_station_outpost_64_map.md`
- `docs/dev/terrain_truth_visual_audit_contract.md`

## Akzeptanzkriterien
- `MissionTestSetup` benoetigt keinen harten `../SimulationRoot`-Pfad mehr.
- JSON-Terrain-Laden bleibt unveraendert primaer.
- Alte Hardcode-Fallbacks sind klar begrenzt, testbar und nicht mit produktiven Karten verwechselt.
- Ungenutzter Tile-Sprite-Suchcode ist entfernt oder nachvollziehbar begruendet.
- Eine 64x64-Map kann Setup-Pruefungen ohne quadratic Legacy-Suchpfad laden.

## Betroffene Dateien
- `scripts/tests/mission_test_setup.gd`
- ggf. Missions-Testszene(n) mit `MissionTestSetup`
- neuer oder bestehender Verifier unter `scripts/tests/`

## Lokale Pruefung
- Neuer TASK_497-Verifier fuer NodePath-Setup und JSON-Terrain-Prioritaet.
- Relevante Regressionen:
  - `scripts/tests/task_494_station_outpost_64_map.gd`
  - `scripts/tests/task_160_tactical_playability_verifier.gd`
  - `scripts/tests/task_159_verifier.gd`
- `git diff --check`

## Risiken / offene Punkte
- Alte Test-Szenen koennen implizit vom relativen `../SimulationRoot`-Pfad abhaengen. Vor Umstellung muessen diese Szenen gezielt geprueft werden.
- Der Fallback darf nicht als zweites Terrain-Datenmodell wachsen.

## Umsetzung
- `MissionTestSetup` nutzt `simulation_root_path` als exportierten Setup-Contract und loest den Root ueber `_get_simulation_root()` auf.
- `mission_reactivity_test.tscn` serialisiert den neuen `simulation_root_path` auf `../SimulationRoot`.
- Der alte Terrain-Hardcode-Fallback ist als `LEGACY_FALLBACK_*`-Fixture-Datenstruktur gebuendelt und erzeugt sichtbar markierte `legacy_tile_*`-IDs.
- Der ungenutzte `_find_tile_sprite_at()`-Nearest-Sprite-Suchhelper ist entfernt; der JSON-Pfad registriert 64x64-Maps direkt aus `TerrainMapData`.
- `scripts/tests/task_497_mission_test_setup_reference_cleanup.gd` prueft Source-Contract, Szenenpfad, JSON-Prioritaet fuer die 64x64-Map und den begrenzten Legacy-Fallback.

## Abschluss-Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_497_mission_test_setup_reference_cleanup.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_494_station_outpost_64_map.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_159_verifier.gd` - lokal rot bei bestehenden 2.5D-Visual-Checks fuer Field Borders, Kenney-Ground-Node-Lookup und Unit-/Dropship-Facing/Scale.
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd` - lokal bereits seit TASK_496 rot beim LZ-Terrain-Field-Marker-Check.
- [x] `git diff --check`
