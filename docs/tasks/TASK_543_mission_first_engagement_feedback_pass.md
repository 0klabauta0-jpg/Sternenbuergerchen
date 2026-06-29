# TASK_543 - Mission First Engagement Feedback Pass

## Status: IMPLEMENTIERT

## Ziel / Problem
Nach dem ersten Feindkontakt muss die erste Engagement-Entscheidung lesbar sein. Der Spieler soll erkennen, ob das Fireteam feuert, auf wen es feuert, mit welcher Waffe und mit welchem Deckungs-/LOS-Kontext. Wenn nicht geschossen wird, muss ein konkreter Blockgrund sichtbar sein.

## Sinnhaftigkeit / Ursache
TASK_542 macht Kontakt sichtbar. Der naechste spielerische Reibungspunkt ist der Moment danach: Ohne Feuerstatus, Zielwahl, Deckung und Blockgrund wirkt Combat zufaellig oder kaputt, selbst wenn die Runtime korrekt entscheidet.

## Umfang
- `MissionTacticalSandboxController` expose't einen read-only `get_mission_first_engagement_feedback_snapshot()`.
- Der Snapshot fasst bestehende FireEvent-, ContactDecision-, Cover-, Security-, Command-Feedback-, Tactical-Communication- und Render-Snapshots zusammen.
- Ein Smoke startet den Homebase-zu-Mission-Pfad, dropped/deboarded ein Fireteam, fuehrt den ersten Move aus, erzeugt reproduzierbaren Kontakt und triggert die bestehende Combat-Entscheidung.
- Der laufende HTML-Arbeitsbericht wird aktualisiert.

## Nicht-Ziele
- Kein neues Combat-System.
- Keine Aenderung an Damage, LOS, Friendly-Fire-Regeln oder ROE.
- Kein neues HUD-System und keine UI-seitige Gameplay-Wahrheit.
- Kein manueller Pixel-/F6-Sichttest in diesem Task.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_542_mission_first_contact_readability_pass.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/runtime_script_layout_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Der Snapshot setzt `ui_sets_gameplay_truth = false`.
- Kontakt und Engagement-Diagnose sind fuer das ausgewaehlte Fireteam sichtbar.
- Bei `fired` sind Angreifer, Ziel, Waffe und FireEvent/Decision-Link sichtbar.
- Bei `waiting` oder `blocked` sind Cooldown oder Blockgrund/Kandidat sichtbar.
- Cover-/Range-/LOS-Kontext ist mit der Entscheidung verknuepft.
- Mission-Control-/Command-Feedback zeigt die Entscheidung als kurzen lesbaren Text.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_543_mission_first_engagement_feedback_pass.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_543_mission_first_engagement_feedback_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_542_mission_first_contact_readability_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Task prueft Headless-Snapshots und keine menschliche Pixelwirkung.
- Der Combat-Tick wird im Smoke reproduzierbar angestossen, damit die Lesbarkeit der Entscheidung pruefbar ist; echtes Encounter-Balancing bleibt Folgearbeit.
