# Asset Scale Alignment Matrix

Datum: 2026-05-07
Status: TASK_246 Alignment-Pass dokumentiert

## Zweck
Diese Matrix sammelt die sichtbaren Groessen-, Socket-, Offset- und Crop-Vertraege fuer NPCs, Attachments, Waffen-VFX, Audio-Anker, Backgrounds und Terrain-Hoehen. Sie ist ein Review-Artefakt: Gameplay-Wahrheit bleibt bei Simulation, Terrain-Daten und bestehenden Runtime-Controllern.

## Runtime-Regeln
- Alle konsumierten Assets muessen ueber `res://` erreichbar sein.
- Visual-Offsets duerfen keine Tile-, LOS-, Cover-, Health-, Damage- oder Movement-Wahrheit aendern.
- Sockets sind sichtbare Attachments; sie ersetzen keine Unit- oder Loadout-Daten.
- Muzzle-Flash, Schuss-Sound und Impact nutzen denselben Ereigniskontext, bleiben aber read-only Feedback.
- Backgrounds sind screenweise UI-Deko mit Dimming und duerfen keine Panel-/Fenstergroessen verschieben.

## NPC- und Attachment-Matrix
| Asset / Gruppe | Anchor / Socket | Scale | Rotation | Offset / Visual Offset | Status | Sichtcheck |
|---|---|---:|---|---|---|---|
| Friendly Space Suit White | Unit proxy root, HeadSocket, RightHandSocket | 0.22 | Y 0 | Fallback Head [0, 1.38, 0], RightHand [0.22, 0.84, 0.10] | Headless pruefbar | Manuell: Tile-/Cover-Groesse in 2.5D pruefen |
| Enemy Space Suit Orange | Unit proxy root, HeadSocket, RightHandSocket, BackSocket | 0.22 | Y 0 | gleicher Default-Socket-Vertrag | Headless pruefbar | Manuell: orange/weiss lesbar trennen |
| Astro Helmet | HeadSocket | max 0.010 | [0, 0, 0] | Offset [0, 0, 0], Visual [0, 0.55, 0] | Headless pruefbar | Manuell: Helm sitzt auf Kopf, nicht im Boden |
| Military Helmet | HeadSocket | max 0.010 | [0, 0, 0] | gleicher Helm-Vertrag | Headless pruefbar | Manuell: kleine CharacterSmall-Variante pruefen |
| Standard Rifle / blaster-a | RightHandSocket | 0.014 | [90, 90, 180] | Visual [0, 0.153, 0.050] | Headless pruefbar | Manuell: Lauf nach unten, Griff an Hand |
| Compact Blaster / blaster-f | RightHandSocket | 0.014 | [90, 90, 180] | Default-Blaster-Offset | Headless pruefbar | Manuell: kleiner Gegner bleibt lesbar |
| Medictool Blaster / blaster-b | RightHandSocket | 0.014 | [90, 90, 180] | Default-Blaster-Offset | Headless pruefbar | Manuell: als Support-Werkzeug nicht zu gross |
| Heavy Blaster / blaster-p | RightHandSocket | 0.014 | [90, 90, 180] | Default-Blaster-Offset | Headless pruefbar | Manuell: Heavy darf nicht Helm/Koerper verdecken |
| Sniper Rifle | RightHandSocket | 0.010 | [90, 90, 180] | Visual [0, 0.105, 0.020] | Headless pruefbar | Manuell: langer Lauf sichtbar vor Hand |
| Rocket Launcher | BackSocket | 0.008 | [0, 90, 0] | Visual [0, 0.120, -0.030] | Headless pruefbar | Manuell: Rueckenmontage ohne Bodenkontakt |

