# Gebaeude, Altmodelle und Renderpfade – Bestandspruefung 10.11.2026

## Ergebnis

Es gibt noch aktive Altmodell-Pfade. Sie liegen insbesondere in der
Editorpalette, den alten Stationskarten und den Test-/Kalibrierungseinstiegen.
Die drei fruehen eigenen Gebaeude und die Pass03-Exporte sind dagegen in den
geprueften Produktpfaden nicht mehr die verwendeten Gebaeudemodelle.

Zusaetzlich ist ein konkreter Verlust von Orts-/Basisdaten beim Speichern ueber
den Editor-MapData-Pfad reproduziert. Vor einem Editor-Nachzug muss dieser
Roundtrip erhalten werden. Das Vorhandensein alter Dateien allein erklaert
keinen Absturz; ein Absturz durch diese Altmodelle ist hier nicht nachgewiesen.

Auftrag: Bestand feststellen, Verwendungen nachweisen, Ablösung vorbereiten.
Keine Assets, Karten, Kataloge oder Produkt-Skripte geaendert oder geloescht.
Keine Editorimplementierung, kein Commit/Push/Export.

Pruefstand: `274f142c2a6abbc6a7cc5b88d17206681f44708f`, eigener Branch
`task/building-asset-audit-20261110`, abgezweigt vom noch nicht integrierten
`task/playtest-plan-20261110`. Dieser Stand enthaelt die neuesten Ortsarbeiten;
das lokale Main stand beim Beginn auf `046b6d91a`.

## 1. Was aktuell ist und was ersetzt wurde

Pfade mit `F/` beginnen unter
`Assets/curated/frontier_illustrated_20261101/`.

| Familie / konkrete Assets | Einstufung | Tatsaechliche Verwendung / Nachfolger |
|---|---|---|
| `F/structures/habitat_01.glb`, `workshop_01.glb`, `service_unit_01.glb` | Historische erste Generation; in den geprueften aktuellen Runtime-/Editorpfaden keine Verwendung gefunden | Fruehe eigene Gebaeudestudien; noch in `art/.../structures/manifest.json` und Pass03-Provenienz referenziert. Heutige Familie: Cutaway-Habitat, Freihafenhalle, Fuelmodell. Keine vollstaendig nachgewiesene 1:1-Migration alter Spielstaende. |
| `F/structures_pass03/habitat_cutaway_01.glb`, `freihafen_hall_01.glb` | Als Runtimeexport durch Pass04 abgeloest | Pass03-Quellen/Helfer bleiben Teil des Pass04-Builds; siehe `art/.../structures/pass04/README.md:21` und `generator/build_pass04.py`. Exportdatei, editierbare Quelle und Buildabhaengigkeit getrennt behandeln. |
| `F/structures_pass04/habitat_cutaway_01.glb`, `freihafen_hall_01.glb` | Aktuelle Originalquellen; in GM01 weiterhin direkt geladen | Fuer die begehbare Basis durch Tuer-Ableitungen ersetzt, als Original aber weiterhin benoetigt. GM01 misst diese Originale, blendet sie aus und zeigt die prozeduralen geschlossenen Aussenhuellen. Nicht global obsolet. |
| `Assets/curated/base_access_20261109/habitat_cutaway_01.glb`, `freihafen_hall_01.glb` | Aktuelle begehbare Basis | Ueber `maps/base_interior_navigation.json` und `BaseInteriorNavigation.layout()` geladen. Moeblierte Ableitungen mit Tueroeffnungen, nicht die alten kahlen Ersatzwaende. |
| `F/structures_pass04/utility_fuel_01.glb` | Aktuell, mehrfach verwendet | Basis/Navigationslayout, GM01, Handelsposten, Frontier-Preview und Editor-Typ `frontier_utility_fuel_01`. |
| `scripts/terrain/frontier_closed_buildings.gd` | Aktuelle prozedurale Gebaeudefamilie | GM01 und neue Handelsposten-Aussenhuellen ueber `frontier_gm01_layout.gd` bzw. `place_reference_dressing.gd`. Kein herumliegendes altes GLB; Geometrie entsteht im Code. |
| `Assets/kenney_space-kit/Models/GLTF format/structure_closed.glb` und Hangars | Alter Baukasten weiterhin aktiv auswaehlbar | `terrain_3d_asset_mapping.json`, acht gerichtete deutsche Gebaeudetypen sowie sieben `spacekit_hangar_*`-Paletteneintraege. Keine gespeicherten Platzierungen dieser Gebaeudetypen in den 21 geprueften parsebaren Karten gefunden; Editor kann sie weiter neu setzen. |
| `Assets/curated/kenney/factory/models/building-a.glb` bis `building-t.glb` | Alter Baukasten weiterhin im Katalog; A/D noch platziert | Alle 20 in der Palette. `building-a` und `building-d`: je 9 Objektzellen in `station_outpost_192x192.json`, je 1 in `station_outpost_64x64.json`. Sie sind nicht durch die neue Basis automatisch ersetzt. |
| `Assets/curated/kenney/space_station/models/` und `models_all/` | Gemischter aktiver Bestand und Dopplungen | 12 bytegleiche Modellpaare. Die neuen Szenen verwenden weiterhin ausgewaehlte Computer/Container/Moebel. Nicht die gesamte Herkunftsfamilie mit den alten kompletten Gebaeuden gleichsetzen. |
| `F/ships_pass05_astra_ultra/refinement_03/cutlass_01.glb` | Aktuelles Schiffmodell | Expliziter `frontier_ship_visual_catalog.json`; historischer statischer `cutlass_01`-Eintrag im Basislayout wird im aktuellen Basisrenderer uebersprungen, echte Schiffe werden separat projiziert. |

