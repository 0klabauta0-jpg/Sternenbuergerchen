# TASK_301 - NPC Card Drag Z-Order Badges Tooltips

## Ziel
NPC-Karten muessen beim Ziehen immer sichtbar vor Fenstern liegen. Rank-/Skill-Auszeichnungen sollen rechts neben der Schrift groesser und lesbarer erscheinen und Tooltips/Popups erklaeren, wofuer sie stehen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_070 - NPC Karten Komponente
- TASK_073 - Homebase Charakterbogen Dragdrop
- TASK_207 - NPC Rank Skill Badge Derivation
- TASK_263 bis TASK_268 - Contextual Help Popups
- TASK_259 - Character Card Roster Switching Playability

## Kontext
Im Einzelspieler liegen die NPC-Karten links in Bereich 2 beim Ziehen hinter Fenstern. Dadurch wirkt Drag and Drop kaputt, obwohl die Karte vielleicht nur verdeckt ist. Die kleinen Auszeichnungen sind zudem zu klein und nicht gut erklaert.

## Umfang
1. Drag-Z-Order:
   - Beim Drag startet die NPC-Karte in einem globalen Drag-Layer oder Top-Canvas.
   - Karte liegt vor Fenstern, Panels und Drop-Zonen.
   - Nach Drop/Cancel kehrt sie sauber an den richtigen Ort zurueck.
2. Drop-Zonen:
   - Drag ueber Homebase, FOB, Transfer Team, Fireteam-Slots und Character Sheet pruefen.
   - Visuelle Drop-Hints bleiben sichtbar.
3. Badge-Layout:
   - Skill-/Rank-Badges rechts neben Name/Rolle/Text.
   - Badges groesser, aber ohne Card-Layout zu sprengen.
   - Badges sollen auch in kompakten Karten lesbar bleiben.
4. Popups/Help:
   - Hover/Focus auf Badge erklaert Bedeutung und Herleitung.
   - Popups auch im Character Sheet.
   - Beim Drag darf der Tooltip nicht die Drop-Zone verdecken; ggf. nur nach Hover ohne aktiven Drag.
5. Verifier:
   - Drag-Layer/Z-Index pruefbar.
   - Badge-Position und Mindestgroesse.
   - Tooltip-Catalog-Coverage fuer verwendete Badges.

## Nicht-Ziele
- Keine neuen Skill-Regeln.
- Keine vollstaendige Character-Sheet-Neugestaltung.
- Keine neuen Badge-Assets ohne eigenen Asset-Pass.

## Akzeptanzkriterien
- [x] Gezogenes NPC-Card-Preview liegt immer vor Fenstern.
- [x] Drop-Zonen bleiben waehrend Drag erkennbar.
- [x] Badges sitzen rechts neben dem Haupttext und sind groesser lesbar.
- [x] Badge-Tooltips erklaeren Bedeutung und Skill-Herkunft.
- [x] Character Sheet nutzt dieselben Badge-Erklaerungen.
- [x] Verifier deckt Drag-Layer, Badge-Layout und Tooltip-Coverage ab.

## Erwartete Dateien
- `scripts/ui/...`
- `scripts/meta/...`
- `data/contextual_help_catalog.json`
- optional `data/rank_particle_asset_catalog.json`
- `scripts/tests/task_301_npc_card_drag_zorder_badges_tooltips.gd`
- `docs/manual_checks/npc_card_drag_badge_tooltip_checklist.md`
- `docs/tasks/TASK_301_npc_card_drag_zorder_badges_tooltips.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_301_npc_card_drag_zorder_badges_tooltips.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_259_character_card_roster_switching_playability.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_267_contextual_help_coverage_layout_verifier.gd`
- [ ] Manueller Drag-and-Drop-Check.
- [ ] `git diff --check`

## Risiken
- Globaler Drag-Layer darf keine Karten duplizieren oder Daten verlieren.
- Tooltips duerfen Drag-and-Drop nicht blockieren.
- Badge-Groesse muss mit fixed UI Fenstern kompatibel bleiben.

## Naechster Schritt
TASK_302 verbessert das Dropship-/Flight-Deck-Fenster und Boarding.
