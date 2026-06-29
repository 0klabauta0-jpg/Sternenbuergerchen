# TASK_607 - Two Instance Host Client Runtime Smoke

## Ziel / Problem
TASK_604 bis TASK_606 haben Host/Client-F6-Lesbarkeit als kombinierte Snapshots und lokale Evidence abgesichert. Offen bleibt, ob Host- und Client-Seite getrennt genug laufen: Transport, serverseitige Command-Autorisierung, Snapshot-Apply und F6-Lesbarkeit muessen zusammen geprueft werden.

Ziel ist ein kleiner Runtime-Smoke mit zwei getrennten Missionsinstanzen im Headless-Lauf und einer lokalen ENet-Verbindung als Transportprobe.

## Sinnhaftigkeit / Ursache
Multiplayer-Faehigkeit scheitert nicht nur an UI-Lesbarkeit. Der naechste Risikohebel ist die Kette: Peer verbindet, Client darf nur erlaubte Commands senden, Host bleibt Autoritaet, Client akzeptiert Server-Snapshots, und beide Seiten behalten den F6-Kontext lesbar.

## Umfang
- Neuer Verifier `task_607_two_instance_host_client_runtime_smoke.gd`.
- Lokale ENet-Server/Client-Verbindung auf freiem Testport.
- Zwei getrennte Mission-Testinstanzen: Host und Client.
- Peer-Zuweisung: Host Peer 1/Alpha/blue, Peer 2/Bravo/red.
- Host akzeptiert Bravo-Command von Peer 2.
- Host lehnt Alpha-Command und State-Mutation von Peer 2 ab.
- Host baut Multiplayer-State-Snapshot.
- Client wendet Host-Snapshot an und speichert Server-State.
- Host- und Client-F6-Snapshots bleiben gruen, kompakt und read-only.
- HTML-Zwischenbericht wird auf TASK_607/TASK_608 aktualisiert.

## Nicht-Ziele
- Kein kompletter LAN-/Steam-/Matchmaking-Test.
- Kein echter Zwei-Prozess-Playtest mit zwei Fenstern.
- Kein neues Networking-System und keine neue Gameplay-Wahrheit im Client.
- Kein visueller Screenshot-Capture in diesem Task.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/multiplayer_authority_command_contract.md`
- `docs/tasks/TASK_556_frontier_probe_host_client_objective_handoff_smoke.md`
- `docs/tasks/TASK_604_core_loop_host_client_feel_smoke.md`
- `docs/tasks/TASK_606_host_client_f6_visual_polish_findings.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Lokale ENet-Verbindung erreicht `CONNECTION_CONNECTED`.
- Host und Client laufen als getrennte Mission-Instanzen.
- Peer 2 darf Bravo/red kommandieren.
- Peer 2 darf Alpha/blue nicht kommandieren.
- State-Mutation-Payload wird abgelehnt.
- Host-Snapshot enthaelt die runtime-relevante Bravo-Unit.
- Client akzeptiert den Host-Snapshot und speichert Server-State.
- Host- und Client-F6-Snapshots bleiben `gate = pass`.
- F6-Snapshot-Lesen enqueued keine Commands.
- TASK_607 dokumentiert TASK_608 als naechsten sichtbaren Runtime-Capture-Slice.

## Betroffene Dateien
- `scripts/tests/task_607_two_instance_host_client_runtime_smoke.gd`
- `docs/tasks/TASK_607_two_instance_host_client_runtime_smoke.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `scripts/tests/task_596_homebase_progression_player_review_notes.gd`
- `scripts/tests/task_598_homebase_progression_evidence_polish_findings.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_607_two_instance_host_client_runtime_smoke.gd`
- Regression: `task_606_host_client_f6_visual_polish_findings.gd`
- Regression: `task_556_frontier_probe_host_client_objective_handoff_smoke.gd`
- Regression: `task_596_homebase_progression_player_review_notes.gd`
- Regression: `task_598_homebase_progression_evidence_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Test nutzt zwei Mission-Instanzen im selben Headless-Prozess plus lokale ENet-Peers. Das ist deutlich naeher an Multiplayer-Runtime, ersetzt aber keinen echten Zwei-Fenster-/LAN-Playtest.
- Sichtbare Host-/Client-Unterschiede im echten Fenster bleiben TASK_608.
- Weitere Runtime-Themen wie Join-Abbruch, Reconnect, Lag, Packet-Loss oder Map-Transfer sind eigene Folge-Slices.