Alle 703 gefundenen Modelldateien unter `Assets/` mit Groesse, SHA256,
Referenzrollen und Fundstellen stehen in [inventory.json](inventory.json).
Die Tabelle `building_palette_and_placements` darin enthaelt die 29
Gebaeude-Mappinggruppen, ihre gerichteten Palettenvarianten und Kartenzaehlungen.
Kartenzaehlungen sind gespeicherte Tile-Fakten, keine garantierte Zahl sichtbarer
Meshinstanzen: externe Visual-Owner koennen die generische Darstellung ersetzen.

## 2. Befunde, die den alten Look wieder einschleusen koennen

### A1 – Alte Testkarten bleiben Render- und Editor-Defaults

- `scripts/editor/map_editor.gd:26`: Default `res://maps/test_mission.json`.
- `scripts/tests/mission_map_3d_calibration.gd:6`: dieselbe alte Karte.
- `scripts/tests/mission_map_3d_render_spike.gd:5`: alte
  `test_mission_32x32_slots8.json`; Einstieg ist
  `scenes/tests/mission_map_3d_render_spike.tscn`.
- Beide Karten haben kein `terrain_visual_theme_id`. Der Frontier-Look ist im
  gemeinsamen `TerrainMap3DView` ohne expliziten Override/CLI damit aus;
  siehe `_update_frontier_art_profile()` ab Zeile1308.
- Die Slots8-Karte enthaelt u.a. 22 `modular_floor`, 21
  `station_set_floor_panel` und 17 `station_wall`-Eintraege. Sie bekommt durch
  einen neuen Basisbuild weder automatisch neue Gebaeude noch einen neuen Stil.

Es ist derselbe gemeinsame Renderer mit alten Eingabedaten, kein nachgewiesener
zweiter eigenstaendiger Renderer. Diese erreichbaren Testeinstiege sind klare
Ablösekandidaten fuer aktuelle Gestaltungspruefungen. Logikfixtures koennen
weiter separat gebraucht werden. Welcher Einstieg den vom Nutzer zuletzt
gesehenen Render erzeugt hat, ist ohne dessen Aufruf/Artefakt nicht bewiesen.

