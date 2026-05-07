# UI Input Cursor Availability

Datum: 2026-05-06
Status: TASK_195 implementiert, keine neuen Asset-Kopien

## Zweck
Dieser Katalog macht vorhandene UI-, Input-Prompt- und Cursor-Assets ueber stabile IDs auffindbar. Er ersetzt kein Theme-System und keine Eingabelogik. TASK_164 bleibt die UI-Komponentenbasis; diese Datei sagt nur, welche Projektassets spaeter sicher referenziert werden koennen.

## Quellen
| Source ID | Projektpfad | Lizenz | Importstatus | Verwendung |
| --- | --- | --- | --- | --- |
| `kenney_ui_pack_space_expansion` | `Assets/kenney_ui-pack-space-expansion/` | Creative Commons Zero, CC0 | reuse existing | sci-fi bars, button frames, crosshair |
| `kenney_ui_pack` | `Assets/kenney_ui-pack/` | Creative Commons Zero, CC0 | reuse existing | basic buttons and status icons |
| `kenney_input_keyboard_mouse` | `Assets/kenney_input-prompts_1.4.1/Keyboard & Mouse/` | Creative Commons Zero, CC0 | reuse existing | tooltip/input prompt visuals |
| `kenney_cursor_pixel_pack` | `Assets/kenney_cursor-pixel-pack/` | Creative Commons Zero, CC0 | reuse existing | cursor visual states |

## Regeln
- Keine Doppelkopie in `Assets/curated` fuer diese Packs.
- Alle IDs zeigen auf `res://Assets/...`-Projektpfade.
- Input-Prompts sind Tooltip-/Hint-Assets, keine Gameplay-Eingabelogik.
- Cursor-IDs sind Anzeige, nicht Tool-State-Wahrheit.
- PNG wird fuer Godot-UI bevorzugt; SVG bleibt Reserve fuer spaetere Skalierungsfaelle.

## UI Assets
| ID | Kategorie | Projektpfad | Verwendung |
| --- | --- | --- | --- |
| `ui_panel_frame_blue` | panel_frame | `res://Assets/kenney_ui-pack-space-expansion/PNG/Blue/Default/bar_square_large.png` | Drop-Light panel frame candidate |
| `ui_progress_bar_blue` | panel_frame | `res://Assets/kenney_ui-pack-space-expansion/PNG/Blue/Default/bar_square_small.png` | compact progress/status bar |
| `ui_button_square_blue` | button | `res://Assets/kenney_ui-pack/PNG/Blue/Default/button_square_flat.png` | square command button candidate |
| `ui_button_rect_blue` | button | `res://Assets/kenney_ui-pack/PNG/Blue/Default/button_rectangle_flat.png` | compact text button candidate |
| `ui_button_sci_square_header` | button | `res://Assets/kenney_ui-pack-space-expansion/PNG/Blue/Default/button_square_header_small_square.png` | sci-fi square button frame |
| `ui_icon_check` | icon | `res://Assets/kenney_ui-pack/PNG/Blue/Default/icon_checkmark.png` | ready/confirm state |
| `ui_icon_cross` | icon | `res://Assets/kenney_ui-pack/PNG/Blue/Default/icon_cross.png` | cancel/blocked state |
| `ui_icon_square` | icon | `res://Assets/kenney_ui-pack/PNG/Blue/Default/icon_square.png` | generic slot/state marker |
| `ui_tactical_crosshair` | tactical_marker | `res://Assets/kenney_ui-pack-space-expansion/PNG/Blue/Default/crosshair_color_a.png` | target/contact marker candidate |

## Input Prompts
| ID | Projektpfad | Verwendung |
| --- | --- | --- |
| `prompt_lmb` | `res://Assets/kenney_input-prompts_1.4.1/Keyboard & Mouse/Default/mouse_left.png` | select/place/confirm tooltip |
| `prompt_rmb` | `res://Assets/kenney_input-prompts_1.4.1/Keyboard & Mouse/Default/mouse_right.png` | cancel/context tooltip |
| `prompt_shift` | `res://Assets/kenney_input-prompts_1.4.1/Keyboard & Mouse/Default/keyboard_shift.png` | multi-select modifier |
| `prompt_ctrl` | `res://Assets/kenney_input-prompts_1.4.1/Keyboard & Mouse/Default/keyboard_ctrl.png` | alternate modifier |
| `prompt_q` | `res://Assets/kenney_input-prompts_1.4.1/Keyboard & Mouse/Default/keyboard_q.png` | cycle left |
| `prompt_e` | `res://Assets/kenney_input-prompts_1.4.1/Keyboard & Mouse/Default/keyboard_e.png` | cycle right |
| `prompt_r` | `res://Assets/kenney_input-prompts_1.4.1/Keyboard & Mouse/Default/keyboard_r.png` | rotate/reset |
| `prompt_f` | `res://Assets/kenney_input-prompts_1.4.1/Keyboard & Mouse/Default/keyboard_f.png` | focus/follow |
| `prompt_g` | `res://Assets/kenney_input-prompts_1.4.1/Keyboard & Mouse/Default/keyboard_g.png` | go/execute |
| `prompt_space` | `res://Assets/kenney_input-prompts_1.4.1/Keyboard & Mouse/Default/keyboard_space.png` | pause/confirm |
| `prompt_escape` | `res://Assets/kenney_input-prompts_1.4.1/Keyboard & Mouse/Default/keyboard_escape.png` | close/cancel |

## Cursor IDs
| ID | Projektpfad | Verwendung |
| --- | --- | --- |
| `cursor_select` | `res://Assets/kenney_cursor-pixel-pack/Tiles/tile_0000.png` | select mode |
| `cursor_move` | `res://Assets/kenney_cursor-pixel-pack/Tiles/tile_0001.png` | move command |
| `cursor_attack` | `res://Assets/kenney_cursor-pixel-pack/Tiles/tile_0002.png` | attack/engage command |
| `cursor_defend` | `res://Assets/kenney_cursor-pixel-pack/Tiles/tile_0003.png` | defend command |
| `cursor_take` | `res://Assets/kenney_cursor-pixel-pack/Tiles/tile_0004.png` | take objective command |
| `cursor_area_drag` | `res://Assets/kenney_cursor-pixel-pack/Tiles/tile_0005.png` | area-order drag |
| `cursor_editor_brush` | `res://Assets/kenney_cursor-pixel-pack/Tiles/tile_0006.png` | editor brush |
| `cursor_height` | `res://Assets/kenney_cursor-pixel-pack/Tiles/tile_0007.png` | height tool |
| `cursor_marker` | `res://Assets/kenney_cursor-pixel-pack/Tiles/tile_0008.png` | marker tool |
| `cursor_patrol` | `res://Assets/kenney_cursor-pixel-pack/Tiles/tile_0009.png` | patrol tool |

## Katalog
`data/ui_asset_catalog.json` spiegelt diese IDs fuer spaetere UI-/Editor-Slices. Der Katalog ist Visual-only und enthaelt keine lokalen Quellpfade.
