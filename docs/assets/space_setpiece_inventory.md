# Space Setpiece Inventory

Datum: 2026-05-06
Status: TASK_194 implementiert

## Zweck
Dieses Inventar dokumentiert das kleine GLB-only-Subset aus `Modular Space Kit` und `Space Station Kit`. Die Assets sind reine Darstellung fuer Homebase, FOB, Flightdeck, Hangar, Medbay und spaetere Preview-/Editor-Setpieces.

Gameplay-State, Kollisionslogik, Walkability, Combat, Terrain-Mapping und Multiplayer-Authority werden aus diesen Setpieces nicht abgeleitet.

## Quellen
| Quelle | Lizenz | Projektpfad | Importstatus |
| --- | --- | --- | --- |
| Kenney Modular Space Kit (1.0) | Creative Commons Zero, CC0 | `Assets/curated/kenney/modular_space/` | 10 GLB + shared `models/Textures/colormap.png` + `License.txt` |
| Kenney Space Station Kit (1.0) | Creative Commons Zero, CC0 | `Assets/curated/kenney/space_station/` | 12 GLB + shared `models/Textures/colormap.png` + `License.txt` |
| Kenney Space Kit (2.0) | Creative Commons Zero, CC0 | `Assets/kenney_space-kit/` | reuse existing, kein neuer Import |

## Importregeln
- GLB-only fuer Modelle in diesem Task; die je Kit benoetigte shared `colormap.png` wird mitgefuehrt, weil die GLBs sie referenzieren.
- Keine FBX-, OBJ-, MTL-, DAE-, STL- oder Unity-Package-Duplikate.
- Keine absoluten lokalen Benutzerpfade in Manifest, Katalog, Runtime, Tests oder Mapping.
- Jede Datei bleibt Visual. Fehlende Dateien sollen ueber Verifier/Missing-Asset-Pfade sichtbar werden.

## Modular Space Kit Subset
| ID | Projektpfad | Kategorie | Einsatzort | Scale |
| --- | --- | --- | --- | ---: |
| `modular_floor` | `res://Assets/curated/kenney/modular_space/models/template-floor.glb` | hangar_floor | small floor insert | 1.0 |
| `modular_floor_big` | `res://Assets/curated/kenney/modular_space/models/template-floor-big.glb` | hangar_floor | large floor block | 1.0 |
| `modular_floor_raised` | `res://Assets/curated/kenney/modular_space/models/template-floor-layer-raised.glb` | docking_pad | raised pad or service bay | 1.0 |
| `modular_wall` | `res://Assets/curated/kenney/modular_space/models/template-wall.glb` | wall_panel | straight modular wall | 1.0 |
| `modular_wall_corner` | `res://Assets/curated/kenney/modular_space/models/template-wall-corner.glb` | wall_panel | corner modular wall | 1.0 |
| `modular_gate` | `res://Assets/curated/kenney/modular_space/models/gate.glb` | door_airlock | airlock frame | 1.0 |
| `modular_gate_door` | `res://Assets/curated/kenney/modular_space/models/gate-door.glb` | door_airlock | closed airlock door | 1.0 |
| `modular_corridor_wide` | `res://Assets/curated/kenney/modular_space/models/corridor-wide.glb` | corridor | wide connector corridor | 1.0 |
| `modular_corridor_wide_corner` | `res://Assets/curated/kenney/modular_space/models/corridor-wide-corner.glb` | corridor | wide corridor corner | 1.0 |
| `modular_room_wide` | `res://Assets/curated/kenney/modular_space/models/room-wide.glb` | hangar_room | wide bay or staging room | 1.0 |

## Space Station Kit Subset
| ID | Projektpfad | Kategorie | Einsatzort | Scale |
| --- | --- | --- | --- | ---: |
| `station_floor` | `res://Assets/curated/kenney/space_station/models/floor.glb` | hangar_floor | station floor tile | 1.0 |
| `station_floor_panel` | `res://Assets/curated/kenney/space_station/models/floor-panel.glb` | hangar_floor | panelled floor tile | 1.0 |
| `station_wall` | `res://Assets/curated/kenney/space_station/models/wall.glb` | wall_panel | straight station wall | 1.0 |
| `station_wall_door` | `res://Assets/curated/kenney/space_station/models/wall-door.glb` | door_airlock | door wall segment | 1.0 |
| `station_wall_window` | `res://Assets/curated/kenney/space_station/models/wall-window.glb` | wall_panel | window wall segment | 1.0 |
| `station_door_single_closed` | `res://Assets/curated/kenney/space_station/models/door-single-closed.glb` | door_airlock | closed inner door | 1.0 |
| `station_computer` | `res://Assets/curated/kenney/space_station/models/computer.glb` | console | small console | 1.0 |
| `station_computer_wide` | `res://Assets/curated/kenney/space_station/models/computer-wide.glb` | console | wide command console | 1.0 |
| `station_table_display` | `res://Assets/curated/kenney/space_station/models/table-display.glb` | console | briefing or planning table | 1.0 |
| `station_bed_single` | `res://Assets/curated/kenney/space_station/models/bed-single.glb` | medbay | medbay bed | 1.0 |
| `station_container_wide` | `res://Assets/curated/kenney/space_station/models/container-wide.glb` | storage_cargo | cargo/storage prop | 1.0 |
| `station_structure_panel` | `res://Assets/curated/kenney/space_station/models/structure-panel.glb` | wall_panel | large structural panel | 1.0 |

## Katalog
`data/space_setpiece_catalog.json` spiegelt die obigen IDs, Projektpfade, Kategorien und Import-Scale-Hinweise fuer spaetere UI-/Editor-/Preview-Verwendung. Der Katalog ist Visual-only und enthaelt keine lokalen Quellpfade. Runtime-/Editor-Scale ist nicht aus diesem Inventar abzuleiten; dafuer ist `data/terrain_3d_asset_mapping.json` die verbindliche Quelle.
