# TASK_792 - Station Reentry Firefight Decision Host Client Findings

## Ziel / Problem
TASK_791 bereitet den Host/Client-Recapture der akzeptierten Firefight-Decision-Card vor. Jetzt fehlt die read-only Auswertung: Ist der Zwei-Fenster-Review noch offen, fehlen Pflichtchecks, gibt es konkrete Host/Client-Abweichungen, oder kann der naechste Multiplayer-Decision-Acceptance-Schritt starten?

## Sinnhaftigkeit / Ursache
Ein Recapture-Paket ist noch kein Befund. Fuer ein angenehmes und multiplayer-faehiges Spiel muss klar werden, ob Host und Client dieselbe Entscheidung sehen und ob Peer-/Team-Kontext, Confirm-Control und No-Auto-Command-Grenze wirklich lesbar bleiben.

## Umfang
- Neuer read-only Service `StationReentryFirefightDecisionHostClientFindings`.
- Auswertung von TASK_791-Paket plus optionalem HTML-/Workbench-Export.
- Status fuer:
  - fehlendes/ungueltiges TASK_791-Paket
  - offenen sichtbaren Host/Client-Decision-Review
  - unvollstaendige Pflichtchecks
  - konkrete Decision-/Host-Client-/Peer-Kontext-/Performance-Follow-ups
  - sauberen naechsten Multiplayer-Decision-Acceptance-Schritt
- Manifestpfad `tmp/station_reentry_firefight_decision_host_client_findings.json`.
- Status, Roadmap, Contract und HTML-Handbuch auf TASK_792 aktualisieren.

## Nicht-Ziele
- Kein automatischer Sichtentscheid und kein Screenshot-Parsing.
- Kein echtes Netzwerk-Transport- oder Authority-Feature.
- Kein Ausfuehren von GO, HOLD, FLANK, SUP, MOVE oder HOLD FIRE.
- Keine Navigation, Commands, FireEvents, DamageEvents oder Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_791_station_reentry_firefight_decision_host_client_recapture.md`
- `docs/tasks/TASK_790_station_reentry_firefight_decision_polish_acceptance.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Der Snapshot nutzt Schema `sternenbuergerchen.station_reentry_firefight_decision_host_client_findings.v1`.
- Fehlendes, falsches oder nicht bereites TASK_791-Paket blockiert und routet zur TASK_791-Reparatur.
- Offene sichtbare Reviews bleiben offen und werden nicht still als erledigt markiert.
- Pflichtchecks enthalten Host-/Client-Fenster, Decision-Card in beiden Fenstern, gleiche Decision-Line, Primary, Quick-Actions, Reason, Guard, Confirm, No-Auto-Command, Existing-Buttons, Peer-/Team-Kontext, Screenshot und Workbench-JSON.
- Issue-Flags routen gezielt zu TASK_770, TASK_786, TASK_787, TASK_783, TASK_736, TASK_501, TASK_773 oder TASK_769.
- Ein sauberer Review routet zu TASK_793 - Station Reentry Firefight Multiplayer Decision Acceptance.
- Der HTML-Bericht exportiert TASK_792-Manifestpfad, Haken und Issue-Flags.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_decision_host_client_findings.gd`
- `scripts/tests/task_792_station_reentry_firefight_decision_host_client_findings.gd`
- `docs/tasks/TASK_792_station_reentry_firefight_decision_host_client_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_792_station_reentry_firefight_decision_host_client_findings.gd`
- Regression: TASK_791, TASK_790, TASK_789
- Reentry-Block TASK_769 bis TASK_792
- `git diff --check`

## Risiken / offene Punkte
TASK_792 wertet Workbench-Haken und optionale Notizen aus, sieht aber weiterhin nicht selbst. Ohne echten Zwei-Fenster-Lauf bleibt `needs_visible_decision_host_client_review` korrekt offen. Naechster sinnvoller Schritt ist TASK_793 fuer eine kleine Multiplayer-Decision-Acceptance auf Basis der Findings.
