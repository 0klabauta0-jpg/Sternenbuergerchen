# Asset Source Availability Matrix

Datum: 2026-05-06
Status: TASK_193 implementiert, keine binaeren Assets importiert

## Zweck
Diese Matrix ist die verbindliche Quellenliste fuer die naechsten Asset-Slices. Sie entscheidet je Quelle, ob vorhandene Projektkopien wiederverwendet werden, ob ein kleines kuratiertes Subset spaeter importiert werden darf oder ob die Quelle nur Reserve bleibt.

Die lokale Quelle liegt unter `%USERPROFILE%/Pictures/Sternenbuerger/` (Windows-Ordnername mit Umlaut: `Sternenbürger`). Runtime-, Mapping-, UI- und Testdateien duerfen daraus nie direkt referenzieren; dort sind nur `res://...`-Projektpfade erlaubt.

## Matrix
| Source ID | Local source | Project path | License | File types / size | Import status | Max subset | Planned usage | Follow task | Notes |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- | --- |
| `modular_space_kit` | `%USERPROFILE%/Pictures/Sternenbuerger/Modular Space Kit` | `Assets/curated/kenney/modular_space/` | Creative Commons Zero, CC0; local `License.txt` | 214 files, 20.08 MB; 40 GLB, 49 PNG, 40 FBX, 40 OBJ/MTL | planned curated subset | 10 GLB | FOB/Homebase/Hangar setpieces only | TASK_194 | GLB first; no FBX/OBJ/MTL duplicates. |
| `space_station_kit` | `%USERPROFILE%/Pictures/Sternenbuerger/Space Station Kit` | `Assets/curated/kenney/space_station/` | Creative Commons Zero, CC0; local `License.txt` | 738 files, 7.10 MB; 177 GLB, 104 PNG, 97 FBX, 97 OBJ/MTL, 80 DAE/STL | planned curated subset | 12 GLB | station/hangar/medbay setpieces only | TASK_194 | Visual setpieces; no terrain or gameplay truth. |
| `kenney_ui_pack_space_expansion` | `%USERPROFILE%/Pictures/Sternenbuerger/kenney_ui-pack-space-expansion` | `Assets/kenney_ui-pack-space-expansion/` | Creative Commons Zero, CC0; local/project `License.txt` | local 1117 files, 0.83 MB; 742 PNG, 370 SVG, 2 TTF | reuse existing project copy | 0 | sci-fi panels, buttons, UI trim | TASK_195 | Existing project copy has Godot imports; do not duplicate. |
| `kenney_ui_pack` | `%USERPROFILE%/Pictures/Sternenbuerger/kenney_ui-pack` | `Assets/kenney_ui-pack/` | Creative Commons Zero, CC0; local/project `License.txt` | local 1315 files, 1.35 MB; 870 PNG, 434 SVG, 6 OGG, 2 TTF | reuse existing project copy | 0 | common UI components and tooltip icons | TASK_195 | Existing TASK_164 UI base remains leading. |
| `kenney_space_kit` | `%USERPROFILE%/Pictures/Sternenbuerger/kenney_space-kit` | `Assets/kenney_space-kit/` | Creative Commons Zero, CC0; local/project `License.txt` | local 1692 files, 17.63 MB; 770 PNG, 153 GLB, 153 FBX/OBJ/MTL/DAE/STL | reuse existing project copy | 0 | existing flightdeck, transport, 2.5D space props | TASK_194 | Existing project copy remains leading; no duplicate Space Kit import. |
| `kenney_ranks_pack` | `%USERPROFILE%/Pictures/Sternenbuerger/kenney_ranks-pack` | `Assets/curated/kenney/ranks/` | Creative Commons Zero, CC0; local `License.txt` | 644 files, 0.78 MB; 633 PNG, 4 SVG, 4 SWF | planned curated subset | 12 PNG | rank, role, skill and state badges | TASK_196 | PNG only for V1; SWF is never imported. |
| `kenney_particle_pack` | `%USERPROFILE%/Pictures/Sternenbuerger/kenney_particle-pack` | `Assets/curated/kenney/particles/` | Creative Commons Zero, CC0; local `License.txt` | 195 files, 14.52 MB; 193 PNG, 1 Unity package | planned curated subset | 12 PNG | muzzle/contact/LZ/objective VFX as visuals | TASK_196 | No gameplay state, no Unity package import. |
| `kenney_input_keyboard_mouse` | `%USERPROFILE%/Pictures/Sternenbuerger/kenney_input-prompts_1.4.1/Keyboard & Mouse` | `Assets/kenney_input-prompts_1.4.1/Keyboard & Mouse/` | Creative Commons Zero, CC0; parent `License.txt` | local 736 files, 0.65 MB; 488 PNG, 243 SVG, 1 OTF, 1 TTF | reuse existing project copy | 0 | command tooltips and editor shortcuts | TASK_195 | Use existing PNG prompts first; SVG only for explicit scaling need. |
| `kenney_cursor_pixel_pack` | `%USERPROFILE%/Pictures/Sternenbuerger/kenney_cursor-pixel-pack` | `Assets/kenney_cursor-pixel-pack/` | Creative Commons Zero, CC0; local/project `License.txt` | local 227 files, 0.07 MB; 223 PNG | reuse existing project copy | 0 | editor cursors, tactical cursor states | TASK_195 | Existing project copy has imports; no second cursor pack. |

