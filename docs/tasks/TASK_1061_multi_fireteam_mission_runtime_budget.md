# TASK_1061 - Multi-Fireteam Mission Runtime Budget

## Ziel / Problem

Der jetzt funktionierende Zwei-Fireteam-Pfad muss sich auch zuegig anfuehlen.
Eine frische TASK-1045-Messung zeigt weiter einen ersten sichtbaren
Missionsframe von rund 4,8 Sekunden, eine einzelne HUD-Refresh-Spitze von rund
0,8 Sekunden und rund 1,2 Sekunden beim LZ-Setzen. Der vorhandene Trace ist
ein Einzelteam-Pfad und markiert den spaeteren LZ-/Deboard-Block nur pauschal.

## Ursache / Sinnhaftigkeit

Fruehere Guards haben Meta-Fanout und wiederholte HUD-Aufbauten bereits
reduziert. Der aktuelle Spielerpfad hat jedoch zwei Fireteams, getrennte
Dropships, ContactTracker-Daten, Preview und Koordination. Bevor weiterer
Cache-Code entsteht, muss die dominante Kostenstelle genau in diesem echten
Pfad als Transport-, Controller-, Simulation-, Terrain- oder UI-Scope
belegt sein.

## Umfang

- Den TASK-1060-Alpha-/Beta-Pfad zeitlich nach Aufbau, Transfer, Deboarding,
  Contact, Move-Preview und `GO` zerlegen.
- Bestehende Timing-Snapshots von TacticalController, SimulationRoot,
  Primary3DView und CombatLoop opt-in und read-only verwenden.
- Pro Stufe die langsamste bekannte Scope, Gesamtdauer und Frames erfassen.
- Erst nach einem reproduzierbaren Befund nur den dominanten Hotpath mit
  Dirty-/Signature-/Throttle-Guard korrigieren.

## Nicht-Ziele

- Kein pauschales Frame-Budget als Gameplay-Blockade.
- Kein Cache-/Refresh-Rewrite ohne gemessene Ursache.
- Kein Abschalten von ContactTracker, Koordination, Planning-Emit oder
  SimulationRoot-Mutationen fuer bessere Messwerte.
- Kein manueller F6-Sichttest in diesem Slice.

## Relevante Contracts

- `docs/ARCHITECTURE.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/dev/combat_loop_authority_contract.md`
- `docs/tasks/TASK_1045_mission_first_contact_end_to_end_timing_trace.md`
- `docs/tasks/TASK_1051_planning_state_signal_fanout_guard.md`
- `docs/tasks/TASK_1060_multi_fireteam_first_command_player_grip.md`

## Akzeptanzkriterien

- Ein eigener Zwei-Fireteam-Trace misst jede relevante Stufe und die
  vorhandenen Cross-System-Snapshots, ohne Gameplay zu mutieren.
- Die Messung benennt fuer jede langsame Stufe einen dominanten Scope oder
  explizit eine noch unaufgeloeste Grenze.
- Ein echter Fix wird nur bei reproduzierbarer Dominanz umgesetzt und behaelt
  Auswahl, Preview, ContactTracker, GO, Coordination und
  SimulationRoot-Autoritaet bei.
- Nach einem Fix bleibt der betroffene Player-Flow gruen und die gemessene
  dominante Kostenstelle sinkt nachvollziehbar.

## Betroffene Dateien

- Neuer Performance-Trace unter `scripts/tests/`.
- Bestehende Controller-/Meta-/Terrain-/Simulation-Skripte nur bei einem
  belegten dominanten Scope.
- Diese Task-Datei sowie Status, Roadmap und Zwischenbericht.

## Lokale Pruefung

- Neuer TASK-1061-Trace.
- `task_1060_multi_fireteam_first_command_player_grip.gd`.
- `task_1059_multi_fireteam_first_contact_runtime_trace.gd`.
- `task_396_mission_dropship_lz_drop_hotfix.gd`.
- `task_503_mission_dropship_fireteam_hud_truth.gd`.
- `git diff --check`.

## Risiken / offene Punkte

Headless-Zeiten sind kein Hardware- oder FPS-Vertrag. Sie dienen nur dazu,
den dominanten Codepfad zwischen vergleichbaren Laeufen zu erkennen. Die
Messung muss deshalb relative Scope-Anteile und keine ungeprueften absoluten
Grenzwerte als Grundlage fuer einen Fix verwenden.

## Ergebnis

- TASK_1061 prueft 11/11 den echten Alpha-/Beta-Pfad inklusive Transfer,
  Deboarding, Contact, Preview, `GO` und Coordination.
- Der opt-in Trace teilt Controller-UI in Labels, Panels, Runtime-Surfaces
  und sekundare Controls und zerlegt Runtime-Surfaces weiter in
  Craft-Controls, World-Overlays, Primary3D-Status, Fireteam-Cards und
  Sichtbarkeit.
- In vergleichbaren Headless-Laeufen waren Runtime-Surfaces und
  Fireteam-Cards der wiederkehrende Script-Kandidat; Welt-Overlays und
  Primary3D-Status blieben deutlich kleiner. Absolute Gesamtzeiten bleiben
  bewusst kein FPS-Vertrag.
- Ein konkreter Rebuild wurde entfernt: Bei einer sich aendernden Suppression
  bleiben unveraenderte Sicherheitsabdeckungs-Segmente der Mini-Card bestehen.
  Nur bei einer echten Form-/Rollen-Aenderung werden sie neu aufgebaut.
- Die breite Karten- und Text-Refresh-Kosten bleiben Folgearbeit; sie werden
  nicht mit diesem kleinen Guard als geloest behauptet.
