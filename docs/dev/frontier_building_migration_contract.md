# Aktuelle Gebaeudepfade und verlustfreies Karten-Authoring

Stand10.11.2026. Nutzerauftrag und Umsetzung:
`docs/tasks/MAP_SAVE_BUILDING_MIGRATION_2026_11_10.md`.

## Kartenspeicherung
TerrainMapData besitzt seine bekannten Terrain-/Marker-/Szenariofelder weiter
selbst. Unbekannte JSON-Rootfelder werden einzeln tief kopiert und unveraendert
mitgeschrieben; insbesondere homebase_exploration, place_world und
singleplayer_site. Bekannte Felder und deren alte Aliasnamen werden nicht als
zweite Kopie erhalten. Der Serializer schreibt diese aus den aktuellen
Ownerfeldern und verwendet volle Zahlenpraezision fuer verschachtelte Fakten.
Opaque Metadaten sind kein neuer Gameplay-Owner und kein UI-State.

## Gebaeudefamilie
Die aktuellen geschlossenen Habitat-/Hallenmodelle werden mit demselben
`frontier_closed_buildings.gd` wie GM01 und Handel erzeugt. Der Offlinebuilder
`build_frontier_exterior_assets.gd` speichert wiederverwendbare PackedScenes
unter scenes/terrain/ und Quellenhashes/Bounds im
`data/frontier_building_visual_catalog.json`. Originale GLB-/BLEND-Quellen
bleiben erhalten. Basisinnenraeume verwenden weiter ihre Tuer-Ableitungen.

Alte Gebaeude-/Hangar-/Factory-IDs bleiben fuer vorhandene Karten lesbar,
laden jedoch aktuelle Aussenhuellen. Ihre Kompatibilitaetsskala bleibt
innerhalb der bisherigen Modellhuele; sie fuehrt keine neuen Terrainfakten
beim Rendern ein. Alle35 alten Paletteneintraege sind fuer neues Authoring
ausgeblendet. Zwei aktuelle Vorlagen besitzen native Vorschaubilder.

## Stationsmissionen
Die64er/192er-Stationen speichern2/18 aktuelle Gebaeude ueber den bestehenden
place_presentation.props-Pfad. Groesse, Rotation und Hoehe sind explizit;
frontier_scene_solid-Zellen speichern dazu Walkability/LOS/Deckung. Der
Renderer installiert nur Modelle und visuelle Besitzzuordnungen.
Der Offline-Migrationshelper darf Kartenfakten erstellen; Runtime-/UI-
Rendering darf dies nicht. Quellenbuilder verwenden dieselbe Migration bzw.
rotieren die gespeicherten Platzierungen und Reservierungen mit ihren Sektoren.

Die zwei Gebaeude werden im Quellsektor je eine Zelle nach innen versetzt,
damit vorhandene Patrouillenpunkte begehbar bleiben. Grobe Reservierungen
duerfen sich in einer Zelle beruehren; die sichtbaren Huelen ueberlappen nicht.
Karten-/Szenarioidentitaeten, Marker und Patrouillen bleiben erhalten.

## Grenze bis zum Editor-Nachzug
Aktuelle Mehrzellen-Gebaeude sind Layoutvorlagen, kein freier Einzelzellen-
Pinsel. Die Palette/Schnellbuttons zeigen sie, erklaeren aber diese Grenze.
Brush und Compiler verweigern falsche Einzelzellen-Platzierung. Das Workbench-
Demo setzt kein solches Gebaeude. Bestehende migrierte Stationsensembles sind
gegen getrennte Terrain-/Objekt-/Markerbearbeitung geschuetzt; SaveAs bleibt
moeglich. Freies Verschieben, Drehen, Entfernen samt Footprint und Undo gehoert
in den anschliessenden Editorauftrag.

## Render-Einstiege
Editor-Default, 3D-Kalibrierung, Render-Spike und der Menuehintergrund-Generator
verwenden die gespeicherte GM01. Der Hintergrund-Generator laedt keine
synthetische Testsimulation mehr. Die alte Grafikvergleichsszene bleibt
explizite historische Probe; sie ist kein aktueller Kampagnen-Render-Einstieg.
Bereits vorhandene Hintergrund-PNGs werden durch einen Quellfix nicht neu
exportiert. Bildvergleich und technische Importpruefung sind keine Nutzer-
Stilabnahme oder allgemeine Releasefreigabe.
