# TASK_192 - Mission Map NPC Behavior Playability Smoke

## Ziel
Nach den Einzelpatches fuer Mission Map und NPC-Verhalten soll ein integrierter Smoke pruefen, ob der eigentliche Spielablauf zusammenhaengt: Units sind da, halten Abstand, bewegen sich lesbar, Medics heilen nur benachbart, Waffen sitzen richtig, Area-Befehle geben klares Feedback.

Der Task ist ein Abschluss-Gate fuer die Reihe TASK_186 bis TASK_191.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_186 - Mission Map Unit Presence and Registry Audit
- TASK_187 - NPC Minimum Spacing and Multiplayer Authority
- TASK_188 - Fireteam Advance Styles Map Readability
- TASK_189 - Medic Adjacent Tile Healing Rule
- TASK_190 - Weapon Visual Loadout Expansion and Scale
- TASK_191 - Command Chain Selection and Area Feedback Pass

## Umfang
1. Integrierter Mission-Run:
   - Mission starten.
   - Friendlys deployen.
   - Enemy-Wave aktivieren.
   - Fireteam auswaehlen.
   - Move/Defend/Take/Engage Area ausfuehren.
   - Bounding oder Caterpillar ueber mehrere Tiles ablaufen lassen.
   - Kontakt herstellen.
   - Medic-Fall mit benachbartem und zu weitem Ziel pruefen.
2. Einheitliche Snapshots:
   - Unit-Presence.
   - Minimalabstand.
   - Advance-Style.
   - Area-Status.
   - Medic-Support.
   - Weapon-Visuals.
   - Multiplayer-Snapshot.
3. Sichtcheck-Punkte:
   - NPCs stapeln nicht.
   - Karte ist nicht mit Text ueberladen.
   - #16/#17/#18 zeigen kurze, richtige Zustandsinformationen.
   - Grosse Waffen sind nicht absurd skaliert.
4. Regressionen:
   - Bestehender `task_160_tactical_playability_verifier.gd` bleibt gruen.
   - Multiplayer-Snapshot-Contract bleibt gruen.

## Nicht-Ziele
- Keine neuen Features.
- Keine neuen Waffenwerte.
- Kein neues UI-Design.
- Keine neue KI.

## Akzeptanzkriterien
- [x] Der integrierte Smoke laeuft durch Mission Start, Deploy, Area Order, Movement, Contact und Medic-Fall.
- [x] Friendly- und Enemy-NPCs sind registriert, sichtbar und nicht doppelt.
- [x] Mindestabstand wird im Run vor Command-Execution eingehalten und Snapshot-seitig diagnostiziert.
- [x] Bounding/Caterpillar ist im Snapshot und auf der Map lesbar.
- [x] Medic heilt nur auf Nachbar-Tile und bewegt sich bei groesserer Distanz.
- [x] Waffenvisuals sind vorhanden oder melden Missing-Asset sauber.
- [x] #16/#17/#18 und Map-Overlay widersprechen sich nicht.

## Erwartete Dateien
- `scripts/tests/task_192_mission_map_npc_behavior_playability_smoke.gd`
- bestehende Verifier aus TASK_186 bis TASK_191
- `docs/tasks/TASK_192_mission_map_npc_behavior_playability_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_192_mission_map_npc_behavior_playability_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_168_multiplayer_snapshot_contract_verifier.gd`
- [ ] Manueller Mission-Map-Sichtcheck des gesamten Ablaufs.
- [x] `git diff --check`

## Umsetzung
- `scripts/tests/task_192_mission_map_npc_behavior_playability_smoke.gd` startet die Live-Testmission, staged das Dropship, deployed BLUE, aktiviert die zweite Enemy-Wave und auditiert UnitRegistry, Tactical-/Combat-Presence, 2.5D-Proxies und Multiplayer-Snapshots in mehreren Phasen.
- Der Smoke baut Move/Defend/Take-Waypoints plus Engage-/Defend-Areas, setzt eine cautious-Stance fuer Bounding/Caterpillar-Lesbarkeit, fuehrt GO aus und prueft Movement-Style-Snapshots, kompakte Map-Labels, Area-Feedback und #16/#17/#18-Snapshots.
- Der Medic-Fall laeuft in derselben Mission mit live positionierten Friendlys: benachbarter Patient erzeugt Heal, ein zwei Tiles entfernter Patient erzeugt nur einen Move-to-neighbor-Tile.
- Fuer TASK_190-Absicherung werden zwei live Friendlys temporaer auf `sniper` und `rocket_launcher` gesetzt und der 2.5D-Visual-Snapshot auf Loadout-/Attachment-Fehler geprueft.

## Risiken
- Ein grosser Smoke kann Fehler nur finden, nicht gut lokalisieren. Deshalb bleibt er Abschluss-Gate und ersetzt nicht die Einzelverifier.

## Naechster Schritt
Nach TASK_192 ist die Mission Map bereit fuer weitere taktische Tiefe oder Multiplayer-Playtests.
