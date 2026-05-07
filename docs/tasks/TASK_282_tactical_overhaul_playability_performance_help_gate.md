# TASK_282 - Tactical Overhaul Playability Performance Help Gate

## Ziel
Der gesamte Tactical-Overhaul soll in einem Abschluss-Gate geprueft werden: Quellenabstraktion, Commander-FTL-Delegation, Regeln, Multi-Fireteam-Plan, FTL-Progression, Kommunikation, Command-UI, Ausbrueche, Air-Asset-Risiko, Editor, Multiplayer, Performance und Hilfe-Popups.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_269 - Tactical Doctrine Source Review Game Abstraction
- TASK_270 - Commander to Fireteam Leader Delegation Contract
- TASK_271 - Tactical Command Modes ROE Fire Rules
- TASK_272 - Multi Fireteam Coordinated Area Plan
- TASK_273 - Fireteam Leader Skill Tactical Progression
- TASK_274 - Tactical Communication Feedback Layer
- TASK_275 - Command Button Hierarchy Arrangement Overhaul
- TASK_276 - Tactical Breakout and Exception Behavior
- TASK_277 - Dropship Freighter Anti Armor Threat Contract
- TASK_278 - Air Asset Loss Recovery Meta Loop
- TASK_279 - LZ Security Air Asset Tactical Playability Smoke
- TASK_280 - Tactical Profile Editor Scenario Authoring
- TASK_281 - Tactical Command Multiplayer Authority Snapshot
- TASK_268 - Post Help Popup Playability Regression Smoke

## Kontext
Diese Reihe veraendert das Herz des Spiels. Deshalb braucht sie am Ende ein Gate, das nicht nur "Tests gruen" sagt, sondern prueft, ob der Spieler versteht, was die Teams tun, ob die Buttons erreichbar sind, ob Air-Asset-Verlust fair ist und ob Performance nicht kippt.

## Umfang
1. End-to-End-Mission:
   - Zwei bis drei Fireteams.
   - Multi-Fireteam-Plan auf Take/Secure.
   - Enemy mit Hold/Push/AT-Threat.
   - Contact, Ausbruch, Kommunikation.
   - LZ secure oder Air-Asset-Verlust.
2. UI/Help:
   - Command-Buttons erreichbar.
   - Help-Popups fuer neue Regeln.
   - #17/#18/Map/Bubbles konsistent.
3. Meta:
   - Debrief und Homebase/FOB bei Air-Asset-Schaden.
   - FTL-Progression sichtbar.
4. Multiplayer:
   - Autoritativer Command-/Snapshot-Smoke.
5. Performance:
   - TASK_222/TASK_249 Gate einbeziehen.
   - Kommunikations-/Overlay-Spam zaehlen.
6. Report:
   - Was ist automatisiert?
   - Was bleibt manueller Sicht-/Spielgefuehl-Check?
   - Balancing-Open-Items.

## Nicht-Ziele
- Kein finaler Kampagnenbalance-Pass.
- Kein echtes Online-Stresstest-Match.
- Kein vollstaendiges Tutorial.

## Akzeptanzkriterien
- [x] Tactical-End-to-End-Smoke laeuft mit Multi-Fireteam-Plan und Air-Asset-Risiko.
- [x] Commander steuert FTLs, nicht einzelne Units direkt.
- [x] Spieler sieht Plan, Ausbrueche, Kommunikation und Folgen.
- [x] UI/Help/Playability-Gates bleiben gruen.
- [x] Multiplayer-Authority bleibt sauber.
- [x] Performance-Gate meldet keine kritische Regression.
- [x] Abschlussreport nennt Balance- und Manual-Check-Restpunkte.

## Erwartete Dateien
- `scripts/tests/task_282_tactical_overhaul_playability_performance_help_gate.gd`
- optional `scripts/tests/run_task_282_tactical_overhaul_gate.ps1`
- `docs/reports/tactical_overhaul_playability_performance_help_gate.md`
- `docs/manual_checks/tactical_overhaul_manual_playability_checklist.md`
- `docs/tasks/TASK_282_tactical_overhaul_playability_performance_help_gate.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_282_tactical_overhaul_playability_performance_help_gate.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_268_post_help_popup_playability_regression_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_281_tactical_command_multiplayer_authority_snapshot.gd`
- [x] `git diff --check`

## Risiken
- Der Abschluss-Smoke ist breit und lokalisiert Fehler schlechter als Einzeltests.
- Wenn UI-Feedback zu laut wird, geht taktische Klarheit verloren.

## Naechster Schritt
Nach TASK_282 kann ein gezielter Balance-Pass entscheiden, welche Taktikprofile, Air-Asset-Risiken und Progressionswirkungen final bleiben.
