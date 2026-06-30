# TASK_688 - Mission Interaction FullHD Evidence

## Ziel / Problem
TASK_686/687 machen Mission-Interactions sichtbar und lassen Objekte reagieren. Was noch fehlt, ist ein reproduzierbares FullHD-Evidenzpaket fuer das Missionsbild: Sind Visualstate-Labels, Objektreaktionen und Renderbudgets im selben Snapshot vorhanden, ohne dass ein manueller Sichttest behauptet wird?

## Sinnhaftigkeit / Ursache
Die neuen Visuals sollen das Spiel angenehmer und schicker machen. Headless-Verifier pruefen bisher nur Daten- und Render-Snapshot-Zaehler, aber kein dauerhaftes PNG/JSON-Paket fuer Review und Handbuch. TASK_688 schreibt deshalb ein FullHD-Evidence-PNG und ein Manifest aus derselben Mission-Szene.

## Umfang
- Neuer Verifier `task_688_mission_interaction_fullhd_evidence.gd`.
- Mission bei `1920 x 1080` instanziieren und bis zum aktiven Computer-Schritt bringen.
- 3D-Mission-Status synchronisieren.
- Render-Snapshot, Visualstate, Object-Reaction und Command-Feedback in ein JSON-Manifest schreiben.
- PNG schreiben: echter Viewport-Readback, wenn verfuegbar; sonst ein generiertes Evidence-Board.
- Doku, Roadmap, Status und HTML-Handbuch fortschreiben.

## Nicht-Ziele
- Kein menschlicher FullHD-Sichtentscheid.
- Kein Door-/Asset-Swap.
- Kein neues Gameplay-System.
- Keine Mutation von Terrain-, Door-, Cargo- oder Objective-State.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_687_mission_interaction_object_reaction.md`
- `docs/tasks/TASK_686_mission_interaction_visual_state.md`

## Akzeptanzkriterien
- PNG existiert und hat `1920 x 1080`.
- Manifest existiert und nennt Schema, Pfade, DisplayServer und Viewport-Readback-Status.
- Render-Snapshot enthaelt Visualstate- und Object-Reaction-Zaehler.
- Evidence markiert `manual_fullhd_review_required = true` und `manual_fullhd_review_done = false`.
- Evidence bleibt read-only und meldet `ui_sets_gameplay_truth = false`.
- Visualbudget bleibt innerhalb eines konservativen kleinen Evidence-Limits.

## Betroffene Dateien
- `scripts/tests/task_688_mission_interaction_fullhd_evidence.gd`
- `docs/tasks/TASK_688_mission_interaction_fullhd_evidence.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_688_mission_interaction_fullhd_evidence.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_687_mission_interaction_object_reaction.gd`
- `git diff --check`

## Risiken / offene Punkte
- Headless-Laeufe erzeugen ein Review-Board statt einer echten Fensteransicht. Der menschliche FullHD-Sichtentscheid bleibt weiterhin offen.
