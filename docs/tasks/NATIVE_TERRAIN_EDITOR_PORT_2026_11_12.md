# Native Terrain Renderer / Editor Port 2026-11-12

## Ziel / Ursache
Source1b924b640 native512 Terrain-Grundlagen im isolierten Integrationscheckout vervollstaendigen. Renderer/RegionalHexSurface/ResourceCache sind bereits vorhanden; Editor-Rampen und Materialparameter fehlen noch.

## Umfang und Nicht-Ziele
Nur Editor-Hoehen/Rampen, TerrainCatalog und fehlende Terrain-Materialparameter. Bestehende Main-Heimatbasisdarstellung bleibt erhalten. Keine Root-/Adapter-/Flow-/Actor-/MissionSetup-/Mapdaten-/Armor-Aenderungen; keine native/grosse Laufzeit-/Performanceabnahme, kein Commit/Push.

## Vertraege / Quellen
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS, terrain_truth_visual_audit_contract, graphics_reference_revision_contract; Source1b924b640 explicit_hex_ramps_contract sowie MAP_WORLD_REBUILD, EXPLICIT_HEX_RAMP_EDITOR/RUNTIME, TERRAIN_RESOURCE_PREFILL, STAR_MAP_TERRAIN_PREPARATION_UI und NATIVE_TERRAIN_PREPARATION_HANDOFF.

## Akzeptanzkriterien
H0-H8 Katalog/Editor, gerichtete Rampen mit Mehrfachauswahl/Undo/Redo und nichtmutierender Vorschau. Keine Legacy-Autoedges auf expliziten Hexkarten. Bestehende Heimatbasis-/dynamische Modellpfade unveraendert. ResourceCache-/RegionalSurface-Quellgleichheit und reale Integrations-API dokumentieren.

## Dateien / lokale Pruefung
scripts/editor/{map_editor,map_editor_height_tool,map_editor_height_preview,building_layout_authoring}.gd, scripts/terrain/{frontier_art_profile,terrain_tile_catalog,place_reference_dressing}.gd, shaders/terrain/{frontier_ground,hex_grid_coverage}.gdshader. Enges Godot4.6.2 check-only und Source-Verifier fuer Rampeneditor/Vorschau/Ressourcencache.

## Risiken / offene Punkte
Integration des Prefill-Gates und Cache-Passthrough liegt beim Root. Native Bildabnahme, 2161-Chunk-Gesamtvorbereitung, Gefecht und Performance bewusst separat. Source-Materialaenderungen nur additiv uebernehmen, Main-homebase_palette/-Pfade erhalten.

## Ergebnis / Nachweis
- Native Renderer, RegionalHexSurface und TerrainChunkResourceCache waren bereits Source1b-gleich; TerrainMap3DView wurde nicht veraendert. Main-homebase_palette, Rockregeln, Pfade, Flatground-Schatten und dynamische Modelle bleiben erhalten.
- Fehlender optionaler slope_softening-Parameter schloss eine echte Inkonsistenz des vorhandenen regionalen Renderers; Materialcache/Shader additiv ergaenzt, inklusive Rampenlesbarkeit. Gridshader publiziert wieder distant_contrast_floor.
- Source-Editorport: H0-H8, Rampenrichtung, Plateau, Hexradius, Auswahlrotation, Undo/Redo samt Untergrunddaten, Vorschau und Stroke-Lifecycle. TerrainCatalog und PlaceReferenceDressing lesen volle Hoehen.
- Godot4.6.2, privates APPDATA/LOCALAPPDATA, vorhandener Importcache, check-only0; Rampeneditor19/0; Hoehenvorschau failures0 einschliesslich echtem Kameraray und ueberlappendem Undo/Redo-Stroke.
- Resourcecache erster unveraenderter Source-Test40/1: aktiver Landeausschnitt enthaelt keine Rampen. Test gezielt auf eine echte gespeicherte Rampenzelle erweitert, ohne Datenmutation oder Vollkartenaufbau. Danach41/0 und2161 erwartete Chunks. Logpfad output/native_terrain_editor_port/. Fehlende lokale sandstone_04 Import-Szene protokolliert weiterhin ResourceLoaderfehler; keine native/Importabnahme behauptet.
- Kein Commit/Push, kein nativer Renderer-/Gefecht-/Perf-Lauf. MapBuilderSceneImporter-Hoehenclamp als einzelne offene Authoringzeile an Root gemeldet.

## Produktionsschnittstelle Prefill
Hidden actor-free View.configure_terrain_resource_prefill(map, payload_budget) startet die vorbereitete Map und ein begrenztes Chunkbudget pro Process. get_terrain_resource_preparation_snapshot liefert status/progress/ready/expected_chunks/prepared_chunks/reason; erst alle erwarteten Chunks liefern ready. get_prepared_terrain_resource_cache liefert dann dieselbe RefCounted-Cacheinstanz. Liveview.set_prepared_terrain_resource_cache(cache) muss VOR configure_from_map/render_map erfolgen. Map, Visualtheme, Frontierflag, Grid und externe Visualowner muessen denselben Kontext liefern; Revisionhash und exakte Chunkzahl werden validiert. Keine Cachebindung vor ready, keine Actors waehrend Vorbereitung. Root besitzt Approach/MissionSetup-Passthrough und Cancel; cancel_terrain_resource_prefill verwirft den Cache nur im aktiven Vorbereitungspfad.

## Gemeinsamer Importabschluss
Root hat den MapBuilderSceneImporter ebenfalls auf TerrainTileData.MAX_HEIGHT_LEVEL
angeglichen. Ein erster eigener Probelauf identifizierte den falsch gewaehlten
Catalog-Konstantenowner; nach Korrektur erhaelt der echte Importer H7 unverkuerzt.
Frischer inkrementeller Godot4.6.2-Editorimport: exit0 ohne Script-/Parse-/Compile-/
ERROR-/ObjectDB-/Ressourcenleckzeilen. Danach ResourceCache41/0 mit tatsaechlich
geladenem Sandstein, keine Loaderfehler. Vier gezeichnete Portraet-Atlasressourcen
haben reale geladene Texturen; kombinierter Importer-/Ressourcencheck bestanden.
Unabhaengiges lesendes Review des Editor-/Materialblocks ohne wichtige Befunde.
Nachweise docs/qa/native_terrain_editor_join_20261112; Vorimport-Diagnosen bleiben
gesondert erhalten. Kein nativer Grosskarten-/FPS-/EXE-Pass daraus.
