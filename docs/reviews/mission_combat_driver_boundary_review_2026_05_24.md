# Mission Combat Driver Boundary Review - 2026-05-24

## Kontext
Dieser Review erfuellt `TASK_495 - Mission Combat Driver Boundary Review`. Geprueft wurde der aktuelle `MissionCombatLoopDriver` gegen die Architekturregel, dass Gameplay-Mutationen ueber `SimulationRoot` laufen und UI/Visuals keine zweite Missions- oder Combat-Wahrheit halten.

## Kurzfazit
Der Driver ist weiter ein funktionierender, aber zu grosser Missions-Orchestrator. Die wichtigsten produktiven Entscheidungen sind bereits teilweise in Resolver/Contracts ausgelagert, dennoch sammelt der Driver auf 3845 Zeilen wieder zu viele Rollen: Tick-Orchestrierung, Enemy-Behavior, Objective-/Mission-Result-Auswertung, Respawn-/Bleedout-Koordination, Readability-UI, Remote-Events und Diagnostik.

Das ist kein Grund fuer einen grossen Rewrite. Der richtige Schnitt ist eine kleine Folge-Kette:
1. zuerst echte Bug-/Kapselungsrisiken beheben,
2. danach Objective/Result und Enemy-Behavior aus dem Driver herausloesen,
3. zuletzt UI-/Remote-Event-Reste weiter an Presenter/Bridge uebergeben.

## Aktueller Driver-Zuschnitt

### Zentrale Tick-Orchestrierung
`_on_tick_processed()` ist der echte Missions-Taktgeber. Pro Tick laufen dort unter anderem:
- Hotpath-Unit-Cache
- Bleedout-Queue
- Fireteam-Leadership
- Detection/Contact Tracking
- Enemy-Security und Enemy-Team-Tactics
- Discipline, Misidentification und Medic-Cooldowns
- Medic-Support
- Enemy-Advance/Patrol/Limbo
- Friendly-Standard-Behavior
- Overwatch
- Standard-Angriffe
- Objective-Countdown und Combat-Resolution
- Multiplayer-Snapshot-Kontext
- Status-/Visual-Refresh

Bewertung: Als Orchestrator ist diese zentrale Tick-Reihenfolge sinnvoll, aber die aufgerufenen Bereiche sind noch zu unterschiedlich gross. Der Driver sollte langfristig die Reihenfolge halten, aber weniger fachliche Details selbst berechnen.

### Bereits sinnvoll ausgelagerte Komponenten
- `CombatFireDecisionResolver` baut Ziel-/Feuerentscheidungen und Damage-Effect-Payloads.
- `MedicSupportResolver` entscheidet Medic-Ziele, Move-/Heal-Actions und Tool-/Range-Gates.
- `OverwatchController` bestimmt Overwatch-Schuesse und enqueued autoritative Damage-Effects.
- `ContactTracker` haelt Kontaktstatus und Relay-Zustaende.
- `FlankVulnerabilityResolver` kapselt Flanken-/Morale-Modifikatoren.
- `EnemyLimboBehaviorAdapter` kapselt den LimboAI-Smoke-Pfad als Decision-Layer.
- `MissionCombatAuthorityContract` kapselt Snapshot- und Mission-Result-Keys.
- `MissionCombatRemoteEventBridge` kapselt read-only Remote-Event-Payloads.

Bewertung: Diese Komponenten bestaetigen, dass die bestehende Architektur nicht grundsaetzlich falsch ist. Der Resttask ist nicht "neues System bauen", sondern die verbleibenden dicken Driver-Bloecke an diese Schnittweise angleichen.

## Verifizierte Befunde

### Hoch: Driver bleibt produktive Runtime im Testpfad
`scripts/tests/mission_combat_loop_driver.gd` ist kein reiner Testdriver mehr. Viele produktive Missionen, Smokes und UI-/Multiplayer-Snapshots haengen daran. Der Pfadname `scripts/tests` ist dadurch irrefuehrend und erhoeht die Gefahr, neue Runtime-Regeln an der falschen Stelle zu verankern.

Folge: Kein sofortiger Dateiumzug in TASK_495. Erst die dicken Verantwortungen schneiden, dann eine risikoarme Pfadentscheidung treffen.

### Hoch: Registry-Kapselung und Elimination sind konkrete Hotfixes
Der Driver ruft `SimulationRoot._get_unit_registry()` von aussen auf. Zusaetzlich gibt `_is_enemy_team_eliminated()` bei leerer aktiver Enemy-Liste immer `false` zurueck, solange der Code im geprueften Stand unveraendert bleibt.

Folge: Das ist kein Review-/Doku-Thema mehr, sondern `TASK_496`.

