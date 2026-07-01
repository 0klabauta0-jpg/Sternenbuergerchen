# TASK_790 - Station Reentry Firefight Decision Polish Acceptance

## Ziel / Problem
TASK_789 liefert Findings zur sichtbaren Firefight-Decision-Card. Jetzt fehlt ein kleiner, eindeutiger Acceptance-Griff: Ist die Decision-Card eng genug akzeptiert fuer den naechsten spielbaren Firefight-Slice, oder muss sie gezielt zurueck in Review, Completion oder Polish?

## Sinnhaftigkeit / Ursache
Ohne Acceptance-Schicht wuerden wir nach den Findings weiter Artefakte sammeln, statt eine klare Arbeitsentscheidung zu treffen. TASK_790 macht die Entscheidung explizit und haelt die Grenze sauber: Akzeptanz ist read-only und setzt keine Gameplay-Wahrheit.

## Umfang
- Neuer read-only Service `StationReentryFirefightDecisionPolishAcceptance`.
- Auswertung eines TASK_789-Findings-Snapshots.
- Status fuer:
  - fehlende/ungueltige TASK_789-Findings
  - offenen sichtbaren Decision-Review
  - unvollstaendige Pflichtchecks
  - konkrete gezielte Decision-Polish-Follow-ups
  - engen Acceptance-Pass fuer den naechsten Firefight-Decision-Slice
- Manifestpfad `tmp/station_reentry_firefight_decision_polish_acceptance.json`.
- Status, Roadmap, Contract und HTML-Handbuch auf TASK_790 aktualisieren.

## Nicht-Ziele
- Kein automatischer Sichtentscheid und kein Screenshot-Parsing.
- Kein neues Command-UI-System.
- Kein Ausfuehren von GO, HOLD, FLANK, SUP, MOVE oder HOLD FIRE.
- Keine Navigation, Commands, FireEvents, DamageEvents oder Gameplay-Wahrheit.
- Kein echter Host/Client-Recapture; der wird erst als Folgetask vorbereitet.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_789_station_reentry_firefight_decision_evidence_findings.md`
- `docs/tasks/TASK_788_station_reentry_firefight_decision_evidence_packet.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Der Snapshot nutzt Schema `sternenbuergerchen.station_reentry_firefight_decision_polish_acceptance.v1`.
- Fehlende, falsche oder nicht read-only TASK_789-Findings blockieren und routen zu TASK_789.
- Offene sichtbare Reviews routen zu TASK_788.
- Fehlende Pflichtchecks routen zu TASK_788-Completion.
- Aktive Issue-Findings routen zum ersten konkreten TASK_789-Action-Item.
- Saubere Findings mit Decision-Line, Primary, Quick-Actions, Reason, Guard, Confirm, No-Auto-Command und Host/Client-Kontext werden als `accepted_for_next_firefight_decision_slice` markiert.
- Ein akzeptierter Snapshot routet zu TASK_791 - Station Reentry Firefight Decision Host Client Recapture.
- Der HTML-Bericht exportiert TASK_790-Manifestpfad und Acceptance-Haken.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_decision_polish_acceptance.gd`
- `scripts/tests/task_790_station_reentry_firefight_decision_polish_acceptance.gd`
- `docs/tasks/TASK_790_station_reentry_firefight_decision_polish_acceptance.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_790_station_reentry_firefight_decision_polish_acceptance.gd`
- Regression: TASK_789, TASK_788, TASK_787
- Reentry-Block TASK_769 bis TASK_790
- `git diff --check`

## Risiken / offene Punkte
TASK_790 akzeptiert nur die vorliegenden Findings. Wenn der sichtbare Fensterlauf nicht wirklich gemacht wurde, bleibt die Kette korrekt bei TASK_788/TASK_789 offen. Naechster sinnvoller Schritt ist TASK_791 fuer einen Host/Client-Recapture der akzeptierten Decision-Card.
