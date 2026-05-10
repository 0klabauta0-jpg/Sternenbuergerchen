# TASK_316 - FOB Fireteam Staging Migration

## Ziel
Fireteam-Karten sollen zwischen den FOB-Fenstern `#10 FIRETEAMS`, `#12 FOB RESPAWN`, `#13 LOADOUT` und `#19 Dropship` wandern, statt gleichzeitig in mehreren Fenstern als aktive Karte sichtbar zu bleiben.

## Status: IMPLEMENTIERT

## Kontext
Nach der kompakten FOB-/Dropship-Umstellung blieben Fireteams teilweise in `#10` sichtbar, obwohl sie in Respawn, Loadout oder Dropship referenziert wurden. Gleichzeitig durften die Karten in `#12`, `#13` und `#19` nicht auf die alte grosse Darstellung anwachsen.

## Umfang
1. Staging-Migration:
   - Eine Fireteam-Karte wird aus `#10 FIRETEAMS` entfernt, sobald sie nach `#12`, `#13` oder `#19` verschoben wird.
   - Die Ziel-Fenster verwenden kompakte Fireteam-Referenzkarten.
2. Respawn:
   - `#12 FOB RESPAWN` zeigt einen Verorten-Fortschritt pro Mitglied.
3. Loadout:
   - `#13 LOADOUT` behaelt kompakte Member-Reihen.
   - Rang-Badges und Loadout-Dropdowns bleiben sichtbar.
   - Das Loadout bleibt auf Fireteam-Karten sichtbar.
4. Dropship:
   - `#19` referenziert die Fireteam-Queue ohne die Karte breit zu ziehen.
5. Character Sheet:
   - NPC-Karten koennen per Doppelklick weiterhin das Character Sheet anfordern, auch in kompakten oder disabled Zuständen.

## Nicht-Ziele
- Keine neue Gameplay-Wahrheit in FOB-UI-Skripten.
- Kein neuer Transport- oder Respawn-Simulationszustand ausserhalb der bestehenden Staging-/Drop-State-Vertraege.
- Keine finale manuelle FullHD-Art-Direction.

## Akzeptanzkriterien
- [x] Fireteam ist nur im aktuellen Staging-Ort als aktive Karte sichtbar.
- [x] `#12`, `#13` und `#19` verwenden kompakte Kartenbreiten.
- [x] `#12` zeigt Verorten-Fortschritt.
- [x] `#13` zeigt kompakte Member-Reihen mit Badges und Dropdowns.
- [x] Doppelklick auf NPC-Karten fordert das Character Sheet an.

## Erwartete Dateien
- `scripts/meta/fob_screen.gd`
- `scripts/meta/fob_fireteam_card.gd`
- `scripts/meta/npc_compact_card.gd`
- `scripts/tests/task_316_fob_fireteam_staging_migration.gd`
- `docs/tasks/TASK_316_fob_fireteam_staging_migration.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_316_fob_fireteam_staging_migration.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_309_fireteam_assignment_board_compact_frames.gd`
- [x] `git diff --check`

## Risiken
- Die kompakten Referenzen muessen den Character-Sheet-Zugang behalten; künftige UI-Politur darf diesen Zugriff nicht zugunsten reiner Kompaktheit entfernen.
- Der finale visuelle Zustand muss weiter manuell in FullHD geprueft werden.
