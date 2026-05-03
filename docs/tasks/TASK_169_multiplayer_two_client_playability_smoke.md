# TASK_169 - Multiplayer Two-Client Playability Smoke

## Ziel
Ein minimaler Zwei-Client-Smoke prueft den kompletten Multiplayer-V1-Pfad lokal: Host, Join, Missionstart, Client-Befehl, Server-Validation, Snapshot-Anzeige und Missionsergebnis.

## Status: IMPLEMENTIERT

## Ergebnis
- `scripts/tests/task_169_multiplayer_two_client_playability_smoke.gd` prueft einen lokalen Host+Client-Commander-State-Smoke mit Peer-IDs `1` und `2`.
- Der Host startet eine Session mit ready Host und ready Client; Peer `2` erhaelt fuer den Smoke Team `team_bravo`, Rolle `commander` und Fireteam `red`.
- Ein erlaubter Client-Move wird serverseitig ueber `SimulationRoot.submit_network_command_for_peer()` validiert, gequeued und verarbeitet.
- Ein ungueltiger Client-Payload mit verbotenem State-Key wird abgelehnt und im Command-Debug gezaehlt.
- Der Client wendet einen Server-Snapshot mit Unit-Bewegung, Objective, Contact und `mission_result` als read-only Spiegelung an.
- `docs/manual_checks/multiplayer_two_client_playability_smoke.md` dokumentiert den manuellen Zwei-Instanzen-Ablauf mit konfigurierbarem Port.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/tasks/TASK_166_multiplayer_authority_command_contract.md`
- Lies `docs/tasks/TASK_167_multiplayer_session_lobby_extraction.md`
- Lies `docs/tasks/TASK_168_multiplayer_snapshot_replication_contract.md`
- Lies `docs/reviews/strategic_review_ui_assets_multiplayer_2026_05_03.md`
- Pruefe den Git-Status

## Kontext
- TASK_160 beweist den Singleplayer-/Live-Mini-Loop.
- Multiplayer braucht einen eigenen Playability-Smoke, bevor weitere Online-Features sinnvoll sind.
- V1 soll kein persistentes PvP und kein Matchmaking sein.

## Umfang
1. Test-Szenario festlegen:
   - kleine bestehende Mission/Scenario-Datei
   - zwei Peers lokal
   - ein Fireteam pro Peer oder Host+Client-Commander-Setup
2. Flow pruefen:
   - Host startet Session
   - Client joint
   - Server startet Mission
   - Client sendet erlaubten Move/Defend/Take oder Area-Command
   - Server validiert und verarbeitet
   - Client sieht Snapshot-Fortschritt
   - Missionsergebnis wird reliable gespiegelt
3. Debug-Snapshot sammeln:
   - peer ids
   - accepted/rejected commands
   - last server tick
   - last client snapshot tick
   - missing remote units

## Nicht-Ziele
- Kein Online-Matchmaking.
- Kein Lag-Compensation-System.
- Kein Balance-Test.
- Kein neuer Spielmodus.

## Architekturregeln
- Test darf keine UI-Wahrheit akzeptieren.
- Server ist authoritativ.
- Client-Visuals duerfen interpolieren, aber nicht simulieren.

## Akzeptanzkriterien
- Zwei lokale Instanzen koennen eine Mini-Mission sichtbar starten.
- Mindestens ein Client-Command wird serverseitig akzeptiert und sichtbar repliziert.
- Ein ungueltiger Command wird abgelehnt.
- Mission result wird reliable gespiegelt.
- Testdokumentation beschreibt manuellen Ablauf, falls vollautomatischer Zwei-Prozess-Test zu fragil ist.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_169_multiplayer_two_client_playability_smoke.gd`
- [x] Neuer Multiplayer-Smoke und manuelle Checkliste unter `docs/manual_checks/`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_167_multiplayer_session_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_166_multiplayer_authority_command_contract_verifier.gd`
- [x] `git diff --check`
- [ ] Manueller Zwei-Instanzen-Test mit konfigurierbarem Port wurde dokumentiert, aber in diesem Headless-Durchlauf nicht ausgefuehrt.

## Risiken
- Automatisierte Godot-Zwei-Prozess-Tests koennen lokal fragil sein. Ein kleiner State-Verifier plus manuelle Checkliste ist fuer V1 akzeptabel.
- Netzwerk-Fehler muessen sichtbar im Debug-Snapshot landen.
