# TASK_787 - Station Reentry Firefight Player Decision Readability Pass

## Ziel / Problem
TASK_786 stellt sicher, dass Host und Client dieselbe polierte Firefight-Command-Surface lesen. Jetzt muss daraus fuer den Spieler ein klarer naechster Griff entstehen: Was soll ich als naechstes tun, warum, und womit bestaetige ich es?

## Sinnhaftigkeit / Ursache
Eine synchronisierte Surface ist technisch gut, aber noch nicht automatisch angenehm spielbar. In einem Feuerwechsel muss der Spieler den naechsten sinnvollen Befehl, Alternativen, Begruendung und No-Auto-Command-Grenze sofort lesen koennen.

## Umfang
- Neuer read-only Service `StationReentryFirefightPlayerDecisionReadabilityPass`.
- Quelle ist ein TASK_786 Host-/Client-Polished-Surface-Snapshot.
- Aufbau einer kleinen Decision-Card:
  - Primary-Action
  - Quick-Actions
  - Warum-Zeile aus der Interaction-Line
  - Guard-Line mit No-Auto-Command und Existing-Buttons
  - Confirm-Control als Hinweis auf bestehende Buttons/GO
- Gates fuer Quelle, Read-only, Primary, Quick-Actions, Begruendung, Guard, No-Auto-Command, Existing-Commands-only, Textbudget und Host/Client-Kontext.
- Manifestpfad `tmp/station_reentry_firefight_player_decision_readability_pass.json`.
- Status, Roadmap, Contract und HTML-Handbuch auf TASK_787 aktualisieren.

## Nicht-Ziele
- Kein Ausfuehren von HOLD, FLANK, SUP, MOVE oder GO.
- Kein neues Command-UI-System.
- Kein automatischer Fenster- oder Screenshot-Entscheid.
- Keine Navigation, Commands, FireEvents, DamageEvents oder Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_786_station_reentry_firefight_host_client_polished_surface_check.md`
- `docs/tasks/TASK_783_station_reentry_firefight_command_surface_polish.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Der Snapshot nutzt Schema `sternenbuergerchen.station_reentry_firefight_player_decision_readability_pass.v1`.
- Nicht bereite oder nicht read-only TASK_786-Quellen blockieren.
- Ein sauberer TASK_786-Snapshot erzeugt eine Decision-Card mit `NEXT HOLD`, Alternativen, Warum-Zeile und Guard-Line.
- Fehlende Primary, zu wenige Quick-Actions, fehlende Begruendung oder fehlende Guard-Line werden als Lesbarkeits-Polish gemeldet.
- Die Decision-Card bleibt read-only und verweist nur auf bestehende Befehle.
- Ein sauberer Check routet zu TASK_788 - Station Reentry Firefight Decision Evidence Packet.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_player_decision_readability_pass.gd`
- `scripts/tests/task_787_station_reentry_firefight_player_decision_readability_pass.gd`
- `docs/tasks/TASK_787_station_reentry_firefight_player_decision_readability_pass.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_787_station_reentry_firefight_player_decision_readability_pass.gd`
- Regression: TASK_786, TASK_785, TASK_783
- Reentry-Block TASK_769 bis TASK_787
- `git diff --check`

## Risiken / offene Punkte
TASK_787 erzeugt noch keine sichtbare Evidence und fuehrt keinen Befehl aus. Der naechste sinnvolle Schritt ist TASK_788, der diese Decision-Card als sichtbares Paket/Fenster-Evidence pruefbar macht.
