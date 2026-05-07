# TASK_237 - Mission Progression XP Morale Frustration

## Ziel
NPCs sollen sich ueber Missionen entwickeln: besser in genutzten Rollen, stabiler in passenden Teams, frustriert oder schlechter, wenn sie dauerhaft falsch eingesetzt, verletzt, ueberlastet oder mit unpassenden Partnern eingesetzt werden.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_096 - Recovery Loop
- TASK_114 - Meta Recovery Integration
- TASK_160 - Tactical Mission Playability Smoke
- TASK_189 - Medic Adjacent Tile Healing Rule
- TASK_207 - NPC Rank Skill Badge Derivation
- TASK_234 - Persistent Player Roster Save and Reset
- TASK_236 - Fireteam Relationship Affinity and Cohesion

## Kontext
Das Ziel ist Progress-Ding, aber nicht sofort ein grosses RPG. V1 soll Missionen auswerten und kleine, nachvollziehbare Aenderungen speichern: Erfahrung, Rolle, Moral, Frust, Recovery und Teamfit.

## Umfang
1. Post-Mission-Events:
   - deployed, survived, downed, healed, objective participation, fired weapon, medic action, pilot/engineer use.
   - Fireteam-Zusammenstellung und Relationship-Kontext.
2. Progression:
   - Kleine XP-/Progress-Werte pro Skill/Rolle.
   - Verbesserungen langsam und begrenzt.
   - Keine harten Spruenge nach einer Mission.
3. Frustration/Morale:
   - Falsche Rolle, dauerhafte Reserve, schlechte Teamfit, Verletzung oder Verlust koennen Frust erzeugen.
   - Gute Missionen und passende Teams koennen Moral/Cohesion verbessern.
4. Debrief:
   - Debrief zeigt 2 bis 5 relevante Character-Events.
   - Keine Textwand.
5. Save:
   - Progression wird im Roster-Save gespeichert.
   - Versionierung fuer neue Felder.
6. Verifier:
   - Nach Mission werden XP/Morale/Cohesion deterministisch aktualisiert.
   - Falsches Team kann leichte Nachteile erzeugen.
   - Limits/Clamps verhindern Extremwerte.

## Nicht-Ziele
- Kein Skilltree.
- Kein Level-Up-Screen mit vielen Perks.
- Kein Permadeath, ausser spaeter bewusst entschieden.
- Kein komplexer Mental-Health-Simulator.

## Akzeptanzkriterien
- [x] Missionsergebnisse erzeugen Character-Progress-Events.
- [x] Skills/Rollen koennen langsam steigen.
- [x] Frust/Morale/Cohesion koennen steigen oder fallen.
- [x] Debrief zeigt knappe relevante Character-Updates.
- [x] Roster-Save roundtrippt Progression.
- [x] Ein TASK_237-Verifier prueft Updateformeln, Clamps, Debrief und Save.

## Umsetzung
- `MissionProgressionResolver` wertet Missionsresultate, Unit-Events, Team-State und Fireteam-Cohesion zentral aus.
- Deployed NPCs erhalten kleine XP-, Skill-, Rollen-, Morale-, Frustration-, Mission-History- und Fireteam-History-Updates. Downed Units gehen in Recovery.
- Relationship-/Cohesion-Drift bleibt pro Mission klein und nutzt die Relationship-Daten aus TASK_236.
- `MetaLayerFlow` wendet Progression beim Combat-Resolve an, aktualisiert den lokalen Roster und speichert den aktualisierten Player-Roster.
- `DebriefTestScreen` zeigt neben Missionsergebnis und Rueckkehrstatus bis zu fuenf knappe Character-Updates.
- `PlayerRosterStore` fuehrt `progression_schema_version` im Save-Payload.

## Erwartete Dateien
- `scripts/meta/mission_progression_resolver.gd`
- `scripts/meta/debrief_screen.gd`
- `scripts/meta/player_roster_store.gd`
- `scripts/tests/task_237_mission_progression_xp_morale_frustration.gd`
- `docs/tasks/TASK_237_mission_progression_xp_morale_frustration.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_237_mission_progression_xp_morale_frustration.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_096_recovery_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_236_fireteam_relationship_affinity_and_cohesion.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_234_persistent_player_roster_save_and_reset.gd`
- [x] Headless Debrief-Sichtcheck im TASK_237-Verifier.
- [x] `git diff --check`

## Risiken
- Zu viele negative Effekte koennen sich unfair anfuehlen. V1 braucht kleine, erklaerte Aenderungen.
- Progression darf Combat-Balance nicht sofort sprengen.

## Naechster Schritt
Nach TASK_237 kann TASK_238 Personalereignisse, Recruiting und Entlassen vorbereiten.
