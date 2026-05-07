# TASK_240 - Multiplayer Player Roster Ownership Contract

## Ziel
Multiplayer braucht einen klaren Vertrag, wem welches Roster gehoert und welche Character-Daten Host, Join und andere Spieler sehen duerfen. Singleplayer und Multiplayer sollen dasselbe Character-Gameplay nutzen koennen, ohne Save-/Privacy-Chaos.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_167 - Multiplayer Session and Lobby Extraction
- TASK_168 - Multiplayer Snapshot Replication Contract
- TASK_221 - Multiplayer Snapshot Serialization Performance Pass
- TASK_227 - Main Menu Multiplayer Host Join Lobby Flow
- TASK_234 - Persistent Player Roster Save and Reset
- TASK_239 - Character Gameplay Bubble Mission Integration

## Kontext
Der User will individuelle Teams auch im Multiplayer. Das kann heissen: Jeder bringt sein Roster mit, der Host stellt ein Szenario-Roster, oder ein Modus mischt beides. Ohne Vertrag werden Save-Daten, Peer-Zuweisung, Fireteams und Snapshot-Daten unklar.

## Umfang
1. Roster-Modi:
   - `host_roster`: Host stellt alle NPCs.
   - `player_rosters`: jeder Peer bringt eigenes Roster/Fireteam.
   - optional `scenario_roster`: Map/Szenario stellt fixe NPCs.
2. Besitz:
   - NPC gehoert Peer, Host oder Szenario.
   - Peer darf nur eigene Roster-Details verwalten.
   - Host bleibt authority fuer laufende Mission.
3. Datenfreigabe:
   - Oeffentlich: Name, Callsign, Rolle, Portrait, Fireteam, grobe Badges.
   - Privat/lokal: volle Progression, Beziehung, Frustdetails, Save-Seed, interne Events.
   - Mission-relevant: nur berechnete Modifikatoren/Snapshots.
4. Lobby:
   - Host waehlt Roster-Modus.
   - Join sieht, ob eigenes Roster genutzt wird.
   - Missing Portrait/Asset-Fallbacks.
5. Snapshot:
   - Unit-Snapshot enthaelt owner_peer_id/roster_source, aber keine vollen privaten Profile.
   - CharacterGameplayResolver laeuft authority-seitig.
6. Verifier:
   - Host roster vs player rosters.
   - Join kann eigenes Fireteam zuweisen.
   - Client erhaelt keine privaten Daten anderer Spieler.

## Nicht-Ziele
- Kein Accountsystem.
- Kein Cloud-Sync.
- Kein Anti-Cheat.
- Kein Cross-Client-Save-Transfer.

## Akzeptanzkriterien
- [x] Multiplayer-Roster-Modi sind dokumentiert und als IDs validierbar.
- [x] Units haben klare owner/source-Felder.
- [x] Lobby kann Roster-Modus strukturell anzeigen/waehlen.
- [x] Snapshot repliziert keine vollen privaten Roster-Daten.
- [x] Character-Gameplay bleibt server-authoritative.
- [x] Ein TASK_240-Verifier prueft Ownership, Privacy und Snapshot-Grenzen.

## Erwartete Dateien
- `docs/dev/multiplayer_player_roster_ownership_contract.md`
- `scripts/multiplayer/multiplayer_roster_contract.gd`
- `scripts/multiplayer/multiplayer_session.gd`
- `scripts/multiplayer/multiplayer_snapshot_contract.gd`
- `scripts/meta/player_roster_store.gd`
- `scripts/tests/task_240_multiplayer_player_roster_ownership_contract.gd`
- `docs/tasks/TASK_240_multiplayer_player_roster_ownership_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_240_multiplayer_player_roster_ownership_contract.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_168_multiplayer_snapshot_contract_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_227_main_menu_multiplayer_host_join_lobby_flow.gd`
- [x] `git diff --check`

## Risiken
- Zu viel private Character-Info im Snapshot kann Multiplayer spaeter unnoetig schwer und unsauber machen.
- Zu wenig Info im Lobby-UI macht Teamwahl unverstaendlich.

## Umsetzung
- `MultiplayerRosterContract` validiert `host_roster`, `player_rosters` und `scenario_roster`, erzeugt Peer-/Unit-Ownership und strippt private Roster-Felder.
- `MultiplayerSession` fuehrt `roster_mode`, `peer_rosters` und einen Lobby-Snapshot mit public/private Field-Policy.
- `MultiplayerSnapshotContract` repliziert `owner_peer_id`, `roster_source`, `roster_mode`, `roster_public_ref` und `character_gameplay_authority`, ohne volle Profile zu kopieren.
- `PlayerRosterStore` erzeugt public-safe Roster-Previews; die Lobby kann den Modus strukturell anzeigen und als Host vor Missionsstart wechseln.

## Naechster Schritt
TASK_241 fasst Character-Gameplay als Playability-Smoke zusammen.
