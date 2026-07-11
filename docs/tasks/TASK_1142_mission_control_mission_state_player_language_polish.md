# TASK_1142 - Mission Control Mission-State Player Language Polish

## Ziel / Problem
Nach der Entscheidungsbereinigung mischt Mission Control weiterhin `Teams`, `Approach`, `Drop wartend`, `off-map`, `inbound`, `outbound`, `staged` und `Preview` mit deutscher Spielsprache.

## Ursache / Sinn
Transport- und Teamzustand werden direkt aus historischen Runtime-Strings zusammengesetzt. Die technischen IDs sind fuer Diagnose sinnvoll, aber keine konsistente Spielerlesung.

## Umfang
- Einen read-only Presenter fuer LZ-, Anflug- und Dropship-Zustand einfuehren.
- Alle sichtbaren Transportphasen in kurze deutsche Statuszeilen uebersetzen.
- Team-Chip sichtbar als Einsatz-/Teamkontext statt `Teams:` formulieren.
- Technische State-, Peer- und Spawnwerte in Snapshots und Tooltips erhalten.

## Nicht-Ziele
- Keine Aenderung an Transportstate, Drop-Sequenz, ETA, LZ, Approach, Peer-Zuweisung oder Spawn-Wahrheit.
- Keine Aenderung an Commands, Effects, RPCs oder Snapshotfeldern.
- Kein Layoutumbau von Mission Control.

## Akzeptanzkriterien
- Mission Control zeigt kurze deutsche Zeilen fuer LZ, Anflug, Bereitschaft, Anflug, Landung, Ausstieg, Abflug und Rueckflug.
- Sichtbare Zeilen enthalten keine Runtime-IDs `inbound`, `outbound`, `to_fob`, `staged` oder `off-map`.
- Der Team-Chip beginnt sichtbar mit `Einsatz:` statt `Teams:`.
- Rohwerte bleiben im Tooltip und read-only Snapshot erhalten.
- Multi-Dropship-, Multiplayer-, HUD- und Performance-Gates bleiben gruen.

## Betroffene Dateien
- `scripts/ui/mission_control_state_presenter.gd`
- `scripts/mission/mission_team_chip_presenter.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1142_mission_control_mission_state_player_language_polish.gd`
- Status, Roadmap und HTML-Arbeitsbericht

## Lokale Pruefung
- TASK_1142-Verifier
- Mission-Team-Chip-Verifier
- Dropship- und Multi-Dropship-Verifier
- TASK_1118, TASK_1109, TASK_222
- echter Full-HD-Capture

## Risiken / offene Punkte
Einige alte Verifier pruefen absichtlich rohe Peer-/Spawn-Texte. Diese Felder bleiben erhalten; nur `display_text` und Mission-Control-Zeilen werden spielerfreundlich.
