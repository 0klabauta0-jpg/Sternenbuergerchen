# TASK_223 - Fog of War Modes Contract and Settings

## Ziel
Fog of War bekommt einen klaren Spielmodus-Vertrag mit drei Modi, der spaeter in den Hauptmenue-Einstellungen auswählbar ist und fuer Singleplayer sowie Multiplayer eindeutig funktioniert.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_029 - Fog of War minimal
- TASK_092 - Stealth and Contact Range Contract
- TASK_160 - Tactical Mission Playability Smoke
- TASK_184 - Gameplay Hill Semantics Patch
- TASK_185 - Hill Visuals and Edge Lines Patch
- TASK_199 - Main Menu Shell and Background Image
- TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay

## Kontext
`FogOfWarSystem` verwaltet aktuell nur boolesche Sichtbarkeit pro `team_id` und `target_id`. Das reicht fuer "Enemy sichtbar oder nicht", aber noch nicht fuer Terrain, erkundete Tiles, Hoehenlinien, Deckung, schwarze unbekannte Bereiche und Settings.

Der neue Vertrag muss Terrainwissen und aktuelle Sicht trennen.

## Modi
1. `off`
   - Kein Fog of War.
   - Terrain, Units, Marker und Gegner folgen den normalen Debug-/Gameplay-Regeln.
2. `known_terrain`
   - Das gesamte Terrain ist bekannt und lesbar.
   - Aktuell sichtbare Units/Enemies/Events werden nur im Sichtbereich angezeigt.
   - Ausserhalb des Sichtbereichs bleibt Terrain sichtbar, aber Gegner und dynamische Events sind verborgen oder als letzte bekannte Kontakte dargestellt.
3. `unexplored_blackout`
   - Nur aktueller Sichtbereich ist hell sichtbar.
   - Bereits erkundetes Terrain bleibt als gedimmtes/erinnertes Terrain sichtbar.
   - Noch nie gesehene Tiles sind schwarz.
   - Gegner und dynamische Events erscheinen nur bei aktueller Sicht oder als bewusst letzte bekannte Kontakte.

## Umfang
1. Datenvertrag:
   - Mode-IDs festlegen.
   - Terrain-Kenntnis, aktuelle Sicht und letzte bekannte Kontakte getrennt definieren.
   - Per Team/Peer statt globaler Einheitsmaske.
2. Settings-Vertrag:
   - Default festlegen, z. B. `known_terrain` fuer taktische Lesbarkeit.
   - Hauptmenue-Settings sollen FoW-Modus speichern koennen.
   - Mission/Testsetup kann Modus explizit ueberschreiben.
3. Gameplay-Grenze:
   - FoW beeinflusst Anzeige und erlaubte Informationssicht.
   - Terrain-Walkability, LOS, Cover und Combat-Wahrheit bleiben in Terrain/LOS/Simulation.
   - Kein UI-Code darf FoW-Wahrheit setzen.
4. Multiplayer:
   - FoW-State ist per Team/Peer lesbar.
   - Host/Server bleibt autoritativ fuer sichtbare Enemy-/Event-Snapshots.
   - Clients duerfen keine versteckten Gegner aus Snapshots rekonstruieren.
5. Dokumentation:
   - `docs/dev/fog_of_war_modes_contract.md` mit Beispielen fuer 32x32/64x64.

## Nicht-Ziele
- Keine komplette FoW-Visualisierung.
- Keine Performance-Optimierung des FoW-Renders.
- Keine neue Stealth-Balance.
- Keine Map-Editor-UI.

## Akzeptanzkriterien
- [x] Drei FoW-Modi sind als stabile IDs dokumentiert.
- [x] Terrainwissen, aktuelle Sicht und letzte bekannte Kontakte sind getrennt.
- [x] FoW-Modus ist als Settings-Wert vorbereitbar.
- [x] Multiplayer-Grenze fuer Team-/Peer-FoW ist dokumentiert.
- [x] Bestehende Minimal-FoW-Ziel-Sichtbarkeit bleibt kompatibel oder bekommt einen Adapter.
- [x] Ein TASK_223-Verifier prueft Mode-IDs, Defaults und Daten-Roundtrip.

## Erwartete Dateien
- `docs/dev/fog_of_war_modes_contract.md`
- `scripts/core/fog_of_war_mode_contract.gd`
- `scripts/core/fog_of_war_system.gd`
- `scripts/ui/game_settings_contract.gd`
- `scripts/tests/task_223_fog_of_war_modes_contract_and_settings.gd`
- `docs/tasks/TASK_223_fog_of_war_modes_contract_and_settings.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_223_fog_of_war_modes_contract_and_settings.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_092_verifier.gd`
- [x] `git diff --check`

## Risiken
- Wenn Terrainwissen und Unit-Sicht vermischt werden, wird FoW spaeter schwer debugbar.
- Multiplayer darf keine versteckten Gegnerdaten an Clients liefern, nur um sie lokal schwarz zu malen.

## Umsetzung
- `FogOfWarModeContract` definiert `off`, `known_terrain`, `unexplored_blackout`, Default `known_terrain`, Settings-Normalisierung und Team-State-Snapshots.
- `FogOfWarSystem` behaelt die alte Ziel-Sichtbarkeit bei und ergaenzt Team-Modus, aktuelle Tile-/Event-Sicht, erkundete Tiles, letzte bekannte Kontakte und Peer-Team-Snapshots.
- `GameSettingsContract` bereitet `fog_of_war_mode` als Gameplay-Settings-Wert vor.
- `MainMenuScreen.get_settings_snapshot()` meldet den Gameplay-/FoW-Settings-Snapshot mit.
- `docs/dev/fog_of_war_modes_contract.md` dokumentiert Modi, getrennten Zustand, Settings, Multiplayer und 32x32/64x64-Beispiele.

## Naechster Schritt
TASK_224 kann Tile-Sicht, Hoehenlinien, Deckung und LOS konkret umsetzen.
