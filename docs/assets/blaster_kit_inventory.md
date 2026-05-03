# Blaster Kit Inventory

Datum: 2026-05-03
Status: TASK_174 Visual-Attachment-Slice

## Quelle
- Lokaler Pfad: `C:\Users\bjoer\Pictures\Sternenbuerger\Blaster Kit`
- Bundle: `Blaster Kit (2.1)`
- Autor/Distributor: Kenney, `www.kenney.nl`

## Lizenz
`License.txt` nennt Creative Commons Zero, CC0. Nutzung fuer persoenliche, edukative und kommerzielle Zwecke ist erlaubt. Credit an `Kenney` oder `www.kenney.nl` ist erwuenscht, aber nicht erforderlich.

## Inventar
| Typ | Anzahl | Entscheidung |
| --- | ---: | --- |
| `.glb` | 40 | Drei Blaster importiert; GLB bleibt das einzige 3D-Format in diesem Slice. |
| `.fbx` | 40 | Nicht importiert, weil GLB vorhanden ist. |
| `.obj` | 40 | Nicht importiert. |
| `.mtl` | 40 | Nicht importiert. |
| `.png` | 46 | Eine Preview plus die von GLB referenzierte `colormap.png` importiert. |
| `.txt` | 1 | Lizenz importiert. |
| `.html` / `.url` | 4 | Nicht importiert. |

## TASK_174 Subset
Zielpfad: `Assets/used/npc/blaster_kit/`

| Datei | Zweck |
| --- | --- |
| `models/blaster-a.glb` | Friendly/default RightHandSocket-Visual. |
| `models/blaster-f.glb` | Enemy/team_bravo RightHandSocket-Visual. |
| `models/blaster-p.glb` | Zweite Enemy-Variante fuer explizite Unit-ID. |
| `models/Textures/colormap.png` | Gemeinsame GLB-Textur, von den importierten Modellen referenziert. |
| `previews/blaster-a.png` | Kleine Preview fuer Dokumentation oder spaetere UI-Anbindung. |
| `License.txt` | Lizenznachweis im importierten Subset. |

## Verwendung
- `data/npc_unit_visual_mapping.json` mappt Blaster nur als 2.5D-Visual-Attachments.
- `TerrainMap3DView` haengt Blaster an `RightHandSocket` aus TASK_173.
- Blaster bleiben reine Darstellung und erzeugen keine Loadout-, Combat-, Ballistik- oder Munitionslogik.

## Importstrategie
- Kein Komplettimport des Blaster Kits.
- Keine parallelen FBX-/OBJ-/MTL-Duplikate.
- Fehlende Blaster-Assets werden im Visual-Pfad sichtbar markiert und im Snapshot ueber `unit_blaster_error_count` gezaehlt.
