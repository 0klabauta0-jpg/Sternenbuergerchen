# TASK_361 - NPCCompactCard Readonly Profile Reference Contract

## Ziel
`NPCCompactCard` soll fuer reine Anzeige einen Readonly-Profilreferenzmodus bekommen, damit Homebase/FOB nicht fuer jede Karte mehrfach `MetaUnitProfile` deep-copyen muessen.

## Status: IMPLEMENTIERT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll, aber `HomebaseScreen` allein reicht nicht. Der aktuelle Code dupliziert Profile sowohl vor `setup_from_profile()` in Homebase als auch innerhalb von `NPCCompactCard.setup_from_profile()`. Ein sauberer Task muss deshalb den Kartenvertrag selbst erweitern.

## Problem
Bei 12 Units ist die Deep-Copy-Last unkritisch. Bei groesseren Roster-Listen, Staging-Kopien, Loadout-Karten und Popups erzeugen doppelte `duplicate_profile()`-Aufrufe unnoetigen GC-Druck und erschweren klares Ownership-Denken.

## Ursache
Die Karte schuetzt sich aktuell dadurch, dass sie eingehende Profile kopiert und `get_profile()` wiederum eine Kopie zurueckgibt. Das ist sicher, aber fuer reine Anzeige zu teuer.

## Umfang
- `NPCCompactCard.setup_from_profile(profile, options)` um einen expliziten Readonly-Referenzmodus erweitern, z. B. `copy_profile = false`.
- Default bleibt kompatibel und kopiert weiter, solange Call-Sites nicht explizit opt-in machen.
- Card darf Profile im Readonly-Modus nicht mutieren.
- `get_profile()` soll fuer externe Consumer weiter eine sichere Kopie liefern oder einen klar benannten Referenzgetter separat anbieten.
- Homebase-/FOB-Call-Sites fuer reine Anzeige auf Readonly-Referenzmodus umstellen.
- Drag/Drop-, Doubleclick-Character-Sheet- und Portrait-Pfade pruefen.

## Akzeptanzkriterien
- [x] Reine Anzeige-Karten koennen dasselbe Profilobjekt referenzieren, ohne es zu mutieren.
- [x] Externe Call-Sites bekommen nicht versehentlich eine mutable interne Referenz.
- [x] Homebase-Roster, Fireteam, Loadout, Flightdeck und FOB-Karten rendern unveraendert.
- [x] Character-Sheet-Popup erhaelt weiter alle Profilwerte.
- [x] Headless-Verifier prueft Kopiermodus, Readonly-Modus und Signal-/Drag-Payload-Sicherheit.

## Umsetzung
- `NPCCompactCard.setup_from_profile()` besitzt jetzt einen kompatiblen Default-Copy-Modus und einen expliziten Anzeige-Referenzmodus ueber `copy_profile = false`.
- `get_profile()` bleibt fuer Signale, Doubleclick und externe Verbraucher copy-safe; der gezielt benannte `get_profile_reference_for_readonly_display()` ist nur fuer Diagnostik/Anzeigevertrag gedacht.
- Kontexttexte wie Homebase-Staging, Loadout-Rollen und Aircraft-Zuordnung laufen ueber `secondary_text_override`, damit Anzeige-Karten keine Profilkopien mehr mutieren muessen.
- Homebase, FOB und Transport-Craft-Pilotkarten optieren fuer reine Anzeige auf den Readonly-Modus.
- Drag-Payloads behalten nur `type`, `unit_id` und `source_context`; Drag-Previews uebernehmen Secondary-Overrides, ohne Profilobjekte weiterzugeben.

## Erwartete Dateien
- `scripts/meta/npc_compact_card.gd`
- `scripts/meta/homebase_screen.gd`
- ggf. `scripts/meta/fob_test_screen.gd`
- ggf. `scripts/meta/fob_fireteam_card.gd`
- `scripts/tests/task_361_npc_compact_card_readonly_profile_reference_contract.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_361_npc_compact_card_readonly_profile_reference_contract.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_346_homebase_direct_staging_character_popup.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_316_fob_fireteam_staging_migration.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_301_npc_card_drag_zorder_badges_tooltips.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_233_portrait_identity_catalog_and_roster_presentation.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Der Readonly-Vertrag muss hart bleiben. Wenn eine Karte spaeter Profile editieren soll, braucht sie einen expliziten Edit-/Commit-Pfad statt stiller Mutation.
- Dieser Task reduziert Copy-Druck, ersetzt aber keine echte Roster-Virtualisierung.