## Importregeln
1. Kein Pack-Komplettimport aus dieser Matrix.
2. Neue 3D-Setpieces bevorzugen GLB; FBX, OBJ, MTL, DAE und STL werden nicht parallel importiert.
3. Godot-UI nutzt PNG zuerst. SVG bleibt Reserve fuer echte Skalierungsanforderungen.
4. Jede spaeter importierte Datei braucht Quelle, Lizenz, Zielpfad, Auswahlgrund und Verbrauchsort im passenden Manifest.
5. Runtime-, Data-, UI- und Testdateien duerfen keine absoluten Benutzerpfade enthalten.
6. Asset-Slices bleiben Darstellung. Gameplay-State, Combat-Werte, Pathfinding, Terrain-Wahrheit und Multiplayer-Authority bleiben bei den bestehenden Systemen.

## Folgezuordnung
| Follow task | Quellen |
| --- | --- |
| TASK_194 | `modular_space_kit`, `space_station_kit`, bestehendes `kenney_space_kit` |
| TASK_195 | bestehendes `kenney_ui_pack_space_expansion`, `kenney_ui_pack`, `kenney_input_keyboard_mouse`, `kenney_cursor_pixel_pack` |
| TASK_196 | `kenney_ranks_pack`, `kenney_particle_pack` |
| TASK_197 | Uebernimmt diese Matrix in einen zentralen kuratierten Asset-Katalog mit Verbrauchsorten. |

## Projektabgleich
| Project path | Status |
| --- | --- |
| `Assets/kenney_ui-pack-space-expansion/` | vorhanden; reuse existing |
| `Assets/kenney_ui-pack/` | vorhanden; reuse existing |
| `Assets/kenney_space-kit/` | vorhanden; reuse existing |
| `Assets/kenney_input-prompts_1.4.1/Keyboard & Mouse/` | vorhanden; reuse existing |
| `Assets/kenney_cursor-pixel-pack/` | vorhanden; reuse existing |
| `Assets/curated/kenney/modular_space/` | fehlt; nur TASK_194 darf ein kleines GLB-Subset anlegen |
| `Assets/curated/kenney/space_station/` | fehlt; nur TASK_194 darf ein kleines GLB-Subset anlegen |
| `Assets/curated/kenney/ranks/` | fehlt; nur TASK_196 darf ein kleines PNG-Subset anlegen |
| `Assets/curated/kenney/particles/` | fehlt; nur TASK_196 darf ein kleines PNG-Subset anlegen |
