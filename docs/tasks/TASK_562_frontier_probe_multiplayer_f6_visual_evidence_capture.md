# TASK_562 - Frontier Probe Multiplayer F6 Visual Evidence Capture

## Status: IMPLEMENTIERT

## Ziel / Problem
TASK_561 macht den manuellen MP-F6-Sichttest auswertbar, aber es liegt noch kein exportierter Review mit Screenshot-/Hover-Notizen vor. Ein direkter "Apply Findings"-Polish waere damit geraten.

## Sinnhaftigkeit / Ursache
Damit der naechste UI-/Layout-Polish nicht aus Bauchgefuehl entsteht, braucht der Frontier-Probe-MP-F6-Pfad eine reproduzierbare visuelle Ausgangsbasis: denselben FullHD-F6-Zustand, dieselben Host/Peer-Assignments, dieselben Objective-/Cargo-Gates und einen Screenshot-/Manifest-Output, den Mensch und Codex gemeinsam bewerten koennen.

## Umfang
- Neuer Headless-/F6-Capture-Smoke fuer den Frontier-Probe-MP-Slice.
- Der Smoke baut den 1920x1080-Missionszustand mit Host Peer 1 Alpha und Peer 2 Bravo auf.
- Der Smoke prueft TASK_557-Readability und TASK_560-Teamchip-Tooltip weiter.
- Der Smoke schreibt ein PNG nach `tmp/frontier_probe_mp_f6_visual_evidence.png`; im Headless-Dummy-Renderer ist das ein markiertes Evidence-Board aus Snapshot-Rects, bei verfuegbarem Viewport-Readback ein Viewport-Bild.
- Der Smoke schreibt ein Manifest nach `tmp/frontier_probe_mp_f6_visual_evidence.json`.
- Das Manifest nennt Evidence-Board-Regionen, damit der HTML-Bericht die Farben sauber erklaeren kann.
- Der Rolling-HTML-Bericht nennt den Capture als aktuellen Zwischenstand; TASK_563 macht die Evidence direkt sichtbar, TASK_564 poliert die Evidence-Lesbarkeit, TASK_565 ist der naechste echte Sichtreview-Slice.

## Nicht-Ziele
- Kein behaupteter menschlicher Screenshot-/Hover-Test.
- Keine Auswertung von User-Notizen, solange kein Review-Export vorliegt.
- Kein HUD-Redesign und keine Gameplay-State-Aenderung.
- Kein neuer Multiplayer-Transport.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_557_frontier_probe_multiplayer_f6_readability_pass.md`
- `docs/tasks/TASK_560_frontier_probe_multiplayer_teamchip_tooltip_polish.md`
- `docs/tasks/TASK_561_frontier_probe_multiplayer_manual_visual_review_guide.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Der Capture-Smoke laeuft gruen.
- PNG und Manifest werden unter `tmp/` erzeugt.
- Das Manifest enthaelt PNG-Pfad, Viewport, Readback-/Evidence-Board-Status, TASK_557-Gate, TASK_560-Gate, Teamchip-Text, Tooltip-Laenge und Evidence-Board-Regionen.
- Der Screenshot ist nicht leer und hat FullHD-Abmessungen.
- Der Smoke bleibt read-only und setzt keine Gameplay-Wahrheit in UI/Report.
- Status, Roadmap, Contract und HTML-Bericht sind aktualisiert.

## Betroffene Dateien
- `scripts/tests/task_562_frontier_probe_multiplayer_f6_visual_evidence_capture.gd`
- `docs/tasks/TASK_562_frontier_probe_multiplayer_f6_visual_evidence_capture.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_562_frontier_probe_multiplayer_f6_visual_evidence_capture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_561_frontier_probe_multiplayer_manual_visual_review_guide.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Capture liefert in Headless eine reproduzierbare Evidence-Board-Bildbasis, ersetzt aber weiterhin nicht den menschlichen Hover-/Lesbarkeitsentscheid im echten Fenster.
- Der naechste sinnvolle Sichtreview-Schritt ist TASK_565: echten F6-/Hover-Screenshot oder exportierte MP-F6-Review-Notizen in konkrete UI-/Layout-Korrekturen uebersetzen.
