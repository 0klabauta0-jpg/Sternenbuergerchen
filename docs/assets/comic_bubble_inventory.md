# Comic Bubble Asset Inventory

Datum: 2026-05-06
Status: TASK_209 implementiert

## Zweck
Dieses Inventar beschreibt die zehn Comic-Bubble-PNGs aus `res://Assets/Comic/` als reine Anzeige-Assets. Fireteamleader-Rueckmeldungen und NPC-Gedanken duerfen spaeter auf diese IDs verweisen, aber Bubbles erzeugen keine `SimulationRoot`-Commands, keine Effects und keine Gameplay-Wahrheit.

## Quelle
| Source ID | Projektpfad | Import | Runtime |
| --- | --- | --- | --- |
| `comic_bubble_pack` | `res://Assets/Comic/` | `comic-1.png` bis `comic-10.png`, plus `preview.png` | Nur die zehn `comic-*.png` Dateien sind Runtime-Bubbles. `preview.png` ist nur Inventar-/Doku-Preview. |

## Visual-Vertrag
| Regel | Wert |
| --- | --- |
| Maximalgroesse | `220x132` Canvas-Pixel |
| Minimalgroesse | `96x56` Canvas-Pixel |
| Text | maximal 2 Zeilen, maximal 26 Zeichen pro Zeile |
| Z-Order | Standard `76`, Warnvarianten bis `79` |
| Aktivitaet | maximal 4 aktive Bubbles insgesamt, maximal 1 pro Unit |
| Dauer | Standard `1.8s`, maximal `3.0s` |
| Occlusion | Nicht dauerhaft ueber Units, wichtigen Markern oder HUD-Fenstern halten |

## Purpose IDs
Runtime-Bubbles verwenden die stabilen Purpose-IDs `ftl_response`, `npc_thought`, `warning`, `quiet_status` und `short_command`.

## Runtime Bubble IDs
| ID | Datei | Zweck | Anchor | Max Size | Text-Inset |
| --- | --- | --- | --- | --- | --- |
| `bubble_ftl_ack` | `res://Assets/Comic/comic-1.png` | FTL-Antwort, bestaetigt | `tail_bottom_center` | `196x108` | `34/20/34/30` |
| `bubble_ftl_short_order` | `res://Assets/Comic/comic-2.png` | kurzer Befehl | `tail_bottom_left` | `180x96` | `30/18/28/28` |
| `bubble_ftl_warning` | `res://Assets/Comic/comic-3.png` | Warnung | `tail_bottom_center` | `208x116` | `36/22/36/32` |
| `bubble_ftl_contact` | `res://Assets/Comic/comic-4.png` | FTL-Kontaktmeldung | `tail_bottom_right` | `212x120` | `38/22/32/30` |
| `bubble_npc_thought_quiet` | `res://Assets/Comic/comic-5.png` | NPC-Gedanke, leise | `tail_bottom_center` | `176x92` | `30/18/30/26` |
| `bubble_npc_thought_focus` | `res://Assets/Comic/comic-6.png` | NPC-Gedanke, Fokus | `tail_bottom_left` | `172x92` | `28/18/28/26` |
| `bubble_npc_alert` | `res://Assets/Comic/comic-7.png` | NPC-Alarm | `tail_bottom_center` | `188x104` | `32/20/32/28` |
| `bubble_npc_status_low` | `res://Assets/Comic/comic-8.png` | leise Statusmeldung | `tail_bottom_right` | `184x100` | `32/20/28/28` |
| `bubble_command_confirm` | `res://Assets/Comic/comic-9.png` | Command-Bestaetigung | `tail_bottom_center` | `196x108` | `34/20/34/30` |
| `bubble_warning_large` | `res://Assets/Comic/comic-10.png` | grosse Warnung | `tail_bottom_center` | `220x132` | `40/24/40/34` |

## Text-Regeln
1. Bubbles zeigen kurze Statussaetze, keine Tutorials.
2. Lange Texte werden gekuerzt oder in ein Statuspanel ausgelagert.
3. Text bleibt in 1 bis 2 Zeilen; keine gestreckten Bubble-Grafiken.
4. Tail-/Anchor-Werte sind Layout-Hinweise fuer Mission-Map- und UI-Renderer.

## Folgepfad
TASK_210 darf Fireteamleader-Rueckmeldungen auf diese IDs setzen. TASK_211 definiert Toggles, Cooldowns und Settings, bevor Bubbles dauerhaft im Mission-Loop sichtbar werden.
