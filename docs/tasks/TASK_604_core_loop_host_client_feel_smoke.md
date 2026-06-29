# TASK_604 - Core Loop Host Client Feel Smoke

## Ziel / Problem
TASK_603 macht den lokalen Mission-HUD-Interaktionsmoment dichter und lesbarer. Offen bleibt, ob derselbe Core-Loop im Host/Client-Gefuehl noch zusammenhaelt: Teamchip, Objective/Cargo, ROE, Selected Fireteam und Multiplayer-F6-Lesbarkeit duerfen nicht auseinanderlaufen.

Ziel ist ein kleiner read-only Smoke, der vorhandene Host/Client-, MP-F6- und HUD-Density-Snapshots zusammenfasst, ohne echtes LAN oder neue Gameplay-Wahrheit zu bauen.

## Sinnhaftigkeit / Ursache
Der Spieler soll spaeter solo, coop oder PvP denselben taktischen Fluss verstehen: Wer gehoert zu welchem Peer, welches Team verfolgt welches Ziel, welches Fireteam ist aktiv und welche Mission-Control-Zeile zaehlt gerade. Diese Lesbarkeit muss vor groesseren Multiplayer- oder visuellen Playtests stabil sein.

## Umfang
- `MissionTacticalSandboxController` bekommt `get_core_loop_host_client_feel_snapshot()`.
- Der Snapshot kombiniert bestehende Multiplayer-F6-Readability-, Teamchip-/Ownership- und Mission-HUD-Density-Daten.
- Ein Verifier baut den Frontier-Probe-Kontext mit Alpha/Bravo-Peer-Zuordnung, Objective/Cargo, SUP-ROE und Kontakt auf.
- Der laufende HTML-Bericht wird als Zwischenbericht auf TASK_604 aktualisiert und benennt TASK_605 als naechsten Sichttest.

## Nicht-Ziele
- Kein echtes Zwei-Prozess-/LAN-Setup.
- Kein neues Networking-System.
- Kein Combat-, Objective-, Cargo- oder HUD-Rewrite.
- Kein finaler menschlicher F6-Sichttest.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_556_frontier_probe_host_client_objective_handoff_smoke.md`
- `docs/tasks/TASK_557_frontier_probe_multiplayer_f6_readability_pass.md`
- `docs/tasks/TASK_603_mission_hud_density_interaction_polish.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- `get_core_loop_host_client_feel_snapshot()` ist read-only und setzt `ui_sets_gameplay_truth = false`.
- Der Snapshot bleibt gruen, wenn TASK_557 MP-F6-Readability und TASK_603 HUD-Dichte gruen sind.
- Teamchip-/Kontexttext nennt Host Peer 1, Peer 2, `spawn_alpha` und `spawn_bravo`.
- Mission Control enthaelt weiterhin `ACT`, `OBJ`, `CARGO` und `ROE`.
- Selected-Fireteam-Kontext bleibt sichtbar.
- `get_command_feedback_snapshot()` exportiert die HUD-Dichte weiter.
- TASK_556, TASK_557 und TASK_603 bleiben als Regressionen anschlussfaehig.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_604_core_loop_host_client_feel_smoke.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `scripts/tests/task_596_homebase_progression_player_review_notes.gd`
- `scripts/tests/task_598_homebase_progression_evidence_polish_findings.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_604_core_loop_host_client_feel_smoke.gd`
- Regression: `task_603_mission_hud_density_interaction_polish.gd`
- Regression: `task_557_frontier_probe_multiplayer_f6_readability_pass.gd`
- Regression: `task_556_frontier_probe_host_client_objective_handoff_smoke.gd`
- Report-Regression: `task_596_homebase_progression_player_review_notes.gd`
- Report-Regression: `task_598_homebase_progression_evidence_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Smoke ersetzt keinen echten Host/Client-Fensterlauf und keinen finalen menschlichen Pixel-Sichttest.
- Falls TASK_605 echte Ueberlappungen, unklare Teamchip-Texte oder zu lange ACT-Zeilen zeigt, braucht es danach einen gezielten Visual-Polish-Slice.
- Networking bleibt serverautoritative Runtime-Wahrheit; der neue Snapshot ist nur Diagnose und Berichtsfutter.
