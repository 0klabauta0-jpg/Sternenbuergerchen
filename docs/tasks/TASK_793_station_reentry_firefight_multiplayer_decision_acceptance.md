# TASK_793 - Station Reentry Firefight Multiplayer Decision Acceptance

## Ziel / Problem
TASK_792 kann jetzt Host/Client-Decision-Findings liefern. Es fehlt noch ein enger Acceptance-Schritt, der daraus entscheidet: Ist der kleine Multiplayer-Firefight-Decision-Slice tragfaehig, oder muss er zurueck in Sichtreview, Completion oder gezielten Polish?

## Sinnhaftigkeit / Ursache
Die Kette soll nicht bei "Findings sind sauber" enden, sondern einen klaren Spielbarkeitsgriff erzeugen. Fuer Multiplayer ist wichtig, dass Host und Client dieselbe Decision-Line, dieselben Actions, dieselbe No-Auto-Command-Grenze und unterscheidbare Rollen sehen, bevor wir ein weiteres Playtest-Paket bauen.

## Umfang
- Neuer read-only Service `StationReentryFirefightMultiplayerDecisionAcceptance`.
- Auswertung von TASK_792-Findings.
- Gates fuer:
  - valide/read-only TASK_792-Quelle
  - manueller und sichtbarer Zwei-Fenster-Review
  - keine fehlenden Pflichtchecks
  - keine aktiven Host/Client-Decision-Issues
  - synchroner Decision-Kern
  - unterscheidbare Host-/Client-Rollen
  - No-Auto-Command- und Existing-Buttons-Grenze
  - sichtbarer Host/Client-Kontext
- Manifestpfad `tmp/station_reentry_firefight_multiplayer_decision_acceptance.json`.
- Status, Roadmap, Contract und HTML-Handbuch auf TASK_793 aktualisieren.

## Nicht-Ziele
- Kein neues Multiplayer-Transport-Feature.
- Kein automatischer Sichtentscheid und kein Screenshot-Parsing.
- Kein Ausfuehren von GO, HOLD, FLANK, SUP, MOVE oder HOLD FIRE.
- Keine Navigation, Commands, FireEvents, DamageEvents oder Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_792_station_reentry_firefight_decision_host_client_findings.md`
- `docs/tasks/TASK_791_station_reentry_firefight_decision_host_client_recapture.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Der Snapshot nutzt Schema `sternenbuergerchen.station_reentry_firefight_multiplayer_decision_acceptance.v1`.
- Fehlende, falsche oder nicht read-only TASK_792-Findings blockieren und routen zu TASK_792.
- Offene sichtbare Reviews routen zurueck zu TASK_791.
- Unvollstaendige Pflichtchecks routen zurueck zu TASK_791-Completion.
- Aktive Issues routen zum ersten konkreten TASK_792-Action-Item.
- Ein sauberer Review setzt `accepted_for_multiplayer_firefight_decision_slice = true`.
- Ein sauberer Review routet zu TASK_794 - Station Reentry Firefight Multiplayer Decision Playtest Packet.
- Der HTML-Bericht exportiert TASK_793-Manifestpfad und Acceptance-Haken.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_multiplayer_decision_acceptance.gd`
- `scripts/tests/task_793_station_reentry_firefight_multiplayer_decision_acceptance.gd`
- `docs/tasks/TASK_793_station_reentry_firefight_multiplayer_decision_acceptance.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_793_station_reentry_firefight_multiplayer_decision_acceptance.gd`
- Regression: TASK_792, TASK_791, TASK_790
- Reentry-Block TASK_769 bis TASK_793
- `git diff --check`

## Risiken / offene Punkte
TASK_793 akzeptiert nur die dokumentierte Host/Client-Decision-Kette. Es beweist noch keinen echten langen Multiplayer-Playtest und keine Netzwerk-Authority unter Last. Naechster sinnvoller Schritt ist TASK_794 als Playtest-Paket fuer den akzeptierten Multiplayer-Decision-Slice.
