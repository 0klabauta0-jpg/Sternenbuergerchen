# TASK_304 - Unified Transit Progress Ghosting Homebase FOB

## Ziel
Wenn Operatoren, Teams, Frachter oder Dropships unterwegs sind, sollen sie auf Quell- und Zielseite sichtbar ausgegraut bleiben und einen Fortschrittsbalken zeigen. Separate Fenster fuer reine Transitlisten sollen reduziert oder ersetzt werden.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_080 - Meta Transfer Sichtbarkeit und Sheet Toggle
- TASK_096 - Meta Missionmap Dropship und CharacterSheet Recovery
- TASK_302 - Dropship Flight Deck Boarding Rename Userology
- TASK_303 - FOB Transfer Dragdrop Card Readability

## Kontext
Fenster 4 und Fenster 6 im FOB wirken fuer Transit/Transfer nicht noetig. Besser: Transfer Team und Dropship/Frachter werden auf beiden relevanten Flaechen ausgegraut, mit Progress-Bar, bis der Transfer auf der Karte abgeschlossen ist.

## Umfang
1. Transit-State-Vertrag:
   - Ein gemeinsamer Meta-State fuer `in_transit`.
   - Enthalten: entity_id, entity_type, source, destination, transport_id, progress, eta, status.
   - Gilt fuer Operator, Fireteam, Dropship, Frachter und spaeter weitere Assets.
2. Darstellung:
   - Quelle zeigt Ghost/ausgegraute Karte mit Fortschritt.
   - Ziel zeigt Ghost/ankommende Karte mit Fortschritt.
   - Map zeigt denselben Fortschritt entlang Route, falls vorhanden.
   - Keine doppelten Wahrheiten zwischen Fenster und Karte.
3. Fenstervereinfachung:
   - Reine Transitfenster pruefen und ggf. entfernen/minimieren.
   - Transfer Team/Dropship-Zonen zeigen Transit direkt.
4. Interaktion:
   - Transit-Karten sind nicht normal auswaehlbar/verschiebbar, ausser Cancel/Details ist erlaubt.
   - Tooltip erklaert "unterwegs", Ziel und ETA.
5. Verifier:
   - Quelle und Ziel spiegeln denselben Transit-State.
   - Progress aktualisiert ohne Datenverlust.
   - Ankunft aktiviert Karte wieder.
   - Keine stale Ghost-Karten nach Abschluss.

## Nicht-Ziele
- Keine neue Routenplanung.
- Kein Echtzeit-Multiplayer-Transit-Sync ausser vorhandener Snapshot-Vertrag reicht.
- Kein Air-Asset-Schadensmodell.

## Akzeptanzkriterien
- [x] Transit-Operatoren erscheinen auf Quelle und Ziel ausgegraut.
- [x] Fortschrittsbalken ist auf beiden Seiten konsistent.
- [x] Dropships/Frachter nutzen denselben Transit-Visual-Vertrag.
- [x] Fenster 4/6 oder vergleichbare Transitlisten sind nicht mehr als primaere Wahrheit noetig.
- [x] Tooltip/Details erklaeren Ziel, Status und ETA.
- [x] Verifier prueft Start, Fortschritt, Abschluss und Cleanup.

## Erwartete Dateien
- `scripts/meta/...`
- `scripts/ui/...`
- `scripts/multiplayer/...` optional nur fuer Snapshot-Spiegelung
- `scripts/tests/task_304_unified_transit_progress_ghosting_homebase_fob.gd`
- `docs/dev/unified_meta_transit_progress_contract.md`
- `docs/manual_checks/unified_transit_progress_ghosting_checklist.md`
- `docs/tasks/TASK_304_unified_transit_progress_ghosting_homebase_fob.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_304_unified_transit_progress_ghosting_homebase_fob.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_096_recovery_verifier.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_278_air_asset_loss_recovery_meta_loop.gd`
- [ ] Manueller Homebase/FOB/Mission-Map-Transitcheck.
- [ ] `git diff --check`

## Risiken
- Ghost-Karten koennen so wirken, als sei die Einheit doppelt vorhanden. UI muss klar "unterwegs" anzeigen.
- Progress darf nicht von mehreren Timern berechnet werden.
- Ankunft/Cleanup muss robust sein, sonst bleiben ausgegraute Karten haengen.

## Naechster Schritt
TASK_305 verbindet Fireteam-Staging, Kopieren und Team-Cohesion-Anzeige mit der neuen Transfer-UX.
