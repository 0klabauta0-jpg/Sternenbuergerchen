# TASK_313 - Dropship Arrival Visibility Feedback Smoke

## Ziel
Der Dropship-Flow soll sichtbar rueckmelden, was passiert, besonders wenn das Dropship nicht erscheint oder nicht kommt. Der User darf nicht im Unklaren bleiben, ob LZ, Go, Pilot, Boarding oder Transit blockiert.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_311 - Dropship LZ Target Pick Accuracy Contract
- TASK_312 - Dropship Command Matrix LZ Go Layout
- TASK_302 - Dropship Flight Deck Boarding Rename Userology
- TASK_304 - Unified Transit Progress Ghosting Homebase FOB

## Kontext
Der User sieht gerade nicht viel, weil das Dropship nicht kommt. Dafuer braucht es einen konkreten Feedback-Smoke: Welche Voraussetzung fehlt? Wurde Go gedrueckt? Ist das Dropship unterwegs? Kommt es spaeter? Ist kein Pilot/Team/LZ gesetzt?

## Umfang
1. Statuskette:
   - No LZ.
   - No Pilot.
   - No Team boarded.
   - Ready.
   - Go accepted.
   - In transit.
   - Arriving.
   - Landed.
   - Cannot / blocked mit Grund.
2. UI-Feedback:
   - Command Matrix zeigt Button-State und Blockgrund.
   - Flight Deck zeigt Dropship-/Pilot-/Insassenstatus.
   - Karte zeigt Ziel-LZ, resolved LZ oder erwarteten Arrival-Hinweis.
   - Comic-/Statusfeedback optional, falls bestehender Bubble-Flow passt.
3. Debug/Verifier:
   - Test fuer jeden Blockgrund.
   - Test fuer erfolgreichen Flow bis Landung.
   - Test fuer "Dropship kommt nicht" mit sichtbarem Grund.
   - Keine stille Failure.
4. Manual:
   - User klickt LZ-Pick, setzt Ziel, sieht Ziel.
   - Go bleibt disabled bis Voraussetzungen da sind.
   - Nach Go sieht man Fortschritt/Arrival.

## Nicht-Ziele
- Keine neue Air-Combat-Mechanik.
- Keine neue Transport-Routenberechnung.
- Kein finales Audio/VFX fuer Dropship.

## Akzeptanzkriterien
- [x] Wenn Dropship nicht kommt, zeigt UI einen konkreten Grund.
- [x] Erfolgreicher Flow zeigt Ziel-LZ, Go accepted, Transit/Arrival und Landung.
- [x] Blockierte Go-Aktion bleibt erklaert und testbar.
- [x] Keine stille Failure in Dropship-LZ-Command-Pfad.
- [x] Verifier deckt Blockgruende und Erfolgsweg ab.

## Erwartete Dateien
- `scripts/mission/...`
- `scripts/meta/...`
- `scripts/ui/...`
- `scripts/tests/task_313_dropship_arrival_visibility_feedback_smoke.gd`
- `docs/manual_checks/dropship_arrival_visibility_feedback_smoke.md`
- `docs/tasks/TASK_313_dropship_arrival_visibility_feedback_smoke.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_313_dropship_arrival_visibility_feedback_smoke.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_311_dropship_lz_target_pick_accuracy_contract.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_312_dropship_command_matrix_lz_go_layout.gd`
- [ ] Manueller Dropship-Flow-Sichtcheck.
- [ ] `git diff --check`

## Risiken
- Zu viele Statusmeldungen koennen nerven. Ziel ist klare Diagnose, nicht Dauertext.
- Feedback darf nicht zur zweiten Transport-Wahrheit werden.

## Naechster Schritt
Nach TASK_313 kann die Dropship-UX wieder mit dem groesseren FOB/Fireteam-Smoke zusammenlaufen.
