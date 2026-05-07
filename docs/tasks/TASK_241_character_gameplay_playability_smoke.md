# TASK_241 - Character Gameplay Playability Smoke

## Ziel
Die Character-Gameplay-Reihe soll in einem spielbaren Flow geprueft werden: erstes Team generieren, Roster speichern, Fireteams bilden, Mission spielen, Debrief sehen, Progression speichern, Beziehungen/Cohesion auswerten und Bubbles/Gedanken passend reagieren lassen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_232 - Start Roster Generation Contract
- TASK_233 - Portrait Identity Catalog and Roster Presentation
- TASK_234 - Persistent Player Roster Save and Reset
- TASK_235 - Character Sheet Roster Gameplay Expansion
- TASK_236 - Fireteam Relationship Affinity and Cohesion
- TASK_237 - Mission Progression XP Morale Frustration
- TASK_238 - Personnel Events Recruit Leave Dismiss Notifications
- TASK_239 - Character Gameplay Bubble Mission Integration
- TASK_240 - Multiplayer Player Roster Ownership Contract

## Kontext
Einzelne Character-Features koennen technisch funktionieren und zusammen trotzdem nicht spielbar sein. Dieser Smoke prueft, ob der Spieler tatsaechlich ein Team bekommt, es versteht, es in Mission nutzt und danach sinnvolle Veraenderungen sieht.

## Umfang
1. First-start Flow:
   - Kein Roster vorhanden.
   - Neues Team erzeugen.
   - 20 bis 30 NPCs sichtbar.
   - Portraits, Badges, Skills, Traits.
2. Teamwahl:
   - Fireteam-Vorschlaege.
   - Player kann Fireteam bestaetigen oder leicht umbauen.
   - Cohesion/Relationship-Hinweise sichtbar.
3. Mission:
   - Fireteam startet Mission.
   - Bubbles/Gedanken reagieren auf Skill/Morale/Cohesion.
   - Character-State bleibt nicht UI-Wahrheit.
4. Debrief:
   - XP/Progress, Frust/Morale, Relationship/Cohesion und Recovery werden knapp gezeigt.
   - Save schreibt neue Werte.
5. Personnel:
   - Nach mehreren Missionen kann ein Personnel-Event demonstriert werden.
   - Nachricht ist sichtbar und knapp.
6. Multiplayer:
   - Ownership-Vertrag prueft, ob Character-Daten sauber begrenzt sind.

## Nicht-Ziele
- Kein finaler Balance-Pass.
- Kein Content-Story-System.
- Kein kompletter Kampagnenmodus.
- Kein Online-Profilservice.

## Akzeptanzkriterien
- [x] First-start erzeugt ein valides Startteam.
- [x] Roster wird gespeichert und nach Neustart wieder geladen.
- [x] Character Sheet/Roster/Fireteam Card zeigen relevante Daten.
- [x] Mission erzeugt Character-Progress-Events.
- [x] Debrief zeigt Fortschritt und speichert ihn.
- [x] Bubbles/Gedanken reagieren sichtbar auf Character-State.
- [x] Multiplayer-Ownership-Grenze bleibt sauber.
- [x] Ein TASK_241-Verifier und eine manuelle Checkliste existieren.

## Erwartete Dateien
- `scripts/tests/task_241_character_gameplay_playability_smoke.gd`
- `docs/manual_checks/character_gameplay_playability_checklist.md`
- `docs/reviews/character_gameplay_balance_and_open_items_review.md`
- `docs/tasks/TASK_241_character_gameplay_playability_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_241_character_gameplay_playability_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_214_comic_bubble_feedback_playability_smoke.gd`
- [ ] Manueller Character-Gameplay-Sichtcheck. Checkliste ist erstellt, aber nicht headless ausgefuehrt.
- [x] `git diff --check`

## Risiken
- Der Smoke findet Zusammenspiel, lokalisiert Fehler aber schlechter als Einzelverifier.
- Character-Gameplay muss interessant sein, ohne den Spieler mit Management zu erschlagen.

## Umsetzung
- Der TASK_241-Smoke erzeugt ein First-start-Roster, speichert/laedt es, prueft sichtbare Identitaet und rendert das Character Sheet.
- Homebase und FOB werden mit denselben Profilen gespeist; der Test prueft Roster-/Transfer-Karten, Fireteam-Cohesion und Teamfit-Text.
- Eine Mission wird als Headless-Resultat ausgewertet, danach prueft der Smoke XP, Mission History, Debrief-Text, Personnel-Event, Character-Gameplay-Snapshot sowie FTL-/Thought-Bubbles.
- Multiplayer-Preview und Unit-Snapshot werden gegen den TASK_240-Privacy-Vertrag geprueft.
- `docs/manual_checks/character_gameplay_playability_checklist.md` und `docs/reviews/character_gameplay_balance_and_open_items_review.md` dokumentieren Sichtcheck und offene Balance-Fragen.

## Naechster Schritt
Nach TASK_241 startet TASK_242 fuer Audio-SFX-Inventar und Curated Import.
