# Local Asset Curation and Import Plan

Datum: 2026-05-03
Status: TASK_165 implementiert, Plan ohne binaeren Import

## Zweck
Dieser Katalog begrenzt den lokalen Asset-Bestand auf kleine, nachvollziehbare Importentscheidungen. Assets bleiben Darstellung. Gameplay-State, Command-Verarbeitung und 2.5D-Primary-Wahrheit bleiben bei den bestehenden Runtime-Pfaden.

Quelle ist der lokale `Pictures\Sternen*`-Assetordner. In diesem TASK wurden keine neuen Asset-Dateien ins Projekt kopiert.

## Bestand In Zahlen
| Typ | Anzahl | Entscheidung |
| --- | ---: | --- |
| `.png` | 8110 | Nur kuratierte UI-/Icon-/Portrait-/Preview-Sets verwenden. |
| `.svg` | 2185 | Fuer UI spaeter moeglich, aber Godot-PNG-Pfad bevorzugen, solange Pixelgroessen stabil bleiben sollen. |
| `.glb` | 978 | Primaerformat fuer neue 3D-Setpieces und Weapons; FBX/OBJ/DAE/STL nicht parallel importieren. |
| `.fbx` | 960 | Nicht fuer V1 importieren, wenn GLB vorhanden ist. |
| `.obj` / `.mtl` | 898 / 898 | Nicht parallel zu GLB importieren. |
| `.dae` | 576 | Nur Alt-/Vergleichsmaterial; GLB bevorzugen. |
| `.stl` | 576 | Kein Godot-Gameplay-Import fuer V1. |
| Fonts | 18 `.ttf`, 14 `.otf` | Nur nach eigenem UI-Font-Task importieren. |
| `.ogg` | 6 | Optional spaeter fuer UI-Feedback, nicht in diesem Task. |
| `.zip` | 9 | Nicht importieren; nur entpackte, kuratierte Inhalte nutzen. |

## Groesse Lokaler Ordner
| Ordner | Dateien | MB | Importstatus |
| --- | ---: | ---: | --- |
| `kenney_input-prompts_1.4.1` | 4099 | 5.1 | Bereits im Projekt vorhanden; keine weitere Kopie. |
| `kenney_space-kit` | 1692 | 17.6 | Bereits im Projekt vorhanden; bestehender 2.5D-Pfad bleibt fuehrend. |
| `kenney_ui-pack` | 1315 | 1.4 | Bereits im Projekt vorhanden; von TASK_164 genutzt. |
| `kenney_ui-pack-space-expansion` | 1117 | 0.8 | Bereits im Projekt vorhanden; von TASK_164 genutzt. |
| `3d` | 924 | 18.2 | Duplikat-Pfad, nicht importieren. |
| `Space Kit` | 924 | 18.2 | Duplikat zu `3d\Space Kit`; bestehendes `kenney_space-kit` nutzen. |
| `Space Station Kit` | 738 | 7.1 | Kandidat fuer spaetere Homebase-/FOB-Setpieces, GLB-only. |
| `Prototype Kit` | 740 | 9.9 | Nur Blocking/Lab, nicht als finaler Stil. |
| `kenney_ranks-pack` | 644 | 0.8 | Kleiner Folgeimport fuer Rollen-/Status-Badges moeglich. |
| `Weapon Pack` | 287 | 14.1 | Kleine GLB-/Preview-Auswahl fuer Loadout moeglich. |
| `Animated Characters Bundle` | 237 | 45.8 | Spaeter, nicht vor Unit-Visual-Konzept. |
| `kenney_cursor-pixel-pack` | 227 | 0.1 | Bereits im Projekt vorhanden; gezielt fuer Editor/Tactical Cursor nutzen. |
| `Modular Space Kit` | 214 | 20.1 | Kleine GLB-Auswahl fuer FOB-/Hangar-Layout moeglich. |
| `Blaster Kit` | 211 | 4.3 | Kleine GLB-Auswahl fuer Waffen-Previews moeglich. |
| `kenney_particle-pack` | 195 | 14.5 | Spaeter fuer reine Visual Effects, nicht fuer Gameplay-Wahrheit. |
| `Char` | 88 | 140.3 | Bereits im Projekt vorhanden; vor weiterer Nutzung Metadaten/Zuschnitt klaeren. |

## Bereits Im Projekt
| Projektpfad | Dateien | MB | Regel |
| --- | ---: | ---: | --- |
| `Assets/kenney_input-prompts_1.4.1` | 8078 | 9.1 | Keine neue Kopie; fuer Tooltips direkt referenzieren. |
| `Assets/kenney_space-kit` | 3051 | 18.7 | Bestehender 2.5D-/Terrain-Pfad bleibt fuehrend. |
| `Assets/kenney_ui-pack` | 2627 | 2.6 | UI-Theme-Basis. |
| `Assets/kenney_ui-pack-space-expansion` | 2231 | 2.0 | Sci-Fi-UI-Basis. |
| `Assets/kenney_cursor-pixel-pack` | 450 | 0.3 | Cursor-/Tool-Status. |
| `Assets/Char` | 176 | 140.4 | Bereits importierte Portraits; keine weiteren Portraits ohne Metadaten. |

