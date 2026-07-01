# TASK_771 - Station Reentry Visible Host Client Playtest Export

## Ziel / Problem
TASK_770 beweist den Host/Client-Gleichstand als Contract. Jetzt braucht der sichtbare Zwei-Fenster-Lauf ein startbares Exportpaket: Welche Fenster werden geoeffnet, welche Texte muessen Host und Client sehen, welche Checks muessen im HTML-Bericht exportiert werden?

## Sinnhaftigkeit / Ursache
Ohne Run-/Exportpaket bleibt der naechste sichtbare Playtest zu frei. Dann kann man im Fenster zwar etwas sehen, aber spaeter nicht sauber sagen, ob Host/Client wirklich denselben naechsten Auftrag, dieselbe Route und denselben Cue gesehen haben.

## Umfang
- Neues Tool `prepare_station_reentry_host_client_playtest_export.ps1`.
- Exportmanifest `tmp/station_reentry_visible_host_client_playtest_export.json`.
- Verifier prueft Tool, Exportpaket, erwartete TASK_770-Felder, manuelle Checks und Berichtsfelder.
- Reentry-Handbuchbericht markiert TASK_771 als aktuellen sichtbaren Export-Schritt.

## Nicht-Ziele
- Kein automatisiertes Bestehen des sichtbaren Playtests.
- Kein Screenshot-Vergleich und kein Computer-Vision-Gate.
- Kein Netzwerk- oder Authority-Rewrite.
- Kein Gameplay-Commit, keine Navigation und kein GO.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_770_station_reentry_host_client_next_order_sync.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Exportpaket bleibt `read_only = true`, `ui_sets_gameplay_truth = false`, `creates_command = false`.
- Paket liest ein TASK_770-Sync-Manifest mit `sync_gate = pass`.
- Erwartete Host-/Client-Next-Order, Route, Cue und Peer-Kontext werden exportiert.
- Start-, Capture-, Workbench- und Re-Run-Kommandos sind enthalten.
- Manuelle Checks fuer Host-Fenster, Client-Fenster, gleiche Next-Order, gleiche Route/Cue, getrennten Peer-/Team-Kontext und Export sind enthalten.
- Das Paket behauptet `manual_review_done = false`.

## Betroffene Dateien
- `scripts/tools/prepare_station_reentry_host_client_playtest_export.ps1`
- `scripts/tests/task_771_station_reentry_visible_host_client_playtest_export.gd`
- `docs/tasks/TASK_771_station_reentry_visible_host_client_playtest_export.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_771_station_reentry_visible_host_client_playtest_export.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_770_station_reentry_host_client_next_order_sync.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_771 erstellt das sichtbare Exportpaket, fuehrt aber keinen menschlichen Fensterentscheid aus.
- Der naechste Schritt ist die Auswertung eines echten Exports: TASK_772.
