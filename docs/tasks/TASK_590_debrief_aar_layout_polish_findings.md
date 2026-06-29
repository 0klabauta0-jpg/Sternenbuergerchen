# TASK_590 - Debrief AAR Layout Polish Findings

## Ziel / Problem
Die TASK_589-Evidence hat gezeigt, dass die neue Debrief-AAR-Sektion zwar strukturell pruefbar ist, aber in der sichtbaren Summary den Praefix doppelt ausgeben kann: `AAR: AAR | ...`. Das ist klein, aber im Debrief genau an der falschen Stelle stoerend, weil der Spieler dort schnell verstehen soll, was passiert ist.

## Sinnhaftigkeit / Ursache
Die Mini-AAR-Daten liefern bereits eine kompakte Summary mit `AAR | ...`. Der Debrief-Presenter hat diesen String nochmals mit `AAR:` ummantelt. Gleichzeitig waren Summary, Rows und Grenztext noch nicht als eigener Layout-Polish-Contract markiert, sodass spaetere UI-Aenderungen den Befund wieder einfuehren koennten.

## Umfang
- AAR-Summary im Debrief normalisieren, ohne die Quelle zu veraendern.
- Summary, Rows und Grenztext mit stabilen Clip-/Overrun-Regeln und Style-Metadaten versehen.
- Einen read-only `get_debrief_aar_layout_polish_snapshot()` fuer Prefix-, Style- und Kompakt-Gates ergaenzen.
- Bestehende TASK_588-/TASK_589-Gates weiterverwenden und nicht ersetzen.
- Laufenden HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Keine XP-, Ammo-, Suppression-, Skill- oder Combat-Wirkung.
- Kein neues Debrief-System.
- Kein echter menschlicher Sichtentscheid anstelle eines Verifiers.
- Kein Umbau von `MissionResult` oder Mini-AAR-Metriken.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_588_debrief_aar_data_bridge.md`
- `docs/tasks/TASK_589_debrief_aar_f6_visual_evidence_pass.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Debrief-AAR-Summary beginnt mit `AAR |` und enthaelt nicht mehr `AAR: AAR`.
- Summary, Rows und Grenztext bleiben einzeilig, kompakt und ellipsieren bei Ueberlauf.
- Style-Metadaten `debrief_aar_summary_v2`, `debrief_aar_rows_v2`, `debrief_aar_limit_v2` sind im Snapshot sichtbar.
- TASK_588 AAR-Bridge und TASK_589 Visual-Evidence bleiben gruen.
- Snapshot und UI bleiben read-only und setzen keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/meta/debrief_screen.gd`
- `scripts/tests/task_590_debrief_aar_layout_polish_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_590_debrief_aar_layout_polish_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_589_debrief_aar_f6_visual_evidence_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_588_debrief_aar_data_bridge.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_587_debrief_visual_polish_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
Der automatische Snapshot bestaetigt Layout-Vertraege und verhindert den konkreten Prefix-/Overflow-Rueckfall. Er ersetzt weiter keinen echten Fenster-Sichttest mit Spielerblick. Ein naechster sinnvoller Schritt ist ein kleiner Debrief-AAR-Player-Review-Notes-Pass, falls der sichtbare Debrief weiter nachgeschliffen werden soll.
