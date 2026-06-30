# TASK_690 - Mission Interaction Manual Sight Notes

## Ziel / Problem
TASK_689 zeigt: Der technische Mission-Interaction-Visualpfad ist gruen, aber der echte FullHD-Fenster-Sichtentscheid ist noch offen. Dieser offene Punkt soll nicht im Chat verschwinden, sondern als ausfuellbare, exportierbare Review-Schiene festgehalten werden.

## Sinnhaftigkeit / Ursache
Headless-Evidence und Polish-Findings koennen Zaehler, Budgets und Read-only-Regeln pruefen. Ob Labels, Objekt-Proxies, HUD-Dichte und Kartenlesbarkeit im echten Fenster angenehm wirken, braucht weiterhin menschliche Beobachtung. TASK_690 macht diesen Schritt strukturiert, ohne Gameplay-Wahrheit zu behaupten.

## Umfang
- Neuer Service `MissionInteractionManualSightNotes`.
- Verifier `task_690_mission_interaction_manual_sight_notes.gd`.
- JSON-Manifest unter `tmp/mission_interaction_manual_sight_notes.json`.
- Interaktive HTML-Workbench `docs/reports/mission_interaction_manual_sight_notes_2026_06_30.html`.
- Doku, Roadmap, Status und aktuelles HTML-Handbuch fortschreiben.

## Nicht-Ziele
- Kein automatischer visueller Freispruch.
- Kein echter menschlicher Fensterlauf in Headless.
- Kein Label-/Proxy-Polish.
- Kein Door-Asset-Swap.
- Kein Gameplay-State-Commit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_689_mission_interaction_visual_polish_findings.md`
- `docs/tasks/TASK_688_mission_interaction_fullhd_evidence.md`

## Akzeptanzkriterien
- Snapshot nennt Schema, Quellen, Required-Checks, Notizfelder und `manual_review_done = false`.
- Snapshot ist read-only und meldet `ui_sets_gameplay_truth = false`.
- Offene manuelle Sichtabnahme bleibt als `awaiting_manual_notes` sichtbar.
- HTML-Workbench hat sichtbare Checklisten, Notizfelder, Evidence-Pfade und Button `JSON exportieren`.
- Export-Daten bleiben Arbeitsnotizen und erzeugen keine Runtime-/Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/mission_interaction_manual_sight_notes.gd`
- `scripts/tests/task_690_mission_interaction_manual_sight_notes.gd`
- `docs/tasks/TASK_690_mission_interaction_manual_sight_notes.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/mission_interaction_manual_sight_notes_2026_06_30.html`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_690_mission_interaction_manual_sight_notes.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_689_mission_interaction_visual_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Workbench macht den manuellen Sichtlauf nur sauber erfassbar. Sie ersetzt weiterhin nicht die echte Fensterbeobachtung.
