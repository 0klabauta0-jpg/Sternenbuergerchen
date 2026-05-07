# TASK_194 - Space Modular and Station Setpiece Import

## Ziel
Aus `Modular Space Kit`, `Space Station Kit` und dem vorhandenen `kenney_space-kit` sollen kuratierte 3D-Setpieces fuer Homebase, FOB, Flightdeck, Hangar, Medbay und spaetere Mission-Setpieces verfuegbar gemacht werden.

Der Task importiert keine kompletten Packs, sondern kleine, benannte GLB-Subsets mit Manifest und Verifier.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_193 - Asset Source Inventory and Availability Matrix
- TASK_179 - Homebase Drop Light Fixed FullHD Layout
- TASK_181 - Drop Light Fixed Window Audit Patch
- TASK_185 - Hill Visuals and Edge Lines Patch, falls Terrain-/Mission-Setpieces betroffen sind

## Quellen
- `C:\Users\bjoer\Pictures\Sternenbürger\Modular Space Kit`
- `C:\Users\bjoer\Pictures\Sternenbürger\Space Station Kit`
- `C:\Users\bjoer\Pictures\Sternenbürger\kenney_space-kit`

## Zielpfade
- `Assets/curated/kenney/modular_space/`
- `Assets/curated/kenney/space_station/`
- vorhandenes `Assets/kenney_space-kit/` nur wiederverwenden, nicht doppelt kopieren
- `docs/assets/space_setpiece_inventory.md`

## Umfang
1. Setpiece-Auswahl:
   - Maximal 12 GLB aus `Space Station Kit`.
   - Maximal 10 GLB aus `Modular Space Kit`.
   - Bestehende `kenney_space-kit`-Modelle nur als Referenz oder bestehende Projektpfade nutzen.
   - Kategorien: Hangar/Floor, Wall/Panel, Console, Door/Airlock, Medbay, Storage/Cargo, Docking/Pad.
2. Importregeln:
   - GLB-only.
   - Keine parallelen FBX/OBJ/MTL/DAE/STL-Kopien.
   - Lizenzdatei oder Quellenhinweis mitkopieren bzw. im Inventar dokumentieren.
   - Keine absoluten lokalen Pfade in Projektdateien.
3. Manifest:
   - `docs/assets/space_setpiece_inventory.md`
   - Optional `data/space_setpiece_catalog.json`
   - Pro Asset: ID, Quelle, Projektpfad, Kategorie, empfohlener Einsatzort, Scale-Hinweis.
4. Verfuegbarkeit:
   - Homebase/FOB koennen spaeter Setpieces per ID referenzieren.
   - Keine direkte Mission-Gameplay-Wahrheit aus Setpieces ableiten.
   - Fehlende Assets muessen im Verifier sichtbar werden.
5. Verifier:
   - Alle importierten GLB sind loadbar.
   - Keine lokalen `C:\Users\...`-Pfade in Manifest/Mapping.
   - Maximalmengen werden eingehalten.
   - Godot-Import erzeugt keine fehlenden Ressourcen.

## Nicht-Ziele
- Kein Komplettimport ganzer Kits.
- Kein Umbau von Homebase/FOB-Layout in diesem Task.
- Keine TerrainMap3DView-Gameplay-Mapping-Erweiterung.
- Keine neuen Kollisions- oder Walkability-Regeln.

## Akzeptanzkriterien
- [x] Space-Station- und Modular-Space-Subsets sind kuratiert und importiert.
- [x] Alle importierten 3D-Assets liegen unter `Assets/curated/kenney/...`.
- [x] Ein Inventar dokumentiert Quelle, Lizenz, Zweck und Zielpfad.
- [x] GLB-Assets sind in Godot loadbar.
- [x] Keine absoluten lokalen Pfade werden in Runtime/Tests/Mapping referenziert.
- [x] Ein TASK_194-Verifier prueft Maximalmengen, Loadbarkeit und Manifest.

## Erwartete Dateien
- `Assets/curated/kenney/modular_space/`
- `Assets/curated/kenney/space_station/`
- `docs/assets/space_setpiece_inventory.md`
- `data/space_setpiece_catalog.json`
- `scripts/tests/task_194_space_modular_station_setpiece_import_verifier.gd`
- `docs/tasks/TASK_194_space_modular_station_setpiece_import.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_194_space_modular_station_setpiece_import_verifier.gd`
- [ ] Manueller Godot-Sichtcheck einer kleinen Setpiece-Preview-Szene, falls eine Szene angelegt wird.
- [x] `git diff --check`

## Umsetzung
- Importiert wurden 10 Modular-Space-GLBs nach `Assets/curated/kenney/modular_space/models/` und 12 Space-Station-GLBs nach `Assets/curated/kenney/space_station/models/`.
- Je Kit wurde `License.txt`, ein README und die von den GLBs referenzierte shared `models/Textures/colormap.png` mitgefuehrt. Es wurden keine FBX/OBJ/MTL/DAE/STL-Duplikate kopiert.
- `docs/assets/space_setpiece_inventory.md` dokumentiert IDs, Quelle, Lizenz, Projektpfad, Kategorie, Einsatzort und Scale-Hinweis.
- `data/space_setpiece_catalog.json` stellt die Setpieces spaeteren UI-/Editor-/Preview-Pfaden per ID bereit. Der Katalog ist Visual-only und enthaelt keine lokalen Quellpfade.
- `scripts/tests/task_194_space_modular_station_setpiece_import_verifier.gd` prueft Maximalmengen, Pflichtkategorien, Loadbarkeit, GLB-only-Regeln, shared Textures, Manifest/Katalog und lokale-Pfad-Freiheit.

## Risiken
- Grosse 3D-Subsets koennen Importzeit und Repo-Groesse schnell erhoehen. Maximalmengen sind Pflicht.
- Setpieces duerfen nicht als unsichtbare Gameplay-Hindernisse missverstanden werden. Gameplay bleibt bei Terrain-Daten.

## Naechster Schritt
Nach TASK_194 kann TASK_197 die Setpieces ueber einen zentralen Asset-Katalog fuer UI/Editor/Mission verfuegbar machen.
