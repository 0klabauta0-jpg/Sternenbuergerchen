# TASK_557 - Frontier Probe Multiplayer F6 Readability Pass

## Status: IMPLEMENTIERT

## Ziel / Problem
TASK_555 und TASK_556 sichern den Frontier-Probe-Multiplayer-Slice in Contracts und Host/Client-Testharnesses. Es fehlt noch ein automatischer F6-Lesbarkeitssmoke, der prueft, ob MP-Besitz, Mission-Team-Chip, Objective-/Cargo-Kontext und kritische HUD-Panels im sichtbaren FullHD-Missionslayout zusammenpassen.

## Sinnhaftigkeit / Ursache
Der Spieler muss im Missionsbild sehen koennen, wem Alpha/Bravo gehoeren, welcher Objective-Pfad aktiv ist und ob Teamchip, Mission Control und Selected Fireteam sich nicht gegenseitig verdecken. Sonst sind die Daten zwar korrekt, aber im echten F6-Spielmoment nicht entscheidungslesbar.

## Umfang
- Neuer read-only Snapshot `get_frontier_probe_multiplayer_f6_readability_snapshot()`.
- Headless-Smoke auf der 192x192-Station-Outpost-Map im FullHD-Viewport.
- Pruefung von:
  - TASK_555-Ownership bleibt gruen.
  - Die relevanten TASK_549-F6-Layoutchecks bleiben gruen.
  - Mission-Team-Chip ist sichtbar.
  - Mission-Team-Chip nennt Host Peer 1, Peer 2, `spawn_alpha` und `spawn_bravo`.
  - Mission Control zeigt AA, COM, OBJ und CARGO gemeinsam.
  - Selected Fireteam zeigt den gewaehlten Fireteam-Kontext.
  - Mission Control, Selected Fireteam, Teamchip und Statuslabels bleiben innerhalb FullHD.
  - Teamchip bleibt im Mission-Control-Bereich und ueberlappt nicht mit Selected Fireteam.
- Rolling-HTML-Bericht wird auf TASK_557 aktualisiert und nennt den naechsten manuellen MP-Sichttest als Anschluss.

## Nicht-Ziele
- Kein manueller Screenshot-Sichttest.
- Kein echter Zwei-Prozess-/LAN-Test.
- Kein UI-Rebuild oder neues HUD-System.
- Keine neue Gameplay-Wahrheit in UI oder Bericht.
- Keine Aenderung an Objective-, Cargo-, Combat- oder Command-Entscheidungen.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_549_combat_hud_f6_visual_audit.md`
- `docs/tasks/TASK_555_frontier_probe_multiplayer_objective_ownership_smoke.md`
- `docs/tasks/TASK_556_frontier_probe_host_client_objective_handoff_smoke.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Der F6-Readability-Snapshot laeuft read-only und setzt `ui_sets_gameplay_truth = false`.
- Ownership, F6-Layout, Teamchip, Mission-Control-Text und Selected-Fireteam-Kontext sind gemeinsam gruen.
- Kritische Panels und Labels bleiben in FullHD-Bounds.
- Der Teamchip liegt im Mission-Control-Bereich und verdeckt nicht Selected Fireteam.
- Der Verifier `scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd` laeuft gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd`
- `docs/tasks/TASK_557_frontier_probe_multiplayer_f6_readability_pass.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_556_frontier_probe_host_client_objective_handoff_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_555_frontier_probe_multiplayer_objective_ownership_smoke.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Smoke ersetzt keinen echten visuellen Screenshot-Check mit User-Blick auf das F6-Fenster.
- Der Smoke prueft FullHD-Automatik-Bounds, aber noch keine Hover-/Screenshot-Aesthetik.
- Naechster sinnvoller Anschluss ist `TASK_558 - Frontier Probe Multiplayer Manual Screenshot Notes Pass`, damit der echte MP-F6-Blick als Notiz-/Screenshot-Workbench bestaetigt wird.
