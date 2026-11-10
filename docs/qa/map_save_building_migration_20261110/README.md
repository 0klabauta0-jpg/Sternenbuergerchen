# Speicherfix und aktuelle Gebaeudepfade – 10.11.2026

## Ergebnis / Ursache
Der reproduzierte Root-Datenverlust ist behoben. Vorher erkannte TerrainMapData
nur seine bekannten Felder und verlor Orts-/Basisdaten beim Speichern.
Jetzt bleiben auch unbekannte verschachtelte Rootfelder erhalten, waehrend
aktuelle Terrain-/Markerwerte weiterhin aus ihren bisherigen Ownern kommen.
Der echte Editor-SaveAs-/Reloadpfad bestaetigt den Erhalt von Ortsidentitaet,
place_world und sichtbarer Ortszuordnung.

Aktive alte Gebaeudepfade sind auf die aktuelle Frontier-Familie umgestellt:
35 alte Paletteneintraege ausgeblendet,29 alte Mappinggruppen kompatibel auf
aktuelle Modelle umgebogen, zwei aktuelle Vorlagen mit nativen Vorschaubildern,
Schnellbuttons und Workbench-Beispiele angepasst. Alte Quelldateien bleiben
erhalten; alle703 urspruenglich inventarisierten Modellhashes sind unveraendert.

## Missions- und Renderumstellung
- Stationskarten64/192 verwenden2/18 aktuelle Aussenhuellen statt der alten
  Fabrikgebaeude. Neue saved place_presentation-Props und passende gespeicherte
  Solidzellen verwenden denselben bestehenden Renderer wie der Handelsposten.
- Groessere Huelen werden mit passenden Hindernisfakten autoriert. Habitat/Halle
  ruecken je eine Quellzelle nach innen; alle Patrouillenpunkte bleiben frei.
  Nachweis:21/189 eindeutige reservierte Zellen, alle nonwalkable/LOS-blocking.
- Marker und Patrouillendaten sind exakt wertgleich zum Ausgangsstand. Alle
  nicht zum neuen Footprint gehoerenden Tiles sind ebenfalls wertgleich.
- Beide Stationsgeneratoren wurden nachgezogen; sektorweise Position, Yaw und
  Reservierungen wurden unabhaengig gegen alle18 grossen Platzierungen geprueft.
- Editor-Default, Kalibrierung und Render-Spike laden aktuelle gespeicherte GM01.
  Der Menuehintergrund-Generator rendert ebenfalls GM01 statt der synthetischen
  Grafikprobe. Dieser Generator wurde geparst, das vorhandene Menue-PNG nicht
  neu exportiert.

## Native Modellpruefung
[Vorher](buildings_before.png) und [nachher](buildings_after.png) sind native
Vulkan-/Forward+-Aufnahmen aus demselben Lauf bei gleicher Kamera, Beleuchtung
und Aufloesung960x640. Historische A/D-Modelle werden ausschliesslich fuer diesen
Vergleich geladen. Aufnahmen wurden geoeffnet und beurteilt: neue Gebaeude
zeigen die gestuften Frontier-Huelen mit ausgearbeiteten Tueren/Daechern statt
der alten einfachen Fabrikbloecke. Die groesseren Umrisse werden in den
Missionskarten durch passende gespeicherte Hindernisflaechen beruecksichtigt.

Keine neue 2D-Entwurfsvariante; uebernommen wird die vorhandene aktuelle
GM01-/Handel-Familie aus frontier_closed_buildings.gd auf Basis der bisherigen
Pass04-Raummasse. Quellenhashes: data/frontier_building_visual_catalog.json.
Zwei gesonderte384x384-Aufnahmen dienen als Palettenicons (je<200KiB).
Dies ist keine neue Nutzer-Stilabnahme und kein kompletter nativer Missionslauf.

## Pruefungen
| Pruefung | Ergebnis / Beleg |
|---|---|
| Metadaten-Regressionsprobe | RED31/10 → GREEN41/0; metadata_red.log und final_map_save_metadata_roundtrip_verifier.log |
| Gebaeude-/Palette-/Kompatibilitaets-/Compilergate |110/0; final_frontier_building_migration_verifier.log |
| Echter Editor-SaveAs/Reload, Schnellbuttons, Preview-only-Brush und realer Stationsrenderer |17/0; final_editor_integration.log |
| Station64-Authoringgate auf neuen Vertragsstand angepasst |33/0; final_task_494_station_outpost_64_map.log |
| Mission-/Szenario-Vertical-Slice |38/0; final_task_517_mission_scenario_vertical_slice.log |
| Bestehendes Frontier-Art-Profil |11/0; frontier_art_profile_verifier.log |
| GM01-Editierschutz / gewoehnliche Bearbeitung auf anderen Karten |24/0; gm01_frontier_editor_guard_verifier.log |
| Frontier-Probe-Kamera/Rendering/HUD | PASS; final_frontier_probe.log |
| RGB-Palettenbilder | RED leeres Thumbnail → GREEN; rgb_preview_red.log und final_rgb_preview.log |
| Unabhaengige gespeicherte Daten-/Bounds-/Wegepruefung | saved_map_verification.json:20 Gebaeude,210 eindeutige Solidzellen,16 freie verbundene Patrouillenpunkte,703 unveraenderte Altmodelle |
| Import | Exit0; final_import.log; bekannte ObjectDB-Shutdown-Leakwarnung |
| Hintergrund-/Stationsgenerator-Parser | Exit0; capture_tool_parse.log und generator_parse.log |

