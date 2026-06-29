# TASK_560 - Frontier Probe Multiplayer Teamchip Tooltip Polish

## Status: IMPLEMENTIERT

## Ziel / Problem
Der Frontier-Probe-F6-Smoke zeigt den Mission-Teamchip bereits kompakt im Mission-Control-Bereich. Fuer den echten MP-Blick ist die Kurzzeile aber zu dicht: Host Peer 1, Peer 2 und die Alpha-/Bravo-Spawns sind zwar im Snapshot vorhanden, aber ohne Hover-Hilfe nicht angenehm lesbar.

## Sinnhaftigkeit / Ursache
TASK_557 sichert Bounds und Kontext, ersetzt aber keinen Bedienkomfort. Der naechste kleine Polish soll die bereits vorhandene Team-/Spawn-Zuordnung erklaeren, ohne sichtbaren HUD-Text aufzublaehen oder Gameplay-Wahrheit in UI zu verschieben.

## Umfang
- `MissionTeamChipPresenter` liefert zusaetzlich einen kurzen Tooltip-Text.
- Das Mission-Teamchip-Label wird hoverbar und bekommt einen Help-Cursor.
- Der Controller markiert den Tooltip mit stabiler Style-/Task-Metadaten.
- Neuer read-only Snapshot `get_frontier_probe_multiplayer_teamchip_tooltip_snapshot()`.
- Neuer Verifier prueft den Tooltip im FullHD-Frontier-Probe-MP-F6-Aufbau.
- Rolling-HTML-Bericht wird als Zwischenstand aktualisiert.

## Nicht-Ziele
- Kein neues HUD-System.
- Kein neuer Multiplayer-State.
- Kein manueller Screenshot-Sichttest.
- Keine Aenderung an Objective-, Cargo-, Combat-, Dropship- oder Command-Entscheidungen.
- Keine laengeren sichtbaren Teamchip-Zeilen.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_557_frontier_probe_multiplayer_f6_readability_pass.md`
- `docs/tasks/TASK_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Der Teamchip bleibt sichtbar und kompakt.
- Hover/Tooltip ist am Teamchip verfuegbar.
- Tooltip nennt Host Peer 1, Peer 2, `spawn_alpha` und `spawn_bravo`.
- Style-/Task-Metadaten sind fuer F6-Visual-Audits auslesbar.
- Snapshot bleibt read-only und setzt `ui_sets_gameplay_truth = false`.
- TASK_557-F6-Readability bleibt gruen.

## Betroffene Dateien
- `scripts/mission/mission_team_chip_presenter.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_560_frontier_probe_multiplayer_teamchip_tooltip_polish.gd`
- `docs/tasks/TASK_560_frontier_probe_multiplayer_teamchip_tooltip_polish.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_560_frontier_probe_multiplayer_teamchip_tooltip_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Tooltip verbessert Hover-Lesbarkeit, ersetzt aber weiterhin keinen echten visuellen Screenshot-/User-Sichttest.
- Der naechste sinnvolle Anschluss bleibt ein gezielter manueller MP-F6-Polish-Pass, sobald echte Screenshot-/Hover-Notizen vorliegen.
