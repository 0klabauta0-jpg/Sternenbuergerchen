# TASK_794 - Station Reentry Firefight Multiplayer Decision Playtest Packet

## Ziel / Problem
TASK_793 akzeptiert den kleinen Multiplayer-Firefight-Decision-Slice. Jetzt fehlt ein reproduzierbares Playtest-Paket, mit dem Host/Client-Fenster, Workbench, Szenario, erwartete Decision-Daten und manuelle Checks zusammen gestartet und dokumentiert werden koennen.

## Sinnhaftigkeit / Ursache
Ein Acceptance-Snapshot ist noch kein sichtbarer Spieltest. Fuer ein angenehmes, spielbares und multiplayer-faehiges Spiel brauchen wir einen sauberen Griff: Fenster starten, Decision-Card in Host und Client sehen, gleiche Inhalte vergleichen, No-Auto-Command-Grenze pruefen, Screenshot/Workbench-JSON sichern und danach Findings auswerten.

## Umfang
- Neues Prepare-Tool `prepare_station_reentry_firefight_multiplayer_decision_playtest_packet.ps1`.
- Es liest `tmp/station_reentry_firefight_multiplayer_decision_acceptance.json`.
- Es schreibt `tmp/station_reentry_firefight_multiplayer_decision_playtest_packet.json`.
- Das Paket enthaelt:
  - Szenario- und Workbench-Pfade
  - TASK_793-Acceptance-Status
  - erwartete Decision-Line, Primary, Quick-Actions, Reason, Guard und Confirm
  - Host-/Client-Rollen
  - No-Auto-Command- und Existing-Buttons-Erwartung
  - manuelle Pflichtchecks fuer den Zwei-Fenster-Playtest
  - Launch-/Capture-/Verifier-Kommandos
- Status, Roadmap, Contract und HTML-Handbuch werden auf TASK_794 aktualisiert.

## Nicht-Ziele
- Kein automatischer Sichtentscheid und kein Screenshot-Parsing.
- Kein Netzwerk-Transport- oder Authority-Umbau.
- Kein Ausfuehren von GO, HOLD, FLANK, SUP, MOVE oder HOLD FIRE.
- Keine Navigation, Commands, FireEvents, DamageEvents oder Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_793_station_reentry_firefight_multiplayer_decision_acceptance.md`
- `docs/tasks/TASK_792_station_reentry_firefight_decision_host_client_findings.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Das Paket nutzt Schema `sternenbuergerchen.station_reentry_firefight_multiplayer_decision_playtest_packet.v1`.
- Fehlende oder nicht akzeptierte TASK_793-Acceptance blockiert das Paket.
- Ein akzeptierter TASK_793-Snapshot setzt `status = ready_to_playtest_firefight_multiplayer_decision`.
- Das Paket bleibt read-only und setzt keine Gameplay-Wahrheit.
- Pflichtchecks enthalten Host-/Client-Fenster, Decision-Card in beiden Fenstern, gleiche Decision-Line, Primary, Quick-Actions, Reason, Guard, Confirm, No-Auto-Command, Existing-Buttons, Peer-/Team-Kontext, Actionability, Performance-Gefuehl, Screenshot und Workbench-JSON.
- Das Paket routet zu TASK_795 - Station Reentry Firefight Multiplayer Decision Playtest Findings.
- Der HTML-Bericht exportiert TASK_794-Manifestpfad und Playtest-Haken.

## Betroffene Dateien
- `scripts/tools/prepare_station_reentry_firefight_multiplayer_decision_playtest_packet.ps1`
- `scripts/tests/task_794_station_reentry_firefight_multiplayer_decision_playtest_packet.gd`
- `docs/tasks/TASK_794_station_reentry_firefight_multiplayer_decision_playtest_packet.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_794_station_reentry_firefight_multiplayer_decision_playtest_packet.gd`
- Regression: TASK_793, TASK_792, TASK_791
- Reentry-Block TASK_769 bis TASK_794
- `git diff --check`

## Risiken / offene Punkte
TASK_794 erzeugt das Playtest-Paket, wertet den echten Fensterlauf aber noch nicht aus. Ohne manuellen Zwei-Fenster-Lauf bleibt die eigentliche Sichtbewertung Folgearbeit. Naechster sinnvoller Schritt ist TASK_795 fuer Playtest-Findings.
