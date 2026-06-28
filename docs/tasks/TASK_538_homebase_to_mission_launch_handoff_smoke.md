# TASK_538 - Homebase To Mission Launch Handoff Smoke

## Status: IMPLEMENTIERT

## Ziel / Problem
Der Pre-Mission-Startflow ist lesbar, aber der naechste spielbare Schritt muss beweisen, dass der startbereite Homebase-Zustand wirklich konsistent in die aktive Mission uebergeben wird.

## Sinnhaftigkeit / Ursache
Review- und Playtest-Risiken lagen mehrfach an Handoff-Grenzen: Fireteam-Auswahl, Dropship-Payload, Loadout, Teamzuordnung und Mission-Daten konnten sichtbar richtig wirken, aber spaeter an anderer Stelle anders ankommen. Dieser Task macht den Uebergang beobachtbar und regressionstestbar.

## Umfang
- `MetaLayerFlow` expose't einen read-only `get_homebase_to_mission_handoff_snapshot()`.
- Der Snapshot vergleicht Mission-Auswahl, Planning-State, aktiven Mission-Setup-State, Fireteam-Definitionen, Member-Loadouts, Dropship-Karte und Timer-Start.
- Ein Smoke startet eine Homebase-Direktmission ueber den bestehenden `request_mission_start()`-Pfad.
- Der Rolling-HTML-Bericht nennt TASK_538 als erledigten Zwischenstand und verschiebt den naechsten Anschluss auf Mission-Insertion-/First-Order-Readability.

## Nicht-Ziele
- Kein neuer Mission-Start-Guard.
- Keine Aenderung an Boarding-/Dropship-Mechanik.
- Kein Mission-Controller-Refactor.
- Keine neue Multiplayer-Session-Logik.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_537_pre_mission_f6_screenshot_visual_audit.md`
- `docs/tasks/TASK_534_pre_mission_readiness_checklist.md`
- `docs/dev/mission_briefing_contract.md`
- `docs/dev/runtime_script_layout_contract.md`

## Akzeptanzkriterien
- Startbereiter Homebase-Direktpayload startet eine aktive Mission.
- `MissionSetup` erhaelt dieselben Unit-IDs, Fireteam-IDs, Fireteam-Definitionen und Member-Loadouts wie der Handoff-Snapshot.
- Der Dropship-Planning-State nennt Quelle, Craft-ID, Passagiere und Karte konsistent.
- Der Starttimer ist gesetzt.
- Der Snapshot bleibt read-only und setzt `ui_sets_gameplay_truth = false`.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_538_homebase_to_mission_launch_handoff_smoke.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_538_homebase_to_mission_launch_handoff_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_537_pre_mission_f6_screenshot_visual_audit.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_536_startflow_icon_status_color_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- Dieser Smoke beweist den Start-Handoff, aber noch nicht, ob die erste Insertion, LZ-Wahl und erste Befehlsrunde im Missionsbild angenehm genug lesbar sind. Das ist der naechste sinnvolle Slice.
