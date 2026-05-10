# TASK_309 - Fireteam Assignment Board Compact Frames

## Ziel
Der FOB/VB-Fireteam-Bereich soll als klares Zuweisungsboard funktionieren: Fireteam 1, Fireteam 2 usw. in eigenen Rahmen, daneben oder darunter eine Unassigned-Spalte. Operatoren koennen per Drag and Drop zugewiesen, herausgenommen und Fireteams umbenannt werden.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_305 - Fireteam Staging Copy Cohesion Status
- TASK_307 - FOB Arrivals Unassigned Operator Pool
- TASK_301 - NPC Card Drag Z-Order Badges Tooltips

## Kontext
Beim Fireteam-Fenster braucht es entweder eine zweite Spalte oder einen klaren Zurueck-/Unassigned-Bereich. Der User moechte kompakte Karten sehen: Fireteam-Leader klar, dazu Portrait und Name der Mitglieder, Spezialraenge/Badges nur soweit sie nicht alles aufblasen.

## Umfang
1. Board-Struktur:
   - Fireteam-Rahmen: "Fireteam 1", "Fireteam 2" usw.
   - Fireteam-Namen sind editierbar.
   - Separate Unassigned-Spalte oder direkt angrenzender Pool.
   - Rahmen duerfen nur begrenzt wachsen; Kartenbereich scrollt oder wrappt kompakt.
2. Fireteam-Karten:
   - Leader prominent, aber kompakt.
   - Mitglieder mit Mini-Portrait, kurzem Namen, Rolle.
   - Wichtigste Spezial-/Rank-Badges sichtbar, aber nicht layoutsprengend.
   - Tooltip erklaert Badges wie in TASK_301.
3. Drag-and-Drop:
   - Unassigned -> Fireteam.
   - Fireteam -> Unassigned.
   - Fireteam -> anderes Fireteam.
   - Reordering innerhalb Fireteam optional, wenn ohne grossen Aufwand.
4. Validierung:
   - Warnung bei fehlendem Leader.
   - Warnung bei zu vielen Mitgliedern.
   - Kein echter Personen-Duplikat durch "Kopieren"; es bleibt eine Zuweisungsreferenz.
5. Entfernen:
   - Kleine X-/Remove-Aktion pro Mitglied als Fallback.
   - Entfernen fuehrt zu Unassigned, nicht ins Nichts.
6. Verifier:
   - Fireteam-Rahmen existieren.
   - Rename persistiert.
   - Drag zwischen Unassigned und Fireteam funktioniert.
   - Remove fuehrt zu Unassigned.
   - Kompaktkarten enthalten Portrait, Name, Leader-Status.

## Nicht-Ziele
- Keine automatische optimale Teamwahl.
- Keine neue Cohesion-Simulation.
- Kein kompletter Homebase-/FOB-Layout-Neubau.

## Akzeptanzkriterien
- [x] Fireteams sind in klaren Rahmen sichtbar.
- [x] Fireteam-Namen koennen umbenannt werden.
- [x] Unassigned-Spalte/Pool liegt direkt beim Fireteam-Board.
- [x] Operatoren koennen per Drag in und aus Fireteams bewegt werden.
- [x] Fireteam-Kompaktkarten zeigen Leader, Portrait, Name und wichtigste Badges.
- [x] Remove/X verschiebt zurueck in Unassigned.
- [x] Verifier prueft Board, Rename, Dragdrop und Compact-Card-Inhalte.

## Erwartete Dateien
- `scripts/meta/...`
- `scripts/ui/...`
- `data/contextual_help_catalog.json`
- `scripts/tests/task_309_fireteam_assignment_board_compact_frames.gd`
- `docs/manual_checks/fireteam_assignment_board_compact_frames.md`
- `docs/tasks/TASK_309_fireteam_assignment_board_compact_frames.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_309_fireteam_assignment_board_compact_frames.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_305_fireteam_staging_copy_cohesion_status.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_301_npc_card_drag_zorder_badges_tooltips.gd`
- [ ] Manueller Fireteam-Board-Sichtcheck.
- [ ] `git diff --check`

## Risiken
- Kompaktkarten koennen zu klein werden; Mindestlesbarkeit fuer Portrait und Namen ist Pflicht.
- Fireteam-Rename darf nicht mit Multiplayer-Team-ID oder Faction-ID vermischt werden.
- Dragdrop darf keine Operatoren duplizieren.

## Naechster Schritt
TASK_310 prueft FOB/VB, Flight Deck und Fireteam-Board als gemeinsamen erweiterten Userology-Smoke.
