# TASK_213 - Skill Based Bubble Text Resolver and Content Pass

## Ziel
FTL-Rueckmeldungen und NPC-Gedanken sollen aus einem zentralen, skill-abhaengigen Textresolver kommen. Skills, Rolle und Situation bestimmen Ton und Informationsgrad, aber nicht die Spielregeln.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_096 - Recovery Loop
- TASK_176 - FOB Loadout Weapon Preview Selector
- TASK_189 - Medic Adjacent Tile Healing Rule
- TASK_207 - NPC Rank Skill Badge Derivation
- TASK_210 - Fireteamleader Command Feedback Bubbles
- TASK_212 - NPC Thought Bubble Hold to Peek Overlay

## Kontext
Wenn FTL-Bubbles und NPC-Gedanken jeweils eigene Textlisten bekommen, driften Ton, Skilllogik und Laenge schnell auseinander. Dieser Task fuehrt einen kleinen Resolver ein: Situation rein, NPC-/FTL-Daten rein, kurzer Bubble-Text raus.

## Umfang
1. Textkategorien:
   - Command accepted.
   - Command blocked.
   - Moving/holding/taking objective.
   - Enemy contact.
   - Need medic/recovering/downed.
   - Low confidence/low morale.
   - Role thoughts: Medic, Shooter, Pilot, Engineer, Leader, Heavy/Support.
2. Skill-Einfluss:
   - Leadership/communication verbessert Klarheit und Priorisierung.
   - Medic-Skill beeinflusst Heal-/Recovery-Gedanken.
   - Shooter/weapon skill beeinflusst Kontakt-/Range-Kommentare.
   - Pilot/Engineer nur dort nutzen, wo diese Rolle im Kontext sichtbar Sinn ergibt.
3. Textform:
   - Kurze deutsche Defaulttexte.
   - Maximal 1 bis 2 Zeilen.
   - Keine langen Erklaerungen.
   - Keine falsche Praezision, wenn Skills niedrig sind.
4. Datenformat:
   - Texttabellen oder kleine Dictionaries mit stabilen Keys.
   - Deterministische Auswahl fuer Verifier.
   - Optional leichte Variation mit Seed, aber nur wenn testbar.
5. Fallbacks:
   - Wenn Skillwerte fehlen: neutrale kurze Texte.
   - Wenn Bubble deaktiviert ist: keine Textauswertung notwendig.
6. Verifier:
   - Hoher Skill liefert klareren Text als niedriger Skill.
   - Niedriger Skill veraendert nicht das Command-Ergebnis.
   - Role-Badges aus TASK_207 koennen Textkategorien beeinflussen.
   - Texte passen in Bubble-Grenzen aus TASK_209.

## Nicht-Ziele
- Kein Storywriting-System.
- Keine prozeduralen langen Dialoge.
- Keine Lokalisierungsinfrastruktur fuer mehrere Sprachen.
- Keine Gameplay-Modifikation durch Text.
- Keine Voice-Ausgabe.

## Akzeptanzkriterien
- [x] Ein zentraler Resolver liefert Texte fuer FTL-Bubbles und NPC-Gedanken.
- [x] Skill-, Rollen- und Situationsdaten beeinflussen Text und Informationsgrad.
- [x] Fehlende Skilldaten haben neutrale Fallbacks.
- [x] Textlaengen passen in die Comic-Bubble-Grenzen.
- [x] Textauswahl ist fuer Tests deterministisch.
- [x] Ein TASK_213-Verifier prueft Skillvarianten, Rollenvarianten, Fallbacks und Laengengrenzen.

## Erwartete Dateien
- `scripts/ui/comic_bubble_text_resolver.gd`
- `data/comic_bubble_text_catalog.json`
- `scripts/ui/fireteamleader_feedback_bubble_resolver.gd`
- `scripts/ui/npc_thought_bubble_resolver.gd`
- `scripts/tests/task_213_skill_based_bubble_text_resolver_and_content_pass.gd`
- `docs/tasks/TASK_213_skill_based_bubble_text_resolver_and_content_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_213_skill_based_bubble_text_resolver_and_content_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_210_fireteamleader_command_feedback_bubbles.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_212_npc_thought_bubble_hold_to_peek_overlay.gd`
- [x] `git diff --check`

## Umsetzung
- `ComicBubbleTextResolver` ist der zentrale, deterministische Resolver fuer FTL-Rueckmeldungen und NPC-Gedanken.
- `data/comic_bubble_text_catalog.json` enthaelt kurze deutsche Texte fuer Command-Status, Health/Recovery, Rollen und neutrale Fallbacks.
- FTL- und NPC-Bubble-Payloads tragen `text_source`, `text_key`, `skill_tier` und rollenspezifische Diagnosefelder, bleiben aber `visual_only`.
- Skill-/Rollenlogik veraendert nur Text und Informationsgrad, nicht Command-Ergebnis, Damage, Healing oder Simulation-State.

## Risiken
- Zu viele witzige oder laute Texte koennen die Spielstimmung kippen. Der erste Pass bleibt knapp, taktisch und lesbar.
- Skillbasierte Unsicherheit darf den Spieler nicht glauben lassen, der Befehl waere technisch kaputt.

## Naechster Schritt
Nach TASK_213 prueft TASK_214 alle Bubble-Pfade zusammen in Mission und Multiplayer-Snapshot.