## Deduplizierung
| Befund | Entscheidung |
| --- | --- |
| `Space Kit` und `3d\Space Kit` enthalten je 924 Dateien mit 924 gleichen relativen Pfaden. | `3d\Space Kit` als Duplikat behandeln. Nicht importieren. |
| Root-Zips existieren neben entpackten Ordnern. | Zips bleiben lokal, nie nach `Assets/` kopieren. |
| GLB, FBX, OBJ, DAE und STL liegen oft parallel vor. | Pro Assetfamilie nur GLB importieren. FBX/OBJ/DAE/STL nur bei fehlendem GLB und eigener Freigabe. |
| PNG und SVG liegen bei UI-Packs parallel vor. | In Godot-UI zuerst PNG verwenden; SVG nur bei klarer Skalierungsanforderung. |
| `Assets/Char` ist schon gross. | Kein weiterer Portrait-Import; zuerst Naming, Zuschnitt und Quellenmetadaten klaeren. |

## Importregeln
1. Jeder Import braucht eine kleine Task-Freigabe mit Zweck, Zielscreen und Maximalmenge.
2. Keine Ordner- oder Pack-Komplettkopien mehr, wenn ein kuratiertes Subset reicht.
3. Zielpfade fuer neue Subsets:
   - `Assets/curated/kenney/ranks/`
   - `Assets/curated/kenney/weapons/`
   - `Assets/curated/kenney/space_station/`
   - `Assets/curated/portraits/`
   - `Assets/curated/transport/`
4. Pro importiertem Subset gehoert eine kurze `README.md` oder Manifest-Zeile dazu:
   - Quelle
   - Lizenz
   - Auswahlgrund
   - Zielpfad
   - geplanter Verbrauchsort
5. Keine neuen stillen Fallbacks: Wenn ein Asset fehlt, bleibt der sichtbare Missing-Asset-/Verifier-Pfad erhalten.
6. Keine 3D-Terrain-Mapping-Erweiterung in Asset-Kuratierungs-Tasks. Mapping-Aenderungen brauchen einen eigenen Runtime-/Rendering-Task.
7. Portraits werden vor Nutzung auf ein einheitliches Kartenformat zugeschnitten und bekommen stabile Dateinamen; keine `Use AI Image...`-Namen in neuen UI-Vertraegen.

## Kandidatenlisten

### P0: Vorhandene UI-/Input-/Cursor-Assets Nutzen
| Kategorie | Quelle | Ziel | Maximalmenge | Zweck |
| --- | --- | --- | ---: | --- |
| UI/Theme | `Assets/kenney_ui-pack`, `Assets/kenney_ui-pack-space-expansion` | kein Import | 0 | TASK_164-Komponenten weiter skinnen. |
| Input Prompts | `Assets/kenney_input-prompts_1.4.1/Keyboard & Mouse/Default/` | kein Import | 0 | Tooltips fuer `Q/E`, `R/F`, `G`, `SHIFT`, `CTRL`, LMB/RMB. |
| Cursor | `Assets/kenney_cursor-pixel-pack/Tiles/` | kein Import | 0 | Editor-Brush, Patrol, Marker, Select, Attack-Area. |

### P1: Kleine Fehlende Subsets Importieren
| Kategorie | Quelle | Vorschlag Zielpfad | Maximalmenge | Zweck |
| --- | --- | --- | ---: | --- |
| Rank-/Role-Badges | lokales `kenney_ranks-pack/PNG/Default/` | `Assets/curated/kenney/ranks/` | 12 PNG | FTL, Medic, Rifle, Pilot, Engineer, Suppressed/Ready/Down-Badges. |
| Blaster Previews | lokales `Blaster Kit/Models/GLB format/` plus Preview-PNGs | `Assets/curated/kenney/weapons/blaster/` | 6 GLB + 6 PNG | Loadout-Preview fuer V1-Waffenfamilien. |
| Weapon Pack Previews | lokales `Weapon Pack/Models/GLTF format/` plus Preview-PNGs | `Assets/curated/kenney/weapons/modern/` | 6 GLB + 6 PNG | Alternative fuer Rifle, Shotgun, Sniper, Rocket, Grenade, Uzi. |
| Transport/Valkyrie | lokale Root-Dateien `Valkyrie_in_space_*` | `Assets/curated/transport/valkyrie/` | 6 JPG/PNG | Dropship-/Transportcraft-Identity in Briefing, Shipcard und Debrief. |

### P2: Spaetere Setpieces
| Kategorie | Quelle | Vorschlag Zielpfad | Maximalmenge | Zweck |
| --- | --- | --- | ---: | --- |
| Space Station Kit | lokales `Space Station Kit/Models/GLB format/` | `Assets/curated/kenney/space_station/` | 12 GLB | Homebase-/FOB-Setpieces, Hangar, Deck, Medbay. |
| Modular Space Kit | lokales `Modular Space Kit/Models/GLB format/` | `Assets/curated/kenney/modular_space/` | 10 GLB | Spaetere 3D-Staging-Szenen, nicht Tactical-Map. |
| Particle Pack | lokales `kenney_particle-pack/PNG/` | `Assets/curated/kenney/particles/` | 12 PNG | LZ, Contact, Suppression und Objective-VFX als reine Darstellung. |
| Portraits | `Assets/Char` und lokales `Char` | `Assets/curated/portraits/` | 12 zugeschnittene PNG | NPC-Karten erst nach Naming-/Metadatenpass. |

