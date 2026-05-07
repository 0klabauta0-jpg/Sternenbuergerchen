# TASK_239 - Character Gameplay Bubble Mission Integration

## Ziel
Character-Gameplay soll in Mission, Fireteam-Verhalten, FTL-Rueckmeldungen und NPC-Gedanken spuerbar werden. Skills, Traits, Beziehungen, Cohesion, Frust und Progression beeinflussen was NPCs tun, denken und sagen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_188 - Fireteam Advance Styles Map Readability
- TASK_210 - Fireteamleader Command Feedback Bubbles
- TASK_212 - NPC Thought Bubble Hold to Peek Overlay
- TASK_213 - Skill Based Bubble Text Resolver and Content Pass
- TASK_236 - Fireteam Relationship Affinity and Cohesion
- TASK_237 - Mission Progression XP Morale Frustration

## Kontext
Character-Daten sollen nicht nur im Homebase-Sheet leben. Sie sollen Missionen veraendern, aber dosiert: bessere Kommunikation, andere Gedanken, kleine Reaktionsunterschiede, Teamfit, Frust-Hinweise und FTL-Antworten.

## Umfang
1. Resolver-Grenze:
   - Ein zentraler CharacterGameplayResolver liefert kleine Modifikatoren.
   - Keine verstreuten Direktzugriffe auf Relationship/Frust in Combat-Hotpaths.
2. Mission-Effekte V1:
   - Communication/Leadership beeinflusst FTL-Rueckmeldungsklarheit.
   - Cohesion beeinflusst Advance-/Coordination-Lesbarkeit oder kleine Timingwerte.
   - Frust/Morale beeinflusst Gedanken und Warnungen.
   - Skillwerte bleiben innerhalb bestehender Combat-/Medic-/Pilot-Resolver.
3. Bubble/Gedanken:
   - Textresolver aus TASK_213 liest Character-State.
   - Niedrige Moral/frustrierte NPCs denken anders, ohne zu viel zu labern.
   - Beziehungen koennen kurze Teamfit-Gedanken erzeugen.
4. Snapshot:
   - Multiplayer-Snapshot zeigt nur noetige Anzeige-IDs/Status, keine privaten Roster-Details.
   - Client rechnet keine Character-Gameplay-Wahrheit.
5. Performance:
   - Character-State wird pro Mission/Tick zusammengefasst.
   - Keine per-frame Relationship-Vollscans.
6. Verifier:
   - Gleicher Befehl, unterschiedliche Leadership -> andere Bubble.
   - Hohe Cohesion -> anderes Teamfit-Snapshot.
   - Frust -> Thought-Text, aber kein illegaler Command-Effekt.

## Nicht-Ziele
- Keine grosse AI-Persoenlichkeit.
- Keine langen Dialoge.
- Keine massiven Combat-Boni.
- Kein Multiplayer-Privacy-System jenseits notwendiger Grenzen.

## Akzeptanzkriterien
- [x] CharacterGameplayResolver liefert zentrale, kleine Modifikatoren.
- [x] Bubbles/Gedanken reagieren auf Skill, Morale, Cohesion und Frust.
- [x] Mission-Verhalten liest Character-State ohne UI-Wahrheit.
- [x] Multiplayer-Viewer erhaelt nur erlaubte Anzeigeinformationen.
- [x] Performance bleibt ohne per-frame Relationship-Vollscan.
- [x] Ein TASK_239-Verifier prueft Bubbles, Thought, Resolver und Snapshot-Grenze.

## Erwartete Dateien
- `scripts/meta/character_gameplay_resolver.gd`
- `scripts/ui/comic_bubble_text_resolver.gd`
- `scripts/ui/npc_thought_bubble_resolver.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/multiplayer/multiplayer_snapshot_contract.gd`
- `scripts/tests/task_239_character_gameplay_bubble_mission_integration.gd`
- `docs/tasks/TASK_239_character_gameplay_bubble_mission_integration.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_239_character_gameplay_bubble_mission_integration.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_213_skill_based_bubble_text_resolver_and_content_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_218_simulation_combat_ai_tick_budget_pass.gd`
- [x] Manueller Mission-Sichtcheck ist fuer V1 durch Verifier-Szenen fuer FTL-Bubble, Thought und Snapshot-Grenze abgedeckt.
- [x] `git diff --check`

## Risiken
- Character-Gameplay kann Combat und AI schnell unuebersichtlich machen. V1 bleibt deshalb klein und zentral.
- Private Roster-Details im Multiplayer duerfen nicht unnoetig repliziert werden.

## Naechster Schritt
TASK_240 prueft Multiplayer-Rosterbesitz und Synchronisation.
