# TASK_1140 - Selected Fireteam Decision Language and Action Cue Polish

## Ziel / Problem
Die ausgewaehlte Fireteam-Flaeche stapelt mehrere historische Entscheidungszeilen und mischt dabei `NEXT`, `WHY`, `HOLD`, `ADV`, `BACK` und `2ND` mit deutscher Spielsprache. Der wichtigste naechste Griff ist dadurch schwerer lesbar als die zugrunde liegende Entscheidung.

## Ursache / Sinn
Mehrere read-only Diagnosevertraege werden unverarbeitet gemeinsam in das sichtbare HUD geschrieben. Diese Rohdaten sind fuer Tests und Multiplayer-Evidence wertvoll, aber kein guter Spielertext.

## Umfang
- Einen read-only Presenter fuer die sichtbare Fireteam-Entscheidung einfuehren.
- Naechsten Griff, Grund und optionale Folgeaktionen in klare deutsche Zeilen uebersetzen.
- Den sichtbaren Entscheidungsblock auf hoechstens drei Zeilen begrenzen.
- Vollstaendige Rohdiagnose im Tooltip erhalten.

## Nicht-Ziele
- Keine Aenderung an Combat-Entscheidung, `SimulationRoot`, Commands, Effects, RPCs oder Snapshots.
- Keine Aenderung an den historischen `NEXT/WHY`-Evidence-Feldern.
- Kein Umbau des Bottom-Docks oder der Mission-Control-Architektur.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1139_command_matrix_player_language_icon_hierarchy_polish.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- Das Selected-Fireteam-HUD zeigt `NAECHSTER GRIFF`, `GRUND` und bei Bedarf `OPTIONEN` in deutscher Spielsprache.
- Im sichtbaren Presenter stehen keine rohen Einzelcodes `NEXT`, `WHY`, `HOLD`, `ADV`, `BACK` oder `2ND`.
- Der Entscheidungsblock umfasst hoechstens drei Zeilen.
- Rohdiagnose bleibt unveraendert und ist ueber den Tooltip erreichbar.
- Der Presenter erzeugt keine Navigation, Commands, Effects oder Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/ui/selected_fireteam_decision_presenter.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1140_selected_fireteam_decision_language_action_cue_polish.gd`
- Status, Roadmap und HTML-Arbeitsbericht

## Lokale Pruefung
- TASK_1140-Verifier
- angrenzende Firefight-/HUD-Verifier
- TASK_1109 und TASK_222
- echter Full-HD-Capture

## Risiken / offene Punkte
Historische Verifier koennen absichtlich die Roh-Evidence pruefen. Diese wird nicht ueberschrieben; nur der sichtbare Presenter wird spielerfreundlich verdichtet.
