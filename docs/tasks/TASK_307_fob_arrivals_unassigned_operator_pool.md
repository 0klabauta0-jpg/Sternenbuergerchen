# TASK_307 - FOB Arrivals Unassigned Operator Pool

## Ziel
In der FOB/VB-Ansicht soll es einen klaren Bereich fuer Operatoren geben, die aus der Homebase angekommen sind, aber noch keinem Fireteam, Loadout- oder Respawn-/FOB-Slot zugewiesen wurden.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_080 - Meta Transfer Sichtbarkeit und Sheet Toggle
- TASK_303 - FOB Transfer Dragdrop Card Readability
- TASK_304 - Unified Transit Progress Ghosting Homebase FOB
- TASK_305 - Fireteam Staging Copy Cohesion Status

## Kontext
Aktuell fehlt ein sichtbarer Zwischenzustand: Leute koennen von der Homebase in der FOB ankommen, sind dort aber noch nicht sinnvoll zugewiesen. Diese Operatoren brauchen ein eigenes, bedienbares Sammelfenster oder eine Spalte, damit der User sie nicht verliert.

## Umfang
1. Unassigned-/Arrivals-Bereich:
   - Sichtbare Gruppe fuer "Angekommen, nicht zugewiesen".
   - Nur Operatoren anzeigen, die am FOB/VB-Ort verfuegbar sind, aber keinem Fireteam, Dropship, Loadout, Respawn oder aktiven Transfer zugeordnet sind.
   - Bereich darf kompakt sein und bei vielen Eintraegen scrollen.
2. Drag-and-Drop:
   - Unassigned -> Fireteam.
   - Unassigned -> Loadout.
   - Unassigned -> FOB Respawn/Reserve.
   - Fireteam -> Unassigned, wenn jemand herausgenommen wird.
3. Kartenformat:
   - Kompakte Mini-Karten mit Portrait, Name, Rolle/Spezialisierung und wichtigsten Badges.
   - Lesbar, aber klein genug fuer mehrere Operatoren.
4. Status:
   - Transit-Ghost aus TASK_304 wird nach Ankunft zu echter Unassigned-Karte.
   - Keine doppelte Anzeige in Available/Homebase und FOB-Unassigned.
5. Verifier:
   - Ankunft erzeugt Unassigned-Eintrag.
   - Zuweisung entfernt ihn aus Unassigned.
   - Herausnehmen aus Fireteam fuehrt zurueck nach Unassigned.

## Nicht-Ziele
- Keine neue Personalwirtschaft.
- Keine automatische Fireteam-Zuweisung.
- Kein neues Savegame-System ausser bestehende Meta-Persistenz.

## Akzeptanzkriterien
- [x] FOB/VB zeigt angekommene, nicht zugewiesene Operatoren klar an.
- [x] Operatoren koennen von dort per Drag and Drop in Fireteam/Loadout/FOB-Reserve geschoben werden.
- [x] Fireteam-Mitglieder koennen zurueck in Unassigned genommen werden.
- [x] Transit-Abschluss erzeugt keine doppelten Karten.
- [x] Verifier prueft Ankunft, Zuweisung, Ruecknahme und Cleanup.

## Erwartete Dateien
- `scripts/meta/...`
- `scripts/ui/...`
- `scripts/tests/task_307_fob_arrivals_unassigned_operator_pool.gd`
- `docs/manual_checks/fob_arrivals_unassigned_operator_pool.md`
- `docs/tasks/TASK_307_fob_arrivals_unassigned_operator_pool.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_307_fob_arrivals_unassigned_operator_pool.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_304_unified_transit_progress_ghosting_homebase_fob.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_303_fob_transfer_dragdrop_card_readability.gd`
- [ ] Manueller FOB/VB-Ankunftscheck.
- [ ] `git diff --check`

## Risiken
- Unassigned darf nicht wie ein zweites Available Operators wirken. Es ist standortbezogen am FOB/VB.
- Doppelanzeigen muessen vermieden werden, sonst verliert der User Vertrauen in den Transfer-State.

## Naechster Schritt
TASK_308 macht Flight Deck und Dropship-Karte kompakter und zeigt Insassen.
