# TASK_526 - Mission HUD Team Chip Polish

## Ziel / Problem
TASK_525 macht Alpha/Bravo-Besitz und Spawnmarker in der Lobby sichtbar. Nach dem Missionsstart fehlt dieselbe Information im laufenden Mission-HUD, obwohl `SimulationRoot` die Peer-Team-Zuordnung bereits als autoritativen Snapshot liefert.

## Sinnhaftigkeit / Ursache
Solo, Coop und PvP sollen im laufenden Missionsbild nicht wieder unklar werden. Der Spieler soll sehen, ob Alpha vom Host, Bravo von Peer 2 oder vom Szenario/NPC kontrolliert wird, ohne die Lobby im Kopf behalten zu muessen.

## Umfang
- Default-Team-Readability-Slice in den bestehenden `MissionMultiplayerTeamOwnershipContract` ziehen.
- Kleinen read-only `MissionTeamChipPresenter` fuer Mission-HUD-Chips bauen.
- Mission-HUD ergaenzt ein kompaktes Teamchip-Label im bestehenden Strategic-HUD.
- Playability-/Command-Snapshot exposed Teamchip-Text und Chip-Daten fuer Verifier.
- Laufenden HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Keine neue Multiplayer-Autoritaet.
- Keine Gameplay-Mutation im HUD.
- Keine finalen Icons oder Minimap-Spawn-Overlays.
- Kein Mission-HUD-Rewrite.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_525_team_badge_spawn_readability_polish.md`
- `docs/tasks/TASK_523_pvp_team_readability_ui_pass.md`
- `docs/tasks/TASK_520_multiplayer_team_ownership_smoke.md`
- `docs/dev/multiplayer_session_lobby.md`
- `docs/dev/html_report_workbench_contract.md`

## Akzeptanzkriterien
- Mission-Teamchip-Snapshot hat `ui_sets_gameplay_truth == false`.
- Bei Peer-Assignment `1 -> team_alpha`, `2 -> team_bravo` zeigt das Mission-HUD Alpha/Host Peer 1 und Bravo/Peer 2.
- Spawnmarker `spawn_alpha` und `spawn_bravo` bleiben im Snapshot sichtbar.
- Lobby-Team-Badge-Regression bleibt gruen.
- Kein per-frame Control-Tree-Rebuild; das Label wird einmal erzeugt und im bestehenden HUD-Refresh aktualisiert.

## Betroffene Dateien
- `scripts/mission/mission_multiplayer_team_ownership_contract.gd`
- `scripts/multiplayer/multiplayer_session.gd`
- `scripts/mission/mission_team_chip_presenter.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_526_mission_hud_team_chip_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_526_mission_hud_team_chip_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_525_team_badge_spawn_readability_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_523_pvp_team_readability_ui_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Mission-Teamchips sind einfache Textlabels. Finales Icon-Polish und Briefing-Minimap-Spawn-Overlays bleiben Folgearbeit.

## Status: IMPLEMENTIERT
