# TASK_281 - Tactical Command Multiplayer Authority Snapshot

## Ziel
Die neuen taktischen Command-, Plan-, Ausbruch-, Kommunikations- und Air-Asset-Zustaende muessen multiplayerfaehig und authority-sauber werden. Clients duerfen planen und anzeigen, aber keine Gameplay-Wahrheit setzen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_166 - Multiplayer Authority Command Contract
- TASK_168 - Multiplayer Snapshot Contract
- TASK_169 - Multiplayer Two-Client Playability Smoke
- TASK_240 - Multiplayer Player Roster Ownership Contract
- TASK_270 - Commander to Fireteam Leader Delegation Contract
- TASK_276 - Tactical Breakout and Exception Behavior
- TASK_277 - Dropship Freighter Anti Armor Threat Contract
- TASK_280 - Tactical Profile Editor Scenario Authoring

## Kontext
Taktikplanung erzeugt viele neue Felder: Intent, Planrolle, Phase, FTL-Antwort, Ausbruch, AirAssetThreat, Debrief-Folge. Das muss sauber in den bestehenden Server-/Snapshot-Vertrag passen.

## Umfang
1. Command-Whitelist:
   - CommanderIntent erlauben.
   - Role override erlauben, wenn Spieler Rechte hat.
   - Ausbruch-Confirm/Abort/Regroup erlauben.
   - Air/LZ-Commands mit Role-/Authority-Pruefung.
2. Snapshot:
   - FireteamPlanStatus.
   - CommunicationEvents.
   - TacticalRules.
   - BreakoutState.
   - AirAssetStatus.
3. Privacy/Ownership:
   - Character-Skill nur soweit noetig.
   - FTL-Skill-Wirkung sichtbar, private Details begrenzen.
4. Deduplizierung:
   - Kommunikation, VFX/SFX und Air-Explosion nicht doppelt lokal/clientseitig ausloesen.
5. Verifier:
   - Host/Client-Simulation.
   - Verbotene State-Mutation abgelehnt.
   - Snapshot klein und stabil sortiert.

## Nicht-Ziele
- Kein echtes Online-Matchmaking.
- Keine Lag-Kompensation.
- Keine komplexe Rollback-Simulation.

## Akzeptanzkriterien
- [x] Neue taktische Commands sind whitelisted oder bewusst verboten.
- [x] Clients koennen Planstatus sehen, aber nicht SimulationRoot-State mutieren.
- [x] AirAssetStatus und BreakoutState werden autoritativ gespiegelt.
- [x] Kommunikation/VFX/SFX werden nicht doppelt abgespielt.
- [x] Snapshot bleibt klein und deterministisch sortiert.
- [x] Verifier prueft erlaubte und verbotene Client-Payloads.

## Erwartete Dateien
- `scripts/multiplayer/multiplayer_command_contract.gd`
- `scripts/multiplayer/multiplayer_snapshot_contract.gd`
- `scripts/tests/task_281_tactical_command_multiplayer_authority_snapshot.gd`
- `docs/dev/tactical_multiplayer_authority_snapshot.md`
- `docs/tasks/TASK_281_tactical_command_multiplayer_authority_snapshot.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_281_tactical_command_multiplayer_authority_snapshot.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_168_multiplayer_snapshot_contract_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_169_multiplayer_two_client_playability_smoke.gd`
- [x] `git diff --check`

## Risiken
- Zu viele Snapshot-Felder koennen Performance und Netzlast erhoehen.
- Clientseitige Preview darf nicht mit autoritativer Ausfuehrung verwechselt werden.

## Naechster Schritt
Nach TASK_281 schliesst TASK_282 die ganze Tactical-Overhaul-Reihe mit Playability, Performance und Hilfe ab.
