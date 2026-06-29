# TASK_600 - Integrated Core Loop Flow Polish Findings

## Ziel / Problem
TASK_599 hat den aktuellen Core Loop als Composite-Evidence-Manifest zusammengefuehrt. Was noch fehlt, ist eine konkrete, priorisierte Flow-Polish-Liste, damit der naechste Schritt nicht wieder diffus wird.

## Sinnhaftigkeit / Ursache
Der Gesamtfluss ist technisch belegt, aber noch nicht als angenehm spielbarer Durchlauf bewiesen. Die offenen Punkte aus TASK_599 sind vor allem menschliche Reibungen: Pacing, Klickgefuehl, HUD-Dichte und Host/Client-Gefuehl. Diese Punkte muessen als kleine, bearbeitbare Folge-Slices sichtbar werden.

## Umfang
- Ein Verifier schreibt `tmp/integrated_core_loop_flow_polish_findings.json`.
- Das Manifest priorisiert die aktuellen Flow-Polish-Findings aus TASK_599.
- Der HTML-Zwischenbericht erhaelt einen exportierbaren TASK_600-Block mit Findings, naechstem Task und manueller Review-Checkliste.
- TASK_600 bleibt read-only: Es dokumentiert und priorisiert Reibungen, ohne Gameplay-State, UI-State oder MissionResult zu veraendern.

## Nicht-Ziele
- Kein echter menschlicher FullHD-Playtest wird behauptet.
- Kein Combat-, UI-, XP-, Roster-, Multiplayer- oder Missions-Rewrite.
- Keine neue Runtime-Wahrheit im Bericht.
- Keine Aenderung an Spielerbefehlen, Simulation oder Hotpaths.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_599_integrated_core_loop_playtest_evidence_pass.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- `scripts/tests/task_600_integrated_core_loop_flow_polish_findings.gd` erzeugt ein JSON-Manifest unter `tmp/`.
- Das Manifest enthaelt `schema = sternenbuergerchen.integrated_core_loop_flow_polish_findings.v1`.
- Mindestens vier konkrete Findings sind als bearbeitbare Folge-Slices enthalten.
- Das Manifest meldet `read_only = true`, `ui_sets_gameplay_truth = false`, `manual_full_playtest_done = false`.
- Der HTML-Zwischenbericht nennt TASK_600 als erledigt, exportiert den Manifestpfad und empfiehlt TASK_601 fuer den echten Core-Loop-FullHD-Capture.

## Betroffene Dateien
- `scripts/tests/task_600_integrated_core_loop_flow_polish_findings.gd`
- `docs/tasks/TASK_600_integrated_core_loop_flow_polish_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_600_integrated_core_loop_flow_polish_findings.gd`
- Regression: `task_599_integrated_core_loop_playtest_evidence_pass.gd`
- Regression: `task_598_homebase_progression_evidence_polish_findings.gd`
- Regression: `task_596_homebase_progression_player_review_notes.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_600 ist eine priorisierte Flow-Polish-Queue, keine vollzogene visuelle oder spielerische Korrektur.
- TASK_601 sollte als naechstes den echten FullHD-Core-Loop-Capture liefern, damit Pacing, HUD-Dichte und Klickgefuehl nicht nur indirekt bewertet werden.
