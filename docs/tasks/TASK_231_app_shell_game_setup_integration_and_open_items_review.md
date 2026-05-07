# TASK_231 - App Shell Game Setup Integration and Open Items Review

## Ziel
Nach Hauptmenue, Settings, FoW, Multiplayer, Editor, Map-Download und Air-Layer soll ein Integrations- und Open-Items-Review pruefen, ob die Spielstartpfade zusammenpassen und welche vergessenen Punkte als naechste Tasks geschnitten werden muessen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_199 - Main Menu Shell and Background Image
- TASK_223 bis TASK_225 - Fog of War Modes und Visual Overlay
- TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay
- TASK_227 - Main Menu Multiplayer Host Join Lobby Flow
- TASK_228 - Multiplayer Editor Map Manifest Download Consent
- TASK_229 - Map Editor Usability Authoring Pass
- TASK_230 - Flight Altitude Layer and Air Visibility Audit

## Kontext
Viele Systeme beruehren den App-Einstieg: Einzelspieler, Multiplayer, Editor, Einstellungen, FoW, Maps, Air-/Dropship, Performance und Assets. Dieser Task ist bewusst ein Abschlussreview, damit nichts nur als halber Testpfad haengen bleibt.

## Umfang
1. Startpfade:
   - Hauptmenue -> Einzelspieler.
   - Hauptmenue -> Multiplayer -> Host/Join -> Lobby -> Mission.
   - Hauptmenue -> Editor -> Map bauen -> Save/Load -> Live-Test.
   - Hauptmenue -> Settings -> FoW/Display/Audio/Input -> zurueck.
2. Settings-Anwendung:
   - FoW-Modus kommt in Mission an.
   - Bubble-Modus kommt in Mission an.
   - Display/Audio veraendern keine Gameplay-Daten.
3. Multiplayer-Map:
   - Host nutzt Editor-Map.
   - Client kennt/kennt nicht Map.
   - Download-Consent funktioniert strukturell.
4. FoW und Air:
   - Terrain/Hoehe/Deckung/FoW sichtbar korrekt.
   - Air-/Dropship-Layer verrät keine Unknown-Map.
5. Offene Punkte:
   - Review von `docs/tasks`, `docs/IMPLEMENTATION_STATUS.md` und manuellen Checklisten.
   - Neue Taskvorschlaege nur konkret und klein schneiden.
6. Abschluss-Smoke:
   - Headless-Verifier fuer App-Shell-Routing.
   - Manuelle Checkliste fuer einen kompletten Spielstart.

## Nicht-Ziele
- Kein grosser neuer Feature-Patch.
- Kein Balance-Pass.
- Kein Content-Pack.
- Kein Redesign.

## Akzeptanzkriterien
- [x] Alle vier Hauptmenue-Pfade sind erreichbar und strukturell getestet.
- [x] Settings-Werte fuer FoW/Bubbles werden in Mission respektiert.
- [x] Multiplayer Host/Join und Map-Consent sind im Flow erreichbar.
- [x] Editor-Map kann fuer Singleplayer/Multiplayer vorbereitet werden.
- [x] FoW, Terrain-Hoehe, Cover und Air-Layer kollidieren nicht sichtbar.
- [x] Offene Punkte sind als konkrete Folge-Tasks dokumentiert, nicht als lose Notizen.
- [x] Ein TASK_231-Verifier und eine manuelle Checkliste existieren.

## Erwartete Dateien
- `docs/reviews/app_shell_game_setup_open_items_review.md`
- `docs/manual_checks/app_shell_full_flow_checklist.md`
- `scripts/tests/task_231_app_shell_game_setup_integration_and_open_items_review.gd`
- `docs/tasks/TASK_231_app_shell_game_setup_integration_and_open_items_review.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_231_app_shell_game_setup_integration_and_open_items_review.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_199_main_menu_shell_background_image_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_227_main_menu_multiplayer_host_join_lobby_flow.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_225_fog_of_war_2_5d_visual_overlay_and_contacts.gd`
- [ ] Manueller Full-Flow-Sichtcheck nach Checkliste.
- [x] `git diff --check`

## Risiken
- Ein Review-Task darf nicht zum Sammelbecken fuer unklare Grossfeatures werden. Alles, was neu ist, wird als eigener kleiner Task geschnitten.

## Naechster Schritt
Nach TASK_231 kann TASK_232 mit dem Character-Gameplay-Roster-Block starten. Offene App-Shell-Punkte bleiben als kleine manuelle Sichtchecks oder spaetere Multiplayer-Transport-Slices dokumentiert.
