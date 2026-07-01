# TASK_789 - Station Reentry Firefight Decision Evidence Findings

## Ziel / Problem
TASK_788 bereitet den sichtbaren Review der Firefight-Decision-Card vor. Jetzt fehlt die read-only Auswertung: Ist der Review noch offen, fehlen Pflichtchecks, gibt es konkrete Polish-Funde, oder kann die naechste Station-Firefight-Iteration starten?

## Sinnhaftigkeit / Ursache
Ein Evidence-Paket ist noch kein Befund. Ohne Findings wuerden Screenshot, Workbench-Export, menschliche Haken und konkrete UI-Probleme wieder nur als lose Artefakte herumliegen. TASK_789 macht daraus einen sauberen Status und naechste Arbeit.

## Umfang
- Neuer read-only Service `StationReentryFirefightDecisionEvidenceFindings`.
- Auswertung von TASK_788-Paket plus optionalem HTML-/Workbench-Export.
- Status fuer:
  - fehlendes/ungueltiges TASK_788-Paket
  - offenen sichtbaren Decision-Review
  - unvollstaendige Pflichtchecks
  - konkrete Decision-Card-/Command-Surface-/Host-Client-/Performance-Follow-ups
  - sauberen naechsten Station-Firefight-Schritt
- Manifestpfad `tmp/station_reentry_firefight_decision_evidence_findings.json`.
- Status, Roadmap, Contract und HTML-Handbuch auf TASK_789 aktualisieren.

## Nicht-Ziele
- Kein automatischer Sichtentscheid und kein Screenshot-Parsing.
- Kein neues Command-UI-System.
- Kein Ausfuehren von GO, HOLD, FLANK, SUP, MOVE oder HOLD FIRE.
- Keine Navigation, Commands, FireEvents, DamageEvents oder Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_788_station_reentry_firefight_decision_evidence_packet.md`
- `docs/tasks/TASK_787_station_reentry_firefight_player_decision_readability_pass.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Der Snapshot nutzt Schema `sternenbuergerchen.station_reentry_firefight_decision_evidence_findings.v1`.
- Fehlendes, falsches oder nicht bereites TASK_788-Paket blockiert und routet zur TASK_788-Reparatur.
- Offene sichtbare Reviews bleiben offen und werden nicht still als erledigt markiert.
- Pflichtchecks enthalten F6-Fenster, Decision-Card, Decision-Line, Primary, Quick-Actions, Reason, Guard, Confirm, No-Auto-Command, Host/Client-Kontext, Screenshot und Workbench-JSON.
- Issue-Flags routen gezielt zu TASK_787, TASK_783, TASK_770 oder TASK_769.
- Ein sauberer Review routet zu TASK_790 - Station Reentry Firefight Decision Polish Acceptance.
- Der HTML-Bericht exportiert TASK_789-Manifestpfad, Haken und Issue-Flags.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_decision_evidence_findings.gd`
- `scripts/tests/task_789_station_reentry_firefight_decision_evidence_findings.gd`
- `docs/tasks/TASK_789_station_reentry_firefight_decision_evidence_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_789_station_reentry_firefight_decision_evidence_findings.gd`
- Regression: TASK_788, TASK_787
- Reentry-Block TASK_769 bis TASK_789
- `git diff --check`

## Risiken / offene Punkte
TASK_789 wertet Workbench-Haken und optionale Notizen aus, sieht aber weiterhin nicht selbst. Ohne echten Fensterlauf bleibt `needs_visible_decision_evidence_review` korrekt offen. Naechster sinnvoller Schritt ist TASK_790 fuer eine kleine Acceptance/Polish-Entscheidung auf Basis der Findings.
