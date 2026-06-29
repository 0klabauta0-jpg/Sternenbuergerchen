# TASK_555 - Frontier Probe Multiplayer Objective Ownership Smoke

## Status: IMPLEMENTIERT

## Ziel / Problem
Der integrierte Frontier-Probe-Ablauf ist gruen, aber derselbe AA-/Computer-/Cargo-Slice muss auch gegen Alpha/Bravo-, NPC- und Peer-Ownership abgesichert werden.

## Sinnhaftigkeit / Ursache
Das Szenario soll solo, coop und PvP-ready bleiben. Wenn Alpha/Bravo-Ownership, Spawnmarker, NPC-Defaults oder Objective-Gates auseinanderlaufen, wirkt die Mission im Briefing/HUD zwar plausibel, aber Host/Client- oder NPC-Besitz kann spaeter falsche Befehle, falsche Zielzustaende oder widerspruechliche Anzeigen erzeugen.

## Umfang
- Read-only Snapshot `get_frontier_probe_multiplayer_objective_ownership_snapshot()`.
- Kombination aus integriertem TASK_554-Objective-Smoke, `MissionMultiplayerTeamOwnershipContract`, Mission-Team-Chip und Frontier-Probe-Scenario-Daten.
- Headless-Smoke fuer:
  - Alpha als player-assignable attacker auf `spawn_alpha`.
  - Bravo als solo/coop NPC-defender auf `spawn_bravo`, aber PvP-assignable.
  - PvP-Zuordnung Alpha -> Host Peer 1, Bravo -> Peer 2.
  - Computer/Cargo-Gates am Alpha-Pfad.
  - Bravo-Air-Defense als AA-Gegenseite.
- Rolling-HTML-Bericht wird auf TASK_555 aktualisiert und nennt TASK_556 als naechsten Host/Client-Anschluss.

## Nicht-Ziele
- Kein echter Netzwerk-Host/Client-Lauf.
- Kein neues Ownership-System.
- Kein Combat-, Objective- oder Cargo-Rewrite.
- Keine UI-seitige Gameplay-Wahrheit.
- Kein manueller F6-Sichttest.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_554_frontier_probe_integrated_objective_playthrough_smoke.md`
- `docs/tasks/TASK_520_multiplayer_team_ownership_smoke.md`
- `docs/tasks/TASK_526_mission_hud_team_chip_polish.md`
- `data/mission_scenarios/frontier_probe_vertical_slice.json`

## Akzeptanzkriterien
- Der integrierte Frontier-Probe-Slice bleibt gruen.
- Alpha/Bravo-Team-Slots sind im Vertical Slice vorhanden und widerspruchsfrei.
- Singleplayer behaelt Bravo als NPC-/Scenario-Team.
- PvP ordnet Alpha Host Peer 1 und Bravo Peer 2 zu.
- Mission-Team-Chip zeigt beide Owner und Spawnmarker.
- Objective-/Computer-/Cargo-Pfad gehoert zu Alpha; AA-Threat gehoert zu Bravo.
- Der Snapshot bleibt read-only.
- Der Verifier `scripts/tests/task_555_frontier_probe_multiplayer_objective_ownership_smoke.gd` laeuft gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_555_frontier_probe_multiplayer_objective_ownership_smoke.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_555_frontier_probe_multiplayer_objective_ownership_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_554_frontier_probe_integrated_objective_playthrough_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_526_mission_hud_team_chip_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Smoke beweist Ownership-Konsistenz in einer Headless-Testszene, aber noch keinen echten Host/Client-Lauf mit zwei Prozessen.
- Naechster sinnvoller Anschluss ist `TASK_556 - Frontier Probe Host Client Objective Handoff Smoke`.
