# TASK_211 - Comic Bubble Toggles Cooldowns and Settings

## Ziel
Comic-Bubbles muessen an-, aus- und begrenzbar sein. Spieler sollen Fireteamleader-Rueckmeldungen abschalten oder reduzieren koennen, und NPC-Gedanken sollen nur per Hold-Taste sichtbar werden.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_180 - Mission Drop Light Fixed HUD Layout
- TASK_195 - UI Input and Cursor Asset Availability Pass
- TASK_199 - Main Menu Shell and Background Image
- TASK_209 - Comic Bubble Asset Catalog and Visual Contract
- TASK_210 - Fireteamleader Command Feedback Bubbles

## Kontext
Sprechblasen koennen Lesbarkeit stark verbessern, aber auch nerven. Deshalb braucht das System direkt Settings, Cooldowns und Eingaben: FTL-Rueckmeldungen optional an/aus/minimal, Gedanken nur solange die Taste gehalten wird, und eine harte Obergrenze fuer gleichzeitige Bubbles.

## Umfang
1. Bubble-Modi:
   - `off`: keine Comic-Bubbles.
   - `minimal`: nur wichtige FTL-Antworten und Warnungen.
   - `normal`: FTL-Befehlsfeedback und kurze Statusantworten.
   - optional `debug`: mehr Diagnosen nur fuer Entwicklung.
2. Separate Kategorien:
   - Fireteamleader command feedback.
   - Fireteamleader combat/status feedback.
   - NPC thought peek.
   - Debug/test bubbles.
3. Cooldowns und Limits:
   - Maximalzahl gleichzeitiger Bubbles.
   - Mindestabstand zwischen automatischen FTL-Bubbles.
   - Prioritaet fuer Warnung/Feindkontakt vor Flavor.
4. Eingabe:
   - Hold-to-show-Taste fuer NPC-Gedanken vorbereiten.
   - InputMap-Eintrag mit kurzem Namen, z. B. `show_npc_thoughts`.
   - Settings zeigen die Bindung oder greifen auf bestehende Input-Prompt-Kataloge zurueck.
5. Persistenz:
   - Settings im vorhandenen Settings-/Config-Pfad speichern.
   - Default: FTL-Rueckmeldungen `normal`, NPC-Gedanken nur Hold.
6. Verifier:
   - `off` blockiert alle Bubble-Renderdaten.
   - `minimal` laesst wichtige FTL-Bubbles durch.
   - Cooldown verhindert Bubble-Spam.
   - Hold-Input schaltet Thought-Peek nur waehrend gedrueckt.

## Nicht-Ziele
- Kein grosses Settings-Menue-Redesign.
- Keine freie Textkonfiguration.
- Keine Accessibility-Komplettloesung.
- Kein Dialogverlauf.

## Akzeptanzkriterien
- [x] Spieler koennen Comic-Bubbles aus, minimal oder normal stellen.
- [x] FTL-Rueckmeldungen respektieren Cooldown und Maximalzahl.
- [x] NPC-Gedanken werden nur per Hold-Taste sichtbar.
- [x] Settings bleiben persistent und haben sichere Defaults.
- [x] Deaktivierte Bubbles erzeugen keine Visual-Nodes.
- [x] Ein TASK_211-Verifier prueft Modi, Cooldowns, Persistenz und Hold-Input.

## Erwartete Dateien
- `scripts/ui/comic_bubble_settings.gd`
- `scripts/ui/comic_bubble_runtime_gate.gd`
- `scripts/ui/tactical_ui_theme.gd`
- `scripts/meta/settings_screen.gd` oder bestehender Settings-Pfad
- `project.godot`
- `scripts/tests/task_211_comic_bubble_toggles_cooldowns_and_settings.gd`
- `docs/tasks/TASK_211_comic_bubble_toggles_cooldowns_and_settings.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_211_comic_bubble_toggles_cooldowns_and_settings.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_210_fireteamleader_command_feedback_bubbles.gd`
- [ ] Manueller Settings-/Mission-Sichtcheck fuer Off/Minimal/Normal und Hold-Taste.
- [x] `git diff --check`

## Risiken
- Ohne Cooldowns werden Bubbles zur Dauerbeschallung.
- Settings duerfen nicht erst nach TASK_199 existieren; falls das Hauptmenue noch fehlt, muss ein kleiner Config-Fallback reichen.

## Naechster Schritt
TASK_212 kann die NPC-Gedanken als Hold-to-Peek-Overlay auf `ComicBubbleRuntimeGate` aufbauen.
