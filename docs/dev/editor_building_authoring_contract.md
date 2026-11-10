# Aktuelle Gebaeude im Karteneditor

Stand10.11.2026; Auftrag: `docs/tasks/EDITOR_BUILDINGS_2026_11_10.md`.

## Besitz und Speicherung
`TerrainMapData.place_presentation.props` besitzt pro Gebaeude `building_id`,
`asset_id`, Szenenpfad, Zentrum in Kartenebene, Elevation, Scale, Yaw und
`reserved_grids`. Der Katalog `data/frontier_building_visual_catalog.json`
liefert die aktuellen Szenen und ihre realen Bounds. Tiles besitzen weiterhin
Walkability, LOS und Deckung; der Renderer veraendert keine dieser Fakten.

`building_authoring.schema_version=1` speichert `next_id` und `base_tiles`.
Letzteres enthaelt nur serialisierbare Terrainfelder unter kanonischen
`x,y`-Schluesseln fuer aktuell reservierte Zellen. Gemeinsame Rasterzellen
behalten ihren Untergrund und ihre Sperre, solange mindestens ein Gebaeude
sie besitzt. Erst der letzte Besitzer gibt sie frei. Die64er/192er-Station
besitzen2/18 stabile IDs und21/189 Untergrunddatensaetze aus dem Altbestand;
ersetzte Factory-Objekte werden beim Freigeben nicht wiederhergestellt.

## Atomare Operation
`building_layout_authoring.gd` plant ohne Mutation. Erst ein erfolgreiches
Ergebnis wird auf dieselbe MapData angewandt. Square-/Hex-Footprints werden
aus den gedrehten, skalierten Modellbounds und echten Zellpolygonen berechnet.
Reale Gebaeudehuellen duerfen nicht ueberlappen; grobe Rasterreservierungen
duerfen sich beruehren. Abgelehnt werden Kartenrandueberstand, belegter oder
unebener Untergrund, Wasser sowie neu blockierte begehbare Marker/Patrouillen.
Scale liegt zwischen0.25 und2.5. Bestehende Placements behalten ihren Scale;
neue Platzierungen verwenden den Palettenwert.

Jede erfolgreiche Operation speichert Presentation und betroffene Tile-
Snapshots in der vorhandenen Editor-Undo-Historie. Ein Strg+Z stellt Modelle,
Reservierungen, Untergrund und vorherige Auswahl gemeinsam wieder her.
Abgelehnte Operationen erzeugen keinen Undo-Schritt. Normale Terrain- und
Gebaeudeaktionen koennen in derselben Historie abwechseln.

## Bedienung
- Palette `Gebaeude`: Habitat oder Freihafenhalle auswaehlen, auf freien Boden klicken.
- Auswahlwerkzeug oder Rechtsklick: eine reservierte Zelle waehlt das ganze Gebaeude.
- `Verschieben`: Ziel auf der Karte anklicken; Escape bricht ohne Mutation ab. Werkzeug-/Vorlagenwechsel und Entfernen beenden den Modus ebenfalls.
- `-90°`/`+90°`: ausgewaehltes Gebaeude samt Footprint drehen.
- `Entfernen`, Delete oder Radierer: ganzes Gebaeude entfernen; Strg+Z stellt es wieder her.
- Save/SaveAs und Reload erhalten stabile IDs, Modelle und Untergrunddaten.

Generische Terrain-, Hoehen-, Objekt-, Netzwerk- oder Inspector-Aenderungen
duerfen reservierte Gebaeudefelder nicht einzeln zerlegen. Auswahlmarkierungen
liegen am Boden mit Tiefentest und uebermalen die sichtbaren Modelle nicht.
Editor und Fallback-Compiler nutzen denselben Plan-/Apply-Pfad. Der Compiler
setzt normale Objekte zuerst, damit spaetere Objektkollisionen erkannt werden.

## Grenzen
Der Editor startet mit der bearbeitbaren64er-Station. Die feste GM01-Buehne
und Basisraeume mit eigener Feinnavigation bleiben geschuetzt. Unbekannte
migrierte Layouts ohne sichere Untergrunddaten werden nicht freigegeben.
Kein Redo, Innenraum-/Tuerbau, Runtimebau oder automatische Releasefreigabe.
