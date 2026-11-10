# Karten speichern und aktive Gebaeudepfade migrieren

## Ziel / Problem / Ursache
Nutzerfreigabe10.11.: Zuerst den belegten Datenverlust beim Kartenspeichern
beheben, danach alte Palette-, Render- und Missionspfade auf aktuelle Modelle
umstellen. Der Editor-Nachzug mit neuen Ortswerkzeugen folgt separat.
MapData serialisiert nur bekannte Rootfelder. Alte Baukaesten bleiben in
Paletten, Stationskarten und Kalibrierungsdefaults aktiv.

## Architektur und Umfang
MapData erhaelt unbekannte JSON-Rootmetadaten als tiefe Kopie, waehrend bekannte
Runtimefelder ausschliesslich aus den bestehenden Ownerfeldern geschrieben
werden. Keine zweite Terrain-/Missionswahrheit im UI.
Aktuelle Frontier-Gebaeudefamilie fuer sichtbare Gebaeude verwenden; alte IDs
fuer gespeicherte Karten kompatibel aufloesen. Keine Assetloeschung, globale
Kit-Entfernung, Savegame-Migration, neue Editorwerkzeuge oder Mainintegration.

## Quellen / Contracts
docs/qa/building_asset_audit_20261110/README.md;
docs/dev/map_editor_asset_workflow_contract.md;
docs/dev/graphics_reference_revision_contract.md;
docs/dev/terrain_truth_visual_audit_contract.md;
docs/dev/gm01_frontier_map_contract.md.

## Plan / Akzeptanz
- [x] Speicherregression mit echten Ortskarten und unbekannten verschachtelten
  Metadaten rot nachweisen; kanonische Aenderungen duerfen nicht ueberschrieben
  werden. Nach Save/Reload bleiben Zusatzdaten wertgleich.
- [x] Rootmetadaten im MapData-Loader/-Serializer erhalten; Defaultkarten ohne
  Zusatzfelder und bestehende place_presentation bleiben kompatibel.
- [x] Aktuelle Modell-/Palettenroute festlegen, alte Gebaeude nicht mehr neu
  anbieten. Kompatibilitaet alter IDs und gespeicherte Missionen absichern.
- [x] Alte Render-/Editor-Defaults auf aktuelle gespeicherte Karte umstellen.
  Historische Vergleichsfixtures explizit historisch halten.
- [x] Stationsmissionen mit aktueller Gebaeudefamilie rendern. Karten-/Szenario-
  Identitaet, Marker, Auftrag und autoritative Navigation konsistent halten.
- [x] Betroffene Verifier, echter SaveAs-/Reloadpfad, Render-/Bounds-Pruefung
  sowie gezielte Missions-/Basisregressionen ausfuehren und dokumentieren.

## Betroffene Dateien
scripts/terrain/terrain_map_data.gd; TerrainTileCatalog/3D-Mapping/Renderer;
scripts/editor/map_editor.gd; Render-Testeinstiege; Stationskarten/-Builder;
data/terrain_tile_catalog.json; data/terrain_3d_asset_mapping.json;
scripts/tests/*map_save* und *building_migration*; QA-Paket und Statusdoku.

## Risiken / Reviewfokus
Unbekannte verschachtelte Metadaten; bekannte Felder nach Edit; SaveAs ohne
Dateinamenidentitaet; Modellgroesse versus Tile-/LOS-Fakten; gerichtete alte
IDs und historische Tests. Sichtbare Modelle duerfen keine neuen unerfassten
Hindernisse erfinden. Alte Quellen/Lizenzen erhalten. Keine breite Release-
oder Performancefreigabe aus fokussierten Tests ableiten.

## Arbeitsbasis / Ausfuehrung
Neuer Branch task/map-save-building-migration-20261110 auf274f142c2,
bewusst auf noch nicht integrierten Ortsarbeiten. Auditdateien und fremde
ungetrackte Dateien bleiben erhalten. Umsetzung direkt in dieser Sitzung;
Nutzer hat Ausfuehrung freigegeben, keine erneute Planfreigabe noetig.
Kein Commit/Push/Export ohne gesonderten Abschlussauftrag.

## Pruefprotokoll / Rulings
41/0 Metadaten,110/0 Migration/Kompatibilitaet/Compiler,17/0 echter Editor,
33/0 Station64,38/0 Mission-Slice,24/0 GM01-Editierschutz und11/0 Artprofil.
Native Modelle bei gleicher Kamera verglichen; zwei aktuelle Palettenicons.
Unabhaengiger Review und gespeicherte Bounds-/Wegepruefung ohne Restblocker.
Vollstaendige Belege und Grenzen: docs/qa/map_save_building_migration_20261110/README.md.

Ruling: Aktuelle Aussenhuellen aus vorhandenem GM01-/Handel-Builder als
PackedScenes wiederverwenden; kein neuer Gebaeudeentwurf. Alte Alias-IDs bleiben
innerhalb ihrer bisherigen Modellhuelen; neue Stationshuelen erhalten explizite
groessere Reservierungen und minimale Innenversetzung fuer freie Patrouillen.

Ruling: Mehrzellen-Vorlagen jetzt sichtbar, falsche Einzelzellen-Platzierung in
Brush/Compiler gesperrt und unsicheres Demo entfernt. Freie Layoutwerkzeuge
bleiben wie beauftragt Folgearbeit. Asset-/Factory-Shortcuts zeigen aktuelle
Vorlagen mit Rueckmeldung. RGB-Thumbnailfehler mit eigener Regression behoben.

Ruling: Vorhandene modulare Waende/Boeden und benutzte Moebel nicht pauschal
ersetzen. Alte Grafikprobe bleibt historische Vergleichsprobe; produktive
Renderdefaults und Hintergrundgenerator verwenden aktuelle gespeicherte GM01.

Risiken: Alter Basisraum-Verifier erwartet36x28 statt bereits vorhandenen96x98
und meldet20/2; kein gruener Gesamtfreigabeclaim. Bekannte Import-Shutdown-
Leakwarnung. Kein Mainmerge, Commit, Push, Export oder Assetloeschen.
