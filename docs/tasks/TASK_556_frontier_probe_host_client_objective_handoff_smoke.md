# TASK_556 - Frontier Probe Host Client Objective Handoff Smoke

## Status: IMPLEMENTIERT

## Ziel / Problem
TASK_555 sichert Alpha/Bravo-Ownership im Frontier-Probe-Slice, aber noch nicht den serverautoritativen Host/Client-Handoff: Session-Zuweisungen, erlaubte Client-Befehle, abgelehnte Fremdteam-/State-Mutationen und replizierter Objective-/Mission-Result-State muessen gemeinsam gruen sein.

## Sinnhaftigkeit / Ursache
Solo/Coop/PvP duerfen sich nicht erst im echten Multiplayer-Pfad widersprechen. Besonders kritisch sind Peer2/Bravo-Command-Rechte, Alpha/Bravo-Teamtrennung, Mission-Start-Assignments und der Server-Snapshot, der Objective- und Ergebnisdaten an den Client spiegelt.

## Umfang
- Neuer read-only Helper `FrontierProbeHostClientHandoffContract`.
- Headless-Smoke mit bestehendem `MultiplayerSession`, zwei `SimulationRoot`-Kontexten und Frontier-Probe-Objective-Daten.
- Pruefung von:
  - Host/Client-Session ist vor Mission-Start bereit.
  - Mission-Start erzeugt stabile Assignments.
  - Host Peer 1 gehoert zu Alpha, Peer 2 zu Bravo.
  - Peer 2 darf Bravo bewegen.
  - Peer 2 darf Alpha nicht bewegen.
  - State-Mutation im Client-Command wird abgelehnt.
  - Server-Snapshot mit Objective/Mission-Result wird vom Client akzeptiert.
  - TASK_555-Ownership bleibt dabei gruen.
- Rolling-HTML-Bericht wird auf TASK_556 aktualisiert und nennt TASK_557 als naechsten visuellen/spielbaren Anschluss.

## Nicht-Ziele
- Kein echter LAN-Socket-/Zwei-Prozess-Test.
- Kein neues Multiplayer-Transport-System.
- Kein Snapshot-Protokoll-Rewrite.
- Kein UI- oder Gameplay-State im Contract-Helper.
- Kein manueller F6-Sichttest.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_555_frontier_probe_multiplayer_objective_ownership_smoke.md`
- `docs/tasks/TASK_169_multiplayer_two_client_playability_smoke.md`
- `docs/tasks/TASK_538_homebase_to_mission_launch_handoff_smoke.md`
- `scripts/multiplayer/multiplayer_session.gd`
- `scripts/core/simulation_root.gd`

## Akzeptanzkriterien
- Session-Assignments aus `MultiplayerSession` werden in Host- und Client-`SimulationRoot` uebernommen.
- Peer 2 / Bravo kann einen Bravo-Move serverseitig einreichen.
- Peer 2 / Bravo kann keinen Alpha-Move einreichen.
- Forbidden-State-Keys werden weiter abgelehnt.
- Der Client akzeptiert den Server-Snapshot und sieht Objective sowie Mission-Result.
- TASK_555-Ownership bleibt Teil des Handoff-Snapshots und gruen.
- Der Verifier `scripts/tests/task_556_frontier_probe_host_client_objective_handoff_smoke.gd` laeuft gruen.

## Betroffene Dateien
- `scripts/mission/frontier_probe_host_client_handoff_contract.gd`
- `scripts/tests/task_556_frontier_probe_host_client_objective_handoff_smoke.gd`
- `docs/tasks/TASK_556_frontier_probe_host_client_objective_handoff_smoke.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_556_frontier_probe_host_client_objective_handoff_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_555_frontier_probe_multiplayer_objective_ownership_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_169_multiplayer_two_client_playability_smoke.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Test nutzt die vorhandenen Host-/Client-Testharnesses und keinen echten Netzwerk-Socket. Ein echter Zwei-Prozess-Playtest bleibt Folgearbeit.
- Naechster sinnvoller Anschluss ist `TASK_557 - Frontier Probe Multiplayer F6 Readability Pass`, damit die MP-Besitz-/Objective-Lesbarkeit sichtbar gegen das FullHD-Missionslayout geprueft wird.
