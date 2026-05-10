# TASK_303 - FOB Transfer Dragdrop Card Readability

## Ziel
FOB-Transfer-UI soll besser lesbar und wirklich drag-and-droppable werden. Grosse Remove-Buttons sollen durch kleine, klare Card-Aktionen ersetzt werden, und graue Texte muessen ausreichend Kontrast haben.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_077 - FOB Fireteam Auswahl
- TASK_079 - FOB Fireteam Staging Ausbau
- TASK_080 - Meta Transfer Sichtbarkeit und Sheet Toggle
- TASK_178 - FOB Drop Light Fixed FullHD Layout
- TASK_301 - NPC Card Drag Z-Order Badges Tooltips

## Kontext
Beim Verschieben von Available Operators ins Transfer Team ist der Remove-Button zu gross. Eigentlich soll Drag and Drop der Hauptweg sein; eine kleine X-Aktion direkt in der NPC-Karte reicht als Fallback. Ausserdem ist die obere/graue Schrift im FOB schlecht lesbar.

## Umfang
1. Textlesbarkeit:
   - Graue Labels und Header-Kontrast pruefen.
   - Actionstyle-/Fokus-/Status-Texte duerfen nicht grau auf grau verschwinden.
   - Wichtige Status-/Fenstertexte heller oder mit Badge/Hintergrund.
   - Fixed-FullHD-Layout bleibt stabil.
2. Drag and Drop:
   - Available Operators -> Transfer Team.
   - Transfer Team -> Available Operators.
   - Transfer Team -> Dropship/Transport, sofern TASK_302 bereit ist.
   - Drop-Hints sichtbar.
3. Remove-Aktion:
   - Grosser Remove-Button raus oder deutlich kleiner.
   - Kleine X-/Remove-Aktion in der Card als Fallback.
   - Keyboard-/Controller-Fallback nicht verlieren.
4. Card-Layout:
   - NPC-Karte bleibt kompakt.
   - Badges aus TASK_301 bleiben sichtbar.
   - Keine abgeschnittenen Namen.
5. Verifier:
   - Drag-Drop-State.
   - Remove-Fallback.
   - Kontrast-/Clipping-Snapshot.

## Nicht-Ziele
- Keine neue Transfer-Simulation.
- Kein kompletter FOB-Redesign.
- Keine neuen NPC-Werte.

## Akzeptanzkriterien
- [x] FOB-Header und graue Texte sind lesbar.
- [x] Actionstyle-/Statusfelder sind auch bei grauem UI-Hintergrund klar erkennbar.
- [x] Operatoren koennen per Drag and Drop zwischen Available und Transfer Team wechseln.
- [x] Grosser Remove-Button ist ersetzt oder stark reduziert.
- [x] Kleine Card-X-Aktion funktioniert.
- [x] Drop-Hints und Drag-Z-Order bleiben korrekt.
- [x] Verifier prueft Layout, Dragdrop und Remove-Fallback.

## Erwartete Dateien
- `scripts/meta/...`
- `scripts/ui/...`
- `scenes/...`
- `scripts/tests/task_303_fob_transfer_dragdrop_card_readability.gd`
- `docs/manual_checks/fob_transfer_dragdrop_card_readability.md`
- `docs/tasks/TASK_303_fob_transfer_dragdrop_card_readability.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_303_fob_transfer_dragdrop_card_readability.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_178_fob_drop_light_fixed_fullhd_layout.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_301_npc_card_drag_zorder_badges_tooltips.gd`
- [ ] Manueller FOB-Dragdrop-Check.
- [ ] `git diff --check`

## Risiken
- Entfernen der grossen Buttons darf keine Barrierefreiheit verlieren.
- Drag and Drop muss auch bei ueberlappenden Fenstern eindeutig bleiben.

## Naechster Schritt
TASK_304 vereinheitlicht Transit-/Progress-Anzeigen fuer Homebase, FOB, Frachter und Dropships.
