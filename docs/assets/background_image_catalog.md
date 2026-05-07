# Background Image Catalog

## Runtime Contract
- Catalog: `res://data/background_image_catalog.json`
- Runtime helper: `res://scripts/assets/background_image_catalog.gd`
- Project copy root: `res://Assets/used/backgrounds/ai_generated/`
- Runtime screens load `res://` paths only.
- Backgrounds are visual-only and never set gameplay state.
- Screens should load only the background they display.

## Imported Images
| Background ID | Source file | Project path | Size | Bytes | Screen suggestion | Crop | Dim |
| --- | --- | --- | --- | ---: | --- | --- | ---: |
| `multiplayer_lobby_hangar` | `Use AI Image Apr 18, 2026, 23_34_01.png` | `res://Assets/used/backgrounds/ai_generated/bg_hangar_shiphall.png` | 1344x768 | 1589094 | Multiplayer Lobby, Mission Setup | center | 0.58 |
| `mission_select_desert_outpost` | `Use AI Image Apr 18, 2026, 23_45_03.png` | `res://Assets/used/backgrounds/ai_generated/bg_desert_outpost.png` | 1376x768 | 1526978 | Singleplayer Setup, Mission Select, Editor Setup | center | 0.52 |
| `loading_asteroid_flight` | `Use AI Image Apr 18, 2026, 23_41_57.png` | `res://Assets/used/backgrounds/ai_generated/bg_asteroid_flight.png` | 1376x768 | 1702838 | Loading, Lobby Variant | center | 0.50 |
| `debrief_desert_explosion_base` | `Use AI Image Apr 18, 2026, 23_21_53.jpeg` | `res://Assets/used/backgrounds/ai_generated/bg_desert_explosion_base.jpg` | 1376x768 | 788232 | Debrief, Mission Result, Loading | center | 0.62 |

## Existing Preferred Main Menu Image
| Background ID | Source | Project path | Size | Bytes | Screen suggestion | Crop | Dim |
| --- | --- | --- | --- | ---: | --- | --- | ---: |
| `main_menu_shell` | TASK_199 curated project asset | `res://Assets/curated/main_menu/sternenbuerger_main_menu_bg.jpeg` | 1376x768 | 717441 | Main Menu, Settings Panel | center-left | 0.35 |

## Screen Usage
- Main Menu keeps `main_menu_shell` from TASK_199 as the preferred first screen.
- Multiplayer Lobby uses `multiplayer_lobby_hangar` with a dark full-screen shade and its existing centered panel.
- Mission Select and Editor Setup should prefer `mission_select_desert_outpost` when those screens get a dedicated setup shell.
- Loading can use `loading_asteroid_flight` for travel/approach and `debrief_desert_explosion_base` for result/debrief contexts.

## Readability Rules
- Put text and buttons inside existing rails, panels, or bottom bands.
- Do not place raw text directly on bright explosion or ship-detail areas.
- Keep dim overlays between `0.50` and `0.62` for the four new images unless a screen has its own opaque panel.
- Do not preload all backgrounds at app start; load by current screen ID.
