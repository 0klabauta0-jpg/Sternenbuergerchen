# Curated Asset Usage Mapping

Datum: 2026-05-06
Status: TASK_197 implementiert

## Zweck
`data/curated_asset_catalog.json` ist der zentrale Einstieg fuer kuratierte und bereits vorhandene Projektassets. Systeme sollen stabile IDs und `res://`-Pfade verwenden, statt lokale Ordner oder Projektverzeichnisse zur Laufzeit zu scannen.

Der Katalog ist read-only. Er beschreibt nur Pfade und Metadaten; Gameplay-State, Combat-Werte, Terrain-Wahrheit, Health, Suppression und Multiplayer-Authority bleiben in den bestehenden Runtime-Systemen.

## Eingebundene Fachkataloge
| Source Catalog | Datenquelle | Zentrale Kategorien | Zielsystem |
| --- | --- | --- | --- |
| `ui_input_cursor_catalog` | `res://data/ui_asset_catalog.json` | `ui`, `input_prompt`, `cursor` | Drop-Light-UI, Mission-HUD, Editor-Tooltips |
| `rank_particle_catalog` | `res://data/rank_particle_asset_catalog.json` | `rank_badge`, `particle` | NPC-Karten, Selected Fireteam, Mission-Feedback |
| `space_setpiece_catalog` | `res://data/space_setpiece_catalog.json` | `setpiece` | FOB/Homebase/Hangar-Setpieces |
| zentrale Eintraege | `data/curated_asset_catalog.json` | `weapon_visual`, `terrain_existing` | Loadout-/2.5D-Waffen und bestehende Terrain-Visuals |

## Kategorie-Mapping
| Kategorie | Beispiele | Verbrauchsort |
| --- | --- | --- |
| `ui` | `ui_panel_frame_blue`, `ui_button_square_blue`, `ui_tactical_crosshair` | Drop-Light-Fenster, kompakte Buttons, Mission-HUD |
| `input_prompt` | `prompt_lmb`, `prompt_rmb`, `prompt_shift`, `prompt_space` | Tooltips, Command-Hints, Editor-Hints |
| `cursor` | `cursor_select`, `cursor_move`, `cursor_attack`, `cursor_editor_brush` | Editor- und Tactical-Cursor-Visuals |
| `rank_badge` | `badge_role_ftl`, `badge_role_medic`, `badge_state_suppressed` | NPC-Karten, #17 Selected Fireteam, Statuszeilen |
| `particle` | `particle_lz_drop`, `particle_contact_ping`, `particle_heal_pulse` | Mission-Map-Visualizer und Visual-Feedback-Layer |
| `setpiece` | `modular_floor`, `station_wall_door`, `station_bed_single` | FOB/Homebase/Hangar-Layouts |
| `weapon_visual` | `weapon_visual_sniper_model`, `weapon_preview_rocket_launcher` | 2.5D-Weapon-Attachments und FOB-Loadout-Preview |
| `terrain_existing` | `terrain_existing_ground_flat`, `terrain_existing_wall_straight` | Bestehender `TerrainMap3DView`-Pfad |

## Resolver-Vertrag
`scripts/assets/curated_asset_catalog.gd` laedt nur explizit eingetragene JSON-Kataloge und einzelne zentrale Eintraege.

- `CuratedAssetCatalog.resolve_asset(id)` gibt `ok`, `path`, `entry` und bei Fehlern ein `diagnostic` zurueck.
- `CuratedAssetCatalog.get_asset_path(id)` gibt nur fuer erfolgreich aufgeloeste IDs einen Pfad zurueck.
- Fehlende IDs liefern `missing_catalog_asset_id:<id>`.
- Fehlende Pfade liefern `missing_catalog_asset_path:<id>:<path>`.
- Es gibt keinen stillen Fallback auf andere Dateien.
- Es gibt kein SceneTree- oder Projektordner-Scanning.

## Folgepfad
TASK_198 prueft den Asset-Import als Gate und darf diesen Katalog als Single Entry Point fuer Loadbarkeits- und Visual-Smoke-Pruefungen nutzen.