### A2 – Alte Fabrikgebaeude leben in Missionskarten weiter

`scripts/meta/meta_layer_flow.gd:49-75` definiert `frontier_probe`,
`frontier_probe_vertical_slice` und `station_route_one_screen_multiplayer_drill`
weiter mit `station_outpost_192x192.json`. Zugehoerige Szenariodateien verweisen
ebenfalls darauf. Die Karte nutzt `ground_mission_mixed_v1`, nicht das aktuelle
Frontierprofil. Die Gebaeude A/D sind dort real gespeichert (siehe Tabelle oben).

Das ist ein aktiver Nebenpfad mit altem Inhalt, kein reines Dateileichenproblem.
Vor Entfernen muessen diese Missions-/Drillpfade ersetzt, bewusst zur Historie
erklaert oder aus aktuellen Einstiegen genommen werden. Nicht behauptet wird,
dass die neue Einfuehrungskampagne diese Karte laedt.

### A3 – Editorpalette mischt alte Baukaesten mit dem neuen Spielstand

Die Palette liest `data/terrain_tile_catalog.json`; die Modelle kommen aus
`data/terrain_3d_asset_mapping.json`. Die alten kompletten Gebaeude sind weiterhin
auswaehlbar. Die beiden aktuellen `base_access`-Gebaeude besitzen dagegen keinen
entsprechenden Terrain-Paletteneintrag. Ein Fuel-Paletteneintrag allein ist kein
vollstaendiger Editor fuer das neue Orts-/Gebaeudelayout.

Auch `data/map_builder_workbench_manifest.json` startet mit altem Space-Kit-
Boden, Strassen und modularen Elementen. `MapBuilderWorkbench` hat
`ground_mission_mixed_v1` als Vorgabe. F6 startet standardmaessig den Runtime-
Editor; das GridMap-/MeshLibrary-Authoring bleibt ein eigener vorbereiteter
Pfad. Nicht beide Wege als gleich aktuellen Ortseditor ausgeben.

### A4 – Grafikpreview ist nicht die heutige begehbare Basis

`scripts/tests/frontier_art_preview.gd:58-63` baut eine synthetische22x18-Hex-
Buehne, setzt die Pass04-Originale und eigene Pads/Figuren. Die Basis verwendet
stattdessen das Tuerlayout und echte Personen. Die Preview ist auch noch Quelle
von `scripts/tools/capture_frontier_main_background.gd:4`.

Der Captureloop ab Zeile437 erzeugt ausdruecklich auch `baseline` und schaltet
dabei das Frontierprofil aus. Alte Vergleichsbilder sind deshalb kein Beleg
dafuer, dass die aktuelle Kampagne zurueckgebaut wurde. Der aktuelle Status der
Preview muss bei kuenftigen Renderauftraegen sichtbar benannt bzw. der Einstieg
ersetzt werden. Hier wurde nichts neu gerendert oder visuell abgenommen.

## 3. Konkrete Stoerstellen vor dem Editor-Nachzug

### S1 – Reproduzierter Datenverlust im Editor-Speicherpfad (zuerst beheben)

`map_editor.gd:795` speichert mit `TerrainMapData.save_to_file()`.
Der Loader liest nicht alle neuen Rootfelder; der Serializer ab Zeile182
schreibt nur die ihm bekannten Felder. Der reale Godot4.6.2-Roundtrip mit
je9408Tiles ergibt:

| Originalkarte | Nach Load → Save fehlende Rootfelder |
|---|---|
| `campaign_intro_base.json` | `homebase_exploration`, `place_world` |
| `homebase_frontier_exploration.json` | `homebase_exploration`, `place_world` |
| `trade_outpost.json` | `singleplayer_site`, `place_world` |
| `satellite_crash_site.json` | `singleplayer_site`, `place_world` |
| `Ground_Mission01_32x32.json` | keine |

