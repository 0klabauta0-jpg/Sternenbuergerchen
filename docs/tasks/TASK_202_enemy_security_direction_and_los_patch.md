# TASK_202 - Enemy Security Direction and LOS Patch

## Ziel
Enemy-Teams sollen eigene Sicherungszustaende bekommen: 360-Grad-Sicherung, gerichtete Gefechtsrichtung, Sichtlinien und Winkel. Diese Zustaende muessen sichtbar und gameplay-relevant sein, ohne Friendly-Systeme nur halb zu spiegeln.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_111 - Fireteam Security Direction and Overwatch
- TASK_113 - Flank Vulnerability Contract
- TASK_160 - Tactical Mission Playability Smoke
- TASK_200 - Enemy Team Tactics Contract and Editor Config
- TASK_201 - Weapon Range Scale and Tile Distance Patch

## Kontext
Friendly-Fireteams besitzen bereits Security/Overwatch-Logik. Gegner nutzen aber derzeit keine gleichwertige eigene Security-Seite. Dadurch gibt es keine klare gegnerische Gefechtsrichtung, keine enemy-seitige 360-Sicherung und keine sauber sichtbare Richtung, aus der Gegner sichern oder flankierbar sind.

Dieser Task macht Enemy-Security symmetrisch genug fuer Taktik, aber klein genug fuer den aktuellen Missionsloop.

## Umfang
1. Enemy-Security-State:
   - Pro Enemy-Team/Gruppe: `security_mode`, `facing_angle`, `sector_width`, `watched_tiles` oder vergleichbarer Snapshot.
   - `360` fuer Hold/Guard oder hohe Alertness.
   - `directional` fuer Push/Patrol/Objective-Fokus.
   - Defaults kommen aus TASK_200-Profilen.
2. Facing und Rotation:
   - Gegner drehen sichtbar in Marschrichtung, Gefechtsrichtung oder Richtung letzter Kontaktmeldung.
   - Rotation bleibt Anzeige + Combat-Snapshot, nicht clientseitige KI.
3. Sichtlinie und Winkel:
   - LOS, Terrain-Hoehe und Cover aus bestehenden Systemen verwenden.
   - Waffenreichweite aus TASK_201 begrenzt den Fire-/Watch-Sektor.
   - Security-Sektor darf nicht durch harte Blocker oder Klippen schauen.
4. Flankbarkeit:
   - Enemy-Teams koennen anhand ihrer Security-Richtung flankierbar werden.
   - 360-Sicherung schuetzt besser, aber nicht kostenlos dauerhaft fuer jedes Profil.
5. Mission Map:
   - Debug-/Gameplay-Overlay kann enemy Facing, Sektor oder kurzer Pfeil anzeigen.
   - Anzeige ist knapp und verdeckt Units nicht.
6. Verifier:
   - Directional Enemy wird seitlich/rear flankierbar.
   - 360 Enemy blockt Flankbonus.
   - LOS durch Wand/Huehe blockiert.
   - Reichweiten-Sektor endet nach Waffenrange.

## Nicht-Ziele
- Kein grosses Wahrnehmungs- oder Stealth-Rework.
- Kein neuer Renderer fuer Fog of War.
- Kein permanentes UI-Tutorial.
- Keine perfekte MilSim-Taktik.

## Akzeptanzkriterien
- [x] Enemy-Teams haben einen eigenen Security-Snapshot.
- [x] Enemy Facing/Gefechtsrichtung ist aus Profil, Bewegung oder Kontakt ableitbar.
- [x] LOS und Waffenreichweite begrenzen enemy-seitige Watch-/Fire-Sektoren.
- [x] Enemy-Units koennen anhand des Security-Sektors flankierbar sein.
- [x] 360-Sicherung ist explizit und testbar, nicht implizit fuer alle Gegner aktiv.
- [x] Mission Map kann die Richtung knapp sichtbar machen.
- [x] Ein TASK_202-Verifier prueft Directional, 360, LOS-Blocker, Range und Flankbarkeit.

## Erwartete Dateien
- `scripts/tactical/fireteam_security_controller.gd`
- `scripts/tactical/enemy_team_tactics_profile.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_202_enemy_security_direction_and_los_patch.gd`
- `docs/tasks/TASK_202_enemy_security_direction_and_los_patch.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_202_enemy_security_direction_and_los_patch.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_111_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_113_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_184_gameplay_hill_semantics_verifier.gd`
- [ ] Manueller 2.5D-Sichtcheck fuer Enemy-Facing und Sektorlesbarkeit.
- [x] `git diff --check`

## Risiken
- Enemy-Security darf nicht als zweite Friendly-Security mit falschen Teamannahmen kopiert werden.
- Zu grosse Sektor-Overlays koennen die Mission Map unlesbar machen.

## Naechster Schritt
Nach TASK_202 kann TASK_203 Deckung und Advance-Entscheidungen enemy-seitig auf Security und Range beziehen.
