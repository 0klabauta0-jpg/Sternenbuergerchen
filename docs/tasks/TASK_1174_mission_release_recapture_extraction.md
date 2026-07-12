# TASK_1174 - Mission Release Recapture Extraction

## Ziel / Problem
Die neuesten Release-Recapture-Methoden fuer First Contact und First Engagement liegen noch im historisch gewachsenen `scripts/tests/mission_tactical_sandbox_controller.gd`. Dadurch waechst der Testcontroller weiter, obwohl die beiden Methoden nur vorhandene Daten zusammenfassen.

## Ursache / Sinnhaftigkeit
Der Controller ist ein Legacy-Bridge-Pfad und bereits sehr gross. Die Recapture-Logik ist datenrein: Sie braucht vorbereitete Handoffs, vorhandene Release-Evidence und Check-Listen, aber keine Nodes, keine UI und keine Simulation. Sie gehoert deshalb als wiederverwendbarer Contract-Builder nach `scripts/mission/`.

## Umfang
- `MissionReleaseRecaptureService` unter `scripts/mission/` anlegen.
- TASK_1172- und TASK_1173-Recapture-Datentransformation unveraendert in den Service verschieben.
- `MissionTacticalSandboxController` behaelt seine oeffentlichen Snapshot-Methoden und sammelt nur noch vorhandene Runtime-/Release-Evidence ein.
- Einen kleinen datenreinen Verifier fuer beide Service-Ausgaben bereitstellen.

## Nicht-Ziele
- Keine Aenderung am sichtbaren Spielerflow, Combat, UI, Export, Multiplayer oder Capture-Format.
- Keine Extraktion aelterer Controller-Funktionen in diesem Task.
- Keine SceneTree- oder Registry-Abfragen im neuen Service.

## Relevante Contracts / Dokumente
- `docs/dev/runtime_script_layout_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1172_first_contact_readability_release_recapture.md`
- `docs/tasks/TASK_1173_first_engagement_feedback_release_recapture.md`

## Akzeptanzkriterien
- `scripts/mission/mission_release_recapture_service.gd` enthaelt datenreine Builder fuer TASK_1172 und TASK_1173.
- Der Controller exponiert weiterhin dieselben oeffentlichen Methoden und delegiert an den Service.
- Service und bestehende TASK_1172-/TASK_1173-Verifier melden identische `schema`, `task_id`, `status`, Read-only-Flags und naechste Task.
- Der neue Service importiert keine UI-, Terrain-, Combat- oder SceneTree-Abhaengigkeiten.

## Betroffene Dateien
- `scripts/mission/mission_release_recapture_service.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1174_mission_release_recapture_extraction.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_1174_mission_release_recapture_extraction.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_1172_first_contact_readability_release_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_1173_first_engagement_feedback_release_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Extraction darf Contract-Felder nicht unbemerkt umbenennen; die bestehenden Recapture-Verifier bleiben deshalb Pflicht.
- Weitere Legacy-Methoden im Controller brauchen jeweils eigene kleine Extraction-Tasks.
