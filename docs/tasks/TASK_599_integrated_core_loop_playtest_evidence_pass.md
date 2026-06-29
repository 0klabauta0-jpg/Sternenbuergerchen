# TASK_599 - Integrated Core Loop Playtest Evidence Pass

## Ziel / Problem
Die letzten Slices haben Homebase, Briefing/Startflow, Dropship, Mission, Debrief und Homebase-Progression einzeln abgesichert. Es fehlt ein laufender, maschinenlesbarer Zwischenstand, der diese Einzelbeweise als einen Core-Loop-Evidence-Pass zusammenfuehrt.

## Sinnhaftigkeit / Ursache
Das Spiel soll angenehmer und spielbarer werden. Einzelne gruene Panel- oder Snapshot-Gates reichen dafuer nicht als Ueberblick: Man muss sehen koennen, ob der Pfad `Homebase -> Dropship -> Mission -> Objective/Combat -> Debrief -> Homebase -> Progression` als Kette belegt ist und wo noch echte menschliche Sicht-/Spielgefuehl-Pruefung fehlt.

## Umfang
- Ein Verifier schreibt `tmp/integrated_core_loop_playtest_evidence.json`.
- Das Manifest referenziert die aktuellen gruenen Flow-Smokes:
  - Homebase -> Mission Launch-Handoff.
  - Mission Fire/Cover Integrated Flow.
  - Frontier-Probe Objective/Cargo Integrated Playthrough.
  - Debrief -> Homebase Return-Handoff.
  - Skill-Award-Contract und Homebase-Progression-Evidence.
- Der HTML-Zwischenbericht zeigt TASK_599 als erledigten Evidence-Pass und exportiert den Manifestpfad.
- Der Pass bleibt read-only und behauptet keinen manuellen FullHD-Playtest.

## Nicht-Ziele
- Kein neues Missionssystem.
- Kein Combat-, XP-, Skill-, Roster- oder Multiplayer-Rewrite.
- Kein neuer Screenshot-Capture-Pfad.
- Keine Behauptung, dass ein Mensch den ganzen Flow final als angenehm bestaetigt hat.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_538_homebase_to_mission_launch_handoff_smoke.md`
- `docs/tasks/TASK_545_mission_fire_cover_integrated_flow_smoke.md`
- `docs/tasks/TASK_554_frontier_probe_integrated_objective_playthrough_smoke.md`
- `docs/tasks/TASK_586_debrief_return_homebase_handoff.md`
- `docs/tasks/TASK_593_skill_progress_award_contract.md`
- `docs/tasks/TASK_597_homebase_progression_f6_evidence_capture.md`
- `docs/tasks/TASK_598_homebase_progression_evidence_polish_findings.md`

## Akzeptanzkriterien
- `scripts/tests/task_599_integrated_core_loop_playtest_evidence_pass.gd` erzeugt ein JSON-Manifest unter `tmp/`.
- Das Manifest enthaelt `schema = sternenbuergerchen.integrated_core_loop_playtest_evidence.v1`.
- Alle Kernschritte sind als eigene Evidence-Steps mit Scriptpfad und Status aufgefuehrt.
- Das Manifest meldet `read_only = true`, `ui_sets_gameplay_truth = false`, `manual_full_playtest_done = false`.
- Der HTML-Zwischenbericht nennt TASK_599 als erledigt, exportiert den Manifestpfad und empfiehlt TASK_600 fuer konkrete Flow-Polish-Findings.

## Betroffene Dateien
- `scripts/tests/task_599_integrated_core_loop_playtest_evidence_pass.gd`
- `docs/tasks/TASK_599_integrated_core_loop_playtest_evidence_pass.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_599_integrated_core_loop_playtest_evidence_pass.gd`
- Stichprobenweise die referenzierten Flow-Smokes:
  - `task_538_homebase_to_mission_launch_handoff_smoke.gd`
  - `task_554_frontier_probe_integrated_objective_playthrough_smoke.gd`
  - `task_586_debrief_return_homebase_handoff.gd`
  - `task_597_homebase_progression_f6_evidence_capture.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Pass ist ein Composite-Evidence-Manifest, kein echter manueller Durchspieltest.
- TASK_600 sollte nur konkrete Flow-Polish-Findings anwenden, falls der naechste echte F6-/Playtest sichtbare Reibung zeigt.
