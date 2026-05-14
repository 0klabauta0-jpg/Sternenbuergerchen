# TASK 404 - Fireteam Movement Posture Bridge

## Ziel / Problem

Fireteam-Bewegungsmuster (`rush`, `bounding`, `caterpillar`) erzeugen bereits UnitCommands, setzen aber noch keine expliziten Runtime-Postures. Dadurch kann das neue Runtime-Animationssystem nicht verlaesslich zeigen, ob ein Fireteam gerade schnell marschiert, taktisch mit Waffe im Anschlag vorrueckt oder als Deckungsgruppe sichert.

## Ursache / Sinn

Die Fireteam-Logik liegt korrekt im `FireteamMovementController`, waehrend sichtbare Animationen jetzt ueber `UnitRuntimeStatus.movement_posture` und `weapon_posture` laufen. Der fehlende kleine Uebersetzungsschritt verhindert, dass Fireteam-Verhalten im Spiel klar sichtbar wird.

## Umfang

- `FireteamMovementController` setzt Postures auf den vorhandenen `UnitCommand`s.
- Rush/Move nutzt Travel/Lowered fuer schnelle Bewegung.
- Bounding nutzt Aimed-Posture fuer bewegende und deckende Gruppen.
- Caterpillar nutzt Crouch-Walk/Aimed fuer den jeweils bewegenden Member und Overwatch/Aimed fuer Deckung.
- Bestehende Command-/SimulationRoot-Autoritaet bleibt unveraendert.
- Headless-Verifier prueft die Command-Postures und die Runtime-Animationsauswahl.
- Der bestehende TASK_110-Verifier misst Live-GO-Fortschritt entlang der geplanten Fireteam-Route, damit Terrain-Umwege nicht als Snapback zum FTL fehlinterpretiert werden.

## Nicht-Ziele

- Kein neues Taktiksystem.
- Keine neue Formation-UI.
- Keine Wegfindungs- oder Cover-Suche in diesem Task.
- Keine direkte UI-Mutation einzelner NPCs.

## Relevante Contracts / Dokumente

- `docs/ARCHITECTURE.md`
- `docs/dev/commander_fireteam_delegation_contract.md`
- `docs/dev/unit_facing_visual_contract.md`
- `docs/tasks/TASK_110_fireteammovementcontroller_und_bewegungsmuster.md`
- `docs/tasks/TASK_403_runtime_animation_combat_cases.md`

## Akzeptanzkriterien

- Rush-Move-Commands tragen `movement_posture = travel` und `weapon_posture = lowered`.
- Bounding-Mover tragen `movement_posture = engage` und `weapon_posture = aimed`.
- Bounding-Deckung traegt `movement_posture = overwatch` und `weapon_posture = aimed`.
- Caterpillar-Mover tragen `movement_posture = crouch_walk` und `weapon_posture = aimed`.
- Posture-Auswahl laeuft ueber `UnitCommand`/`SimulationRoot` und nicht ueber UI.
- Runtime-Visualauswahl kann daraus `run`, `walkShoot`, `crouchWalkShoot` und `standShoot` ableiten.

## Betroffene Dateien

- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tests/task_110_verifier.gd`
- `scripts/tests/task_404_fireteam_movement_posture_bridge.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/tasks/TASK_404_fireteam_movement_posture_bridge.md`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tests/task_404_fireteam_movement_posture_bridge.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_110_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_403_runtime_animation_combat_cases.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- Die konkrete Balance, wann ein Fireteam Crouch statt normalem Aim-Walk nutzt, ist bewusst nur fuer Caterpillar hart gesetzt. Spaetere Taktikregeln koennen das anhand von Terrain/Kontakt feiner steuern.
