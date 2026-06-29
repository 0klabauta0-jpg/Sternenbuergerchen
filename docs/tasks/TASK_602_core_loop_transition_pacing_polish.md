# TASK_602 - Core Loop Transition Pacing Polish

## Ziel / Problem
TASK_601 schafft den FullHD-Capture-Ort, aber die offenen Pacing-Fragen sind noch nicht als konkrete, pruefbare Budgets formuliert. Ohne Zielwerte bleibt unklar, ob ein Uebergang wirklich zu langsam ist oder nur ungewohnt wirkt.

## Sinnhaftigkeit / Ursache
Der Core Loop soll angenehm spielbar werden. Dafuer muessen die Uebergaenge zwischen Homebase, Briefing, Dropship, Mission, Debrief und Progression schnell lesbar sein, ohne den Spieler zu hetzen oder UI-Wahrheit zu erzeugen.

## Umfang
- Ein Verifier schreibt `tmp/core_loop_transition_pacing_polish.json`.
- Das Manifest definiert kleine Zielbudgets fuer die Core-Loop-Uebergaenge.
- Der HTML-Zwischenbericht erhaelt einen exportierbaren TASK_602-Pacing-Block mit Budget, Toleranz, Schweregrad und manuellen Review-Feldern.
- TASK_602 bleibt read-only und erzeugt keine Runtime-Timer, keine Commands und keine Gameplay-Wahrheit.

## Nicht-Ziele
- Kein automatischer Runtime-Speedup.
- Kein neues Lade-/Transition-System.
- Kein UI-Rewrite und keine Animationen.
- Keine Behauptung, dass ein echter Mensch die Zielbudgets bereits bestaetigt hat.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_601_core_loop_manual_fullhd_playtest_capture.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- `scripts/tests/task_602_core_loop_transition_pacing_polish.gd` erzeugt ein JSON-Manifest unter `tmp/`.
- Das Manifest enthaelt `schema = sternenbuergerchen.core_loop_transition_pacing_polish.v1`.
- Mindestens sechs Uebergangsbudgets sind mit Zielzeit, Toleranz und Schweregrad enthalten.
- Der HTML-Zwischenbericht nennt TASK_602 als erledigt, exportiert Pacing-Budget-Felder und empfiehlt TASK_603 fuer Mission-HUD-Dichte.
- Alle Daten bleiben read-only: `read_only = true`, `ui_sets_gameplay_truth = false`.

## Betroffene Dateien
- `scripts/tests/task_602_core_loop_transition_pacing_polish.gd`
- `docs/tasks/TASK_602_core_loop_transition_pacing_polish.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_602_core_loop_transition_pacing_polish.gd`
- Regression: `task_601_core_loop_manual_fullhd_playtest_capture.gd`
- Regression: `task_600_integrated_core_loop_flow_polish_findings.gd`
- Regression: `task_596_homebase_progression_player_review_notes.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_602 setzt Zielbudgets und Review-Felder, misst aber noch keine echten Nutzerzeiten.
- TASK_603 sollte als naechstes die Mission-HUD-Dichte im echten Interaktionsmoment angehen, damit Pacing und Informationsdichte zusammen bewertet werden.
