# TASK_788 - Station Reentry Firefight Decision Evidence Packet

## Ziel / Problem
TASK_787 baut aus der synchronen Firefight-Surface eine lesbare Decision-Card. Jetzt braucht der sichtbare Playtest ein reproduzierbares Evidence-Paket: Welche Szene, welche Workbench, welche Decision-Zeilen und welche manuellen Checks gehoeren zum echten Fensterblick?

## Sinnhaftigkeit / Ursache
Ohne Paket werden technische Readability-Contracts, Screenshot, Workbench-Export und menschlicher Sichtentscheid leicht vermischt. TASK_788 trennt deshalb Vorbereitung von Abnahme: Das Manifest bereitet den Review vor, laesst `manual_review_done = false` und erzeugt keine Gameplay-Wahrheit.

## Umfang
- Neues Tool `scripts/tools/prepare_station_reentry_firefight_decision_evidence_packet.ps1`.
- Quelle ist `tmp/station_reentry_firefight_player_decision_readability_pass.json` aus TASK_787.
- Manifest `tmp/station_reentry_firefight_decision_evidence_packet.json`.
- Paket nennt:
  - Scenario und Workbench
  - erwartete Decision-Line
  - Primary, Quick-Actions, Reason-Line, Guard-Line und Confirm-Control
  - No-Auto-Command-/Existing-Buttons-Grenze
  - manuelle Checks fuer echten Fensterblick
  - Launch-/Capture-/Verifier-Kommandos
- Status, Roadmap, Contract und HTML-Handbuch auf TASK_788 aktualisieren.

## Nicht-Ziele
- Kein automatischer Sichtentscheid.
- Kein Screenshot-Parsing.
- Kein GO, HOLD, FLANK, SUP, MOVE oder HOLD FIRE.
- Keine Navigation, Commands, FireEvents, DamageEvents oder Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_787_station_reentry_firefight_player_decision_readability_pass.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Das Tool schreibt ein Manifest mit Schema `sternenbuergerchen.station_reentry_firefight_decision_evidence_packet.v1`.
- Das Manifest wird nur `ready_to_capture_firefight_decision_evidence`, wenn Szene, Workbench und bereites TASK_787-Manifest vorhanden sind.
- Erwartete Decision-Daten aus TASK_787 werden unveraendert als Review-Erwartung uebernommen.
- `manual_review_required = true` und `manual_review_done = false`.
- Das Paket bleibt read-only und setzt keine Gameplay-Wahrheit.
- Der HTML-Bericht exportiert Manifestpfad und zentrale TASK_788-Checks.
- Der naechste Schritt ist TASK_789 - Station Reentry Firefight Decision Evidence Findings.

## Betroffene Dateien
- `scripts/tools/prepare_station_reentry_firefight_decision_evidence_packet.ps1`
- `scripts/tests/task_788_station_reentry_firefight_decision_evidence_packet.gd`
- `docs/tasks/TASK_788_station_reentry_firefight_decision_evidence_packet.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_788_station_reentry_firefight_decision_evidence_packet.gd`
- Regression: TASK_787, TASK_786
- `git diff --check`

## Risiken / offene Punkte
TASK_788 erzeugt kein echtes Screenshot-Urteil. Der naechste sinnvolle Schritt ist TASK_789, der Workbench-/Fenster-Notizen und dieses Paket als Findings auswertet.