### TASK_171: Animated Characters Micro-Subset
| Quelle | Ziel | Umfang | Zweck |
| --- | --- | ---: | --- |
| Lokales `Animated Characters Bundle` | `Assets/used/npc/animated_characters/` | 2 FBX-Modelle, 2 PNG-Skins, 2 FBX-Animations-Probes, Lizenzdatei | Testweiser 2.5D-Unit-Visual-Ersatz ohne Gameplay-State-Aenderung. |

Lizenz: `License.txt` im Bundle nennt Creative Commons Zero, CC0. Der Import bleibt bewusst klein und wird ueber `data/npc_unit_visual_mapping.json` nur als Visual-Mapping verwendet.

### TASK_172: Animated Characters Scale Animation and Helmets
| Quelle | Ziel | Umfang | Zweck |
| --- | --- | ---: | --- |
| Lokales `Animated Characters Bundle/Accessories` | `Assets/used/npc/animated_characters/accessories/` | 2 FBX-Helme | Rein visuelle Helm-Attachments fuer friendly und enemy 2.5D-Unit-Proxies. |

TASK_172 nutzt die bereits importierten Idle-/Walk-FBX-Dateien als rein visuelle `AnimationPlayer`-Quelle, reduziert die Modellskalierung im Mapping auf `0.22` und mappt Gegner-IDs explizit. Helme bleiben Anzeige und werden nicht zu Loadout-, Ruestungs- oder Gameplay-State.

### TASK_173: Animated Character Skeleton Socket Contract
| Quelle | Ziel | Umfang | Zweck |
| --- | --- | ---: | --- |
| Bereits importiertes `Animated Characters Bundle` Subset | kein neuer Asset-Import | 0 | Skeleton-/Bone-Inventar, Idle-/Walk-Vertrag und stabile visuelle Sockets fuer Head/Hands. |

TASK_173 importiert keine neuen Assets. Es dokumentiert den gemeinsamen Skeleton-Vertrag (`Hips`, `Spine`, `Head`, `LeftHand`, `RightHand`) und stellt `HeadSocket`, `RightHandSocket`, `LeftHandSocket` und `BackSocket` als rein visuelle Attachment-Punkte bereit, damit Helme und Waffen nicht per geratenen Offsets schweben.

### TASK_174: Character Helmet and Blaster Attachment Visuals
| Quelle | Ziel | Umfang | Zweck |
| --- | --- | ---: | --- |
| `C:\Users\bjoer\Pictures\Sternenbuerger\Blaster Kit\Models\GLB format` | `Assets/used/npc/blaster_kit/` | 3 GLB-Blaster, 1 gemeinsame Textur, optional 1 Preview-PNG, Lizenz | Rein visuelle Hand-Attachments fuer 2.5D friendly/enemy NPC-Proxies. |

Blaster-Kit-Regel: GLB-only, kein paralleler FBX/OBJ/MTL-Import, kein Komplettimport. Die gemeinsame `colormap.png` wird mitkopiert, weil die GLBs sie referenzieren. Waffen bleiben Anzeige und werden nicht zu Combat-, Loadout- oder Balance-State.

## Erste Empfohlene Folge-Tasks
1. `TASK_165A - Rank and Role Badge Subset`
   - Importiert max. 12 PNG aus `kenney_ranks-pack`.
   - Verdrahtet sie nur in UI-Komponenten als Icons/Badges.
   - Kein Gameplay-State.
2. `TASK_165B - Input Prompt Tooltip Pass`
   - Nutzt bereits vorhandene Input-Prompt-Dateien.
   - Fuegt Icons/Tooltips an Command-Buttons und Editor-Tools an.
   - Kein Asset-Import.
3. `TASK_165C - Dropship Identity Image Subset`
   - Importiert max. 6 Valkyrie-Bilder.
   - Nutzt sie in Shipcards/Briefing nur als Anzeige.
4. `TASK_165D - Weapon Preview Micro-Subset`
   - Importiert max. 6 GLB + 6 PNG.
   - Bindet sie spaeter an bestehende Loadout-Anzeige, nicht an Combat-Balance.

## Lokale Pruefung Fuer Folgeimporte
- `git diff --stat` muss zeigen, dass nur das freigegebene Subset importiert wurde.
- Godot einmal starten oder einen headless Import/Verifier laufen lassen, wenn neue `.import`-Dateien entstehen.
- Bei UI-Assets: manuelle Sichtpruefung auf Lesbarkeit in 100%, 125% und kleinerem Fenster.
- Bei 3D-Assets: Primary-View-Snapshot darf keine stillen Fallbacks einfuehren; fehlende Assets bleiben sichtbar.
