# Nature Kit Classic Inventory

Stand: 2026-05-07
Task: TASK_251

## Quelle
- Pack: Kenney Nature Kit (Classic) 1.0
- Quelle: `%USERPROFILE%/Pictures/Kenney Game Assets All-in-1 3.4.0/3D assets/Nature Kit (Classic)`
- Lizenz: Creative Commons Zero, CC0
- Projektziel: `res://Assets/used/terrain/nature_kit_classic/`

## Source Audit
- `Models/glTF format`: 232 `.gltf` und 232 `.bin`
- `Models/FBX format`: 232 `.fbx`
- `Models/OBJ format`: 232 `.obj` und 232 `.mtl`
- Top-level: `License.txt`, `Preview.png`, `Sample.png`, `sprites_isometric.zip`, `sprites_topdown.zip`
- Runtime-Entscheidung: glTF plus benachbarte `.bin` wird bevorzugt; FBX/OBJ/ZIP werden nicht als Runtime-Duplikate importiert.

## Kuratiertes Subset
Es wurden 25 Modelle als kleines V1-Subset kopiert. Das ist bewusst kein Komplettimport der 232 Modelle, also No complete pack import.

| Kategorie | Modelle | Einsatz |
| --- | ---: | --- |
| cliffs | 10 | TASK_252 Cliff-/Slope-/Hill-Edge-Mapping |
| ground | 3 | TASK_253 Ground-/Surface-Palette |
| rocks | 4 | TASK_254 Rock-/Cover-/Prop-Kandidaten |
| vegetation | 5 | TASK_254 Tree/Bush/Cactus-Kandidaten |
| props | 3 | optionale Natur-Props |

## Cliff- und Slope-Kandidaten
- `cliffBrown`, `cliffBrown_cornerTop`, `cliffBrown_cornerInnerTop`
- `cliffBrown_steps`, `cliffBrown_stepsEnd`
- `cliffGrey`, `cliffGrey_cornerTop`, `cliffGrey_cornerInnerTop`
- `cliffGrey_steps`, `cliffGrey_stepsEnd`

`steps` und `stepsEnd` sind visuelle Kandidaten fuer `edge_type = slope`. Gerade und Corner-Cliffs sind visuelle Kandidaten fuer `edge_type = cliff`. Gameplay-Wahrheit bleibt bei `TerrainPathfinder`, `TerrainRegistry` und dem TASK_182-Hoehenvertrag.

## Ground-, Rock-, Vegetation- und Prop-Kandidaten
- Ground: `ground_dirt`, `ground_dirtRiverTile`, `grass`
- Rocks/Stones: `rock_large1`, `rock_small1`, `rock_tall1`, `stone_block`
- Vegetation: `tree_default`, `tree_pine_tall`, `plant_bush`, `cactus_tall`, `cactus_large`
- Props: `logs_stack`, `campfire_small`, `fence_simple`

## Projektstruktur
```text
Assets/used/terrain/nature_kit_classic/
  License.txt
  cliffs/
  ground/
  rocks/
  vegetation/
  props/
  documentation/
```

Jedes Runtime-Modell liegt als `.gltf` zusammen mit der gleichnamigen `.bin` im selben Ordner. `Preview.png` und `Sample.png` liegen nur unter `documentation/` und sind keine Runtime-Abhaengigkeit.

## Runtime-Regeln
- Runtime-Daten nutzen nur `res://`-Pfade aus `data/nature_kit_asset_catalog.json`.
- Keine lokalen User-Pfade im Katalog.
- Keine ZIPs als Runtime-Abhaengigkeit.
- Keine FBX/OBJ/glTF-Duplikate fuer dasselbe Asset im Projekt.
- Nature-Kit-Visuals sind Darstellung; sie veraendern keine Walkability, LOS, Cover oder SimulationRoot-Wahrheit.
