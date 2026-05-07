# TASK_266 - Command Mission Editor Settings Help Content Pass

## Ziel
Befehlsplatten, Mission-HUD, Fireteam-Aktionen, Area Orders, Fog of War, Multiplayer-Vorbereitung, Editor-Werkzeuge und Settings sollen kompakte Hilfe-Popups bekommen, die Funktion und Auswirkung kurz erklaeren.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_191 - Command Chain Selection and Area Feedback Pass
- TASK_223 - Fog of War Modes Contract and Settings
- TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay
- TASK_227 - Main Menu Multiplayer Host Join Lobby Flow
- TASK_229 - Map Editor Usability Authoring Pass
- TASK_257 - Button Reachability and Interaction Verifier
- TASK_264 - Contextual Help Popup Component Settings Toggle
- TASK_265 - Character Sheet Loadout Help Content Pass

## Kontext
Viele taktische Aktionen sind schwer selbsterklaerend: Move, Defend, Take, Area einnehmen, Fireteam-Stance, Advance Styles, Medic-Regeln, Fog of War, Editor-Hoehenwerkzeug, Host/Join und Map-Download. Hilfe muss hier erklaeren, was ein Klick macht und welche Grenze er hat.

## Umfang
1. Mission-HUD und Befehlsplatten:
   - Command Matrix.
   - Selected Fireteam.
   - Mission Control.
   - Move, Defend, Take, Attack/Defend Area, GO/Plan-Ausfuehrung.
   - Stance/Advance Styles, Overwatch/Security, Medic-Adjacency soweit sichtbar.
2. FoW/Settings:
   - Kein Fog of War.
   - Bekanntes Gelaende, Sichtbereich fuer Einheiten.
   - Unbekannt schwarz, nur erkundeter Bereich sichtbar.
   - Display/Audio/Input/Gameplay-Settings knapp erklaeren.
3. Multiplayer:
   - Host, Join, Ready, Start.
   - Map-Download-Zustimmung.
   - Roster-/Ownership-Hinweise nur soweit UI-seitig relevant.
4. Editor:
   - Tile-Palette.
   - Hoehenwerkzeug, Slope, Cliff, Surface, Object.
   - Save/Load/Save As.
   - Playtest/Back.
5. Content-Regeln:
   - Kurzhilfe beantwortet "Was macht das?"
   - Detailhilfe beantwortet "Wann nutze ich das, was passiert danach, welche Grenze gibt es?"
   - Keine langen UI-Texte in Buttons selbst.
6. Katalog:
   - Hilfe-IDs gruppiert nach `mission`, `settings`, `multiplayer`, `editor`.
   - Fehlende Inhalte als `todo` markiert und vom Coverage-Report erfasst.

## Nicht-Ziele
- Kein Tutorial-Level.
- Keine komplette Taktikschule.
- Keine Multiplayer-Netzwerkdoku im UI.
- Keine Editor-Handbuchseiten.

## Akzeptanzkriterien
- [x] Befehlsplatten und Mission-HUD-Pflichtcontrols haben Hilfe-IDs.
- [x] Fog-of-War-Modi und zentrale Settings sind erklaert.
- [x] Host/Join/Ready/Map-Download haben kompakte Hilfe.
- [x] Editor-Hoehen-/Kanten-/Surface-/Object-Tools sind erklaert.
- [x] Texte bleiben kompakt und nutzen Detailhilfe fuer laengere Auswirkungserklaerungen.
- [x] Ein Verifier prueft Abdeckung gegen Playability-Matrix und Katalog.

## Erwartete Dateien
- `data/contextual_help_catalog.json`
- `docs/content/command_mission_editor_settings_help_copy.md`
- `scripts/ui/...`
- `scripts/tests/task_266_command_mission_editor_settings_help_content_pass.gd`
- `docs/tasks/TASK_266_command_mission_editor_settings_help_content_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_266_command_mission_editor_settings_help_content_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_257_button_reachability_and_interaction_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_223_fog_of_war_modes_contract_and_settings.gd`
- [x] `git diff --check`

## Risiken
- Hilfe darf keine Befehle ausloesen oder Mission-State veraendern.
- Detailhilfe darf taktische UI nicht ueberdecken, wenn der Spieler gerade planen will.

## Naechster Schritt
TASK_267 automatisiert nun die Hilfeabdeckung, Textgroessen, Positionierung und Abschaltung als Gate.
