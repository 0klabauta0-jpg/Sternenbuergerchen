# TASK_251 - Nature Kit Classic Source Inventory and Subset Import

## Ziel
Das lokale Kenney `Nature Kit (Classic)` soll als Terrain-Assetquelle inventarisiert und als kleines, projektlokales Subset vorbereitet werden. Fokus sind Klippen/Kanten fuer Huegel, passende Bodenstuecke, Felsen, Baeume, Buesche, Cacti und einfache Natur-Props.

Es wird kein kompletter Pack-Import gemacht. Nur Assets, die fuer Huegel, Map-Editor und Missionsdarstellung geplant sind, werden ins Projekt kopiert.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_182 - Terrain Hill Rules Contract
- TASK_185 - Hill Visuals and Edge Lines Patch
- TASK_193 - Asset Source Inventory and Availability Matrix
- TASK_197 - Curated Asset Catalog and Usage Mapping
- TASK_247 - Used Asset Project Locality Audit Gate

## Quellenliste
- `%USERPROFILE%\Pictures\Kenney Game Assets All-in-1 3.4.0\3D assets\Nature Kit (Classic)`
- `Models\glTF format`
- `Models\FBX format`
- `Models\OBJ format`
- `License.txt`
- `Preview.png`
- `Sample.png`
- `sprites_isometric.zip`
- `sprites_topdown.zip`

## Kontext
Das vorhandene Terrain-Mapping nutzt hauptsaechlich Space-Kit-Assets. Fuer natuerlichere Huegelrander, Klippenlinien, Bodenvarianten und Vegetation ist das Nature Kit passender. Der Pack enthaelt u. a. braune/graue Cliff-Varianten, Steps, Inner-/Outer-Corners, Ground-Dirt-/River-Stuecke, Felsen, Cacti, Buesche und Baeume.

Godot-kompatibel soll bevorzugt die glTF-Quelle genutzt werden. Bei glTF muessen `.gltf` und die zugehoerigen `.bin`-Dateien projektlokal zusammenbleiben.

## Umfang
1. Quellen-Audit:
   - Dateitypen und Mengen erfassen.
   - Lizenz als CC0 dokumentieren.
   - Cliff-, Ground-, Rock-, Tree-/Plant- und Prop-Kandidaten katalogisieren.
   - glTF/FBX/OBJ-Duplikate vergleichen und bevorzugtes Runtime-Format festlegen.
2. Kuratiertes Subset definieren:
   - Cliff-Brown und Cliff-Grey Kernteile.
   - Steps/Entrance fuer begehbare Slope-/Rampendarstellung.
   - Ground-Dirt/Grass-Stuecke als sichtbare Surface-Varianten.
   - Rocks, Tree, Bush, Cactus als erste Natur-Objekte.
   - Optional Preview-/Sample-Bilder nur fuer Doku/Editor-Thumbnail-Pruefung.
3. Projektimport planen:
   - Zielpfad `Assets/used/terrain/nature_kit_classic/`.
   - Unterordner fuer `cliffs`, `ground`, `rocks`, `vegetation`, `props`.
   - `.gltf` und `.bin` zusammen kopieren oder bewusst in ein Godot-freundliches Format ueberfuehren.
   - Lizenzdatei mitkopieren.
4. Manifest:
   - `docs/assets/nature_kit_classic_inventory.md`
   - `data/nature_kit_asset_catalog.json`
   - Quelle, Projektpfad, Kategorie, bevorzugter Verbrauchsort, Scale-Hinweis, Gameplay-Rolle.
5. Importregeln:
   - Keine lokalen User-Pfade in Runtime-Daten.
   - Keine ZIPs als Runtime-Abhaengigkeit.
   - Keine doppelten FBX/OBJ/glTF-Kopien ohne Grund.

## Nicht-Ziele
- Kein sofortiger Renderer-Umbau.
- Kein finaler Map-Editor-Palette-Pass.
- Kein Gameplay-Cover fuer Baeume/Felsen; das folgt in TASK_254.
- Kein Komplettimport aller 232 Modelle.

## Akzeptanzkriterien
- [x] Das Nature Kit ist in `docs/assets/nature_kit_classic_inventory.md` dokumentiert.
- [x] `data/nature_kit_asset_catalog.json` enthaelt stabile Asset-IDs fuer das kuratierte Subset.
- [x] Alle importierten Runtime-Dateien liegen unter `Assets/used/terrain/nature_kit_classic/`.
- [x] glTF-Abhaengigkeiten wie `.bin` liegen projektlokal neben den genutzten Modellen.
- [x] Lizenz und Quelle sind dokumentiert.
- [x] Ein Verifier prueft Katalog, Projektpfade, Dateiexistenz und lokale Pfadfreiheit.

## Erwartete Dateien
- `docs/assets/nature_kit_classic_inventory.md`
- `data/nature_kit_asset_catalog.json`
- `Assets/used/terrain/nature_kit_classic/...`
- `scripts/tests/task_251_nature_kit_classic_source_inventory_and_subset_import.gd`
- `docs/tasks/TASK_251_nature_kit_classic_source_inventory_and_subset_import.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_251_nature_kit_classic_source_inventory_and_subset_import.gd`
- [x] `git diff --check`

## Umsetzung
- 25 kuratierte glTF-Modelle plus die jeweils gleichnamige `.bin` liegen unter `Assets/used/terrain/nature_kit_classic/` in `cliffs`, `ground`, `rocks`, `vegetation` und `props`.
- `License.txt`, `Preview.png` und `Sample.png` wurden projektlokal fuer Lizenz/Doku kopiert; ZIP/FBX/OBJ/MTL-Duplikate wurden nicht importiert.
- `data/nature_kit_asset_catalog.json` beschreibt Asset-IDs, Kategorie, Projektpfad, `.bin`-Abhaengigkeit, geplanten Verbrauchsort und Gameplay-Rollenhinweis.
- `scripts/tests/task_251_nature_kit_classic_source_inventory_and_subset_import.gd` prueft Doku, Katalog, Projektpfade, ResourceLoader, glTF/bin-Nachbarschaft, lokale Pfadfreiheit und dass kein Komplettpack importiert wurde.

## Risiken
- glTF ohne passende `.bin`-Datei importiert nicht sauber.
- Ein zu grosses Subset belastet Importzeit, Projektgroesse und spaetere Performance.
- Nature-Kit-Visuals duerfen nicht still die bestehende Terrain-Gameplay-Wahrheit veraendern.

## Naechster Schritt
Nach TASK_251 kann TASK_252 die Klippen- und Huegelkanten-Visuals aus dem Subset auf den bestehenden Hoehenvertrag mappen.
