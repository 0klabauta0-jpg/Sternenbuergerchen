# TASK_563 - Frontier Probe Multiplayer F6 Evidence Report Preview

## Status: IMPLEMENTIERT

## Ziel / Problem
TASK_562 erzeugt ein lokales MP-F6-PNG und ein Manifest unter `tmp/`, aber diese Artefakte waren im laufenden HTML-Zwischenbericht nicht direkt sichtbar. Fuer den User bedeutet das: Der Bericht sagt zwar, dass Evidence existiert, aber man muss den Pfad kennen und separat suchen.

## Sinnhaftigkeit / Ursache
Der Zwischenbericht soll als laufende Lagekarte dienen. Wenn eine visuelle Evidence-Basis erzeugt wird, gehoert sie direkt in diese Workbench: sichtbar, exportierbar und klar als Headless-Evidence-Board oder echter Screenshot markiert.

## Umfang
- TASK_562-PNG direkt im HTML-Zwischenbericht referenzieren.
- Manifest-/PNG-Pfade, Viewport, Readability-Gate, Teamchip-Tooltip-Gate, Readback-Status und Evidence-Board-Status exportierbar machen.
- Den Bericht auf TASK_563 als erledigt und TASK_564 als naechsten Visual-Polish-Slice aktualisieren.
- Einen statischen Verifier fuer Report-, Status-, Roadmap- und Contract-Anbindung ergaenzen.

## Nicht-Ziele
- Kein neuer Screenshot-Capture.
- Kein behaupteter menschlicher Hover-/Sichttest.
- Kein UI-Polish aus geratenen Befunden.
- Keine Runtime-, Peer-, Combat-, Cargo-, Objective- oder Gameplay-State-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_562_frontier_probe_multiplayer_f6_visual_evidence_capture.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Der HTML-Zwischenbericht enthaelt eine TASK_562-Evidence-Preview.
- Der Bericht referenziert `../../tmp/frontier_probe_mp_f6_visual_evidence.png`.
- Der Bericht exportiert PNG-Pfad, Manifest-Pfad, Viewport, Readability-/Tooltip-Gates und Headless-Evidence-Flags.
- Der Bericht markiert den manuellen Review weiter als offen.
- Status, Roadmap und Contract nennen TASK_563 und TASK_564 als naechsten Apply-Slice.
- TASK_562 bleibt als Capture-Smoke unveraendert read-only.

## Betroffene Dateien
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/tasks/TASK_563_frontier_probe_multiplayer_f6_evidence_report_preview.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `scripts/tests/task_563_frontier_probe_multiplayer_f6_evidence_report_preview.gd`
- `scripts/tests/task_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.gd`
- `scripts/tests/task_561_frontier_probe_multiplayer_manual_visual_review_guide.gd`
- `scripts/tests/task_562_frontier_probe_multiplayer_f6_visual_evidence_capture.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_563_frontier_probe_multiplayer_f6_evidence_report_preview.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_562_frontier_probe_multiplayer_f6_visual_evidence_capture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_561_frontier_probe_multiplayer_manual_visual_review_guide.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Preview zeigt nur lokale Artefakte. Wenn `tmp/` neu geloescht wurde, muss TASK_562 erneut laufen, bevor das Bild im Browser sichtbar ist.
- Das Headless-Bild bleibt ein Evidence-Board und ersetzt nicht den echten menschlichen F6-/Hover-Sichttest.
- Naechster sinnvoller Schritt ist `TASK_564 - Frontier Probe Multiplayer Apply Visual Polish Findings`: konkrete Visual-Polish-Findings aus echter Sichtung oder Review-Export anwenden.
