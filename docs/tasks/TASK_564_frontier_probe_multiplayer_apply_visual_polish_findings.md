# TASK_564 - Frontier Probe Multiplayer Apply Visual Polish Findings

## Status: IMPLEMENTIERT

## Ziel / Problem
TASK_562/TASK_563 haben die MP-F6-Evidence sichtbar gemacht. Der konkrete Befund aus dem Headless-Artifact ist aber: Das Evidence-Board ist als Farbflaechen-Beleg zwar technisch reproduzierbar, aber ohne Legende und Region-Kontext zu wenig lesbar fuer schnelle Review-Entscheidungen.

## Sinnhaftigkeit / Ursache
Solange der echte manuelle F6-/Hover-Screenshot noch offen ist, soll kein geratenes HUD-Redesign entstehen. Der sichere, belegbare Polish ist deshalb die Lesbarkeit des Evidence-Boards selbst: Welche Flaeche steht fuer Teamchip, Mission Control, Selected Fireteam, HUD-Panels und Tooltip-Probe?

## Umfang
- Headless-Evidence-Board aus TASK_562 visuell strukturieren.
- Region-Outlines, Raster und Farblegende ergaenzen.
- Manifest um Evidence-Board-Regionen und Region-Count erweitern.
- HTML-Zwischenbericht um eine passende Legende und Exportfelder erweitern.
- Verifier fuer Doku, Report, Manifest-Contract und naechsten TASK_565 ergaenzen.

## Nicht-Ziele
- Kein Gameplay-HUD-Redesign ohne echten Screenshot-/Hover-Befund.
- Kein neuer Multiplayer-Transport.
- Keine Runtime-, Peer-, Combat-, Cargo-, Objective- oder Command-State-Aenderung.
- Keine Behauptung, dass der menschliche Sichttest abgeschlossen ist.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_562_frontier_probe_multiplayer_f6_visual_evidence_capture.md`
- `docs/tasks/TASK_563_frontier_probe_multiplayer_f6_evidence_report_preview.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- TASK_562 erzeugt weiter PNG und Manifest read-only.
- Das Headless-Evidence-Board enthaelt klare Region-Outlines, Raster und Swatch-Leiste.
- Das Manifest nennt `evidence_board_regions` und `evidence_board_region_count`.
- Der HTML-Bericht zeigt eine Legende fuer Teamchip, Mission Control, Selected Fireteam, HUD-Panels und Tooltip-Probe.
- Der Bericht markiert TASK_564 als erledigt und TASK_565 als naechsten echten Sichtreview-Slice.
- Bestehende TASK_562-/TASK_563-Verifier bleiben gruen.

## Betroffene Dateien
- `scripts/tests/task_562_frontier_probe_multiplayer_f6_visual_evidence_capture.gd`
- `scripts/tests/task_564_frontier_probe_multiplayer_apply_visual_polish_findings.gd`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/tasks/TASK_562_frontier_probe_multiplayer_f6_visual_evidence_capture.md`
- `docs/tasks/TASK_563_frontier_probe_multiplayer_f6_evidence_report_preview.md`
- `docs/tasks/TASK_564_frontier_probe_multiplayer_apply_visual_polish_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_564_frontier_probe_multiplayer_apply_visual_polish_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_562_frontier_probe_multiplayer_f6_visual_evidence_capture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_563_frontier_probe_multiplayer_f6_evidence_report_preview.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der echte F6-/Hover-Sichttest ist weiterhin offen. TASK_564 verbessert die automatische Review-Evidence, nicht die finale menschliche UI-Bewertung.
- Naechster sinnvoller Schritt ist `TASK_565 - Frontier Probe Multiplayer Real F6 Screenshot Review Pass`.
