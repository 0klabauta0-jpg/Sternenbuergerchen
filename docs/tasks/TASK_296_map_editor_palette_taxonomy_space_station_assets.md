# TASK_296 - Map Editor Palette Taxonomy Space Station Assets

## Ziel
Die linke Tile-Palette soll uebersichtlicher werden und kuratierte Space-Station-Kit-Assets aufnehmen. Terrain, Nature, Waende, Cliffs, Rampen, Felsen, Deko, Technik, Gebaeude und Missions-/Szenario-Objekte sollen klarer gruppiert werden.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_165 - Local Asset Curation and Import Plan
- TASK_251 - Nature Kit Classic Source Inventory and Subset Import
- TASK_295 - Map Editor Paint Toolbar Tools Polish
- vorhandenes `Assets/curated/kenney/space_station/README.md`
- vorhandene Asset-Kataloge unter `data/`

## Kontext
Die Palette wird mit Nature, Space, Technik und spaeter weiteren Sets schnell zu lang. Der User moechte links weiter eine Auswahl, aber besser sortiert: erst Gelaende, dann Nature, Waende/Cliffs/Rampen, Gebaeudekram, Deko/Technik usw. Ausserdem sollen passende Kenney Space Station Kit Assets nutzbar werden.

## Umfang
1. Palette-Taxonomie:
   - Terrain/Boden
   - Nature Boden
   - Nature Props
   - Waende
   - Cliffs
   - Rampen
   - Felsen
   - Space Station / Gebaeude
   - Technik / Deko
   - Missionsmarker / Szenario-Objekte nur in separater Gruppe
2. UI-Verbesserung:
   - Gruppen einklappbar oder gefiltert.
   - Suchfeld optional, wenn schnell machbar.
   - Aktive Gruppe/aktiver Typ sichtbar.
3. Space-Station-Kit:
   - Nur ein kuratiertes Subset ins Projekt oder aus bestehendem curated/used-Pfad referenzieren.
   - Projektlokale `res://` Pfade.
   - Scale/Y-Offset/Rotation fuer 2.5D.
   - Shared `colormap.png` muss im 3D-View auf den Space-Station-GLBs sichtbar sein.
   - Kein externer absoluter Pfad im Runtime-Katalog.
4. Katalog-Grenzen:
   - Palette-Eintrag bestimmt Visual/Objekt/Semantik nur ueber bestehende Datenfelder.
   - Objekt-Layer bleibt getrennt von Surface/Hoehe.
5. Verifier:
   - Katalog parsebar.
   - Alle referenzierten Ressourcen loadbar.
   - Palette-Gruppen vorhanden und sortiert.
   - Space-Station-Assets erzeugen keine Missing-Asset-Marker in der Referenz-Map.

## Nicht-Ziele
- Kein Mass-Import des kompletten Space Station Kits.
- Keine neue Bau-/Snap-Mechanik fuer mehrtile Gebaeude.
- Keine finalen Mission-Szenario-Tools.

## Akzeptanzkriterien
- [x] Palette ist gruppiert und deutlich uebersichtlicher.
- [x] Space-Station-Kit-Subset ist projektlokal und loadbar.
- [x] Neue Assets haben sichtbare, plausible Scale/Rotation/Y-Offsets.
- [x] Bodenpinsel, Objekte und Hoehe bleiben getrennte Authoring-Ebenen.
- [x] Verifier prueft Katalog, Ressourcen und Palettenreihenfolge.

## Erwartete Dateien
- `data/terrain_object_catalog.json`
- `data/space_setpiece_catalog.json`
- `data/terrain_3d_asset_mapping.json`
- `scripts/editor/map_editor.gd`
- optional `Assets/used/terrain/space_station/...`
- `scripts/tests/task_296_map_editor_palette_taxonomy_space_station_assets.gd`
- `docs/assets/space_station_palette_inventory.md`
- `docs/manual_checks/map_editor_palette_space_station_checklist.md`
- `docs/tasks/TASK_296_map_editor_palette_taxonomy_space_station_assets.md`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_296_map_editor_palette_taxonomy_space_station_assets.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_229_map_editor_usability_authoring_pass.gd`
- [ ] Manueller Palette-Sichtcheck.
- [ ] `git diff --check`

## Risiken
- Zu viele Assets machen die Palette trotz Gruppen wieder unhandlich.
- Falsch skalierte Gebaeude koennen Grid/Selection verdecken.
- Runtime darf keine absoluten lokalen Quellpfade verwenden.

## Naechster Schritt
TASK_297 trennt rechts Tile Properties, Map Settings und Scenario Settings sauberer.