`place_presentation` bleibt bei Handel/Satellit erhalten. Alle fuenf
Speichervorgaenge melden `OK`, alle Tilezahlen bleiben erhalten. Der Befund
betrifft also zusaetzliche Orts-/Basisdaten, nicht einen allgemeinen Verlust
aller Gebaeudemodelle. Noch keine pauschale Aussage ueber jede Gameplayfolge
der fehlenden Felder. Nachweise: [roundtrip.json](roundtrip.json) und
[roundtrip.log](roundtrip.log). Alle Original-SHA256 blieben identisch.

### S2 – Basisdaten und tatsaechliches Gebaeudelayout haben verschiedene Pfade

`BaseInteriorNavigation.supports()` erkennt nur zwei konkrete Dateinamen.
`layout()` liest fuer sie Gebaeude/Bedienpunkte aus
`base_interior_navigation.json`, statt aus der gerade geladenen Basiskarte.
`ExplorableHomebase._initialize_runtime()` ab Zeile485 verwendet diesen Pfad.
Damit laedt die Basis korrekt die Tuer-Ableitungen, waehrend eine generische
Editoransicht der groben Karte diese Gebaeudezuordnung nicht selbst aufbaut.

Folge fuer den Nachzug: SaveAs/Umbenennen und Gebaeudeverschiebungen duerfen
nicht scheinbar funktionieren, waehrend weiterhin alte externe Laufwege oder
das andere Layout gelten. Eine konkrete Fehlbewegung wurde hier nicht getestet.

### S3 – Veralteter Ersatzraum-Builder ist noch im Code

`explorable_homebase.gd:819` enthaelt noch `_build_authored_interiors()` mit
prozeduralen Hexwaenden. Im aktuellen Quellstand kein Aufruf dieses Builders
gefunden. Die aktive Initialisierung laedt die moeblierten GLBs. Einstufung:
inaktiver Altpfad / Ablösekandidat, kein Nachweis aktuell sichtbarer Ersatzwaende.

### S4 – Pinke Kaesten koennen auch Fehlermarker sein

`TerrainMap3DView._add_missing_asset_marker()` ab Zeile4577 erzeugt pinke
Boxen bei fehlenden Zuordnungen. Vor einer Assetentfernung muessen die
Verwendungen migriert werden; sonst wird der alte Look durch Fehlerkaesten
ersetzt. Im geprueften statischen Mapping sind keine fehlenden realen
Produkt-Modelldateien und keine fehlenden externen glTF-Abhaengigkeiten
gefunden worden. Ein Bild mit Kaesten allein identifiziert deren Ursache nicht.

## 4. Weitere Bestandsspuren, getrennt von Produktfehlern

- 12 bytegleiche Modellpaare zwischen `space_station/models` und `models_all`.
  Vollstaendige Pfade in `byte_identical_groups`. Textur-/Katalogreferenzen und
  Importmetadaten trotzdem vor Zusammenlegung getrennt migrieren.
- Alte Astra-Schiffsmanifeste verweisen auf vier nicht mehr vorhandene Exporte
  im Basisordner bzw. `refinement_01`. Gefunden nur in historischen
  `art/.../manifest.json`, nicht als aktive Schiffkatalogpfade.
- `missing-task-175.glb` ist ein absichtlicher Negativtest, kein defektes Spielasset.
- Zwei Manifest-Pfadvorlagen mit `{role}` bzw. `{cutlass_01,buccaneer_01}` sind
  Muster, keine fehlenden Dateien. Separat in der Inventardatei ausgewiesen.
- `maps/Test_mission_32x32.json` ist wegen eines `//`-Kommentars kein gueltiges
  JSON. Im geprueften Quellumfang keine aktuelle direkte Verwendung dieses
  exakten Pfades gefunden. Nicht mit der gueltigen Slots8-Testkarte verwechseln.
- Dateien ohne statische Referenz sind **nicht** automatisch unbenutzt:
  dynamische Pfade und editierbare Quellen bleiben explizit ungeklärt.

