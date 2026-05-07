# TASK_203 - Enemy Cover Advance and Team Tactics Patch

## Ziel
Feindteams sollen Deckung, Vorruecken und Kontaktverhalten als kleine, lesbare Teamtaktik nutzen: nicht nur nach Schaden zur Deckung springen, sondern je nach Profil halten, druecken, sichern oder in Etappen vorgehen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_089 - Enemy Cover-Seeking on Damage
- TASK_130 - Lokale Unit-Avoidance mit ORCA/RVO-Light
- TASK_187 - NPC Minimum Spacing and Multiplayer Authority
- TASK_188 - Fireteam Advance Styles Map Readability
- TASK_200 - Enemy Team Tactics Contract and Editor Config
- TASK_202 - Enemy Security Direction and LOS Patch

## Kontext
Der aktuelle Gegnerpfad kann objective-/patrol-orientiert laufen und bei Schaden Deckung suchen. Das ist ein guter Anfang, aber noch kein Teamverhalten. Fuer spielbare Taktik braucht es erkennbare Entscheidungen: Wer haelt Deckung, wer bewegt sich, wer schaut wohin, und warum bleiben Gegner nicht alle auf demselben Tile?

## Umfang
1. Deckungswahl:
   - Gegner bewerten nahe begehbare Tiles nach Cover, LOS zum Ziel, Waffenreichweite und Hoehe.
   - Keine Deckung auf nicht-walkable Tiles, hinter harten Klippen oder ausserhalb sinnvoller Range.
   - Deckungssuche darf nicht alle Gegner auf denselben Slot ziehen.
2. Advance-Stile:
   - Profile aus TASK_200 steuern mindestens `hold`, `push`, `bounding` und `probe`.
   - Bounding/ueberschlagendes Vorgehen soll ueber mehrere Tiles sichtbar werden.
   - "Raupenartig" kann als langsamer Team-Fortschritt mit Vorder-/Rueckgruppe abgebildet werden, wenn TASK_188 das Friendly-Vokabular schon bereitstellt.
3. Teamrollen:
   - Kleine Rollen ableiten: point, cover, support, medic/special, sniper/watch.
   - Rollen beeinflussen Zielposition und Security, aber nicht sofort eine grosse Charakter-KI.
4. Mindestabstand:
   - TASK_187 bleibt autoritativ.
   - Taktik-Offsets duerfen keine rein visuellen Positionen erfinden.
5. Statuslesbarkeit:
   - Mission Map oder Debug-Snapshot zeigt knappe Taktiklabels, z. B. `HOLD`, `PUSH`, `COVER`, `WATCH`.
   - Keine langen Texte ueber Units.
6. Verifier:
   - Enemy-Team nimmt mehrere Deckungsslots.
   - Push-Team bewegt mindestens zwei Units ueber mehrere Tiles.
   - Hold-Team bleibt im Sektor und sichert.
   - Mindestabstand bleibt auch waehrend Kontakt erhalten.

## Nicht-Ziele
- Keine vollstaendige Squad-AI.
- Keine komplexe Rollenprogression.
- Keine neue Formation-Slot-Engine.
- Keine neuen Waffen oder Particles.
- Keine clientseitige Bewegungsentscheidung.

## Akzeptanzkriterien
- [x] Enemy-Deckungswahl nutzt Cover, LOS, Range und Walkability.
- [x] Mindestens zwei Enemy-Advance-Profile verhalten sich sichtbar unterschiedlich.
- [x] Feindteams stapeln auch bei Deckungswahl und Contact-Stop nicht.
- [x] Bounding/Push-Verhalten ist ueber mehrere Tiles im Snapshot oder Overlay nachvollziehbar.
- [x] Teamrollen sind kleine Daten/Labels, keine neue monolithische KI.
- [x] Ein TASK_203-Verifier prueft Deckung, Advance, Mindestabstand und Statuslesbarkeit.

## Erwartete Dateien
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tactical/enemy_team_tactics_profile.gd`
- `scripts/tactical/local_avoidance_resolver.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_203_enemy_cover_advance_and_team_tactics_patch.gd`
- `docs/tasks/TASK_203_enemy_cover_advance_and_team_tactics_patch.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_203_enemy_cover_advance_and_team_tactics_patch.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_089_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_187_npc_minimum_spacing_and_multiplayer_authority.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_188_fireteam_advance_styles_map_readability.gd`
- [ ] Manueller Mission-Map-Sichtcheck fuer Enemy-Push/Hold.
- [x] `git diff --check`

## Risiken
- Zu viel Taktik auf einmal kann unspielbar oder schwer testbar werden. Der erste Patch soll wenige klare Profile liefern.
- Deckungswahl darf das Terrain-Hoehenmodell aus TASK_182 bis TASK_185 nicht umgehen.

## Naechster Schritt
Nach TASK_203 muss TASK_204 sicherstellen, dass diese Enemy-Entscheidungen multiplayerfaehig und autoritativ bleiben.
