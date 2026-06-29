# TASK_608 - Host Client Runtime Visual Capture

## Ziel / Problem
TASK_607 prueft den Host/Client-Runtime-Pfad als Headless-Smoke mit lokaler ENet-Verbindung, zwei Mission-Instanzen, serverseitiger Command-Autorisierung und Client-Snapshot-Apply. Offen ist ein sichtbares, wiederholbares Artefakt, das diesen Pfad im laufenden HTML-Bericht reviewbar macht.

Ziel ist ein kleiner Visual-Capture-Slice mit PNG und JSON-Manifest unter `tmp/`, damit Transport, Authority, Snapshot-Apply und Host/Client-F6-Gates nicht nur im Testlog stehen.

## Sinnhaftigkeit / Ursache
Der User braucht zwischendurch einen Bericht, der zeigt, was gemacht wurde und was als Naechstes ansteht. Fuer Multiplayer ist Text allein zu abstrakt: Ein sichtbarer Capture macht den Runtime-Stand pruefbar, ohne gleich einen echten Zwei-Fenster-/LAN-Playtest zu behaupten.

## Umfang
- Neuer Verifier `scripts/tests/task_608_host_client_runtime_visual_capture.gd`.
- Wiederverwendung der TASK_607-Runtime-Kette: lokale ENet-Probe, Host-/Client-Mission-Instanzen, Peer-Authority-Commands, Client-Snapshot-Apply, Host-/Client-F6-Snapshots.
- Erzeugung von `tmp/host_client_runtime_visual_capture.png`.
- Erzeugung von `tmp/host_client_runtime_visual_capture.json`.
- HTML-Zwischenbericht zeigt Artefaktpfade, Runtime-Gates, manuellen Review-Status und TASK_609-Follow-up.
- Contract haelt fest: Capture ist read-only und setzt keine Gameplay-Wahrheit.

## Nicht-Ziele
- Kein echter Zwei-Prozess- oder LAN-Playtest.
- Kein neues Networking-System.
- Kein neues UI-Layout fuer die Mission.
- Keine Runtime-, Movement-, Combat-, Objective-, Cargo- oder Peer-Wahrheit im HTML-Bericht.
- Keine finalen Visual-Polish-Fixes aus dem Capture heraus.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_607_two_instance_host_client_runtime_smoke.md`
- `docs/tasks/TASK_606_host_client_f6_visual_polish_findings.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- TASK_608-Verifier laeuft headless gruen.
- Lokale ENet-Verbindung ist im Manifest als verbunden festgehalten.
- Host- und Client-Mission-Instanzen sind vorbereitet.
- Peer 2 Bravo-Command ist akzeptiert.
- Peer 2 Alpha-Command ist abgelehnt.
- State-Mutation-Payload ist abgelehnt.
- Client-Snapshot-Apply ist akzeptiert.
- Host- und Client-F6-Gate stehen auf `pass`.
- PNG und JSON-Manifest werden unter `tmp/` geschrieben.
- Manifest setzt `read_only = true` und `ui_sets_gameplay_truth = false`.
- HTML-Bericht exportiert die TASK_608-Pfade und Runtime-Gates.
- Roadmap nennt TASK_609 als naechsten Visual-Polish-Findings-Slice.

## Betroffene Dateien
- `scripts/tests/task_608_host_client_runtime_visual_capture.gd`
- `docs/tasks/TASK_608_host_client_runtime_visual_capture.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `scripts/tests/task_596_homebase_progression_player_review_notes.gd`
- `scripts/tests/task_598_homebase_progression_evidence_polish_findings.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_608_host_client_runtime_visual_capture.gd`
- Regression: `task_607_two_instance_host_client_runtime_smoke.gd`
- Regression: `task_606_host_client_f6_visual_polish_findings.gd`
- Regression: `task_596_homebase_progression_player_review_notes.gd`
- Regression: `task_598_homebase_progression_evidence_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Capture ist ein Headless-Evidence-Board. Er zeigt Runtime-Gates und Artefaktstruktur, ersetzt aber keinen echten Zwei-Fenster-Sichttest.
- TASK_609 sollte nur belegte visuelle Reibung aus PNG, Manifest oder HTML-Export anwenden.
- Spaetere Themen wie Latenz, Reconnect, Map-Transfer und echte LAN-Synchronitaet bleiben eigene Slices.
