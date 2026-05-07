# TASK_212 - NPC Thought Bubble Hold to Peek Overlay

## Ziel
Einzelne NPCs sollen kurze Gedanken-Bubbles anzeigen koennen, aber nur solange der Spieler die zugehoerige Taste gedrueckt haelt. Das macht Status, Sorge, Motivation oder naechste Absicht lesbar, ohne die Mission dauerhaft vollzutexten.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_096 - Recovery Loop
- TASK_114 - Meta Recovery Integration
- TASK_160 - Tactical Mission Playability Smoke
- TASK_187 - NPC Minimum Spacing and Multiplayer Authority
- TASK_207 - NPC Rank Skill Badge Derivation
- TASK_209 - Comic Bubble Asset Catalog and Visual Contract
- TASK_211 - Comic Bubble Toggles Cooldowns and Settings

## Kontext
NPC-Gedanken sind ein anderer Kanal als FTL-Befehlsantworten. Sie sollen nicht automatisch bei jedem Tick erscheinen, sondern als bewusster Peek: Taste halten, lesen, loslassen, Karte ist wieder frei.

## Umfang
1. Hold-to-Peek:
   - Gedanken-Bubbles erscheinen nur, waehrend `show_npc_thoughts` gehalten wird.
   - Beim Loslassen verschwinden sie schnell oder sofort.
   - Bubble-Modus `off` blockiert auch Gedanken.
2. Auswahlbereich:
   - Standard: Gedanken fuer ausgewaehltes Fireteam oder sichtbare/nahe NPCs.
   - Harte Maximalzahl, z. B. 3 bis 5 gleichzeitig.
   - Prioritaet fuer selektierte, verletzte, fuehrende oder gerade befehligte NPCs.
3. Gedankenquellen:
   - Health/Downed/Bleedout/Recovery.
   - Aktueller Befehl/Status.
   - Rolle/Top-Badges aus TASK_207.
   - Morale/Suppression/Contact, falls vorhanden.
4. Keine Spoiler:
   - NPC-Gedanken zeigen keine versteckten Gegnerdaten, die der Spieler nicht wissen darf.
   - Friendly-NPCs koennen Unsicherheit ausdruecken, aber nicht unsichtbare Feindpositionen verraten.
5. Visual:
   - Gedanke unterscheidet sich visuell von FTL-Befehl, z. B. andere Bubble-ID oder kleinerer Stil.
   - Text bleibt kurz.
6. Verifier:
   - Hold gedrueckt -> Thought-Snapshot sichtbar.
   - Hold losgelassen -> Thought-Snapshot leer.
   - Off-Modus blockiert.
   - Maximalzahl wird eingehalten.
   - Kein Thought enthaelt hidden enemy data.

## Nicht-Ziele
- Kein permanentes Dialogsystem.
- Keine langen Monologe.
- Keine Persoenlichkeits-KI.
- Keine neuen Gameplaywerte.
- Keine Gedanken fuer Gegner, ausser spaeter bewusst geplant.

## Akzeptanzkriterien
- [x] NPC-Gedanken erscheinen nur waehrend der Hold-Taste.
- [x] Es werden nur ausgewaehlte/nahe/relevante NPCs gezeigt und maximal begrenzt.
- [x] Gedanken entstehen aus vorhandenen Status-, Rollen- oder Skilldaten.
- [x] Hidden Enemy-Daten werden nicht verraten.
- [x] Gedanken-Bubbles sind visuell von FTL-Befehlsbubbles unterscheidbar.
- [x] Ein TASK_212-Verifier prueft Hold-State, Off-Modus, Maximalzahl, Textquelle und Spoilerschutz.

## Erwartete Dateien
- `scripts/ui/npc_thought_bubble_resolver.gd`
- `scripts/ui/comic_bubble_runtime_gate.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/task_212_npc_thought_bubble_hold_to_peek_overlay.gd`
- `docs/tasks/TASK_212_npc_thought_bubble_hold_to_peek_overlay.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_212_npc_thought_bubble_hold_to_peek_overlay.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_211_comic_bubble_toggles_cooldowns_and_settings.gd`
- [ ] Manueller Mission-Map-Sichtcheck mit Hold-Taste.
- [x] `git diff --check`

## Risiken
- Gedanken koennen zu viel verraten oder zu viel erklaeren. Besser knapp und statusnah bleiben.
- Wenn zu viele NPCs gleichzeitig sprechen, geht die Lesbarkeit sofort verloren.

## Naechster Schritt
TASK_213 kann die Textauswahl zentral nach Skills, Rolle und Situation ordnen.
