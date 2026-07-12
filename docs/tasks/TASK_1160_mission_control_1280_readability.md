# TASK_1160 - Mission Control 1280 Readability

## Ziel / Problem
Die rechte Einsatzkontrolle `#18 EINSATZKONTROLLE` ist im 1280x720-Release nach Command Matrix, Member-Karten und Event Log die naechste zu kleine primaere Entscheidungsflaeche. Der Spieler soll Contact-Fire, naechsten Griff, Objective/Cargo/ROE und kurze Statuszeilen lesen koennen, ohne ins Tooltip oder Debug-Log auszuweichen.

## Sinnhaftigkeit / Ursache
Das Mission-Control-Panel ist im festen FullHD-HUD nur 344x248 gross und wird im 1280er Release auf etwa 229x165 skaliert. Der aktuelle Label-Pfad nutzt noch 10/11-Pixel-Schrift aus frueheren Combat-Density-Tasks. Dadurch schrumpft die effektive Spielschrift zu stark, obwohl die Flaeche eine primaere Entscheidungsflaeche ist.

## Umfang
- Mission-Control-Statuslabel visuell fuer 1280 haerten.
- Header und Statuszeilen mit eigener Readability-Metadaten/Snapshot absichern.
- Statuszeilen begrenzen, Tooltip als Detailtraeger behalten.
- Bestehende Mission-Control-Texte und Command-/Simulation-Pfade nicht veraendern.

## Nicht-Ziele
- Kein neuer Missionsflow.
- Kein neues Mission-Control-Panel.
- Keine Aenderung an `SimulationRoot`, Commands, Effects, Transport, Combat oder Multiplayer-Wahrheit.
- Keine Ueberarbeitung des kompletten HUD-Layouts.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_1157_command_matrix_1280_readability.md`
- `docs/tasks/TASK_1158_selected_fireteam_member_cards_1280_readability.md`
- `docs/tasks/TASK_1159_tactical_event_log_1280_readability.md`

## Akzeptanzkriterien
- `#18 EINSATZKONTROLLE` nutzt eine stabile 1280er Lesbarkeitsmarkierung.
- Statuslabel nutzt mindestens 13 Pixel Schrift, Outline und Wrap.
- Maximal vier sichtbare Statuszeilen bleiben im Panel; Details bleiben im Tooltip.
- Label und Scrollbereich bleiben innerhalb des bestehenden Mission-Control-Panels.
- Readability-Refresh erzeugt keine Commands oder Effects.
- Bestehende Mission-Control- und HUD-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1160_mission_control_1280_readability.gd`
- `docs/tasks/TASK_1160_mission_control_1280_readability.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- Neuer Verifier: `scripts/tests/task_1160_mission_control_1280_readability.gd`
- Regressionen: TASK_1107, TASK_1118, TASK_1141, TASK_1142, TASK_1157, TASK_1158, TASK_1159, TASK_222.

## Risiken / offene Punkte
Die Statusflaeche bleibt eng. Dieser Task verbessert die Lesbarkeit, ersetzt aber nicht die langfristige Frage, ob Mission-Control spaeter als groesserer Inspector oder kontextuelles Radial-/Side-Panel besser funktioniert.
