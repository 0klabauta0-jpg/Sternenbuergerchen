# TASK_642 - Frontier Probe Homebase Visible Readiness Review

## Ziel / Problem
TASK_641 macht den naechsten Homebase-Schritt nach Frontier-Probe-Debrief-Return technisch und textlich sichtbar. Jetzt braucht dieser Zustand ein sichtbares Review-Paket, damit weitere Polishes aus einem belegten Homebase-Blick entstehen und nicht aus Vermutung.

## Sinnhaftigkeit / Ursache
Die Rueckkehr zur Homebase ist ein wichtiger Core-Loop-Moment. Wenn die neue Next-Sortie-Zeile zwar existiert, aber im echten Layout ueberlaeuft, untergeht oder mit der Debrief-Summary kollidiert, fuehlt sich der Loop weiterhin rau an. TASK_642 prueft deshalb Sichtbarkeit, Reihenfolge, Panel-Bounds und schreibt PNG/Manifest fuer den Review.

## Umfang
- `HomebaseTestScreen.get_frontier_probe_homebase_visible_readiness_review_snapshot()` fuer sichtbare Readiness-Review-Daten.
- Verifier erzeugt `tmp/frontier_probe_homebase_visible_readiness_review.png`.
- Verifier erzeugt `tmp/frontier_probe_homebase_visible_readiness_review.json`.
- Rolling HTML-Report und Ist-Stand-/Handbuch-Report werden fortgeschrieben.

## Nicht-Ziele
- Kein neuer Button, keine neue Navigation und kein automatischer Start.
- Kein Layout-Redesign der Homebase.
- Keine Progression-/MissionResult-Aenderung.
- Kein finaler menschlicher Geschmackstest; der bleibt als manuelle Review offen.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_641_frontier_probe_homebase_next_sortie_readiness.md`
- `docs/tasks/TASK_640_frontier_probe_post_debrief_homebase_readability.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Akzeptanzkriterien
- Der Snapshot liefert `schema = sternenbuergerchen.frontier_probe_homebase_visible_readiness_review.v1`.
- `readiness_gate = pass`, `post_summary_visible = true`, `next_sortie_visible = true`.
- Post-Debrief- und Next-Sortie-Zeile liegen im MissionPanel und ueberlappen nicht.
- Next-Sortie-Zeile sitzt unter der Post-Debrief-Zeile und bleibt kompakt.
- Manifest enthaelt PNG-Pfad, Rects, `manual_review_required = true`, `manual_review_done = false`.
- `read_only = true`, `ui_sets_gameplay_truth = false`, `creates_navigation = false`, `creates_command = false`.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_642_frontier_probe_homebase_visible_readiness_review.gd`
- `docs/tasks/TASK_642_frontier_probe_homebase_visible_readiness_review.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`
- angrenzende Report-Regressions unter `scripts/tests/task_641_*.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_642_frontier_probe_homebase_visible_readiness_review.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_641_frontier_probe_homebase_next_sortie_readiness.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_640_frontier_probe_post_debrief_homebase_readability.gd`
- `git diff --check`

## Risiken / offene Punkte
- Headless kann statt echtem Viewport nur ein Evidence-Board erzeugen. Ein sichtbarer Nicht-Headless-F6/Homebase-Blick bleibt fuer finales Spielgefuehl sinnvoll.
- TASK_642 bewertet belegbare Layout-Gates, aber noch keine Schoenheit im engeren Sinn.
- Naechster sinnvoller Schritt: `TASK_643 - Frontier Probe Homebase Readiness Visual Polish Findings`, falls PNG/Manifest oder echter Fensterblick konkrete Reibung zeigen.
