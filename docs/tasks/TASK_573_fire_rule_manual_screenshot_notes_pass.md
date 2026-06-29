# TASK_573 - Fire Rule Manual Screenshot Notes Pass

## Ziel / Problem
Die Fire-Rule-Controls aus TASK_571 und der FullHD-Smoke aus TASK_572 zeigen, dass `HF`, `RF`, `FW` und `SUP` technisch korrekt, kompakt und im HUD-Bounds-Budget liegen. Offen bleibt der menschliche Blick: Fuehlen sich die ROE-Buttons im echten F6-Missionsfenster verstaendlich an, sind Kontrast, Reihenfolge, Tooltips und Befehlsfluss angenehm, und entsteht keine neue Reibung mit First-Move-Preview, Threat-Lines oder Command-Matrix?

## Sinnhaftigkeit / Ursache
Automatisierte Layout-Smokes finden Bounds- und Overlap-Fehler, aber nicht, ob ein Spieler beim ersten Gefecht schnell erkennt, welche Feuerregel aktiv ist und ob der naechste Klick sicher ist. Diese Beobachtungen sollen im laufenden HTML-Bericht landen, damit daraus ein konkreter Folge-Task entstehen kann statt Chat-Notizen zu verlieren.

## Umfang
- TASK_573 als manueller Fire-Rule-/ROE-Screenshot-Notizblock im HTML-Zwischenbericht.
- Exportierbare Felder fuer Screenshotpfad, Viewport, aktive Rule, Button-Erkennbarkeit, Tooltip-/Hover-Check, Kontrast, Panel-/Weltverdeckung, Threat-Preview-Zusammenspiel und naechsten Follow-up.
- Statischer Verifier, der sicherstellt, dass Task, Contract, Roadmap, Status und Report diese Felder enthalten.
- Bericht markiert den echten manuellen Sichttest bewusst als offen/pending, bis der User oder ein Playtest ihn bestaetigt.

## Nicht-Ziele
- Kein echter Screenshot wird als bereits erledigt behauptet.
- Keine neue Fire-Rule-, Combat-, Suppression-, Movement- oder Command-Logik.
- Kein HUD-Redesign ohne belegte Screenshot-/Spielgefuehl-Notiz.
- Keine Runtime- oder Gameplay-Wahrheit im HTML-Bericht.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_571_fire_rule_controls_readability_polish.md`
- `docs/tasks/TASK_572_fire_rule_f6_readability_smoke.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Der HTML-Bericht enthaelt einen sichtbaren TASK_573-Notizblock fuer Fire-Rule-/ROE-F6-Screenshot-Review.
- Der JSON-Export erfasst `fire_rule_manual.*` Controls und `notes.fire_rule_manual_review`.
- Der Bericht markiert nicht, dass ein manueller Fire-Rule-Screenshot bereits erledigt ist.
- TASK_574 ist als naechster moeglicher Follow-up aus echten Sichtnotizen sichtbar.
- Der TASK_573-Verifier laeuft gruen.

## Betroffene Dateien
- `docs/reports/project_review_status_2026_06_28.html`
- `scripts/tests/task_573_fire_rule_manual_screenshot_notes_pass.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_573_fire_rule_manual_screenshot_notes_pass.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_573_fire_rule_manual_screenshot_notes_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_572_fire_rule_f6_readability_smoke.gd`
- `git diff --check`

## Risiken / offene Punkte
- Dieser Task bereitet die manuelle Sichtpruefung vor und macht sie exportierbar, fuehrt sie aber nicht selbst aus.
- Ein moeglicher TASK_574 sollte erst konkrete Fire-Rule-Screenshot-/Spielgefuehl-Befunde anwenden.
