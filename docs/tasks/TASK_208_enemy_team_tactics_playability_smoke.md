# TASK_208 - Enemy Team Tactics Playability Smoke

## Ziel
Die Enemy-Team-Tactics-Reihe soll in einem integrierten Missionslauf geprueft werden: Editor-Profil, Waffenreichweite, Enemy-Security, Deckung/Vorruecken, Multiplayer-Snapshot, Muzzle-Flash, orange Enemy-Visuals und Rank-/Skill-Badges.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_200 - Enemy Team Tactics Contract and Editor Config
- TASK_201 - Weapon Range Scale and Tile Distance Patch
- TASK_202 - Enemy Security Direction and LOS Patch
- TASK_203 - Enemy Cover Advance and Team Tactics Patch
- TASK_204 - Enemy Tactics Multiplayer Authority Snapshot Patch
- TASK_205 - Weapon Fire VFX Muzzle Flash Particles
- TASK_206 - Enemy Visual Faction Archetypes Orange Suit
- TASK_207 - NPC Rank Skill Badge Derivation

## Kontext
Die Einzel-Tasks pruefen jeweils klare Scheiben. Am Ende braucht es aber einen spielbaren Pass: Sieht man, wo Gegner hinschauen? Sind Reichweiten komprimiert? Kommen Gegner nicht ineinander? Ist Orange klar Gegner? Blitzt die Waffe beim Schuss? Bleiben Snapshots authority-sicher?

## Umfang
1. Testmission:
   - Kleine 32x32-Fixture mit Deckung, Huegel/Klippe/Sand, Enemy-Hold und Enemy-Push.
   - Optional 64x64-Fixture fuer Sniper-/Rifle-Range-Grenzen.
2. Editor-Roundtrip:
   - Enemy-Taktikprofil und Facing im Editor speichern/laden.
   - Mission-Testsetup liest dieselbe Konfiguration.
3. Combat-/Taktiklauf:
   - Friendly bewegt in Kontakt.
   - Enemy-Team haelt oder pusht je nach Profil.
   - Enemy-Security/Facing bleibt sichtbar.
   - Waffenreichweiten begrenzen Schuesse.
4. Visual-/VFX-Lauf:
   - Orange Enemy-Archetyp sichtbar.
   - Muzzle-Flash bei Friendly und Enemy-Schuss sichtbar.
   - Rank-/Skill-Badges sind in mindestens einem Meta-/Mission-Panel sichtbar.
5. Multiplayer-Snapshot:
   - Snapshot enthaelt Positionen nach Mindestabstand.
   - Enemy-Taktikfelder, Facing und Fire-Events werden gespiegelt.
   - Client-/Viewer-Pfad entscheidet keine Enemy-Taktik neu.
6. Manueller Sichtcheck:
   - Kurze Checkliste fuer 2.5D: Direction, Cover, Range, VFX, Badges, Orange Enemy.

## Nicht-Ziele
- Kein Ersatz fuer Einzelverifier.
- Kein kompletter Balance-Pass.
- Kein neuer Content-Pack.
- Kein grosser UI-Redesign-Pass.

## Akzeptanzkriterien
- [x] Ein integrierter TASK_208-Smoke startet eine Mission mit mindestens zwei Enemy-Profilen.
- [x] Enemy-Facing, Security und Taktikstatus sind im Snapshot/Overlay nachvollziehbar.
- [x] Waffenreichweiten verhindern offensichtlich zu weite Standardwaffen-Schuesse.
- [x] Enemy- und Friendly-Units halten Mindestabstand.
- [x] Muzzle-Flash wird durch Fire-Events angezeigt.
- [x] Orange Enemy-Archetyp und Friendly-Archetyp sind klar unterscheidbar.
- [x] Rank-/Skill-Badges werden aus NPC-Daten abgeleitet sichtbar.
- [x] Multiplayer-Snapshot-Anwendung bleibt side-effect-arm.

## Umsetzung
- `maps/enemy_tactics_smoke_32x32.json` ist eine kompakte 32x32-Fixture mit Sand, Hoehe/Slope, Cliff, walkable Cover und Markern fuer Alpha, Enemy-Hold, Enemy-Push und Objective.
- `scripts/tests/task_208_enemy_team_tactics_playability_smoke.gd` baut ein integriertes Szenario mit `guard_hold`, `defensive_cover` und `aggressive_push`; prueft Editor-Roundtrip, MissionTestSetup-Konfigurationslesung, Range-Limits, Enemy-Security, Cover/Push/Hold-Taktiken, Mindestabstand, Fire-Events, 2.5D-Render-Snapshots, Archetypen, Badges und Multiplayer-Snapshot-Side-Effects.
- `docs/dev/enemy_team_tactics_manual_smoke_checklist.md` dokumentiert den offenen manuellen 2.5D-Sichtcheck fuer Direction, Cover, Range, VFX, Badges und Orange/Friendly-Kontrast.

## Erwartete Dateien
- `scripts/tests/task_208_enemy_team_tactics_playability_smoke.gd`
- `maps/enemy_tactics_smoke_32x32.json`
- optional `maps/enemy_tactics_range_smoke_64x64.json`
- `docs/dev/enemy_team_tactics_manual_smoke_checklist.md`
- `docs/tasks/TASK_208_enemy_team_tactics_playability_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_208_enemy_team_tactics_playability_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_168_multiplayer_snapshot_contract_verifier.gd`
- [ ] Manueller Mission-Map-Sichtcheck anhand Checkliste.
- [x] `git diff --check`

## Risiken
- Ein integrierter Smoke kann Fehler schlechter lokalisieren als Einzeltests. Er soll nur die Reihe zusammenhalten.
- Wenn alle Visuals gleichzeitig laut werden, braucht es danach einen kleinen Lesbarkeitspass.

## Naechster Schritt
Nach TASK_208 kann die Reihe entweder in Balance/Polish gehen oder die naechsten Waffen-/Archetypenpakete aufnehmen.
