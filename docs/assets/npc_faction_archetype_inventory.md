# NPC Faction Archetype Inventory

Status: TASK_206

## Zweck
Enemy- und Friendly-NPCs brauchen in der 2.5D-Mission eine klare visuelle Teamlesbarkeit. Diese Datei beschreibt die stabilen Visual-Archetypen. Sie sind reine Darstellung und erzeugen keine Gameplaywerte.

## Quelle
- Bundle: Kenney Animated Characters Bundle 4.0
- Projektpfad: `res://Assets/used/npc/animated_characters/`
- Lizenz: CC0, dokumentiert ueber `res://Assets/used/npc/animated_characters/License.txt`

## Produktive Archetypen
| Archetyp-ID | Faction | Modell | Skin | Loadout | Einsatz |
| --- | --- | --- | --- | --- | --- |
| `friendly_space_suit_white` | friendly | `characterMedium.fbx` | `astroMaleA.png` | `standard_rifle` | Friendly-/Default-NPCs mit hellem Raumanzug |
| `enemy_space_suit_orange` | enemy | `characterSmall.fbx` | `astroFemaleB.png` | `compact_blaster` | Standard-Gegenteam mit orangefarbenem Raumanzug |

`enemy_space_suit_orange` erlaubt `astroMaleB.png` als alternative Skin-Variante fuer groessere oder explizit gemappte Enemy-Units wie `enemy_echo`.

## Vorbereitete Archetypen
| Archetyp-ID | Status | Fallback |
| --- | --- | --- |
| `enemy_robot` | planned | `enemy_space_suit_orange` |
| `enemy_alien` | planned | `enemy_space_suit_orange` |
| `enemy_zombie` | planned | `enemy_space_suit_orange` |
| `enemy_soldier` | planned | `enemy_space_suit_orange` |

Die vorbereiteten IDs sind absichtlich noch keine produktiven Imports. Sie dienen als stabiler Vertrag fuer spaetere Asset-Auswahl.

## Socket- und Scale-Vertrag
- Beide produktiven Archetypen nutzen den bestehenden Default-Socket-Vertrag aus `data/npc_unit_visual_mapping.json`.
- Helm: `HeadSocket`
- Handwaffen: `RightHandSocket`
- Ruecken-/Schwerwaffen: `BackSocket`
- Scale: `0.22`, innerhalb der vorhandenen NPC-Grenzen.

## Runtime-Grenze
- `TerrainMap3DView` loest `visual_archetype_id` und enemy-seitige `enemy_visual_archetype_id` nur fuer die Darstellung auf.
- Enemy-Team-Tactics-Profile referenzieren `enemy_space_suit_orange`; alte Aliaswerte wie `orange_suit` werden weiterhin auf diesen Archetyp normalisiert.
- Missing-Assets bleiben ueber die bestehenden `unit_visual_error`-/Missing-Marker sichtbar.