Der aeltere Basisraum-Verifier meldet20/2: beide Fehler verlangen noch36x28,
waehrend die im Ausgangsstand bereits vergroesserten Karten96x98 sind. Diese
beiden Basiskarten wurden hier nicht veraendert; die20 Modell-/Originalquellen-
und Tuerableitungspruefungen bestehen. Keine pauschale Behauptung einer komplett
gruenen Gesamtsuite. Siehe base_original_rooms_restore_test.log.

Historische Zwischenlaeufe/RED-Logs bleiben erhalten, insbesondere compiler_red
und editor_red. Der erste Compilerreview fand einen ungesicherten Demo-/Import-
Pfad und Schnellbuttons auf alten IDs. Beide korrigiert und technisch geprueft.
Der volle Editorlauf deckte ferner ein RGB/RGBA-blit_rect-Problem auf. Der
Thumbnailpfad normalisiert das Bildformat vor dem Kopieren; die native RGB-
Vorschau wird dadurch nicht mehr leer. Nachweis im separaten Rot-/Gruen-Test
und wiederholten finalen Editorlauf; editor_before_rgb_fix.log bleibt erhalten.
Der abschliessende unabhaengige Review fand im beauftragten Umfang keinen
verbleibenden Blocker. Die Zellen-/Wegepruefung wurde danach lokal erneut
ausgefuehrt. Quellen-/Bildhashes stehen in saved_map_verification.json.

## Grenzen und naechster Auftrag
Kein freier Mehrzellen-Editor vorgetaeuscht: neue Gebaeude sind inspizierbare
Layoutvorlagen; Einzelzellen-Brush/Compiler blocken deren falsche Platzierung
mit Rueckmeldung. Migrierte Ensembles bleiben bis zum Editor-Nachzug geschuetzt.
Der naechste Auftrag umfasst gemeinsames Platzieren/Verschieben/Drehen/Entfernen,
Footprint-/Tueren-/Wegepflege und Undo sowie Besuchen nach Save/Reload.

Alte IDs funktionieren fuer bereits gespeicherte Karten innerhalb ihrer alten
Modellabmessungen. Das ist keine automatische inhaltliche Migration persoenlicher
user://-Spielstaende. Modulare Waende/Boeden und gezielt genutzte Moebel wurden
nicht pauschal entfernt. Kein Asset geloescht, kein Commit/Push/Mainmerge,
kein EXE-/Releaseexport und keine allgemeine Performance-/MP-Freigabe.

## Betroffene Dateien / Git
TerrainMapData; TileCatalog; map_editor/MapBuilder-Importer/-Workbench;
Terrain-3D-Props-Gate und PlaceReferenceDressing; zwei Kataloge und Workbench-
Manifest; zwei Stationskarten/-Generatoren; drei Render-Einstiege; neue
Exterior-PackedScenes, Quell-/Boundsmanifest, Authoringtools und Verifier;
Task/Contract/QA/Statusdokumentation.

Eigener Branch task/map-save-building-migration-20261110 auf274f142c2,
bewusst auf den noch nicht integrierten Ortsarbeiten. Gleichzeitig vorhandene
fremde Aenderungen an Basis-/Missionsdarstellung, Geologie, Ground-Shader und
Playtestdoku bleiben erhalten. In TerrainMap3DView gehoert zu diesem Task nur
das Zulassen von Props/Pads ohne structures beim kalten Ortsaufbau; die anderen
aktuellen Diffhunks stammen aus dem parallelen Arbeitsstrang.

## Reproduktion
```powershell
godot_console.exe --headless --path . --script scripts/tests/map_save_metadata_roundtrip_verifier.gd
godot_console.exe --headless --path . --script scripts/tests/frontier_building_migration_verifier.gd
godot_console.exe --headless --path . --script scripts/tests/map_editor_metadata_saveas_verifier.gd
python docs/qa/map_save_building_migration_20261110/verify_saved_maps.py
git diff --check
```
UI-Pruefungen verwendeten private APPDATA-Verzeichnisse unter
output/map_save_building_migration_20261110/. Native Aufnahme offscreen ohne
Maus-/Tastatureingaben. Headless-Import ist kein Nachweis fuer eine fehlerfreie
Editor-Shutdownphase; die bekannte Leakwarnung ist separat ausgewiesen.
