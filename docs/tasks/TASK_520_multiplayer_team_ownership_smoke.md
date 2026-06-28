## Status: IMPLEMENTIERT

# TASK_520 - Multiplayer Team Ownership Smoke

## Ziel / Problem
Der Frontier-Probe-Slice ist fuer Singleplayer, Coop und `multiplayer_pvp` gedacht. Nach TASK_517 bis TASK_519 gab es aber noch eine Ownership-Reibung: `team_bravo` war im Scenario als `npc_owned: true` markiert, waehrend der bestehende Multiplayer-Lobby-Smoke Peer 2 standardmaessig `team_bravo` zuordnet.

## Sinnhaftigkeit / Ursache
Solo/Coop braucht Bravo als NPC-Verteidiger. PvP braucht dagegen eine lesbare, host-authoritative Team-Zuordnung, in der Peer 2 Bravo kontrollieren darf, ohne private Roster-Daten oder UI-Gameplay-Wahrheit zu replizieren. Dieser Unterschied muss als Scenario-/Mission-Contract ausdrueckbar sein, nicht als Sonderfall im HUD.

## Umfang
- Team-Slots koennen `player_assignable_modes` tragen.
- Kleiner Mission-Contract baut einen Team-Ownership-Snapshot aus Vertical-Slice-Team-Slots und MultiplayerSession-Assignments.
- Multiplayer-Roster-Defaults bleiben privacy-sicher `host_roster`; `player_rosters` ist weiterhin explizit waehlbar.
- Smoke prueft:
  - Singleplayer/Coop: Alpha Spieler, Bravo NPC.
  - PvP: Host/Peer-Zuweisung Alpha/Bravo ist gueltig.
  - Nicht erlaubte Peer-Zuweisungen auf NPC-Teams werden erkannt.
- Roster-/Peer-Ownership bleibt host-authoritative und public-safe.
- Bestehender Roster-Ownership-Contract bleibt gruen.

## Nicht-Ziele
- Kein echter Zwei-Instanzen-LAN-Test.
- Kein Matchmaking.
- Kein Persistenz- oder Roster-Save-Rewrite.
- Keine Aenderung am Combat-/Command-Authority-Pfad.

## Relevante Contracts / Dokumente
- `docs/dev/multiplayer_session_lobby.md`
- `docs/dev/multiplayer_player_roster_ownership_contract.md`
- `docs/dev/combat_loop_authority_contract.md`
- `docs/tasks/TASK_517_mission_scenario_vertical_slice.md`
- `docs/tasks/TASK_519_cargo_touchdown_runtime_bridge.md`

## Akzeptanzkriterien
- `frontier_probe_vertical_slice` deklariert, dass Bravo im PvP einem Peer zuweisbar ist, obwohl Bravo solo/coop NPC-besetzt bleibt.
- Ein Contract-Snapshot zeigt fuer PvP Host/Alpha und Peer2/Bravo eindeutig.
- Singleplayer/Coop behandelt Bravo weiter als NPC-Team.
- Ungueltige Peer-Zuweisung auf ein nicht assignable NPC-Team wird als Fehler gemeldet.
- UI und Lobby bleiben Setup-/Snapshot-Leser; Gameplay-Mutationen laufen nicht in diesem Task.

## Betroffene Dateien
- `data/mission_scenarios/frontier_probe_vertical_slice.json`
- `scripts/mission/mission_scenario_vertical_slice_contract.gd`
- `scripts/mission/mission_multiplayer_team_ownership_contract.gd`
- `scripts/multiplayer/multiplayer_roster_contract.gd`
- `scripts/multiplayer/multiplayer_session.gd`
- `scripts/tests/task_520_multiplayer_team_ownership_smoke.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_520_multiplayer_team_ownership_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_517_mission_scenario_vertical_slice.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_167_multiplayer_session_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_240_multiplayer_player_roster_ownership_contract.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der echte Host/Join-LAN-Test mit zwei Godot-Instanzen bleibt manuell.
- PvP-UI-Polish, Teamfarben und In-Mission-Besitzanzeigen sind Folgearbeit.
