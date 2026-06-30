# TASK_676 - Mission Interaction Use Feedback

## Ziel / Problem
TASK_675 liefert den read-only Runtime-Use-State fuer AA-Zone, Station-Computer und Cargo-Hold. Fuer den Spieler fehlt noch eine kompakte Rueckmeldung: Was kann das ausgewaehlte Fireteam jetzt tun, was ist blockiert, was laeuft und was ist fertig?

## Sinnhaftigkeit / Ursache
Der Use-State ist maschinenlesbar, aber noch nicht als Spieler-/Verifier-Feedback aufbereitet. Ohne Presenter muessten HUD, Eventlog oder Tests die Rohdaten selbst interpretieren. Das wuerde schnell zu doppelten Textregeln und UI-Parallelwissen fuehren.

## Umfang
- `MissionInteractionUseFeedback` als Mission-Presenter fuer den TASK_675-Snapshot anlegen.
- Feedback-Prioritaet festlegen: `in_progress` vor `usable`, dann nahe `blocked`, dann `out_of_range`, `complete`, `unknown`.
- Kurze `feedback_line`, `action_label`, `detail_text`, `severity` und `selected_relevance` liefern.
- `MissionTacticalSandboxController.get_mission_interaction_use_feedback_snapshot()` und Export im bestehenden `get_command_feedback_snapshot()`.
- Doku, Roadmap, Status und HTML-Handbuch fortschreiben.
- Verifier fuer Helper und Controller-/Command-Feedback-Anschluss.

## Nicht-Ziele
- Kein Use-Button.
- Keine SimulationRoot-Mutation.
- Kein Door-/Computer-/Hold-Fortschrittsproducer.
- Kein sichtbarer HUD-Umbau und kein neuer per-frame UI-Rebuild.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_675_mission_interaction_runtime_use_state.md`
- `docs/tasks/TASK_674_mission_interaction_point_bindings.md`
- `docs/dev/runtime_script_layout_contract.md`

## Akzeptanzkriterien
- Feedback ist read-only und setzt `ui_sets_gameplay_truth = false`.
- Aus einem `usable` Cargo-Hold entsteht eine klare `CARGO ... bereit`-Zeile mit passendem Required-Order-Hinweis.
- Ein `blocked` Cargo-Hold nennt den Blocker, statt nur stumm nicht bedienbar zu sein.
- Ein `in_progress` Computer zeigt Progress/Hold-Zeit kompakt.
- Controller und `get_command_feedback_snapshot()` exportieren denselben Feedback-Snapshot.
- Der Verifier `scripts/tests/task_676_mission_interaction_use_feedback.gd` laeuft gruen.

## Betroffene Dateien
- `scripts/mission/mission_interaction_use_feedback.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_676_mission_interaction_use_feedback.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_676_mission_interaction_use_feedback.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_676_mission_interaction_use_feedback.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_675_mission_interaction_runtime_use_state.gd`
- `git diff --check`

## Risiken / offene Punkte
- Das Feedback ist noch keine echte Bedienaktion. Danach sollte entweder ein kleiner Use-Command oder ein Runtime-Fortschrittsproducer fuer Computer-/Hold-Zonen folgen.
