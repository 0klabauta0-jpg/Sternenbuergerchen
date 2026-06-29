# TASK_601 - Core Loop Manual FullHD Playtest Capture

## Ziel / Problem
TASK_600 priorisiert die offenen Flow-Reibungen, aber es fehlt noch ein konkreter FullHD-Capture-Ort fuer den gesamten Core Loop. Ohne Bild-/Manifest-Artefakt bleiben Pacing, HUD-Dichte, Klickfluss und Host/Client-Gefuehl zu indirekt.

## Sinnhaftigkeit / Ursache
Das Spiel soll angenehm spielbar und multiplayer-faehig werden. Dafuer reicht ein Composite-Manifest nicht: Der Spielerblick braucht einen reproduzierbaren FullHD-Arbeitsstand, der Route, Pflichtchecks und offene Notizen sichtbar macht.

## Umfang
- Ein Verifier schreibt `tmp/core_loop_manual_fullhd_playtest_capture.png`.
- Ein Manifest schreibt `tmp/core_loop_manual_fullhd_playtest_capture.json`.
- Der Capture deckt den Pfad `Homebase -> Briefing/Loadout -> Dropship -> Mission -> Debrief -> Homebase Progression` als FullHD-Evidence-Board ab.
- Der HTML-Zwischenbericht erhaelt einen exportierbaren TASK_601-Block mit Screenshotpfad, Manifestpfad, Pflichtchecks, Ratings und freier Review-Notiz.
- Der Task bleibt read-only und behauptet keinen abgeschlossenen menschlichen Playtest.

## Nicht-Ziele
- Kein neuer Meta-/Mission-Flow.
- Kein Combat-, UI-, Multiplayer- oder Progressions-Rewrite.
- Keine Runtime-Mutation und keine zweite Gameplay-Wahrheit im Bericht.
- Kein automatischer Ersatz fuer einen echten menschlichen Spielgefuehl-Entscheid.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_600_integrated_core_loop_flow_polish_findings.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- `scripts/tests/task_601_core_loop_manual_fullhd_playtest_capture.gd` erzeugt PNG und JSON unter `tmp/`.
- Das Manifest enthaelt `schema = sternenbuergerchen.core_loop_manual_fullhd_playtest_capture.v1`.
- Das Manifest meldet die sechs Core-Loop-Stages, vier Pflichtchecks und `manual_review_done = false`.
- Der HTML-Zwischenbericht nennt TASK_601 als erledigt, exportiert Screenshot-/Manifestpfad und empfiehlt TASK_602 fuer belegten Pacing-Polish.
- Alle Daten bleiben read-only: `read_only = true`, `ui_sets_gameplay_truth = false`.

## Betroffene Dateien
- `scripts/tests/task_601_core_loop_manual_fullhd_playtest_capture.gd`
- `docs/tasks/TASK_601_core_loop_manual_fullhd_playtest_capture.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_601_core_loop_manual_fullhd_playtest_capture.gd`
- Regression: `task_600_integrated_core_loop_flow_polish_findings.gd`
- Regression: `task_599_integrated_core_loop_playtest_evidence_pass.gd`
- Regression: `task_596_homebase_progression_player_review_notes.gd`
- `git diff --check`

## Risiken / offene Punkte
- Headless erzeugt ein Evidence-Board, keinen echten Fenster-Screenshot. Ein echter Sichtentscheid bleibt manuell.
- TASK_602 sollte nur dann Pacing-Polish anwenden, wenn TASK_601-Export oder echter Screenshot konkrete Reibung zeigt.
