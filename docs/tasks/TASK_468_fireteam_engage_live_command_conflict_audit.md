# TASK_468 - Fireteam Engage Live Command Conflict Audit

## Ziel / Problem

Im manuellen Drill wirkt `Engage` weiter widerspruechlich: `normal` bleibt haeufig stehen oder zuckt, `aggressiv` laeuft in Gegner hinein, und Schuesse/Muzzleflash bleiben aus. Es wirkt, als ob mehrere Runtime-Pfade unterschiedliche Unit-Commands oder Facing-Informationen schreiben.

## Sinnhaftigkeit / Ursache

TASK_467 hat den MovementController um einen Contact-Halt erweitert, aber der Playtest zeigt weiter Abweichungen im echten Drill-Fenster. Daher muss nicht nur der isolierte Controller-Verifier, sondern der komplette Live-Pfad geprueft werden: TacticalController, FireteamMovementController, SimulationRoot-Command-Queue, CombatLoop, Friendly-Standard-Behavior, Security/Facing und Drill-Map-Setup.

## Umfang

- Pruefen, ob der aktuelle Branch/Commit die erwarteten TASK_467-Regeln enthaelt.
- Alle Live-Schreiber auf Friendly-Unit-Commands im Drill-Pfad identifizieren.
- Einen Verifier bauen, der den User-Ablauf `DEF/Move -> Engage N/A in Gegnernaehe` als Live-Tick testet.
- Konflikte beheben, bei denen ein Pfad `Engage`-Contact-Halt oder Fire-Ready-Commands wieder ueberschreibt.
- Diagnose so halten, dass zukuenftige Haenger als konkreter Blockgrund sichtbar werden.

## Nicht-Ziele

- Keine neue Cover-Suchlogik.
- Keine finale Gegner-KI-Patrouille.
- Keine groessere LimboAI- oder Terrain3D-Umstellung.
- Keine UI-Umgestaltung ausser klar notwendiger Diagnose.

## Relevante Contracts / Dokumente

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_465_fireteam_engage_resume_contact_progress.md`
- `docs/tasks/TASK_466_fireteam_live_defend_contact_fire_damage.md`
- `docs/tasks/TASK_467_fireteam_engage_contact_halt_fire.md`

## Akzeptanzkriterien

- Der Drill-Live-Pfad zeigt bei attackierbarem Engage-Kontakt keinen Befehlskampf zwischen Movement, Auto-Defend und Friendly-Standard-Behavior.
- `Engage N` und `Engage A` behalten einen eindeutigen Runtime-Command-Zustand, statt zwischen alten und neuen Commands zu wechseln.
- Wenn ein Gegner in LOS/Waffenreichweite sichtbar ist, entsteht entweder ein Fire-Event oder eine konkrete `NO FIRE`-Diagnose.
- Der Verifier bildet mindestens einen User-nahen Live-Ablauf ohne forcierte Endentscheidung ab.

## Betroffene Dateien

- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scenes/tests/fireteam_command_drill_map.tscn`
- `scripts/tests/task_468_fireteam_engage_live_command_conflict_audit.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_468_fireteam_engage_live_command_conflict_audit.gd`
- Relevante TASK_465/TASK_466/TASK_467-Regressionen
- `git diff --check`

## Risiken / offene Punkte

Wenn der Fehler nur im interaktiven Godot-Fenster durch Editor-Reihenfolge, alte laufende Instanz oder manuelles Szenen-Setup entsteht, muss der Verifier zusaetzliche Diagnosewerte liefern, statt den Fehler im Headless-Lauf zu verstecken.
