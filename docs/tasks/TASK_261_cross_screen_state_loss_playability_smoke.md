# TASK_261 - Cross Screen State Loss Playability Smoke

## Ziel
Ein automatisierter Cross-Screen-Smoke soll pruefen, ob auf dem Weg durch Menue, Settings, Homebase, FOB, Loadout, Mission, Debrief, Editor und Multiplayer-Vorbereitung etwas verloren geht oder in einem unspielbaren Zustand endet.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay
- TASK_227 - Main Menu Multiplayer Host Join Lobby Flow
- TASK_229 - Map Editor Usability Authoring Pass
- TASK_231 - App Shell Game Setup Integration and Open Items Review
- TASK_241 - Character Gameplay Playability Smoke
- TASK_250 - Asset Audio Background Playability Smoke
- TASK_257 - Button Reachability and Interaction Verifier
- TASK_259 - Character Card Roster Switching Playability
- TASK_260 - Loadout Selection Decorative Weapons Weight Playability

## Kontext
Viele Probleme entstehen nicht in einem einzelnen Screen, sondern beim Wechsel: Settings ueberschreiben etwas, Loadout bleibt am falschen NPC, Character Card zeigt alte Daten, Mission-Start verliert Fireteams, Debrief speichert nicht, oder Editor/Multi-Flow kommt nicht sauber zurueck.

## Umfang
1. Hauptflow:
   - Start im Hauptmenue.
   - Settings oeffnen/aendern/zurueck.
   - Einzelspieler/Homebase oeffnen.
   - Roster/Character Card/Fireteam/Loadout konfigurieren.
   - FOB oeffnen, Startvorbereitung ausfuehren.
   - Mission starten, minimalen Loop spielen, Debrief erreichen.
   - Zurueck in Homebase, State pruefen.
2. Editorflow:
   - Editor oeffnen.
   - Kleine Karte laden/erstellen.
   - Tile/Height/Object aendern.
   - Save/Load pruefen.
   - Zurueck ohne App-State zu verlieren.
3. Multiplayer-Vorbereitung:
   - Host/Join-Screen oeffnen.
   - Host-Konfiguration pruefen.
   - Join-Felder pruefen.
   - Back/Disconnect bringt sauberen Zustand.
4. State-Invarianten:
   - Roster-ID-Set bleibt erhalten.
   - Character-Auswahl zeigt korrekte Unit.
   - Fireteam-Zuweisung bleibt konsistent.
   - Loadout/Gewicht bleibt konsistent.
   - Settings bleiben gespeichert oder bewusst session-lokal.
   - Keine doppelten Commands/Audio/Visual-Events durch Screenwechsel.
5. Report:
   - Verlorene IDs, falsche Auswahl, stale UI, unerwartete Defaults, fehlender Rueckweg.

## Nicht-Ziele
- Kein vollstaendiger Kampagnenmodus.
- Kein Zwei-Client-Netzwerktest.
- Kein finaler Balancing- oder Story-Test.

## Akzeptanzkriterien
- [x] Hauptmenue -> Homebase -> FOB -> Mission -> Debrief -> Homebase laeuft automatisiert.
- [x] Roster, Fireteam, Character Card, Loadout und Gewicht bleiben konsistent.
- [x] Editor-Flow verliert keinen App-/Roster-State.
- [x] Multiplayer-Vorbereitung laesst sich oeffnen, bedienen und sauber verlassen.
- [x] Settings-Aenderungen haben erwarteten Persistenzstatus.
- [x] Report nennt alle offenen State-Loss- oder Rueckweg-Probleme.

## Umsetzung
- `scripts/tests/task_261_cross_screen_state_loss_playability_smoke.gd` fuehrt Main Menu/Settings, Homebase, FOB, Mission, Debrief, Editor und Multiplayer-Lobby nacheinander mit denselben Fixture-IDs aus.
- Der Smoke prueft Routen, Settings-Persistenz, Homebase-Transfer, FOB-Fireteam-/Loadout-Uebergabe, Mission-Registry, Mission-Loadout-Gewicht, Debrief-Identitaet und Rueckkehr nach Homebase.
- Editor- und Multiplayer-Flows werden nach dem Hauptflow geoeffnet und gegen State-Mutation, doppelte Audio-/Start-Events und unerwartete `SimulationRoot`-Erzeugung geprueft.
- `docs/reports/playability_cross_screen_state_loss_report.md` dokumentiert abgedeckte Flows, Invarianten und manuelle Restpunkte.

## Erwartete Dateien
- `scripts/tests/task_261_cross_screen_state_loss_playability_smoke.gd`
- `docs/reports/playability_cross_screen_state_loss_report.md`
- `scripts/tests/playability/playability_test_harness.gd`
- `docs/tasks/TASK_261_cross_screen_state_loss_playability_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_261_cross_screen_state_loss_playability_smoke.gd` (67/0)
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_241_character_gameplay_playability_smoke.gd` (34/0)
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_250_asset_audio_background_playability_smoke.gd` (102/0)
- [x] `git diff --check`

## Risiken
- Ein langer End-to-End-Smoke lokalisiert Fehler schlechter als Einzeltests.
- Testdaten muessen deterministisch bleiben, sonst werden State-Vergleiche instabil.

## Naechster Schritt
TASK_262 kann alle Playability-Checks in ein wiederholbares Regression-Gate zusammenfassen.
