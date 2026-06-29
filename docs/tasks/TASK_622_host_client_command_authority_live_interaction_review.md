# TASK_622 - Host Client Command Authority Live Interaction Review

## Problem
TASK_621 buendelt die Host-/Client-Evidence fuer den naechsten Spielgefuehltest. Der naechste konkrete Multiplayer-Risiko-Punkt ist aber die Interaktion selbst: Darf Peer 2 im Testsetup wirklich Bravo kommandieren, wird Alpha sauber abgelehnt, werden State-Mutationsversuche geblockt und kommt der Server-Snapshot beim Client an?

## Ursache
Die Authority-Grenze ist technisch in `SimulationRoot.submit_network_command_for_peer()` und im Multiplayer-Command-Contract vorhanden. Fuer den laufenden Review fehlt ein enger, exportierbarer Interaction-Befund, der die kritischen Checks als aktuelles Manifest zusammenfasst und die sichtbare Zwei-Fenster-Pruefung vorbereitet.

## Umfang
- Kleiner Headless-Interaction-Review mit Host- und Client-`SimulationRoot`.
- Peer-Zuordnung: Peer 1 ist Host/Alpha/Blue, Peer 2 ist Fireteam/Bravo/Red.
- Probe-Units fuer Alpha und Bravo registrieren.
- Peer 2 Bravo-Move akzeptieren und in die Host-Command-Queue bringen.
- Peer 2 Alpha-Move ablehnen.
- Peer 2 State-Mutation ablehnen.
- Host-State-Snapshot bauen und auf Client anwenden.
- Review-Manifest `tmp/host_client_command_authority_live_interaction_review.json` schreiben.
- Reports/Handbuch aktualisieren, ohne manuelle Fensterchecks als erledigt zu behaupten.

## Nicht-Ziele
- Kein neuer Netcode.
- Kein neuer UI-Button-Flow.
- Kein automatischer GUI-/Fensterlauf.
- Keine neue Session-/Lobby-Wahrheit.
- Keine Runtime-, Peer-, Command-, Objective-, Cargo-, Combat-, Movement- oder UI-Wahrheit im Review-Manifest.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/multiplayer_authority_command_contract.md`
- `docs/tasks/TASK_621_host_client_multiplayer_feel_review_bundle.md`
- `docs/tasks/TASK_607_two_instance_host_client_runtime_smoke.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Akzeptanzkriterien
- Verifier erzeugt `tmp/host_client_command_authority_live_interaction_review.json`.
- Manifest nutzt Schema `sternenbuergerchen.host_client_command_authority_live_interaction_review.v1`.
- Manifest meldet `peer2_bravo_command_accepted = true`.
- Manifest meldet `peer2_alpha_command_rejected = true` mit `alpha_reject_reason = peer_team_mismatch`.
- Manifest meldet `state_mutation_rejected = true` mit `state_mutation_reject_reason` beginnend mit `state_mutation_key:damage`.
- Manifest meldet, dass die akzeptierte Command-Queue auf dem Host angekommen und nach einem Tick nicht gewachsen ist.
- Manifest meldet `server_snapshot_built = true`, `client_snapshot_apply_accepted = true` und `client_received_bravo_unit = true`.
- Manifest bleibt `read_only = true` und `ui_sets_gameplay_truth = false`.
- Reports empfehlen danach nur belegte Findings oder einen manuellen Zwei-Fenster-Authority-Sichttest.

## Betroffene Dateien
- `docs/tasks/TASK_622_host_client_command_authority_live_interaction_review.md`
- `scripts/tests/task_622_host_client_command_authority_live_interaction_review.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_622_host_client_command_authority_live_interaction_review.gd`
- Regression: `godot_console.exe --headless --path . --script scripts/tests/task_621_host_client_multiplayer_feel_review_bundle.gd`
- Regression: `godot_console.exe --headless --path . --script scripts/tests/task_607_two_instance_host_client_runtime_smoke.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Verifier ist ein Headless-Interaction-Review, kein menschlicher Fensterlauf. Er belegt Authority und Snapshot-Sync technisch, aber nicht Input-Latenz, UI-Lesbarkeit oder Bediengefuehl.
- Wenn dieser Task gruen ist, sollte der naechste Slice entweder belegte UI-Findings anwenden oder einen echten Zwei-Fenster-Sichttest mit diesen vier Checks dokumentieren.
