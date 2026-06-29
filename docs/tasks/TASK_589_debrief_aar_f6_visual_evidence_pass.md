# TASK_589 - Debrief AAR F6 Visual Evidence Pass

## Ziel / Problem
TASK_588 bringt die Mini-AAR-Metriken in den sichtbaren Meta-Debrief. Noch fehlt aber eine reproduzierbare FullHD-/Viewport-Evidence, ob die neue AAR-Sektion im Debrief wirklich Platz hat, lesbar bleibt und nicht mit Buttons oder Panelgrenzen kollidiert.

## Sinnhaftigkeit / Ursache
Der Debrief ist ein spielbarer Lernmoment. Wenn FIRE/SUP/FF/Status zwar datenmaessig ankommen, aber visuell zu eng, zu lang oder schlecht scanbar sind, hilft der AAR dem Spieler nicht. Der naechste Schritt ist deshalb ein kleiner Evidence-Pass statt eines grossen AAR-Systems.

## Umfang
- `DebriefTestScreen` liefert einen read-only Visual-Evidence-Snapshot fuer die AAR-Sektion.
- Der Snapshot prueft Panel-Bounds, AAR-Reihenfolge vor den Buttons, kompakte Texte, Chip-/Row-Anzahl und die TASK_588-Bruecke.
- Ein Verifier schreibt `tmp/debrief_aar_f6_visual_evidence.png` und `tmp/debrief_aar_f6_visual_evidence.json`.
- Im Headless-Lauf entsteht ein markiertes Evidence-Board; bei echtem Viewport-Readback kann ein Screenshot genutzt werden.
- Der laufende HTML-Zwischenbericht zeigt die neue Evidence-Pfade und bleibt exportierbar.

## Nicht-Ziele
- Kein menschlicher finaler Geschmackstest.
- Keine XP-/Skill-/Ammo-/Suppression-Wirkung.
- Kein Debrief-Rewrite.
- Keine neue Gameplay-Wahrheit im UI.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_588_debrief_aar_data_bridge.md`
- `docs/tasks/TASK_587_debrief_visual_polish_pass.md`

## Akzeptanzkriterien
- `get_debrief_aar_visual_evidence_snapshot()` liefert `schema = sternenbuergerchen.debrief_aar_visual_evidence.v1`.
- Der Snapshot bleibt read-only und setzt keine Gameplay-Wahrheit.
- TASK_588-Bridge-Gate bleibt gruen.
- AAR-Summary, Chip-Strip, Rows und Limit liegen im Debrief-Panel und vor der ButtonRow.
- Summary, Rows und Limit bleiben kompakt.
- PNG und Manifest werden unter `tmp/` geschrieben.
- Manifest nennt PNG, Viewport, Gate, Rects, Manual-Review-Status und den naechsten Task.
- Der HTML-Zwischenbericht nennt TASK_589 als erledigt und TASK_590 als naechsten Folge-Polish.

## Betroffene Dateien
- `scripts/meta/debrief_screen.gd`
- `scripts/tests/task_589_debrief_aar_f6_visual_evidence_pass.gd`
- `docs/tasks/TASK_589_debrief_aar_f6_visual_evidence_pass.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_589_debrief_aar_f6_visual_evidence_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_588_debrief_aar_data_bridge.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_587_debrief_visual_polish_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Headless-Capture ist ein Evidence-Board, kein finaler menschlicher Sichtentscheid.
- Falls die echte F6-/Fenster-Evidence spaeter Engstellen zeigt, sollte TASK_590 daraus einen gezielten Debrief-AAR-Layout-Polish machen.
