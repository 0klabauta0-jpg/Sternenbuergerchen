# TASK_300 - App Shell Return To Main Menu Navigation

## Ziel
Einzelspieler, Multiplayer, Editor und Einstellungen muessen einen klaren, sicheren Rueckweg zum Hauptmenue haben.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_199 - Main Menu Shell and Background Image
- TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay
- TASK_227 - Main Menu Multiplayer Host Join Lobby Flow
- TASK_231 - App Shell Game Setup Integration and Open Items Review

## Kontext
Das Hauptmenue ist der Einstieg. Wenn man in Einzelspieler, Multiplayer, Editor oder Einstellungen gelandet ist, muss man ohne Umwege wieder zurueckkommen. Das ist besonders wichtig, solange viele Screens noch im Aufbau sind.

## Umfang
1. Navigationsvertrag:
   - Jeder Hauptbereich hat einen sichtbaren Zurueck-/Hauptmenue-Button.
   - Button-Bezeichnung und Icon sind konsistent.
   - Bei ungespeicherten Editor-/Settings-Aenderungen gibt es eine Rueckfrage.
2. Bereiche:
   - Einzelspieler/Game Setup/Homebase
   - Multiplayer Host/Join/Lobby
   - Editor
   - Einstellungen
3. State-Sicherheit:
   - Zurueck zum Hauptmenue beendet keine laufende Multiplayer-Session heimlich.
   - Editor fragt bei ungespeicherter Map.
   - Settings schreiben nur bestaetigte Werte.
4. Verifier:
   - App-Shell kann jeden Bereich instanziieren.
   - Return-Callback fuehrt zum Main Menu.
   - Dirty-State erzeugt Confirm-Flow.

## Nicht-Ziele
- Kein kompletter Screen-Transition-Rework.
- Kein Savegame-System fuer laufende Missionen.
- Keine Netzwerk-Disconnect-UX ausser klarer Warnung.

## Akzeptanzkriterien
- [x] Einzelspieler hat Rueckweg zum Hauptmenue.
- [x] Multiplayer hat Rueckweg zum Hauptmenue und warnt bei aktiver Session.
- [x] Editor hat Rueckweg und Dirty-Map-Warnung.
- [x] Einstellungen haben Rueckweg.
- [x] Verifier prueft alle vier Hauptbereiche.

## Erwartete Dateien
- `scenes/...`
- `scripts/ui/...`
- `scripts/meta/...`
- `scripts/tests/task_300_app_shell_return_to_main_menu_navigation.gd`
- `docs/manual_checks/app_shell_main_menu_return_checklist.md`
- `docs/tasks/TASK_300_app_shell_return_to_main_menu_navigation.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_300_app_shell_return_to_main_menu_navigation.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_231_app_shell_game_setup_open_items_review.gd`
- [ ] Manueller Main-Menu-Navigationscheck.
- [ ] `git diff --check`

## Risiken
- Ruecknavigation darf keine Runtime-/SimulationRoot-Wahrheit resetten, ohne dass der User es merkt.
- Editor-Dirty-State muss erhalten bleiben oder bewusst verworfen werden.

## Naechster Schritt
TASK_301 repariert die Drag-/Z-Order- und Badge-Lesbarkeit der NPC-Karten.