### Mittel: Enemy-Behavior ist der groesste fachliche Block
Enemy-Security, Team-Tactics, Patrol, Limbo-Cover, Contact-Hold, Damage-Reposition und Fallback-Advance liegen noch stark im Driver. Es gibt zwar `EnemyTeamTacticsProfile` und `EnemyLimboBehaviorAdapter`, aber die Gruppenbildung, Target-Slots, Posture-Felder und Command-Payloads entstehen weiter inline im Driver.

Folge: Nach `TASK_496` sollte ein eigener Enemy-Behavior-Orchestrator-Slice kommen. Der Driver liefert Kontext und enqueued weiterhin ueber `SimulationRoot`, aber Ziel-/Posture-/Command-Entscheidungen sollten produktiv gekapselt werden.

### Mittel: Objective-/Mission-Result ist klein genug fuer einen fruehen Schnitt
Objective-Capture/-Defense, Countdown, Elimination und Mission-Result-Building liegen nah beieinander. Ein kleiner `MissionCombatResolutionResolver` oder Contract-Helper koennte diese Logik aus dem Driver holen, ohne Combat-Balancing anzufassen.

Folge: Nach dem Elimination-Hotfix ist das der naechste risikoarme Strukturkandidat.

### Mittel: UI-/Debug-Nodes gehoeren aus dem Runtime-Driver heraus
Der Driver erzeugt und aktualisiert `Line2D`/`Label`-Nodes fuer Kontaktlinie, Eventtext und Siegertext. Das ist als Test-Readability entstanden, liegt aber heute neben Runtime-Entscheidungen.

Folge: Erst nach den Gameplay-Grenzen schneiden. Ein Presenter darf Snapshots lesen und anzeigen, aber keine Combat-Wahrheit halten.

## Veraltete oder bereits geloeste Review-Befunde
- `roll_override: 0.4` ist im aktuellen Standard-Angriffspfad nicht mehr vorhanden. Der Damage-Effect kommt aus `CombatFireDecisionResolver`.
- Der duplizierte Bleedout-Code ist bereits generisch auf `_queue_bleedout_for_downed_units()` reduziert.
- `_find_tile_sprite_at()` im `MissionTestSetup` ist aktuell ein toter/ungenutzter Helper, kein bestaetigter 64x64-Hotpath. Das bleibt sinnvoll fuer `TASK_497`, aber nicht als akutes Runtime-Performanceproblem.
- Doppelte `TASK_020` bis `TASK_023` im aktuellen `IMPLEMENTATION_STATUS.md` wurden in diesem Stand nicht bestaetigt.

## Empfohlene Folge-Reihenfolge
1. `TASK_496 - Mission Combat Registry and Elimination Hotfix`
   - oeffentlichen Registry-Zugriff oder explizite Injection schaffen
   - Elimination-Edge-Case absichern
   - kleiner Verifier

2. Neuer Folgeslice nach TASK_496: Mission Combat Resolution Boundary
   - Objective-Countdown, Objective-Victory, Elimination und Mission-Result in kleinen Resolver/Contract ziehen
   - bestehende Snapshot-Keys unveraendert lassen

3. Neuer Folgeslice: Enemy Behavior Orchestrator
   - Enemy-Team-Tactics, Patrol, Limbo-Cover/Hold und Damage-Reposition aus dem Driver herausloesen
   - Driver bleibt Reihenfolge-/Authority-Orchestrator
   - Commands weiter nur ueber `SimulationRoot.enqueue_command()`

4. Neuer Folgeslice: Combat Readability Presenter
   - `Line2D`/`Label`-Erzeugung und Eventtext-Refresh aus dem Driver ziehen
   - Presenter konsumiert read-only Snapshots/Events

5. Neuer Folgeslice: Remote Event Bridge Completion
   - bestehende RPC-Methoden auf minimale Bridge-/Driver-Grenze reduzieren
   - read-only UI-Events klar vom Gameplay-State getrennt halten

## Nicht-Empfehlungen
- Keine Massenverschiebung von `mission_combat_loop_driver.gd` in einen neuen Pfad, solange der Inhalt noch mehrere Verantwortungen enthaelt.
- Kein neues Combat-System und keine KI-Neuerfindung.
- Keine Snapshot-Key-Umbenennung im Rahmen der Strukturarbeit.
- Keine direkte UI-Abhaengigkeit in neuen Resolvern.

## Akzeptanz-Check fuer TASK_495
- Aktueller Verantwortungsumfang dokumentiert: ja.
- Vorhandene Auslagerungen abgeglichen: ja.
- Veraltete Befunde markiert: ja.
- Kleine Extraktionsreihenfolge festgelegt: ja.
- Keine Gameplay-Wahrheit in UI-/Debug-Pfade verschoben: ja, nur Doku/Review.
