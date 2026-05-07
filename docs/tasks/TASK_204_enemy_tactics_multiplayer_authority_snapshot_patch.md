# TASK_204 - Enemy Tactics Multiplayer Authority Snapshot Patch

## Ziel
Enemy-Taktik, Waffenreichweite, Facing, Security und Fire-Events sollen multiplayer-sicher werden: Die Entscheidung liegt authority-seitig, Clients zeigen nur Snapshots und VFX an.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_166 - Multiplayer Authority Command Contract
- TASK_168 - Multiplayer Snapshot Replication Contract
- TASK_186 - Mission Map Unit Presence and Registry Audit
- TASK_187 - NPC Minimum Spacing and Multiplayer Authority
- TASK_200 - Enemy Team Tactics Contract and Editor Config
- TASK_201 - Weapon Range Scale and Tile Distance Patch
- TASK_202 - Enemy Security Direction and LOS Patch
- TASK_203 - Enemy Cover Advance and Team Tactics Patch

## Kontext
Enemy-KI ist besonders riskant fuer Multiplayer, weil Clients sonst unterschiedliche Gegnerpositionen, Fire-Entscheidungen oder Facing-Winkel sehen koennen. Der Task zieht eine harte Grenze: Enemy-Taktik entscheidet nur der autoritative Runtime-Pfad. Snapshots transportieren sichtbare Ergebnisse.

## Umfang
1. Authority-Grenze:
   - Enemy-Commands, Move-Ziele, Cover-Wechsel, Security-State und Fire-Events entstehen authority-seitig.
   - Client-/Viewer-Pfade duerfen keine Enemy-Entscheidungen nachbauen.
2. Snapshot-Felder:
   - Enemy team id, tactic profile, current tactic state.
   - Facing/Gefechtsrichtung, Security-Modus, Sektor oder knappe Diagnose.
   - Aktive Waffe und effektive Range als Anzeige.
   - Fire-event-IDs fuer VFX aus TASK_205.
3. Determinismus:
   - Entscheidungen, die Reihenfolge brauchen, sortieren nach stabiler Unit-ID oder Team-ID.
   - Keine Random-Nutzung ohne Seed/Authority-Kontext.
4. Konfliktfreiheit mit Mindestabstand:
   - Snapshot-Positionen liegen nach TASK_187-Separation vor.
   - Client erzeugt keine eigenen Visual-Korrekturen, die Gameplay-Positionen verdecken.
5. Verifier:
   - Authority-Snapshot enthaelt alle sichtbaren Enemy-Taktikfelder.
   - Client-Anwendung mutiert keine SimulationRoot-Commands/Effects.
   - Fire-event wird einmalig gespiegelt, nicht pro Client neu entschieden.

## Nicht-Ziele
- Keine echte Netzwerkverbindung.
- Keine Prediction.
- Kein Lag-Compensation-System.
- Keine Multiplayer-Lobbyarbeit.

## Akzeptanzkriterien
- [x] Enemy-Taktikentscheidungen laufen nur im authority-Pfad.
- [x] Multiplayer-Snapshot enthaelt Enemy-Facing, Security, Taktikstatus, Weapon/Range-Anzeige und Fire-event-Diagnose.
- [x] Snapshot-Anwendung erzeugt keine neuen Enemy-KI-Entscheidungen.
- [x] Mindestabstand wird vor Snapshot-Build angewendet.
- [x] Fire-/Muzzle-Events koennen von Clients angezeigt werden, ohne Combat neu auszuwerten.
- [x] Ein TASK_204-Verifier prueft Authority-Grenze, Snapshot-Felder und Determinismus.

## Erwartete Dateien
- `scripts/core/simulation_root.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/multiplayer/multiplayer_snapshot_contract.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_204_enemy_tactics_multiplayer_authority_snapshot_patch.gd`
- `docs/tasks/TASK_204_enemy_tactics_multiplayer_authority_snapshot_patch.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_204_enemy_tactics_multiplayer_authority_snapshot_patch.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_168_multiplayer_snapshot_contract_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_187_npc_minimum_spacing_and_multiplayer_authority.gd`
- [x] `git diff --check`

## Risiken
- Wenn VFX direkt Combat ausloest, wird Multiplayer spaeter nondeterministisch.
- Wenn Clients Enemy-Facing selbst berechnen, koennen Overwatch/Security-Anzeigen auseinanderlaufen.

## Naechster Schritt
Nach TASK_204 kann TASK_205 Muzzle-Flash-Particles sicher an Fire-Events haengen.
