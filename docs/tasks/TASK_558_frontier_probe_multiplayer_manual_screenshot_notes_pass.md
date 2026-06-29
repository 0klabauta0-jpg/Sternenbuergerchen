# TASK_558 - Frontier Probe Multiplayer Manual Screenshot Notes Pass

## Status: IMPLEMENTIERT

## Ziel / Problem
TASK_557 prueft den Frontier-Probe-Multiplayer-Slice automatisiert im FullHD-F6-Missionslayout. Das ersetzt aber nicht den menschlichen Blick auf Screenshot, Hover-Gefuehl, Lesbarkeit, Panel-Reibungen und sichtbare Alpha/Bravo-/Objective-/Cargo-Zusammenhaenge.

Ziel dieses Tasks ist kein behaupteter Screenshot, sondern eine belastbare Arbeitsflaeche: Der laufende HTML-Bericht muss einen strukturierten MP-F6-Screenshot-/Hover-Notizblock haben, dessen Felder per `JSON exportieren` an Codex zurueckgegeben werden koennen.

## Sinnhaftigkeit / Ursache
Multiplayer-Lesbarkeit scheitert oft nicht an Contracts, sondern am Moment im Bild: Ist klar, welcher Peer Alpha/Bravo besitzt? Sieht man Objective und Cargo ohne Suchen? Stoert der Teamchip? Verdecken Dropship- oder Fireteam-Panels wichtige Weltinformationen? Solche Beobachtungen brauchen einen festen Ort im Bericht, sonst verschwinden sie im Chat.

## Umfang
- TASK_558 als manueller Frontier-Probe-MP-F6-Screenshot-/Hover-Check im HTML-Zwischenbericht.
- Exportierbare Felder fuer Screenshotpfad, Viewport, Host/Client-Kontext, Teamchip, Objective/Cargo, Selected-Fireteam-Kontext, Panel-Ueberlappung, Hover-/Stil-/Follow-up-Notizen.
- Statischer Verifier, der sicherstellt, dass der Bericht diese Felder, TASK_558-Status und TASK_559-Follow-up enthaelt.
- Status, Roadmap und Contract werden aktualisiert.

## Nicht-Ziele
- Kein echter Screenshot wird als erledigt behauptet.
- Kein Pixeltest und keine native Tooltip-Render-Messung.
- Kein Multiplayer-Transport-, Snapshot-, Objective-, Cargo-, Combat- oder Command-Change.
- Kein grosses Mission-HUD-Redesign.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_557_frontier_probe_multiplayer_f6_readability_pass.md`
- `docs/tasks/TASK_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.md`

## Akzeptanzkriterien
- Der HTML-Bericht enthaelt einen sichtbaren TASK_558-Notizblock fuer MP-F6-Screenshot-/Hover-Review.
- Der JSON-Export erfasst `mp_f6_manual.*` Controls und `notes.mp_f6_manual_review`.
- Der Bericht markiert nicht, dass ein manueller MP-F6-Screenshot bereits erledigt ist.
- TASK_559 ist als naechster visueller/spielbarer Follow-up sichtbar.
- Der TASK_558-Verifier laeuft gruen.

## Betroffene Dateien
- `docs/reports/project_review_status_2026_06_28.html`
- `scripts/tests/task_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Dieser Task bereitet die manuelle Sichtpruefung vor und macht sie exportierbar, fuehrt sie aber nicht selbst aus.
- Die naechste konkrete UI-Aenderung sollte aus den exportierten Notizen abgeleitet werden, damit wir nicht blind am MP-HUD polieren.
