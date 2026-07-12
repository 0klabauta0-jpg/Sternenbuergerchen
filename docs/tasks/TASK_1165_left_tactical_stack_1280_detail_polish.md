# TASK_1165 - Left Tactical Stack 1280 Detail Polish

## Ziel / Problem
TASK_1164 hat die linke taktische Stack-Flaeche im 1280x720-Spielerblick bewertet. Die Mini-Cards sind grundsaetzlich nutzbar, aber der Member-/Detailstrip bleibt zu klein. Der Eventlog-Filter/Zaehler wirkt gedrungen. Das kombinierte Desktop-Capture bleibt als Sichtbeleg ungeeignet, waehrend separate Host-/Client-Fensterbilder belastbar sind.

## Sinnhaftigkeit / Ursache
Der linke Stack ist inzwischen die primaere Fireteam-Uebersicht im Einsatz. Wenn Lead, Status, Mitglieder und Eventfilter dort zu dicht sind, muss der Spieler zu lange lesen, obwohl die eigentliche Karte und der Bottom-Dock bereits brauchbarer geworden sind.

## Umfang
- Mission-Mini-Cards erhalten eine detailfreundlichere 1280er Dichte fuer Lead-/Member-/Statusdaten.
- Der Eventlog-Filter/Zaehler bekommt eine ruhigere, groessere Leseflaeche.
- Ein read-only TASK_1165-Snapshot belegt, dass die TASK_1164-Reibungen abgearbeitet sind.
- Bestehende Mini-Card-, Eventlog- und Hotpath-Vertraege bleiben erhalten.

## Nicht-Ziele
- Kein neues HUD-Layout fuer die gesamte Mission.
- Kein neues Capture-Harness.
- Keine Aenderung an Fireteam-, Dropship-, Combat-, Movement- oder Multiplayer-Wahrheit.
- Keine per-frame Rebuilds von Mini-Cards oder Eventlog.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1164_left_tactical_stack_1280_visual_findings.md`
- `docs/tasks/TASK_1162_left_tactical_stack_1280_readability_focus_balance.md`
- `docs/tasks/TASK_1159_tactical_event_log_1280_readability.md`

## Akzeptanzkriterien
- `get_left_tactical_stack_1280_detail_polish_snapshot()` liefert Schema `sternenbuergerchen.left_tactical_stack_1280_detail_polish.v1`.
- Snapshot liest TASK_1164 als Quelle und setzt bei sauberem Polish `left_stack_detail_polish_ready`.
- Mini-Cards melden fuer Mission-Mini-Kontext mindestens 120 Pixel Kartenhoehe, 12-Pixel-Detail-/Leadschrift und sichtbare Member-/Portrait-Strips.
- Eventlog meldet mindestens 13-Pixel-Filtertext, eine stabile 96-Pixel-Filter-Hitflaeche und einen getrennt lesbaren Zaehler.
- TASK_1164 Default-Review ist nach dem Polish akzeptiert oder routet nicht mehr zu Detail-Polish.
- Snapshot bleibt read-only und erzeugt keine Commands, Effects, Fire-/Damage-Events oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/meta/fob_fireteam_card.gd`
- `scripts/ui/tactical_event_log_panel.gd`
- `scripts/tests/task_1165_left_tactical_stack_1280_detail_polish.gd`
- `docs/tasks/TASK_1165_left_tactical_stack_1280_detail_polish.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1165_left_tactical_stack_1280_detail_polish.gd`
- Regressionen: TASK_1164, TASK_1162, TASK_1159, TASK_222, `git diff --check`.

## Risiken / offene Punkte
Die Aenderung verbessert die lesbaren Detailflaechen strukturell. Ein erneuter echter 1280x720-Host/Client-Capture bleibt sinnvoll, wenn danach die subjektive Blickruhe final bewertet werden soll.
