# TASK_273 - Fireteam Leader Skill Tactical Progression

## Ziel
Fireteam-Leader sollen taktisch spuerbar besser werden koennen. Leadership, Erfahrung, Team-Cohesion und Rollen-Skills sollen Planqualitaet, Kommunikation, Reaktion auf Kontakt, Ausbrueche und Tempo beeinflussen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_088 - Leadership-Bonus auf Fireteam-Mitglieder
- TASK_120 - Teamqualitaet als FTL-Ausfuehrungsfaktor
- TASK_232 - Start Roster Generation Contract
- TASK_236 - Fireteam Relationship Affinity and Cohesion
- TASK_237 - Mission Progression XP Morale Frustration
- TASK_270 - Commander to Fireteam Leader Delegation Contract
- TASK_272 - Multi Fireteam Coordinated Area Plan

## Kontext
Der User soll merken: Dieses Fireteam ist eingespielt, der FTL kommuniziert gut, der Plan laeuft sauberer, Ausbrueche sind sinnvoller, und Fortschritt nach Missionen ist nicht nur Zahl im Charakterbogen.

## Umfang
1. FTL-Kompetenzwerte:
   - Leadership.
   - Tactical Sense.
   - Communication.
   - Discipline/Initiative.
   - Team Cohesion.
2. Wirkung:
   - Bessere Planrollen-Vorschlaege.
   - Weniger Delay/Scatter.
   - Bessere Contact-Reports.
   - Sicherere Ausbruchsentscheidungen.
   - Bessere Formation/Spacing innerhalb bestehender Mindestabstandslogik.
3. Progression:
   - Missionserfahrung steigert relevante Werte langsam.
   - Falsche Einsaetze, Frust oder schlechte Cohesion koennen Fortschritt bremsen.
   - Keine extreme Schneeballbalance.
4. UI/Feedback:
   - Character Sheet zeigt nicht nur Wert, sondern taktische Auswirkung.
   - Help-Popups erklaeren Effekte.
   - Debrief nennt kleine Fortschritte.
5. Tests:
   - Low-/Mid-/High-FTL fuehren denselben Intent unterschiedlich aus.
   - Unterschiede bleiben innerhalb fairer Grenzen.

## Nicht-Ziele
- Kein komplexer RPG-Skilltree.
- Keine automatische Super-KI.
- Keine direkte Trefferbonus-Explosion.
- Kein neues Relationship-System jenseits vorhandener Taskreihe.

## Akzeptanzkriterien
- [x] FTL-Kompetenzwerte sind als Datenvertrag definiert.
- [x] Planqualitaet, Kommunikation und Ausbrueche koennen von FTL-Skill beeinflusst werden.
- [x] Debrief/Character Sheet zeigen Fortschritt und Auswirkung kompakt.
- [x] Help-Popups erklaeren die wichtigsten Zusammenhaenge.
- [x] Verifier vergleicht Low-/High-FTL ohne unstabile Zufallswerte.
- [x] Multiplayer-Snapshot enthaelt nur noetige, nicht private Daten.

## Erwartete Dateien
- `docs/dev/fireteam_leader_tactical_progression.md`
- `scripts/meta/meta_unit_profile.gd`
- `scripts/tactical/fireteam_behavior_resolver.gd`
- `scripts/tactical/multi_fireteam_plan_resolver.gd`
- `scripts/tests/task_273_fireteam_leader_skill_tactical_progression.gd`
- `docs/tasks/TASK_273_fireteam_leader_skill_tactical_progression.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_273_fireteam_leader_skill_tactical_progression.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_237_mission_progression_xp_morale_frustration.gd`
- [x] `git diff --check`

## Risiken
- Fortschritt darf nicht zu stark werden, sonst ersetzt Skill Taktik.
- Zu viele Werte machen den Charakterbogen schwer lesbar.

## Naechster Schritt
Nach TASK_273 kann TASK_274 die sichtbare taktische Kommunikation fuer diese Entscheidungen bauen.
