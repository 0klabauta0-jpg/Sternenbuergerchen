# TASK_284 - Gameplay Truth Architecture Boundary Audit

## Ziel
Der Code soll darauf geprueft werden, ob Gameplay-Wahrheit weiterhin an den richtigen Stellen liegt. UI, Visualizer, Help-Popups, Editor und Multiplayer-Preview duerfen keine heimliche zweite Wahrheit erzeugen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_166 - Multiplayer Authority Command Contract
- TASK_168 - Multiplayer Snapshot Contract
- TASK_191 - Command Chain Selection and Area Feedback Pass
- TASK_247 - Used Asset Project Locality Audit Gate
- TASK_270 - Commander to Fireteam Leader Delegation Contract
- TASK_281 - Tactical Command Multiplayer Authority Snapshot
- TASK_282 - Tactical Overhaul Playability Performance Help Gate
- TASK_283 - Post Tactical Docs Consistency Audit

## Kontext
Mit Command-UI, Multi-Fireteam-Planung, Ausbruechen, Help-Popups, Editorprofilen und AirAssetStatus entstehen viele neue Beruehrungspunkte. Genau dort schleichen sich gern "nur kurz hier speichern wir den State"-Abzweige ein. Dieser Audit sucht diese Abzweige gezielt.

## Umfang
1. Authority-Linien:
   - SimulationRoot/Runtime-Komponenten setzen Gameplay-State.
   - TacticalController/Command-Schicht erstellt Commands/Intents, nicht Wahrheit.
   - UI liest Snapshots und sendet Commands.
   - Visualizer rendert Snapshots.
   - Editor schreibt Authoringdaten, nicht laufenden Runtime-State.
2. Mutationssuche:
   - UI-Dateien auf direkte Unit-/Mission-/AirAsset-Mutationen pruefen.
   - Visualizer auf Runtime-State-Schreibzugriffe pruefen.
   - Help-/Tooltip-Schicht auf State-Mutation pruefen.
   - Multiplayer-Clientpfade auf verbotene Mutationen pruefen.
3. Datenpfade:
   - CommanderIntent -> FireteamExecutionPlan -> UnitAction.
   - BreakoutState.
   - TacticalCommunicationEvent.
   - AirAssetStatus.
   - Loadout/Gewicht und Character Card.
4. Report:
   - Befunde als Code-Review-Liste mit Datei, Zeile, Risiko, vorgeschlagenem Fix.
   - Keine grossen Fixes im Audit selbst.
5. Guard-Verifier:
   - Statische Muster fuer verbotene Pfade.
   - Laufzeit-Snapshots fuer UI-only Aktionen ohne SimulationRoot-Mutation.

## Nicht-Ziele
- Kein kompletter Architekturrewrite.
- Keine neuen Gameplayfeatures.
- Keine groben Umbenennungen.
- Kein pauschales Blockieren legitimer Testhelpers.

## Akzeptanzkriterien
- [x] UI/Visualizer/Help schreiben keinen autoritativen Gameplay-State.
- [x] Editor-Daten sind klar von Runtime-State getrennt.
- [x] Multiplayer-Clientpfade umgehen Command-Whitelist nicht.
- [x] Tactical-, AirAsset- und Loadout-Datenpfade haben je eine klare Quelle der Wahrheit.
- [x] Befunde sind mit Datei/Zeile und Schweregrad dokumentiert.
- [x] Ein Verifier erkennt bekannte verbotene Mutation-Muster.

## Erwartete Dateien
- `docs/reviews/gameplay_truth_architecture_boundary_audit.md`
- `scripts/tests/task_284_gameplay_truth_architecture_boundary_audit.gd`
- optional `scripts/tests/run_task_284_truth_boundary_scan.ps1`
- `docs/tasks/TASK_284_gameplay_truth_architecture_boundary_audit.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_284_gameplay_truth_architecture_boundary_audit.gd`
- [x] `powershell -ExecutionPolicy Bypass -File scripts/tests/run_task_284_truth_boundary_scan.ps1`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_166_multiplayer_authority_command_contract_verifier.gd`
- [x] `git diff --check`

## Risiken
- Rein statische Suche kann False Positives liefern. Report muss Pfadtyp und Kontext bewerten.
- Audit darf nicht legitime Command-Erzeugung mit State-Mutation verwechseln.

## Naechster Schritt
Nach TASK_284 prueft TASK_285 die Entscheidungslogik auf verschampfte Nebenabzweige.
