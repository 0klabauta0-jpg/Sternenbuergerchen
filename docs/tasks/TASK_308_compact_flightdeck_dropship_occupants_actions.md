# TASK_308 - Compact Flightdeck Dropship Occupants Actions

## Ziel
Flight Deck und Dropship-Karte sollen kompakter werden, ohne wichtige Informationen zu verlieren. Der User soll sehen, wer Pilot ist und wer im Dropship sitzt. "Removed Focused" soll verschwinden und durch eine kleine X-/Remove-Aktion mit Bestaetigung ersetzt werden.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_302 - Dropship Flight Deck Boarding Rename Userology
- TASK_303 - FOB Transfer Dragdrop Card Readability
- TASK_304 - Unified Transit Progress Ghosting Homebase FOB
- TASK_307 - FOB Arrivals Unassigned Operator Pool

## Kontext
Das Flight-Deck-Fenster darf insgesamt kleiner werden. Das Dropship-Element soll kompakter sein, die Pilotenkarte kleiner, aber das Dropship-Bild/Asset weiterhin gut erkennbar. Gleichzeitig fehlt eine kompakte Anzeige der Insassen.

## Umfang
1. Fensterlayout:
   - Flight Deck insgesamt kompakter.
   - Dropship-Karte kompakter, keine riesigen Leerraeume.
   - Header: Name, Status, Pilot kurz.
2. Pilot:
   - Kleine Pilotenkarte oder Pilot-Badge.
   - "No Pilot" nur kompakt als Status, nicht als grosse Flaeche.
3. Insassen:
   - Mini-Karten fuer sitzende Operatoren/Fireteam.
   - Mindestens Portrait + kurzer Name.
   - Optional Rolle/Badge, solange es klein bleibt.
   - Leere Plaetze als dezente Slots.
4. Aktionen:
   - "Removed Focused" entfernen.
   - Kleine X-/Remove-Aktion an passender Karte/Slot.
   - Bestaetigung, bevor jemand zurueckgeschickt oder ausgeladen wird.
   - Drag-and-drop bleibt Hauptinteraktion.
5. Rename:
   - Dropship-Name bleibt umbenennbar.
   - Rename-UI darf nicht den Header aufblasen.
6. Verifier:
   - Layout-Snapshot hat kompakte Slots.
   - Pilot und Insassen werden getrennt angezeigt.
   - X-Aktion fordert Bestaetigung.
   - Remove sendet Person/Team in korrekten Zielzustand.

## Nicht-Ziele
- Keine neue Flugmechanik.
- Kein neues Transportkapazitaetsmodell, falls bereits vorhanden.
- Keine finale Air-Asset-Detailansicht.

## Akzeptanzkriterien
- [x] Flight Deck wirkt deutlich kompakter.
- [x] Pilotstatus ist klein, aber eindeutig sichtbar.
- [x] Dropship zeigt Insassen als Mini-Karten oder Slots.
- [x] "Removed Focused" ist nicht mehr sichtbar.
- [x] Kleine X-Aktion mit Bestaetigung ersetzt grobe Remove-Aktion.
- [x] Verifier prueft Pilot, Insassen, Remove-Confirm und Layout.

## Erwartete Dateien
- `scripts/meta/...`
- `scripts/ui/...`
- `scripts/tests/task_308_compact_flightdeck_dropship_occupants_actions.gd`
- `docs/manual_checks/compact_flightdeck_dropship_occupants.md`
- `docs/tasks/TASK_308_compact_flightdeck_dropship_occupants_actions.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_308_compact_flightdeck_dropship_occupants_actions.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_302_dropship_flight_deck_boarding_rename_userology.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_096_recovery_verifier.gd`
- [ ] Manueller Flight-Deck-Sichtcheck.
- [ ] `git diff --check`

## Risiken
- Zu kompakte Karten duerfen nicht unlesbar werden.
- Remove/X darf keine Operatoren verlieren; Zielzustand muss eindeutig sein.
- Confirm darf Drag-and-drop nicht zaeh machen.

## Naechster Schritt
TASK_309 baut das Fireteam-Zuweisungsboard mit Unassigned-Spalte und kompakten Fireteam-Rahmen.
