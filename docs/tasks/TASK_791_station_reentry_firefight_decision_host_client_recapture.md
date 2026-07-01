# TASK_791 - Station Reentry Firefight Decision Host Client Recapture

## Ziel / Problem
TASK_790 akzeptiert die Decision-Card eng fuer den naechsten Firefight-Slice. Jetzt fehlt ein reproduzierbares Host/Client-Recapture-Paket, damit wir die akzeptierte Decision-Card in zwei Fenstern pruefen koennen: Host und Client sollen dieselbe Entscheidung, dieselben Alternativen und dieselben Guard-Grenzen sehen, ohne Peer-/Team-Kontext zu vermischen.

## Sinnhaftigkeit / Ursache
Multiplayer-Faehigkeit entsteht hier nicht durch neue Features, sondern durch lesbare, reproduzierbare Zwei-Fenster-Pruefung. TASK_791 nimmt den akzeptierten TASK_790-Stand und macht daraus ein manuelles Capture-Paket mit klaren Erwartungen und Checks.

## Umfang
- Neues Prepare-Tool `prepare_station_reentry_firefight_decision_host_client_recapture.ps1`.
- Manifestpfad `tmp/station_reentry_firefight_decision_host_client_recapture.json`.
- Das Paket liest ein TASK_790-Acceptance-Manifest.
- Es sammelt Szenario, Workbench, erwartete Decision-Line, Primary, Quick-Actions, Reason, Guard, Confirm-Control, Host-/Client-Rollen und Start-/Capture-Kommandos.
- Status, Roadmap, Contract und HTML-Handbuch auf TASK_791 aktualisieren.

## Nicht-Ziele
- Kein automatisches Sichturteil und kein Screenshot-Parsing.
- Kein echter Netzwerktransport und kein erzwungener Zwei-Fenster-Run im Test.
- Kein Ausfuehren von GO, HOLD, FLANK, SUP, MOVE oder HOLD FIRE.
- Keine Navigation, Commands, FireEvents, DamageEvents oder Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_790_station_reentry_firefight_decision_polish_acceptance.md`
- `docs/tasks/TASK_789_station_reentry_firefight_decision_evidence_findings.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Das Paket nutzt Schema `sternenbuergerchen.station_reentry_firefight_decision_host_client_recapture.v1`.
- Fehlendes oder nicht akzeptiertes TASK_790-Manifest blockiert das Paket.
- Ein akzeptiertes TASK_790-Manifest erzeugt Status `ready_to_capture_firefight_decision_host_client`.
- Das Paket traegt Decision-Line, Primary, Quick-Actions, Reason-Line, Guard-Line, Confirm-Control, No-Auto-Command und Existing-Buttons-Grenze weiter.
- Host-Kontext `HOST P1 ALPHA` und Client-Kontext `CLIENT P2 BRAVO` sind als erwartete Sichtanker enthalten.
- Pflichtchecks pruefen Host/Client-Fenster, gleiche Decision-Line, Primary, Quick-Actions, Reason, Guard, Confirm, No-Auto-Command, Existing-Buttons, Peer-/Team-Kontext, Screenshot und Workbench-JSON.
- Das Paket bleibt read-only und setzt keine Gameplay-Wahrheit.
- Es routet zu TASK_792 - Station Reentry Firefight Decision Host Client Findings.

## Betroffene Dateien
- `scripts/tools/prepare_station_reentry_firefight_decision_host_client_recapture.ps1`
- `scripts/tests/task_791_station_reentry_firefight_decision_host_client_recapture.gd`
- `docs/tasks/TASK_791_station_reentry_firefight_decision_host_client_recapture.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_791_station_reentry_firefight_decision_host_client_recapture.gd`
- Regression: TASK_790, TASK_789, TASK_788
- Reentry-Block TASK_769 bis TASK_791
- `git diff --check`

## Risiken / offene Punkte
TASK_791 bereitet nur den sichtbaren Host/Client-Run vor. Ob beide Fenster wirklich dieselbe Decision-Card lesbar zeigen, muss der naechste Findings-Task aus Screenshot/Workbench-Export bewerten.
