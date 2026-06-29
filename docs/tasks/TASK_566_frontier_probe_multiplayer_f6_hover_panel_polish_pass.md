# TASK_566 - Frontier Probe Multiplayer F6 Hover And Panel Polish Pass

## Status: IMPLEMENTIERT

## Ziel / Problem
Nach TASK_565 ist der sichtbare #17-Status/Card-Widerspruch behoben. Im echten MP-F6-Screenshot bleibt als naechste Reibung die #18-Mission-Control-Teamchip-Zeile: Die sichtbare Alpha/Bravo-/Host-/Peer-/Spawn-Zusammenfassung ist in der schmalen Mission-Control-Spalte noch zu lang und bricht unruhig. Der Hover enthaelt bereits die vollstaendige Erklaerung, wird aber noch nicht als Teil eines eigenen Panel-/Weltverdeckungs-Slices abgesichert.

## Sinnhaftigkeit / Ursache
Der Mission-Teamchip zeigt im Panel fast dieselben Daten wie der Tooltip. Das ist informativ, aber fuer die untere F6-HUD-Spalte zu breit. Die sichtbare Zeile soll schneller scannbar werden; die vollstaendigen Owner-/Spawn-Daten bleiben im Tooltip und Snapshot.

## Umfang
- Sichtbaren Mission-Teamchip-Text fuer F6 kompakter machen.
- Vollstaendige Host-/Peer-/spawn_alpha-/spawn_bravo-Erklaerung im Tooltip und `status_text` erhalten.
- Eigenen read-only TASK_566-Snapshot fuer Teamchip-Hover, Paneldichte und Weltverdeckung ergaenzen.
- HTML-Zwischenbericht, Status, Roadmap, Contract und Verifier auf TASK_566 aktualisieren.

## Nicht-Ziele
- Kein neues HUD-Layout.
- Keine neue Multiplayer-Authority oder Gameplay-Wahrheit.
- Keine Aenderung an Peer-Team-Zuordnung, Objective-, Cargo-, Dropship- oder Fireteam-State.
- Kein erzwungener manueller Hover-Abschluss.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_560_frontier_probe_multiplayer_teamchip_tooltip_polish.md`
- `docs/tasks/TASK_561_frontier_probe_multiplayer_manual_visual_review_guide.md`
- `docs/tasks/TASK_565_frontier_probe_multiplayer_real_f6_screenshot_review_pass.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Sichtbarer Mission-Teamchip bleibt einzeilig/kompakt genug fuer die #18-Spalte und enthaelt Alpha/Bravo, Host/P2 und A-LZ/B-LZ.
- Tooltip/Snapshot nennt weiter Host Peer 1, Peer 2, spawn_alpha und spawn_bravo.
- TASK_566-Snapshot prueft Teamchip-Hover, kompakte sichtbare Zeile, Panel-Bounds und Bottom-HUD-Weltverdeckung read-only.
- Bestehende TASK_557/TASK_560/TASK_565-Smokes bleiben gruen.
- Roadmap, Status, Contract, Bericht und Verifier sind aktualisiert.

## Betroffene Dateien
- `scripts/mission/mission_team_chip_presenter.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_566_frontier_probe_multiplayer_f6_hover_panel_polish_pass.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_566_frontier_probe_multiplayer_f6_hover_panel_polish_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_560_frontier_probe_multiplayer_teamchip_tooltip_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_565_frontier_probe_multiplayer_real_f6_screenshot_review_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die native Tooltip-Position bleibt engine-seitig; TASK_566 prueft Hoverbarkeit, Kontext und geschaetzte Panel-/Weltverdeckung, ersetzt aber keinen finalen menschlichen Spielgefuehl-Test.
- Naechster sinnvoller Schritt nach TASK_566 ist ein echter First-Order-/Threat-Preview-Polish oder ein kleiner Combat-Decision-Readability-Slice.
