# TASK_497 - Mission TestSetup Reference Cleanup

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
