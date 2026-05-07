# TASK_257 - Button Reachability and Interaction Verifier

## Ziel
Alle wichtigen Buttons und Controls sollen automatisiert darauf geprueft werden, ob sie vorhanden, sichtbar, erreichbar, sinnvoll aktiviert/deaktiviert und funktional angebunden sind.

Das betrifft Hauptmenue, Settings, Multiplayer Host/Join, Editor, Homebase, FOB, Character Sheet, Loadout, Mission-HUD und Debrief.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_181 - Drop Light Fixed Window Audit Patch
- TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay
- TASK_227 - Main Menu Multiplayer Host Join Lobby Flow
- TASK_229 - Map Editor Usability Authoring Pass
- TASK_256 - Automated Playability Coverage Contract

## Kontext
Ein Button kann visuell da sein und trotzdem unspielbar sein: offscreen, verdeckt, disabled ohne Grund, ohne Signal, mit kaputtem Callback oder nur mit Maus erreichbar. Der Task soll diese einfachen, aber nervigen Playability-Fehler automatisch abfangen.

## Umfang
1. Button-Inventar:
   - Pflichtbuttons aus der Coverage-Matrix laden.
   - Gefundene Buttons mit Node-Pfad, Text/Icon, Screen, Zustand und Callback-Diagnose reporten.
2. Sichtbarkeit und Erreichbarkeit:
   - Button liegt im Viewport.
   - Button liegt innerhalb seines festen Fensters oder vorgesehenen Scrollbereichs.
   - Button wird nicht von einem anderen Control komplett verdeckt.
   - Button ist per Maus-Klick und, wo vorgesehen, per Fokus/Keyboard erreichbar.
3. Funktionsbindung:
   - `pressed`, `toggled`, `item_selected` oder definierte Action ist angebunden.
   - Klick erzeugt erwartete Navigation, Toggle-State, Dialog oder Diagnose.
   - Disabled-State hat einen erwarteten Grund.
4. Screens:
   - Hauptmenue: Einzelspieler, Multiplayer, Editor, Einstellungen, Zurueck/Exit soweit vorgesehen.
   - Settings: Display/Fenster, Audio, Input, Gameplay/Fog-of-War.
   - Multiplayer: Host, Join, Ready, Start, Disconnect/Back.
   - Editor: Laden, Speichern, Save As, Palette, Hoehe, Objekt, Test/Back.
   - Homebase/FOB: Roster, Character Card, Transfer, Fireteams, Loadout, Flightdeck, Start.
   - Mission-HUD: Command, Selected Fireteam, Mission Control, Pause/Back soweit vorgesehen.
5. Bericht:
   - Fehlend, offscreen, verdeckt, disabled, ohne Callback, Klickfehler.

## Nicht-Ziele
- Kein finaler UX-Textpass.
- Kein Playtest der fachlichen Balance.
- Keine Reparatur aller kaputten Buttons in diesem Task, ausser sehr kleine offensichtliche Bindungsfixes.

## Umsetzung
- `scripts/tests/task_257_button_reachability_and_interaction_verifier.gd` prueft Pflichtcontrols aus Main Menu, Settings, Multiplayer Lobby, Map Editor, Homebase, FOB, Mission-HUD und Debrief auf Existenz, Sichtbarkeit, Viewport-Erreichbarkeit, Vollverdeckung, Signalbindungen, dokumentierte Disabled-/Hidden-Gruende und sichere Kernklicks.
- Der TASK_256-Harness wurde um generische Signalpruefung, Control-Deskriptoren und einen einfachen Full-Cover-Heuristikcheck erweitert.
- `docs/reports/playability_button_reachability_report.md` fasst abgedeckte Screens, defekte Interaktionen und manuelle Restpunkte zusammen.

## Akzeptanzkriterien
- [x] Pflichtbuttons aus `docs/qa/playability_coverage_matrix.md` werden gefunden oder als fehlend gemeldet.
- [x] Kein Pflichtbutton ist offscreen oder vollstaendig verdeckt.
- [x] Pflichtbuttons haben erwartete Signal-/Action-Bindungen.
- [x] Disabled-Pflichtbuttons haben begruendete erwartete Bedingungen.
- [x] Klicks auf Kernwege fuehren zu erwarteten Screen- oder State-Aenderungen.
- [x] Ein Report listet alle offenen manuellen oder defekten Interaktionen.

## Erwartete Dateien
- `scripts/tests/task_257_button_reachability_and_interaction_verifier.gd`
- `docs/reports/playability_button_reachability_report.md`
- `scripts/tests/playability/playability_test_harness.gd`
- `docs/tasks/TASK_257_button_reachability_and_interaction_verifier.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_257_button_reachability_and_interaction_verifier.gd` (427/0)
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_181_drop_light_fixed_window_audit_verifier.gd` (43/0)
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_256_automated_playability_coverage_contract.gd` (50/0)
- [x] `git diff --check`

## Risiken
- Headless-Klicks koennen echte Maus-/Hover-Gefuehle nur begrenzt pruefen.
- Manche Buttons sind absichtlich kontextabhaengig; der Test muss Setup-Zustaende sauber erzeugen statt false positives zu melden.

## Naechster Schritt
Nach TASK_257 prueft TASK_258 Layout, Clipping, Scrollbars und feste Fenster systematisch.
