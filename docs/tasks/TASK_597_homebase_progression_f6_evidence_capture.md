# TASK_597 - Homebase Progression F6 Evidence Capture

## Ziel / Problem
TASK_596 stellt den Review-Ort fuer den Spielerblick auf die Homebase-Progression bereit. Es fehlt noch ein reproduzierbarer Evidence-Lauf, der zeigt, ob die `MISSION GAIN`-Zeile im echten Homebase-/Character-Sheet-Kontext sichtbar, kompakt und innerhalb der erwarteten Panels liegt.

## Sinnhaftigkeit / Ursache
Der Core Loop soll nach dem Einsatz Fortschritt zeigen, ohne dass der Spieler die Information suchen muss. Ein manueller Reviewblock ist hilfreich, aber der naechste robuste Schritt ist ein lokales PNG/JSON-Artefakt, das den aktuellen sichtbaren Zustand belegbar macht.

## Umfang
- `HomebaseTestScreen` liefert einen read-only Evidence-Snapshot fuer die Homebase-Progression im Character-Sheet.
- Der Snapshot misst Popup-, Sheet- und Award-Row-Rects, Badge/Text, Style-ID, Kompaktheit und read-only-Grenze.
- Ein Verifier schreibt `tmp/homebase_progression_f6_evidence.png` und `tmp/homebase_progression_f6_evidence.json`.
- Im Headless-Lauf entsteht ein markiertes Evidence-Board; bei echtem Viewport-Readback kann ein Screenshot genutzt werden.
- Der laufende HTML-Zwischenbericht nennt die neuen Evidence-Pfade und bleibt exportierbar.

## Nicht-Ziele
- Kein neuer menschlicher Geschmackstest.
- Keine XP-, Skill-, Roster- oder Persistenzmutation.
- Kein Character-Sheet-Rewrite.
- Keine Gameplay-Wahrheit im UI oder im HTML-Bericht.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_596_homebase_progression_player_review_notes.md`
- `docs/tasks/TASK_595_homebase_progression_visual_polish.md`

## Akzeptanzkriterien
- `get_homebase_progression_f6_evidence_snapshot()` liefert `schema = sternenbuergerchen.homebase_progression_f6_evidence.v1`.
- Der Snapshot bleibt read-only und setzt keine Gameplay-Wahrheit.
- TASK_594/595-Gate bleibt gruen: Award-Summary, Style-ID `homebase_progression_delta_v1` und Badge `MISSION GAIN` sind sichtbar.
- Award-Row, Label und Value liegen im Character-Sheet-Popup und bleiben kompakt.
- PNG und Manifest werden unter `tmp/` geschrieben.
- Manifest nennt PNG, Viewport, Gate, Rects, Badge, Style-ID, Manual-Review-Status und den naechsten Task.
- Der HTML-Zwischenbericht nennt TASK_597 als erledigt und eine konkrete Folgeempfehlung.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/character_sheet_formatter.gd`
- `scripts/meta/character_sheet_view.gd`
- `scripts/meta/drop_light_layout_contract.gd`
- `scripts/tests/task_597_homebase_progression_f6_evidence_capture.gd`
- `docs/tasks/TASK_597_homebase_progression_f6_evidence_capture.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_597_homebase_progression_f6_evidence_capture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_596_homebase_progression_player_review_notes.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_595_homebase_progression_visual_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Headless-Capture ist ein Evidence-Board, kein finaler menschlicher Sichtentscheid.
- Falls echte F6-/Fenster-Evidence Engstellen zeigt, sollte ein kleiner TASK_598 nur die belegten Layout-/Kontrastbefunde anwenden.
