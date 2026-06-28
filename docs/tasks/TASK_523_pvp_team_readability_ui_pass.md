# TASK_523 - PvP Team Readability UI Pass

## Ziel / Problem
TASK_520 klaert technisch, welchem Peer Alpha/Bravo gehoeren und wann Bravo NPC-kontrolliert bleibt. Fuer den Spieler ist das im Lobby-/Setup-Pfad aber noch zu schlecht sichtbar.

## Sinnhaftigkeit / Ursache
Der Frontier-Probe-Slice soll singleplayer-, coop- und pvp-faehig bleiben. Wenn Alpha/Bravo-/NPC-Besitz nur im Contract existiert, sieht man beim Testen nicht sofort, ob man gerade gegen NPCs, zusammen gegen NPCs oder gegeneinander startet.

## Umfang
- Team-Ownership-Contract um read-only Anzeige-Felder erweitern.
- MultiplayerSession liefert eine kompakte Team-Readability-Summary aus den bestehenden Peer-Team-Assignments.
- Multiplayer-Lobby und Lobby-Testscreen zeigen die Summary sichtbar an.
- Verifier prueft Singleplayer/Coop/PvP-Lesbarkeit und UI-Snapshot.

## Nicht-Ziele
- Kein neues Multiplayer-Missionssystem.
- Keine Gameplay-Mutation im UI.
- Kein echter Zwei-Instanzen-LAN-Test.
- Keine finalen Team-Badges oder Art-Direction.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_520_multiplayer_team_ownership_smoke.md`
- `docs/dev/multiplayer_session_lobby.md`
- `docs/dev/multiplayer_player_roster_ownership_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `scripts/mission/mission_multiplayer_team_ownership_contract.gd`
- `scripts/multiplayer/multiplayer_session.gd`

## Akzeptanzkriterien
- Ownership-Snapshot enthaelt Teamfarben, Kurzlabel, Owner-/Control-Text und eine Summary.
- UI-Daten markieren weiter `ui_sets_gameplay_truth = false`.
- Lobby-Snapshot zeigt `PvP: Alpha -> Host Peer 1 | Bravo -> Peer 2` fuer Versus-Setup.
- Coop/Solo zeigen Bravo als NPC/Scenario-Kontrolle.
- Bestehender TASK_520-Smoke bleibt gruen.

## Betroffene Dateien
- `scripts/mission/mission_multiplayer_team_ownership_contract.gd`
- `scripts/multiplayer/multiplayer_session.gd`
- `scripts/ui/multiplayer_lobby_screen.gd`
- `scripts/tests/lobby_test_screen.gd`
- `scenes/ui/multiplayer_lobby.tscn`
- `scenes/tests/lobby_test.tscn`
- `scripts/tests/task_523_pvp_team_readability_ui_pass.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_523_pvp_team_readability_ui_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_520_multiplayer_team_ownership_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_167_multiplayer_session_verifier.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Anzeige ist noch textuell. Spaetere Team-Badges, Spawnkarten und Mission-HUD-Teamchips bleiben Folgearbeit.
- Der echte LAN-/WAN-Zwei-Instanzen-Test bleibt manuell.

## Status: IMPLEMENTIERT
