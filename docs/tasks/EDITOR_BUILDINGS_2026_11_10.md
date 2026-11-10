# Aktuelle Mehrzellen-Gebaeude im Karteneditor

## Ziel / Ursache
Nutzerauftrag: Main92b20f106 pushen und den bestehenden Editor um Platzieren,
Verschieben, Drehen und Undo fuer Habitat/Freihafenhalle erweitern. Bisher
waren diese Mehrzellen-Vorlagen gesperrt, weil Einzelzellen-Brush und Undo ihre
sichtbare Geometrie von Hindernissen/LOS getrennt haetten.

## Umfang / Architektur
Ein Authoring-Helper plant atomare Aenderungen am vorhandenen TerrainMapData:
place_presentation.props ist die Gebaeudequelle, Tiles besitzen Navigation.
Pro reservierter Zelle werden die darunterliegenden Terrainfelder gespeichert,
damit Verschieben/Entfernen sie exakt freigibt. UI haelt nur Auswahl/Move-Modus
und reiht Gebaeude-/Tileaenderungen in dieselbe bestehende Undo-Historie ein.
Bestehende Controls: Palette/Brush platzieren, Auswahl/Rechtsklick selektieren,
Kontextaktion Verschieben und Zielklick, +/-90 drehen, Entfernen, Strg+Z.

## Nicht-Ziele
Keine neue Gebaeudegrafik, Innenraum-/Tuerautorierung, freie Bearbeitung der
festen GM01-Buehne oder der separaten Basis-Feinnavigation, Redo, Runtimebau,
Speicherstandmigration, Releaseexport oder automatische Mainintegration.

## Dokumente
docs/dev/frontier_building_migration_contract.md;
docs/dev/map_editor_asset_workflow_contract.md;
docs/dev/terrain_truth_visual_audit_contract.md;
docs/qa/map_save_building_main_integration_20261110/README.md.

## Plan / Akzeptanz
- [x] Datenvertrag und Service-Tests zuerst: Square/Hex-Footprints, Kollision,
  Grenzen, Unebenheit, Marker/Patrouillen, Freigabe und fehlerfreie Atomaritaet.
- [x] Authoringhelper und serialisierbare Untergrunddaten; vorhandene beiden
  Stationskarten offline mit stabilen IDs/Originaluntergrund ergaenzen.
- [x] Palette, Auswahl, Kontextmenu/Move-Modus, Drehbuttons und Eraser anbinden.
  Ganze Operation jeweils ein Undo-Schritt einschliesslich Metadaten und Tiles.
- [x] Kein generisches Brush-/Height-/Inspector-/Network-Edit darf einen
  reservierten Gebaeudeteil unabhaengig veraendern.
- [x] Reales SaveAs/Reload, gemischte Tile-/Gebaeude-Undo-Historie, abbrechen,
  persistierte Stationsgebäude, aktualisierte sichtbare Auswahl/Footprints.
- [x] Native Bedien-/Bildprobe, Regressionen und abschliessendes Review.

## Dateien / Pruefung / Risiken
Neuer Authoringhelper und Verifier, map_editor.gd, Stationsmetadata/Builder,
kleine Renderer-Auswahlhilfe falls erforderlich, Task/Contracts/QA/Status.
Fokussierte Godot4.6.2-Headless-Gates und nativer offscreen Bediennachweis;
git diff --check. Keine Scans grosser Control-/SceneTrees pro Frame.
Bestehende geteilte Rasterreservierungen, Kartenraender und SaveAs sind
Reviewfokus. Originalfakten muessen vor der ersten Freigabe vorhanden sein;
unbekannte Alt-Ensembles bleiben geschuetzt statt Untergrund zu erraten.

## Basis / Git
task/editor-buildings-20261110 von gepushtem Main92b20f106 im sauberen
Arbeitsverzeichnis C:/dev/SternenBuergerchen-worktrees/building-main-20261110.
Umsetzung/Pruefung/Commit auf Taskbranch; Main wurde bereits erfolgreich gepusht.

## Ergebnis
Service49/0, echter Editor29/0 headless und29/0 Vulkan/Forward+, Compiler0
Fehler; Generator18 eindeutige IDs und189 Untergrundpruefungen,0 Fehler.
Save41/0, Editor-SaveAs17/0, Migration110/0, GM01-Guard24/0, Station33/0,
Mission-Slice38/0, Palettentaxonomie52/0 und Stroke-Undo17/0.
Altes Floor-/Undo-Sammelgate63/21: ausschliesslich ueberholte16..24px-
Iconannahme; aktueller Browservertrag fordert>=64px. Kein pauschales Gruen.

Reviewbefunde vor Abschluss behoben: JSON-Float-Schluessel kanonisiert,
Select-Tool auf gemeinsame Gebaeudeauswahl gefuehrt, Sektorrotation und
Terrainvariation in Generator-Untergrunddaten erhalten, Buttonstatus auch
bei Bodenauswahl aktualisiert. Native Bilder geoeffnet: aktuelle Modelle,
Grundrissauswahl mit Tiefentest und passende Aktionen sichtbar.
Werkzeug-/Vorlagenwechsel und Entfernen beenden einen laufenden Move-Modus.
Belege und Grenzen: docs/qa/editor_buildings_20261110/README.md.
