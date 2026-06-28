# TASK_525 - Team Badge / Spawn Readability Polish

## Ziel / Problem
TASK_523 zeigt Alpha/Bravo-/NPC-/Peer-Besitz als Textzeile in der Lobby. Fuer schnelles Erfassen vor einem Multiplayer- oder Coop-Test fehlen aber farbige Team-Badges und sichtbare Spawn-Hinweise.

## Sinnhaftigkeit / Ursache
Der Spieler soll vor Missionsstart ohne Lesen langer Assignment-Listen erkennen, welches Team er kontrolliert, wem Bravo gehoert und an welchem Spawn-Marker die Seite startet. Das macht den PvP-/Coop-Setup-Flow lesbarer und bereitet spaetere Briefing-/Mission-HUD-Teamchips vor.

## Umfang
- Team-Ownership-Readability um Badge- und Spawn-Chip-Texte erweitern.
- Produktive Multiplayer-Lobby rendert Alpha/Bravo-Badges aus dem read-only Team-Readability-Snapshot.
- Lobby-UI-Snapshot expose't Badge-Text, Badge-Anzahl und Badge-Daten fuer Tests.
- Verifier prueft Contract-Felder, PvP-Badges und Spawn-Marker.

## Nicht-Ziele
- Kein neues Briefing-Fenster.
- Kein Mission-HUD-Rewrite.
- Keine Gameplay-Mutation im UI.
- Keine finalen Icons oder Art-Direction.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_523_pvp_team_readability_ui_pass.md`
- `docs/tasks/TASK_520_multiplayer_team_ownership_smoke.md`
- `docs/dev/multiplayer_session_lobby.md`
- `docs/dev/mission_briefing_contract.md`
- `docs/dev/html_report_workbench_contract.md`

## Akzeptanzkriterien
- Team-Readability-Eintraege enthalten `badge_text`, `spawn_chip_text`, `spawn_marker_id` und `team_color_hex`.
- Produktive Lobby zeigt mindestens zwei Team-Badges fuer Alpha und Bravo.
- PvP-Badge-Text enthaelt Alpha/Host, Bravo/Peer 2 und die Spawnmarker `spawn_alpha` / `spawn_bravo`.
- UI-Snapshot bleibt read-only und fuehrt keine Gameplay-Wahrheit ein.
- TASK_523- und TASK_520-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/mission/mission_multiplayer_team_ownership_contract.gd`
- `scripts/ui/multiplayer_lobby_screen.gd`
- `scenes/ui/multiplayer_lobby.tscn`
- `scripts/tests/task_525_team_badge_spawn_readability_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_525_team_badge_spawn_readability_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_523_pvp_team_readability_ui_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_520_multiplayer_team_ownership_smoke.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Badges sind einfache Labels, keine finalen Icons.
- Briefing-Minimap-Overlays und Mission-HUD-Teamchips bleiben als separater TASK_526-Anschluss sinnvoll.

## Status: IMPLEMENTIERT
