# TASK_265 - Character Sheet Loadout Help Content Pass

## Ziel
Charakterbogen, Roster, Skills, Raenge, Traits, Fireteam-Zugehoerigkeit, Loadout, Gewicht und Zierwaffen sollen kompakte, sinnvolle Hilfe-Popups bekommen. Die Hilfe soll erklaeren, woraus Werte entstehen und welche Auswirkung sie haben.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_207 - NPC Rank Skill Badge Derivation
- TASK_232 - Start Roster Generation Contract
- TASK_235 - Character Sheet Roster Gameplay Expansion
- TASK_237 - Mission Progression XP Morale Frustration
- TASK_259 - Character Card Roster Switching Playability
- TASK_260 - Loadout Selection Decorative Weapons Weight Playability
- TASK_264 - Contextual Help Popup Component Settings Toggle

## Kontext
Der Charakterbogen ist ein Kernteil des Spiels. Spieler sollen verstehen, warum ein NPC guter Heiler, Schuetze, Pilot oder schlechter Teamfit ist, was Gewicht bedeutet, warum ein Loadout erlaubt oder nicht erlaubt ist und welche Werte nur Darstellung sind.

## Umfang
1. Character Sheet:
   - Name/Role/Rank.
   - Skills und abgeleitete Badges.
   - Traits, Morale, Frustration, XP/Progress.
   - Fireteam/Cohesion/Relationship soweit vorhanden.
2. Wert-Herkunft:
   - Kurzhilfe: Was bedeutet der Wert?
   - Detailhilfe: Woraus entsteht er, was beeinflusst er, wo wirkt er?
   - Keine freien Formeln, wenn die Daten noch nicht final sind; dann "wirkt derzeit auf ..." oder "geplant fuer ...".
3. Loadout:
   - Waffenrollen: SMG, Rifle, LMG, Sniper, Rocket, Medictool.
   - Gewicht und Bewegungs-/Modifier-Auswirkung.
   - "Keine Waffe" und wann sie erlaubt ist.
   - Zierwaffen/Visual-only klar als nicht spielbare Auswahl erklaeren.
   - Disabled-Gruende knapp erklaeren.
4. Roster/Fireteam:
   - Warum jemand in einem Fireteam ist.
   - Was Umstellen bewirkt.
   - Was beim Entfernen/Zuruecklegen passiert.
5. Content-Qualitaet:
   - Kompakte Texte, keine langen Einzeiler.
   - Detailtexte mit konkretem Nutzen, nicht Flavour-Only.
   - Hilfe-IDs im Katalog, nicht hart im Screen verteilt.

## Nicht-Ziele
- Kein finales Balancing aller Werte.
- Keine Story-/Lore-Texte.
- Keine vollstaendige Relationship-Simulation.
- Keine neuen Character-Stats.

## Akzeptanzkriterien
- [x] Charakterbogen-Pflichtwerte haben `help_id`s.
- [x] Loadout-Optionen, Gewicht und leere Auswahl sind erklaert.
- [x] Zierwaffen/Visual-only sind fuer Spieler klar unterscheidbar.
- [x] Detailhilfe nennt Herkunft/Auswirkung, ohne falsche Gameplay-Wahrheit zu erzeugen.
- [x] Texte bleiben unter den Laengen-/Wrapping-Regeln aus TASK_263.
- [x] Ein Verifier prueft Katalogabdeckung, fehlende IDs, Textlaengen und Character-Card-Zugriff.

## Erwartete Dateien
- `data/contextual_help_catalog.json`
- `scripts/meta/...`
- `scripts/ui/...`
- `scripts/tests/task_265_character_sheet_loadout_help_content_pass.gd`
- `docs/content/character_sheet_loadout_help_copy.md`
- `docs/tasks/TASK_265_character_sheet_loadout_help_content_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_265_character_sheet_loadout_help_content_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_259_character_card_roster_switching_playability.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_260_loadout_selection_decorative_weapons_weight_playability.gd`
- [x] `git diff --check`

## Risiken
- Hilfe kann schnell zu Balancing-Doku werden. Unfertige Werte muessen vorsichtig beschrieben werden.
- Wenn Loadout-Hilfe nicht aus denselben Daten kommt wie Loadout-Regeln, wird sie irrefuehrend.

## Ergebnis
Der Hilfe-Katalog enthaelt Character-Sheet- und Loadout-Copy fuer Identitaet, Rolle, Fireteam, Badges, Traits, Status, Recovery, Morale, Frustration, Teamfit, Progress, Kernwerte, Verhalten, Plattform-Skills, Loadout-Gewicht, Waffenoptionen, No Weapon, Visual-only und Disabled-Gruende. `CharacterSheetFormatter` gibt Zeilen mit `help_id`s aus, `CharacterSheetView` setzt die IDs auf gerenderten Controls, und die FOB-Loadout-Zeilen markieren Armor, Waffen-Slots, Preview, Gewicht, Empty-Slot und Clear-Fokus. `docs/content/character_sheet_loadout_help_copy.md` dokumentiert Copy- und Source-Regeln.

## Naechster Schritt
TASK_266 kann Befehlsplatten, Mission-HUD, Editor, Multiplayer und Settings mit Hilfeinhalten ausstatten.
