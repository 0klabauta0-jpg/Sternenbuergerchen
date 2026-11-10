# Gebaeudeeditor: Umsetzung und begrenzte Pruefung

10.11.2026, Godot4.6.2.stable.official.71f334935.
Basis: gepushter Main92b20f1067ffe6b0c73cba35bb6f33fefa086fa6;
Editorarbeit auf `task/editor-buildings-20261110` im isolierten Worktree
`C:/dev/SternenBuergerchen-worktrees/building-main-20261110`.
Main wurde zuerst gepusht und danach per origin-Ref abgeglichen.
Der Editorauftrag fuehrt keine automatische Mainintegration aus.

## Problem, Ursache und Aenderung
Neue Mehrzellenmodelle waren sichtbar, aber der alte Einzelzelleneditor
konnte Modellplatzierung und Hindernisfelder nicht gemeinsam verschieben.
Die temporaere Sperre wird fuer sichere Stationsdaten durch einen atomaren
MapData-Helper ersetzt. Palette, Auswahl, Dreh-/Move-/Entfernenaktionen,
Fallback-Compiler, SaveAs und die bestehende Undo-Historie nutzen denselben
Vertrag. Fremde WIP im urspruenglichen Arbeitsverzeichnis bleiben erhalten.

## Ergebnisse
Alle genannten Logs liegen neben diesem Bericht. Private APPDATA-Verzeichnisse
unter dem externen Evidenceordner isolierten die Test-Praeferenzen/Saves.

| Pruefung / Log | Ergebnis |
| --- | --- |
| service_final_candidate | 49/0; Square/Hex, reale Bounds, Plan ohne Mutation, Kollision, Rand, Untergrund, Marker/Patrouille, Shared Cells, gespeicherte Stationen |
| controls_final | 29/0; echter Editor, sichtbare Controls und Inputroute, gemischtes Undo, Ablehnung ohne Historyeintrag, SaveAs/Reload, Escape, Werkzeug-/Vorlagenwechsel, Entfernen/Undo |
| controls_native_final | 29/0; gleicher Ablauf, Vulkan1.4.357 Forward+, RTX4070TiSUPER, 1920x1080, Offscreen-Fenster |
| generator_final | 18 eindeutige IDs, 189 Untergrundfelder gegen normalen Terrain-Stempelpfad und nach Entfernen aller Gebaeude; 0 Fehler |
| editor_building_compiler_verifier | 0 Fehler; Mehrzellenplatzierung, spaetere Objektkollision, Rand und alte IDs |
| map_save_metadata_roundtrip_verifier | 41/0 |
| map_editor_metadata_saveas_verifier | 17/0 |
| frontier_building_migration_verifier | 110/0 |
| gm01_frontier_editor_guard_verifier | 24/0 |
| task_494_station_outpost_64_map | 33/0 |
| task_517_mission_scenario_vertical_slice | 38/0 |
| task_296_map_editor_palette_taxonomy_space_station_assets | 52/0 |
| task_358_mapeditor_undo_stroke_transactions | 17/0 |
| bugfix_map_editor_station_floor_structure_undo | 63/21; alle21 Fehler dieselbe alte16..24px-Iconforderung. Seit TASK484 fordert der Browser>=64px; an dieser Aufgabe keine Icongroesse geaendert. Undo-/Layerchecks bestehen. |

Die Logpruefung findet keine SCRIPT ERROR/ERROR-Zeilen. Der alte Sammeltest
ist bewusst als rot dokumentiert. Ein erster Batch-Auswerter markierte auch
`passed=41 failed=0` faelschlich per Regex als Fehler; deshalb wurden die
tatsaechlichen Summaries und Fehlerzeilen jedes Logs einzeln geprueft.

Reproduzieren aus diesem Worktree:
`godot_console.exe --headless --path . --quit-after 200 --script scripts/tests/editor_building_authoring_verifier.gd`
Analog controls/compiler/generator und die aufgefuehrten bestehenden Gates.
Nativ: `godot_console.exe --path . --position -20000,-20000 --resolution 1920x1080 --rendering-driver vulkan --rendering-method forward_plus --quit-after 200 --script scripts/tests/editor_building_controls_verifier.gd -- --capture-editor-buildings`.
Beim nativen Harness ist der externe Capturepfad im Script explizit festgelegt.

## Native Bilder und sichtbare Beurteilung
Dies sind echte Godot-Aufnahmen des bestehenden integrierten Modellstands,
keine Konzeptbilder oder neuen Modellkandidaten. Modellquellen und Stilziele
bleiben die des vorangegangenen Frontier-Migrationspakets; kein Mesh wurde
veraendert. SHA-256 fuer verwendete Szenen, Katalog, Karten, Helper und Bilder
stehen in `source_image_hashes.json`.

- `01_placed.png`: Freihafenhalle im Hex-Fixture, beide aktuellen Palettenvorlagen, Gebaeudeaktionen und freie Randzellen der Auswahl sichtbar.
- `02_reloaded.png`: derselbe Gebaeudestand nach echtem SaveAs/Reload.
- `03_existing_station.png`: gespeichertes Habitat und Halle in der64er-Station; Habitat ausgewaehlt, Rotation180/Scale0.85 aus Prop gelesen, Aktionen aktiv.

Die Bilder wurden geoeffnet und beurteilt. Die Auswahl uebermalt die Modelle
nicht; sichtbare Kit-Skelettteile wurden aus `Gebaeude` nach `Space Station`
eingeordnet, bleiben dort verwendbar. Die rechte Aktionsgruppe ist lesbar.
Fixture und Stationskarte zeigen weiterhin ihre vorhandenen Mission-/Terrain-
Validierungswarnungen im Authoringstatus; diese Pruefung erteilt keine komplette
Karten-, Stil-, Gameplay-, Performance- oder Releaseabnahme.

## Review und Grenzen
Frisches abschliessendes Lesereview fand drei echte Befunde: Float-Rasterkeys
in64er-Untergrunddaten, Auswahltool umging Ganzgebaeudeauswahl, Sektorkopie
vergass Untergrundrotation/Variation. Alle behoben und mit Regressionen geprueft.
Zusaetzlich Buttonstatus bei Bodenauswahl und Auswahl-Tiefentest korrigiert.
Vorlagen-/Werkzeugwechsel und Entfernen beenden laufendes Verschieben;
die letzten29/0-Pruefungen sichern diesen Ablauf ebenfalls ab. Ein JSON-
Vergleich gegen Main bestaetigt fuer beide Stationskarten: Nur stabile IDs
und Untergrundmetadaten ergaenzt, alle bisherigen Kartenfakten identisch.

Festes GM01-Ensemble, Basisraeume mit separater Feinnavigation und unbekannte
Alt-Layouts ohne Untergrunddaten bleiben geschuetzt. Kein Redo/Runtimebau,
kein Assetloeschen, kein Releaseexport. Hauptdateien: building_layout_authoring,
map_editor, map_builder_scene_importer, Renderer-Auswahlmaterial, Stations-
Metadaten und ihre Builder; zugehoerige Tests/Contracts/Task/Status.
