# Asset Expansion Visual Smoke Checklist

Datum: 2026-05-06
Status: TASK_198 Checkliste dokumentiert

## Zweck
Diese Checkliste ist der manuelle Sichtcheck zum automatischen TASK_198-Gate. Sie prueft nur sichtbare Verfuegbarkeit und Lesbarkeit der Assets aus TASK_193 bis TASK_197. Gameplay-State, Combat-Logik, Health, Suppression, Terrain-Wahrheit und Multiplayer-Authority werden hier nicht bewertet.

## Vorbereitung
- Godot-Projekt im Editor oeffnen.
- Sicherstellen, dass `godot_console.exe --headless --path . --import` zuvor ohne Fehler lief.
- Bei Bedarf den zentralen Katalog `res://data/curated_asset_catalog.json` als Referenz offen halten.

## FOB / Homebase / Mission-HUD Icons
- [ ] Beispiel-UI-Asset `ui_panel_frame_blue` in einer Vorschau oder einem UI-Test sichtbar pruefen.
- [ ] Beispiel-Button `ui_button_square_blue` bei 100% und 125% Skalierung auf klare Kontur pruefen.
- [ ] `ui_tactical_crosshair` gegen dunklen Drop-Light-Hintergrund auf Kontrast pruefen.

## Input / Cursor / Editor-Hints
- [ ] `prompt_lmb`, `prompt_rmb`, `prompt_shift` und `prompt_space` als Tooltip-/Hint-Assets auf Lesbarkeit pruefen.
- [ ] `cursor_select`, `cursor_move`, `cursor_attack` und `cursor_editor_brush` gegen Mission- und Editor-Hintergrund pruefen.
- [ ] Keine Cursor-/Prompt-Assetauswahl darf Tool-State oder Eingabelogik ersetzen.

## Rank-/Role-Badges
- [ ] `badge_role_ftl`, `badge_role_medic`, `badge_role_heavy` auf NPC-Kartengroesse pruefen.
- [ ] `badge_state_down`, `badge_state_ready`, `badge_state_suppressed` neben Statuszeilen auf visuelle Ruhe pruefen.
- [ ] Badge-Nutzung darf keine Rollen-, Health- oder Suppression-Wahrheit darstellen.

## Particle-Visuals
- [ ] `particle_lz_drop`, `particle_contact_ping`, `particle_suppression_smoke`, `particle_heal_pulse` auf transparentem Hintergrund pruefen.
- [ ] Particles muessen als reine Visuals lesbar sein und duerfen keine SimulationRoot-Effects ersetzen.

## Setpiece-/Weapon-/Terrain-Visuals
- [ ] Mindestens je ein Modular-Space- und Space-Station-Setpiece in einer Preview-Szene oder Importvorschau oeffnen.
- [ ] `weapon_visual_sniper_model` und `weapon_visual_rocket_launcher_model` in der Importvorschau auf sichtbare Geometrie pruefen.
- [ ] Bestehende Terrain-Referenzen wie `terrain_existing_ground_flat` und `terrain_existing_wall_straight` weiter sichtbar pruefen.

## Ergebnisnotiz
- [ ] Ergebnis im Task-Review oder Commit-Text vermerken.
- [ ] Auffaellige Assets nicht direkt ersetzen; erst einen kleinen Folge-Task fuer Auswahl, Skalierung oder Kontrast anlegen.
