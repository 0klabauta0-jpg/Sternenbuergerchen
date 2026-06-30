# TASK_677 - Mission Interaction Use Intent

## Ziel / Problem
TASK_676 macht AA-/Computer-/Cargo-Interactions als Spielerfeedback lesbar. Es fehlt noch der naechste spielbare Schritt: Aus `CARGO bereit` oder `COM bereit` soll ein echter Befehls-Intent fuer das ausgewaehlte Fireteam entstehen, statt nur ein Text zu bleiben.

## Sinnhaftigkeit / Ursache
Die aktuellen Interactions duerfen keine UI-Wahrheit werden. Ein direkter Gate-Commit waere falsch, und der bestehende Ad-hoc-Pfad unterstuetzt keine `take`-/`defend`-Orders. Der passende erste Schritt ist daher ein geplanter Waypoint-Intent mit dem gebundenen `required_order`, der spaeter ueber GO den bestehenden Mission-Tactical-Pfad nutzt.

## Umfang
- Controller-Methode `create_selected_mission_interaction_use_intent(interaction_id = "")` anlegen.
- Primaere oder explizite Interaction aus `MissionInteractionUseFeedback`/Use-State aufloesen.
- `required_order` auf erlaubte Waypoint-Kommandos mappen (`take`, `defend`, `move`, `flank`; `hold` -> `defend`, `operate`/`breach` -> `take`).
- Einen geplanten Waypoint fuer das passende Fireteam am Interaction-Marker erzeugen und dessen Command-Type setzen.
- Command-Feedback/Last-Command-Text und Snapshot fuer Verifier exportieren.
- Doku, Roadmap, Status und HTML-Handbuch fortschreiben.

## Nicht-Ziele
- Kein direkter Scenario-Gate-Commit.
- Keine Door-Animation.
- Kein Computer-Hack-Minispiel.
- Kein neuer Ad-hoc-Order-Typ.
- Kein automatisches GO.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_676_mission_interaction_use_feedback.md`
- `docs/tasks/TASK_675_mission_interaction_runtime_use_state.md`
- `docs/dev/runtime_script_layout_contract.md`

## Akzeptanzkriterien
- Bei nutzbarem Cargo-Hold erzeugt der Use-Intent einen `defend`-Waypoint am Cargo-Marker.
- Bei nutzbarem Station-Computer erzeugt der Use-Intent einen `take`-Waypoint am Computer-Marker.
- Blockierte oder ausser Reichweite liegende Interactions erzeugen keinen Waypoint und liefern einen klaren Blockgrund.
- Der Intent bleibt read-only gegen Scenario-/Objective-Wahrheit und setzt `ui_sets_gameplay_truth = false`.
- Der neue Intent-Snapshot ist im `get_command_feedback_snapshot()` sichtbar.
- Der Verifier `scripts/tests/task_677_mission_interaction_use_intent.gd` laeuft gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_677_mission_interaction_use_intent.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_677_mission_interaction_use_intent.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_677_mission_interaction_use_intent.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_676_mission_interaction_use_feedback.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Intent ist noch kein fertiger Interaction-Resolver. Abschluss, Hold-Fortschritt und Gate-State brauchen einen spaeteren Runtime-Produzenten.
