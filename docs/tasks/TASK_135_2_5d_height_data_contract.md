# TASK_135 - 2.5D Height Data Contract

## Ziel
Eine kleine, belastbare Datenbasis fuer 2.5D-Bodenkampf einfuehren: Tiles bleiben gridbasiert, bekommen aber explizite Hoehen-, Deckungs- und Blockerwerte, die Navigation, LOS, Cover und 3D-Darstellung spaeter gemeinsam nutzen koennen.

## Status: IMPLEMENTIERT

## Kontext
- TASK_133/134 haben eine parallele 3D-Darstellung aufgebaut, ohne Simulation oder Gameplay auf Full-3D umzubauen.
- Das Projekt soll zuerst als 2.5D-Hybrid wachsen: autoritative 2D-/Grid-Logik bleibt, Hoehe wird als Datenebene ergaenzt.
- Bestehende Terrain-/Map-Daten muessen rueckwaertskompatibel lesbar bleiben.

## Umfang
1. `TerrainTileData` um 2.5D-Felder erweitern:
   - `height_level`
   - `floor_height`
   - `unit_eye_height_bonus`
   - `cover_height`
   - `blocks_los_height`
   - `is_elevated_surface`
2. JSON-Load/Save rueckwaertskompatibel erweitern.
3. Terrain-Katalog um konservative Defaultwerte pro Typfamilie ergaenzen.
4. `TerrainRegistry` um lesende Hoehen-API erweitern.
5. Verifier fuer Roundtrip, Defaults und alte Karten ohne Hoehendaten.

## Nicht-Ziele
- Keine neue LOS-Formel.
- Keine Navigation ueber Rampen/Treppen.
- Keine Multi-Floor-Stapelung auf demselben Grid-Feld.
- Keine Full-3D-Physik.

## Akzeptanzkriterien
- [x] Alte Map-JSON-Dateien laden ohne Datenverlust.
- [x] Neue 2.5D-Felder werden gespeichert und wieder geladen.
- [x] Katalogtypen liefern sinnvolle Defaultwerte.
- [x] `TerrainRegistry` kann Bodenhoehe, Coverhoehe und LOS-Blockerhoehe pro Grid abfragen.
- [x] Verifier deckt Default-, Roundtrip- und Legacy-Faelle ab.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_135_verifier.gd`

## Risiken
- Falsche Defaults koennen spaetere LOS-/Cover-Ergebnisse verzerren; Werte deshalb defensiv klein halten.
- Die Felder duerfen nicht zu versteckter Gameplay-Wahrheit im Editor werden, sondern bleiben Terrain-Daten.
