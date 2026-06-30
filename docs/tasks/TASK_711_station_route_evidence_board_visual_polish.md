# TASK_711 - Station Route Evidence Board Visual Polish

## Ziel / Problem
Das TASK_708-Evidence-PNG ist technisch sichtbar, aber im Headless-Fallback fuer Menschen zu abstrakt. Ohne Labels sieht man farbige Balken und Rechtecke, aber nicht sofort: Door ist offen, Computer ist kontrolliert, Cargo ist abgeschlossen.

## Sinnhaftigkeit / Ursache
Das Spiel soll angenehmer und schicker werden. Solange echte Fenster-Sichttests offen sind, muss zumindest das generierte Review-Board klar lesbar sein, damit Review, Playtest und naechste Polish-Entscheidungen weniger Ratespiel sind.

## Umfang
- Das generierte Station-Route-Review-Board bekommt Titel, Statuszeile, Objektlabels und Legende.
- Das TASK_708-Manifest exportiert Board-Style und Label-Anzahl.
- Neuer Verifier fuer TASK_711 prueft Task, Contract, Status, Roadmap, Report und Board-Polish-Anker.
- Keine Aenderung an Runtime-Gameplay, Door-State, Objective-Gates oder Host/Client-Authority.

## Nicht-Ziele
- Kein echter Fenster-Sichtentscheid.
- Kein Host/Client-Klicklauf.
- Kein neues UI-System.
- Kein Ersatz fuer TASK_709-Notizen.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_708_station_route_visual_evidence.md`
- `docs/tasks/TASK_710_station_route_polish_readiness_findings.md`
- `docs/reports/project_current_state_handbook_refresh_2026_06_30.html`

## Akzeptanzkriterien
- Generated Evidence Board nutzt `evidence_board_style_id = station_route_labeled_v1`.
- Board enthaelt mindestens acht Pixeltext-Labels.
- Manifest bleibt `read_only = true` und `ui_sets_gameplay_truth = false`.
- TASK_708-Regressionslauf schreibt weiterhin PNG und Manifest.
- TASK_711-Verifier prueft die Doku- und Script-Anker.

## Betroffene Dateien
- `docs/tasks/TASK_711_station_route_evidence_board_visual_polish.md`
- `scripts/tests/task_708_station_route_visual_evidence.gd`
- `scripts/tests/task_711_station_route_evidence_board_visual_polish.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_refresh_2026_06_30.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_711_station_route_evidence_board_visual_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_708_station_route_visual_evidence.gd`
- `git diff --check`

## Risiken / offene Punkte
- Das verbessert das Review-Artefakt und den Headless-Fallback, nicht automatisch die echte Fensteransicht.
- Der menschliche Sichtentscheid aus TASK_709 bleibt weiter noetig.
