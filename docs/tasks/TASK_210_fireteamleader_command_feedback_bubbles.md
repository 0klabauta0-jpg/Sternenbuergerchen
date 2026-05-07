# TASK_210 - Fireteamleader Command Feedback Bubbles

## Ziel
Fireteamleader sollen kurze Comic-Sprechblasen als Rueckmeldung auf Spielerbefehle anzeigen: Befehl verstanden, in Bewegung, nicht moeglich, Feindkontakt, Deckung, Objective laeuft oder Auftrag erledigt.

Die Bubbles bestaetigen und erklaeren den bestehenden Befehlsfluss, ersetzen aber keine Command- oder SimulationRoot-Logik.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_160 - Tactical Mission Playability Smoke
- TASK_180 - Mission Drop Light Fixed HUD Layout
- TASK_188 - Fireteam Advance Styles Map Readability
- TASK_191 - Command Chain Selection and Area Feedback Pass
- TASK_209 - Comic Bubble Asset Catalog and Visual Contract

## Kontext
Spielerbefehle gehen an Fireteamleader. Im Moment muss der Spieler aus UI-Status, Markern und Bewegung ablesen, ob ein Befehl wirklich angenommen wurde. Eine kurze Sprechblase am FTL kann das staerker machen, solange sie knapp bleibt und nicht als zweite Gameplay-Wahrheit arbeitet.

## Umfang
1. Command-Events:
   - Bubbles fuer `move`, `defend`, `take`, `engage`, `hold`, `heal/support` oder vorhandene Projekt-IDs.
   - Positive Annahme, Ablehnung/ungueltiges Ziel, laufender Auftrag, Abschluss und Gefahrkontakt unterscheiden.
   - Bestehende Command-/Area-Feedback-Pfade aus TASK_191 weiterverwenden.
2. Skill-abhaengige Rueckmeldung:
   - Hohe Leadership/Communication: klar, kurz, praezise.
   - Niedrige Skills: knapper, unsicherer oder weniger informativ, aber nicht nervig.
   - Skill veraendert Text/Timing, nicht die Command-Wahrheit.
3. Textumfang:
   - Maximal 1 bis 2 kurze Zeilen.
   - Beispiele: `Verstanden. Ruecke vor.`, `Zu weit. Brauche neuen Punkt.`, `Kontakt links.`, `Objective laeuft.`
   - Keine langen Erklaertexte auf der Karte.
4. Anzeigeort:
   - Bubble am FTL oder in direkter Naehe des Fireteam-Ankers.
   - #17 Selected Fireteam darf parallel eine kurze Statuszeile behalten.
   - Bubbles duerfen nicht dauerhaft ueber Units oder Missionszielen liegen.
5. Toggle-Vorbereitung:
   - Der Renderer fragt eine zentrale Bubble-Setting-Quelle ab.
   - Wenn deaktiviert, gibt es keine sichtbaren Bubbles, aber der Command-Flow bleibt identisch.
6. Verifier:
   - Befehl angenommen -> eine passende FTL-Bubble.
   - Ungueltiger Befehl -> kurze Ablehnungsbubble.
   - Skillvariante aendert Textgruppe, nicht Command-Ergebnis.

## Nicht-Ziele
- Kein Voice-System.
- Kein vollstaendiges Dialogsystem.
- Keine neuen Befehle.
- Keine SimulationRoot-Mutation aus Bubble-Code.
- Keine NPC-Gedanken.

## Akzeptanzkriterien
- [x] Fireteamleader zeigen kurze Bubbles fuer angenommene Spielerbefehle.
- [x] Ungueltige oder blockierte Befehle bekommen eine knappe Rueckmeldung.
- [x] Mindestens zwei Skillstufen erzeugen unterscheidbare, aber gleichwertige Textvarianten.
- [x] Deaktivierte Bubbles veraendern keinen Command-Flow.
- [x] Bubbles nutzen IDs aus dem TASK_209-Katalog.
- [x] Ein TASK_210-Verifier prueft Command-Bindung, Skillvariante, Toggle-Abfrage und Side-Effect-Grenze.

## Erwartete Dateien
- `scripts/ui/fireteamleader_feedback_bubble_resolver.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/ui/tactical_ui_theme.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/task_210_fireteamleader_command_feedback_bubbles.gd`
- `docs/tasks/TASK_210_fireteamleader_command_feedback_bubbles.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_210_fireteamleader_command_feedback_bubbles.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_191_command_chain_selection_area_feedback_pass.gd`
- [ ] Manueller Mission-Map-Sichtcheck fuer Befehlsbubbles.
- [x] `git diff --check`

## Risiken
- Zu viele Bestaetigungen werden schnell laestig. Der Task braucht spaeter Cooldowns und Settings aus TASK_211.
- Skill-Texte duerfen schlechte Werte nicht wie kaputte UI wirken lassen.

## Naechster Schritt
TASK_211 setzt Toggles, Cooldowns und Anzeige-Modi fuer alle Bubble-Typen auf dem neuen visual-only Feedback-Pfad auf.
