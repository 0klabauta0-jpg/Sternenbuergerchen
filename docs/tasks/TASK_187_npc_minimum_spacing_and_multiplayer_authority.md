# TASK_187 - NPC Minimum Spacing and Multiplayer Authority

## Ziel
Friendly- und Enemy-NPCs sollen einen festen Minimalabstand einhalten und sichtbar nicht ineinander laufen. Der Abstand muss aus dem autoritativen Bewegungs-/Snapshot-Pfad kommen, nicht aus der 2.5D-Darstellung.

Der Task baut auf TASK_130 auf, prueft aber explizit beide Seiten: Spieler-NPCs, Gegner-NPCs, Spawn-/Deploy-Situationen, Bewegung, Combat, Respawn und Multiplayer-Snapshots.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_130 - Lokale Unit-Avoidance mit ORCA/RVO-Light
- TASK_160 - Tactical Mission Playability Smoke
- TASK_166 - Multiplayer Authority Command Contract
- TASK_168 - Multiplayer Snapshot Replication Contract
- TASK_186 - Mission Map Unit Presence and Registry Audit

## Kontext
Lokale Avoidance existiert bereits als Korrekturschicht unterhalb der Pfadfindung. Dieser Task macht daraus einen spielbaren Vertrag: Units duerfen auf der Mission Map nicht stapeln, weder friendly untereinander noch enemies untereinander noch friendly/enemy waehrend Kontakt oder Engpass.

## Umfang
1. Minimalabstandsvertrag:
   - Ein zentraler Mindestabstand fuer Runtime-Units definieren.
   - Abstand in Weltkoordinaten und, wenn TerrainRegistry vorhanden ist, sinnvoll auf Tile-Masse beziehen.
   - Der Wert muss fuer 2.5D-Modellscale und Gameplay-Lesbarkeit passen.
2. Spawn-/Deploy-Separation:
   - Friendly-Dropship-Deploy verteilt Units auf begehbare Nachbarpositionen statt auf denselben Punkt.
   - Enemy-Waves und Respawn verwenden denselben Abstand.
   - Wenn nicht genug Platz da ist: deterministische Fallback-Slots oder Wartestatus statt Stapeln.
3. Movement-Separation:
   - `LocalAvoidanceResolver`/`SimulationRoot` verhindern Ueberlappungen waehrend Pfadfolge.
   - Avoidance gilt fuer friendly und enemy Units.
   - Terrain-Sicherheit aus TASK_130 bleibt: keine Unit wird auf nicht-walkable Tiles geschoben.
4. Contact-/Combat-Separation:
   - Units duerfen beim Stoppen fuer Feuerkontakt nicht in andere Units hineinbremsen.
   - Downed/bleedout Units belegen weiterhin Raum oder haben eine dokumentierte kleine Kollisionshuelle.
5. Multiplayer-Grenze:
   - Minimalabstand wird server-/authority-seitig aufgelöst.
   - Multiplayer-Snapshot spiegelt Positionen, erfindet aber keine lokalen Client-Korrekturen.
   - Deterministische Sortierung nach Unit-ID oder Spawnreihenfolge fuer Konfliktaufloesung.
6. Verifier:
   - Spawn-Cluster.
   - Zwei kreuzende Fireteams.
   - Enemy-Wave in engem Bereich.
   - Friendly/enemy Kontaktstop.
   - Multiplayer-Snapshot nach Separation.

## Nicht-Ziele
- Kein kompletter Physik-Kollisionsumbau.
- Kein NavMesh-Rewrite.
- Keine Formation-Slot-KI.
- Keine clientseitige Prediction fuer Multiplayer.
- Keine rein visuelle 2.5D-Offset-Korrektur als Ersatz fuer Runtime-Positionen.

## Akzeptanzkriterien
- [x] Friendly-NPCs halten nach Deploy und waehrend Bewegung Mindestabstand.
- [x] Enemy-NPCs halten nach Spawn/Wave/Respawn und waehrend Bewegung Mindestabstand.
- [x] Friendly und enemy Units stapeln bei Kontaktstop nicht sichtbar.
- [x] Avoidance bewegt Units nicht auf nicht-walkable Tiles.
- [x] Downed Units werden im Abstandskonzept bewusst behandelt.
- [x] Multiplayer-Snapshots enthalten bereits getrennte autoritative Positionen.
- [x] Ein TASK_187-Verifier deckt Spawn, Bewegung, Engpass, Kontakt und Snapshot ab.

## Erwartete Dateien
- `scripts/core/simulation_root.gd`
- `scripts/tactical/local_avoidance_resolver.gd`
- `scripts/tests/mission_test_setup.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/multiplayer/multiplayer_snapshot_contract.gd`
- `scripts/tests/task_187_npc_minimum_spacing_and_multiplayer_authority.gd`
- `docs/tasks/TASK_187_npc_minimum_spacing_and_multiplayer_authority.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_187_npc_minimum_spacing_and_multiplayer_authority.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_130_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_168_multiplayer_snapshot_contract_verifier.gd`
- [x] `git diff --check`

## Ergebnis
- `SimulationRoot` erzwingt nach Commands und Effects einen autoritativen Mindestabstand fuer registrierte Runtime-Units. Der Abstand liegt vor Objective-Auswertung und Multiplayer-Snapshot an.
- `LocalAvoidanceResolver` hat eine deterministische Positions-Separation fuer registrierte Units bekommen. TerrainRegistry-Sicherheit verhindert Korrekturen auf nicht-walkable Tiles; blockierte Paare werden diagnostisch gemeldet.
- Downed/bleedout/respawning Units belegen im Abstandskonzept weiterhin Raum; der Debug-Snapshot dokumentiert `downed_units_keep_space`.
- `scripts/tests/task_187_npc_minimum_spacing_and_multiplayer_authority.gd` prueft Spawn-Cluster, Dropship-Deploy, Enemy-Wave-Cluster, kreuzende Friendlys, Friendly/Enemy-Kontaktstop, Downed-Units, Respawn und Multiplayer-Snapshot-Positionen.

## Risiken
- Zu starker Abstand kann Fireteams an Engpaessen blockieren. Der Task braucht Deadlock-Diagnose statt unsichtbarer Teleports.
- Ein reiner Visual-Offset wuerde Multiplayer spaeter brechen. Die autoritative Position muss getrennt sein.

## Naechster Schritt
Nach TASK_187 kann TASK_188 die Bewegungsmuster auf der Mission Map klar sichtbar machen, ohne dass Units ineinander laufen.
