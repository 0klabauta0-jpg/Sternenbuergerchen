# TASK_598 - Homebase Progression Evidence Polish Findings

## Ziel / Problem
TASK_597 erzeugt eine reproduzierbare Homebase-Progression-Evidence. Das Headless-Evidence-Board ist technisch korrekt, aber fuer einen schnellen menschlichen Blick zu abstrakt: farbige Rects zeigen Bounds, erklaeren aber nicht direkt, welche Region Popup, Sheet, Award, Label oder Value ist.

## Sinnhaftigkeit / Ursache
Der laufende HTML-Bericht soll ein Arbeitsbericht sein, den man zwischendurch oeffnen kann. Wenn ein Evidence-Bild erst ueber JSON-Rects entschluesselt werden muss, hilft es zu wenig bei der Frage, ob der Core-Loop angenehm lesbar ist.

## Umfang
- Das Headless-Evidence-Board aus TASK_597 bekommt sichtbare Pixel-Labels und Callouts fuer Popup, Sheet, `MISSION GAIN`, Value, Gate und offenen Manual-Review-Status.
- Das Manifest meldet Legende/Callouts als read-only Evidence-Metadaten.
- Der HTML-Zwischenbericht markiert TASK_598 als erledigt und exportiert die neuen Evidence-Board-Polish-Flags.
- Ein kleiner Verifier prueft Task-Datei, Status, Roadmap, Report-Keys, Manifest-Felder und dass der TASK_597-Capture weiter verfuegbar bleibt.

## Nicht-Ziele
- Kein echter menschlicher Sichttest.
- Keine Runtime-, XP-, Skill-, Roster- oder Persistenzmutation.
- Keine neue Character-Sheet- oder Homebase-Gameplay-Logik.
- Kein neuer Screenshot-Capture-Pfad ausserhalb des vorhandenen TASK_597-Verifiers.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_597_homebase_progression_f6_evidence_capture.md`
- `docs/tasks/TASK_596_homebase_progression_player_review_notes.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Das TASK_597-Headless-Evidence-Board enthaelt erkennbare Labels/Callouts fuer die wichtigsten Rects.
- Das Manifest enthaelt `evidence_polish_task_id = TASK_598`, `region_legend_present = true` und eine positive `callout_label_count`.
- Der HTML-Zwischenbericht nennt TASK_598 als erledigt und laesst die neuen Manifestwerte per JSON exportieren.
- TASK_597 bleibt gruen und schreibt weiterhin PNG/Manifest.
- Die Aenderung bleibt reine Evidence-/Report-Politur und setzt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/tests/task_597_homebase_progression_f6_evidence_capture.gd`
- `scripts/tests/task_598_homebase_progression_evidence_polish_findings.gd`
- `docs/tasks/TASK_598_homebase_progression_evidence_polish_findings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_597_homebase_progression_f6_evidence_capture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_598_homebase_progression_evidence_polish_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_596_homebase_progression_player_review_notes.gd`
- `git diff --check`

## Risiken / offene Punkte
- Pixel-Labels im Headless-Board ersetzen keinen echten F6-Fenster-Sichttest.
- Falls spaeter echte Viewport-Readbacks statt Headless-Boards entstehen, muss die Report-Legende weiter klar zwischen Screenshot und synthetischem Evidence-Board unterscheiden.
