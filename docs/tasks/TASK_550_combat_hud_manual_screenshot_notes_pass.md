# TASK_550 - Combat HUD Manual Screenshot Notes Pass

## Ziel / Problem
TASK_549 prueft Combat-HUD-Tooltip, Hover-Faehigkeit und FullHD-Bounds automatisiert. Das ersetzt aber nicht den menschlichen Blick auf Stil, Hover-Gefuehl, Lesbarkeit und stoerende Ueberlagerungen im echten F6-Fenster.

Ziel dieses Tasks ist kein behaupteter Screenshot, sondern eine belastbare Arbeitsflaeche: Der laufende HTML-Bericht muss einen strukturierten Combat-HUD-Screenshot-/Hover-Notizblock haben, dessen Felder per `JSON exportieren` an Codex zurueckgegeben werden koennen.

## Sinnhaftigkeit / Ursache
Viele UI-Probleme sind nicht nur logisch, sondern geschmacklich und ergonomisch: Text wirkt zu laut, Tooltip dauert zu lange, Hover-Flaechen fuehlen sich falsch an oder Panels sehen zwar korrekt, aber unruhig aus. Ohne strukturierten Notizblock verschwinden solche Beobachtungen im Chat.

## Umfang
- TASK_550 als manueller Combat-HUD-Screenshot-/Hover-Check im HTML-Zwischenbericht.
- Exportierbare Felder fuer Screenshotpfad, Viewport, Selected-Fireteam-Hover, Mission-Control-Hover, Ergebnisentscheidung, Hover-Notizen, Stilnotizen und Follow-up.
- Statischer Verifier, der sicherstellt, dass der Bericht diese Felder, TASK_550-Status und TASK_551-Follow-up enthaelt.
- Status, Roadmap und Contract werden aktualisiert.

## Nicht-Ziele
- Kein echter Screenshot wird als erledigt behauptet.
- Kein Pixeltest und keine native Tooltip-Render-Messung.
- Kein Combat-, Contact-, Damage- oder Movement-Change.
- Kein grosses Mission-HUD-Redesign.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_550_combat_hud_manual_screenshot_notes_pass.md`
- `docs/tasks/TASK_549_combat_hud_f6_visual_audit.md`

## Akzeptanzkriterien
- Der HTML-Bericht enthaelt einen sichtbaren TASK_550-Notizblock fuer Combat-HUD-Screenshot-/Hover-Review.
- Der JSON-Export erfasst `combat_hud_manual.*` Controls und `notes.combat_hud_manual_review`.
- Der Bericht markiert nicht, dass ein manueller Screenshot bereits erledigt ist.
- TASK_551 ist als naechster Stil-/Polish-Follow-up sichtbar.
- Der TASK_550-Verifier laeuft gruen.

## Betroffene Dateien
- `docs/reports/project_review_status_2026_06_28.html`
- `scripts/tests/task_550_combat_hud_manual_screenshot_notes_pass.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_550_combat_hud_manual_screenshot_notes_pass.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_550_combat_hud_manual_screenshot_notes_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Dieser Task bereitet die manuelle Sichtpruefung vor und macht sie exportierbar, fuehrt sie aber nicht selbst aus.
- Die naechste konkrete UI-Aenderung sollte aus den exportierten Notizen abgeleitet werden, damit wir nicht wieder blind am HUD polieren.