## Weapon VFX und Audio
| Ereignis / Asset | Anchor | Scale / Size | Offset | Status | Sichtcheck |
|---|---|---:|---|---|---|
| Rifle Muzzle `muzzle_flash_01` | attacker -> target Richtung, `muzzle_position` | pixel_size 0.010 | barrel_offset_world 28 | Headless pruefbar | Manuell: Flash am Lauf, nicht Tile-Mitte |
| SMG Muzzle `muzzle_flash_02` | gleicher Fire-Event-Kontext | pixel_size 0.009 | barrel_offset_world 24 | Headless pruefbar | Manuell: kurze Burst-Optik lesbar |
| Sniper Muzzle `muzzle_flash_04` | gleicher Fire-Event-Kontext | pixel_size 0.011 | barrel_offset_world 34 | Headless pruefbar | Manuell: laengerer Lauf plausibel |
| Heavy/Rocket Muzzle `muzzle_flash_05` | gleicher Fire-Event-Kontext | pixel_size 0.012 | barrel_offset_world 38 | Headless pruefbar | Manuell: heavy Flash nicht zu gross |
| Weapon Fire SFX | `world_to_surface_3d_position(muzzle_position, 0.78)` | Audio event only | dedupe per fire event | Headless pruefbar | Manuell: Schuss klingt am sichtbaren Flash |
| Impact / Explosion SFX | Damage-hit context target position | Audio event only | dedupe per fire event | Headless pruefbar | Manuell: Impact folgt Treffer, Explosion nur heavy/rocket |

## Background-Crops
| Background ID | Screen-Hint | Size | Crop Anchor | Dim | Fixed Window Contract | Sichtcheck |
|---|---|---:|---|---:|---|---|
| `main_menu_shell` | main_menu, settings_panel | 1376x768 | center_left | 0.35 | Main menu 1920x1080 Root, Rail 520 px | Manuell: Hauptmotiv nicht unter linker Rail verlieren |
| `multiplayer_lobby_hangar` | multiplayer_lobby, mission_setup | 1344x768 | center | 0.58 | Lobby Root 1280x720, Panel 720x560 | Manuell: Panel bleibt ruhig, Hangar lesbar |
| `mission_select_desert_outpost` | singleplayer_setup, mission_select, editor_setup | 1376x768 | center | 0.52 | Vorbereitet, screenweise anwenden | Manuell: Panel- oder Rail-Zone nutzen |
| `loading_asteroid_flight` | loading, multiplayer_lobby_variant | 1376x768 | center | 0.50 | Vorbereitet, screenweise anwenden | Manuell: Bewegtes Motiv nicht unter Text |
| `debrief_desert_explosion_base` | loading, debrief, mission_result | 1376x768 | center | 0.62 | Vorbereitet, screenweise anwenden | Manuell: Explosion nicht mit Result-Text kollidieren |

## Terrain- und Hoehenanker
| Element | Anchor | Vertrag | Status | Sichtcheck |
|---|---|---|---|---|
| Ground tiles | `height_level * height_step` | visuelle Hoehe folgt TerrainMapData | Headless pruefbar | Huegelkante deckt sich mit Kartenlogik |
| Objects / Walls | `height_level + object_height` | Objektmesh sitzt auf Tile-Top | Headless pruefbar | Mauern schweben nicht und sinken nicht ein |
| Unit proxies | `world_to_surface_3d_position(unit_world_position, 0.06)` | Einheit steht auf Terrainoberflaeche | Headless pruefbar | Unit-Fuesse auf Huegeln pruefen |
| Order lines / markers | `world_to_surface_3d_position(..., offset)` | Anzeige schwebt ueber Gameplay-Anker | Headless pruefbar | Marker kaschieren keine Hoehenfehler |
| Muzzle trace | `world_to_surface_3d_position(muzzle_position, 0.78)` | Trace nutzt gleiche Terrainoberflaeche wie Flash/Sound | Headless pruefbar | Trace liegt ueber Huegeln plausibel |

## Offene Sichtbefunde
- Manueller 2.5D-Sichtcheck fuer Friendly/Enemy, Helm, Standard-Blaster, Sniper und Rocket bleibt offen.
- Manueller Full-HD-Check fuer Main Menu und Multiplayer-Lobby bleibt offen.
- Mission-Select, Loading und Debrief nutzen vorbereitete Background-IDs erst in Folge-Screens.
- Performance-Wirkung von Backgrounds, VFX und Audio wird bewusst in TASK_249 gemessen.
