# TASK_302 - Dropship Flight Deck Boarding Rename Userology

## Ziel
Das Dropship-/Flight-Deck-Fenster soll lesbarer und nuetzlicher werden: Dropship-Name und Pilotstatus duerfen nicht riesig Platz fressen, das Dropship-Bild darf groesser sein, Dropships sollen umbenennbar sein, und Teams sollen direkt von dort einsteigen koennen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_096 - Meta Missionmap Dropship und CharacterSheet Recovery
- TASK_106 - Dropship LZ Insertion und verzoegerte Aktivierung
- TASK_117 - Dropship Deploy als Simulation Effects
- TASK_277 - Dropship Freighter Anti Armor Threat Contract
- TASK_278 - Air Asset Loss Recovery Meta Loop

## Kontext
Beim Rufen/Verwalten des Dropships wirkt oben "Dropship 1 / No Pilot" zu gross. Das ist eigentlich Fenster-/Statusinformation und sollte kompakter sein. Gleichzeitig soll das Dropship als Objekt sichtbarer sein und wie ein eigenes benanntes Asset funktionieren.

## Umfang
1. Header:
   - Kompakter Titel: Dropship-Name plus Pilotstatus.
   - Kein riesiges "No Pilot" als dominanter Fliesstext.
   - Statusfarben/Badges fuer Pilot fehlt, Pilot zugewiesen, unterwegs, bereit.
2. Umbenennen:
   - Dropship kann einen Namen bekommen.
   - Name persistiert in Meta-/Air-Asset-State.
   - Defaultname bleibt bei fehlendem Namen stabil.
3. Visual:
   - Dropship-Bild/Preview groesser und besser lesbar.
   - Bild darf Layout nicht sprengen.
4. Boarding:
   - Team kann direkt vom Flight Deck einsteigen, wie bei FOB-Boarding.
   - Boarding kann Richtung FOB/Transfer vorbereiten.
   - Drag-and-drop und Button-Fallback.
5. Pilot:
   - Pilot-Zuweisung klarer anzeigen.
   - Fehlender Pilot blockiert nur Aktionen, die wirklich Pilot brauchen.
6. Verifier:
   - Header-Textgroessen/Statusfelder.
   - Rename persistiert.
   - Boarding nutzt denselben Transfer-/Transport-Vertrag wie FOB.

## Nicht-Ziele
- Keine neue Flugphysik.
- Keine neue Dropship-Kampfmechanik.
- Keine finale Air-Asset-Strategiekarte.

## Akzeptanzkriterien
- [x] Dropship-Header ist kompakt und lesbar.
- [x] Dropship-Bild ist groesser und passt ins Fenster.
- [x] Dropship kann umbenannt werden.
- [x] Pilotstatus ist klar, aber nicht ueberdominant.
- [x] Team kann direkt vom Flight Deck ins Dropship steigen.
- [x] Verifier prueft Rename, Boarding und Layout-Snapshot.

## Erwartete Dateien
- `scripts/meta/...`
- `scripts/ui/...`
- `data/...`
- `scripts/tests/task_302_dropship_flight_deck_boarding_rename_userology.gd`
- `docs/manual_checks/dropship_flight_deck_userology_checklist.md`
- `docs/tasks/TASK_302_dropship_flight_deck_boarding_rename_userology.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_302_dropship_flight_deck_boarding_rename_userology.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_096_recovery_verifier.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_278_air_asset_loss_recovery_meta_loop.gd`
- [ ] Manueller Flight-Deck-Sichtcheck.
- [ ] `git diff --check`

## Risiken
- Dropship-Name darf nicht mit Asset-ID oder Network-ID verwechselt werden.
- Boarding vom Flight Deck muss denselben Transfer-State nutzen wie FOB/Homebase.

## Naechster Schritt
TASK_303 poliert FOB-Operator- und Transfer-Team-Dragdrop.
