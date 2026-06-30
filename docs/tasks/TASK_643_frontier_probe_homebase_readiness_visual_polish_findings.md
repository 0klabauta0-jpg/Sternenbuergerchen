# TASK_643 - Frontier Probe Homebase Readiness Visual Polish Findings

## Ziel / Problem
TASK_642 erzeugte ein Homebase-Visible-Readiness-PNG, aber das Headless-Evidence-Board war fuer sich allein zu wenig erklaerend: farbige Rechtecke ohne sichtbare Callout-Bedeutung sind als Review-Grundlage schwach.

## Sinnhaftigkeit / Ursache
Weitere Homebase-UI-Polishes sollen aus belegten Befunden entstehen. Wenn das Evidence-Board selbst nicht lesbar ist, entsteht wieder Interpretationsrauschen. TASK_643 poliert deshalb das Review-Artefakt: Titel, Legende, Callouts, aktueller Schritt und Follow-up werden direkt in das PNG gezeichnet und im Manifest messbar gemacht.

## Umfang
- TASK_642-Evidence-Board bekommt Pixel-Textlabels fuer MissionPanel, Post-Debrief-Summary, Next-Sortie-Readiness, Status und Follow-up.
- TASK_642-Manifest meldet `visual_polish_task_id = TASK_643`, `callout_label_count` und `evidence_board_readability_gate`.
- Neuer Verifier prueft Task, Docs, Reports, Manifest-Felder, generiertes PNG und den neuen kompakten Ist-Stand-/Handbuch-Bericht.

## Nicht-Ziele
- Kein Runtime-Homebase-Layoutumbau.
- Kein neuer Button, keine Navigation, kein Command.
- Kein finaler menschlicher Homebase-Geschmackstest.
- Keine Aenderung an Progression, MissionResult oder Readiness-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_642_frontier_probe_homebase_visible_readiness_review.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Akzeptanzkriterien
- `scripts/tests/task_642_frontier_probe_homebase_visible_readiness_review.gd` zeichnet mindestens acht Callout-Labels ins Headless-Evidence-Board.
- Das Manifest enthaelt `visual_polish_task_id = TASK_643`.
- Das Manifest enthaelt `evidence_board_readability_gate = pass`.
- Das Manifest enthaelt `callout_label_count >= 8`.
- Der TASK_643-Verifier erwartet das zuvor erzeugte TASK_642-PNG/Manifest und prueft die neuen Felder.
- `docs/reports/project_state_handbook_2026_06_30.html` existiert als exportierbare Ist-Stand-/Handbuch-Workbench.
- `read_only = true`, `ui_sets_gameplay_truth = false`, `creates_navigation = false`, `creates_command = false` bleiben erhalten.

## Betroffene Dateien
- `scripts/tests/task_642_frontier_probe_homebase_visible_readiness_review.gd`
- `scripts/tests/task_643_frontier_probe_homebase_readiness_visual_polish_findings.gd`
- `docs/tasks/TASK_643_frontier_probe_homebase_readiness_visual_polish_findings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`
- `docs/reports/project_state_handbook_2026_06_30.html`
- angrenzende Report-Regressions unter `scripts/tests/task_642_*.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_642_frontier_probe_homebase_visible_readiness_review.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_643_frontier_probe_homebase_readiness_visual_polish_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_641_frontier_probe_homebase_next_sortie_readiness.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_643 verbessert das Review-Artefakt, nicht die echte Homebase-UI. Der echte Fensterblick bleibt der naechste bessere Entscheidungsanker.
- Naechster sinnvoller Schritt: Ein echter sichtbarer Homebase-Fensterlauf oder, falls dort konkrete Reibung sichtbar ist, ein kleiner Runtime-UI-Polish fuer die Next-Sortie-Zeile.