## 5. Reihenfolge der Ablösung und des Editor-Nachzugs

1. Orts-/Basisfelder beim MapData-Roundtrip erhalten und mit realen Karten
   absichern; Originaldateien weiter unveraendert lassen.
2. Aktuelle Orte und ihre Gebaeudezuordnung als gemeinsamen Authoringpfad
   festlegen, einschliesslich Tuermodellen, Laufwegen und SaveAs-Identitaet.
3. Alte komplette Gebaeude aus der aktuellen Palette und den aktuellen
   Renderdefaults nehmen; vorher Missions-/Testverbraucher mit konkreten
   Nachfolgern zuordnen. Historische Logikfixtures getrennt kennzeichnen.
4. Stations-/Probe-Karten mit A/D-Gebaeuden entscheiden und ggf. Modell samt
   Platzierung, Groesse, Hindernis-/LOS-Fakten und Zugaengen gemeinsam ersetzen.
5. Danach aktuelle Gebaeude/Orte im Editor bedienen: setzen/verschieben,
   speichern, neu laden, im normalen Spiel besuchen und Tueren/Wege pruefen.
6. Erst nach Referenzmigration Altmodelle und unnoetige Ordner aus dem aktiven
   Projekt entfernen. Quellen, Lizenzen und historische Belege getrennt erhalten.

Dies ist eine priorisierte Grundlage, noch keine umgesetzte Bereinigung.

## 6. Pruefumfang und Reproduktion

Verwendet: `ai-game-studio:asset-audit`, auf den beauftragten Gebaeude-/
Verwendungsabgleich begrenzt. Keine pauschale Umbenennungs- oder Loeschregel.

- 703 Modelldateien unter `Assets/` inventarisiert und gehasht.
- 352 Terrain-Mappingeintraege ausgewertet, darunter29 Gebaeudegruppen.
- 21 parsebare gespeicherte Karten ausgewertet; eine weitere JSON-Vorlage
  als Parsefehler festgehalten. Fein-Navigationskarte ist eingeschlossen.
- 193 externe glTF-Bild-/Bufferverweise auf Dateiexistenz geprueft:0 fehlen.
- Direkte Modellpfade in `scripts`, `scenes`, `maps`, `data`, Art-Quellmanifesten
  und `docs/dev` nachgewiesen. QA-/Capture-/eingefrorene Source-Asset-Kopien
  werden nicht als aktive Verbraucher gezaehlt.
- Dynamische GM01-/Preview-/Worklife- und Basisloader manuell gelesen.
  Direkte Referenzrolle ist keine automatische Mainmenu-Erreichbarkeitsanalyse.
- Fuenf echte Godot-MapData-Roundtrips nur in prozessspezifischem
  `user://building_asset_audit_20261110_<pid>/`; Ergebnisdatei nennt den Pfad.

```powershell
python docs/qa/building_asset_audit_20261110/scan_assets.py
godot_console.exe --headless --path . --script docs/qa/building_asset_audit_20261110/probe_roundtrip.gd
git diff --check
```

Exit0 der Probe bedeutet erfolgreich ausgefuehrte Messung; die Tabelle S1
enthaelt weiterhin echte Produktbefunde. Kein gruener Daten-Erhaltungscheck.
Keine nativen Bilder, keine visuelle Stilabnahme, keine Generalabnahme von
Import, Performance, Kampagne, MP oder alten user://-Spielstaenden. Binaere
BLEND-Abhaengigkeiten und reine UID-Referenzen sind nicht vollstaendig aufgeloest.

## 7. Geaenderte Dateien / Git

Nur diese Auditdokumentation, Scanner, Probe, Nachweis-JSON/-Log sowie
`docs/tasks/BUILDING_ASSET_AUDIT_2026_11_10.md` und ein kurzer Verweis im
Implementierungsstatus. Vorhandene fremde/ungetrackte Arbeitsdateien erhalten.
Kein Commit, Push, Merge, Export oder Assetentfernen ausgefuehrt.
