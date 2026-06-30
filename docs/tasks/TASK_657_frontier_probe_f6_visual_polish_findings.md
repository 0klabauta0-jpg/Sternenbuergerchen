# TASK_657 - Frontier Probe F6 Visual Polish Findings

## Ziel / Problem
TASK_656 hat fuer die verdichtete Frontier-Probe-F6-Anzeige ein PNG-/JSON-Reviewpaket erzeugt. Jetzt braucht der Stand einen kleinen, pruefbaren Polish-Findings-Slice: Die kompakte `PLAN ... | NEXT ...`-Zeile soll als eigener Lesbarkeitsanker erkennbar sein, ohne die bestehende Mission-Control-Zeile oder alte Contracts zu brechen.

## Sinnhaftigkeit / Ursache
Der Spieler muss im F6-Blick sofort lesen koennen: Route, aktuelles NEXT und warum die alte NEXT-Detailzeile nicht doppelt auftaucht. Gleichzeitig darf daraus kein neuer HUD-Baum und keine UI-seitige Gameplay-Wahrheit entstehen.

## Umfang
- Frontier-Probe-spezifischen Mission-Control-Polish-Marker auf das bestehende Label setzen.
- Read-only Snapshot `get_frontier_probe_f6_visual_polish_findings_snapshot()` ergaenzen.
- Snapshot exportiert Route-Token-Badges, NEXT-Badge, Zeichenbudget, Label-Konfiguration und konkrete Gates.
- Aktuellen HTML-Handbuchbericht auf TASK_657 aktualisieren.

## Nicht-Ziele
- Kein neues Mission-Control-Widget.
- Kein neues Objective-, Cargo-, Combat-, Multiplayer- oder Command-System.
- Kein automatischer GO-/Debrief-/Homebase-Flow.
- Kein Ersatz fuer einen echten menschlichen Fensterblick.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_656_frontier_probe_real_f6_visual_review.md`
- `docs/tasks/TASK_655_frontier_probe_one_screen_visual_tuning_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- `get_frontier_probe_f6_visual_polish_findings_snapshot()` liefert Schema, Task-ID, Style-ID, Route-Badges, NEXT-Badge und Mission-Control-Labeldaten.
- Die kompakte One-Screen-Zeile bleibt sichtbar.
- Die redundante NEXT-Detailzeile bleibt sichtbar unterdrueckt.
- Das Mission-Control-Label traegt den TASK_657-Polish-Marker und behält Autowrap, Clip/Overrun und Outline-Guards.
- Snapshot und Manifest bleiben read-only und setzen keine Gameplay-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_657_frontier_probe_f6_visual_polish_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_657_frontier_probe_f6_visual_polish_findings.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_657_frontier_probe_f6_visual_polish_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_656_frontier_probe_real_f6_visual_review.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_655_frontier_probe_one_screen_visual_tuning_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_652_current_state_handbook_refresh.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_657 ist ein kleiner Polish-Contract und kein finaler visueller Kunstpass.
- Der naechste sinnvolle Schritt ist ein echter kurzer Spieler-Entscheidungsdrill, nicht noch eine weitere reine Screenshot-Schleife.
