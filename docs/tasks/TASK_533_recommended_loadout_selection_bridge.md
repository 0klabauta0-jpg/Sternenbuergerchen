# TASK_533 - Recommended Loadout Selection Bridge

## Status: IMPLEMENTIERT

## Ziel / Problem
Briefing-Loadout-Empfehlungen waren seit TASK_532 sichtbar, blieben aber reine Textkarten. Der Spieler konnte daraus nicht direkt eine gestagte Homebase-Auswahl vorbereiten.

## Sinnhaftigkeit / Ursache
Der Pre-Mission-Workflow soll lesbar werden: Briefing ansehen, Empfehlung auswaehlen, gestagte Operatoren bestaetigt ausruesten, danach Dropship/Mission starten. Die UI darf dabei keine zweite Loadout-Wahrheit erzeugen.

## Umfang
- `MissionBriefingPanelPresenter` gibt pro Empfehlung eine stabile `recommendation_id`, Waffenfelder und eine read-only `loadout_patch_preview` aus.
- `HomebaseTestScreen` rendert Empfehlungskarten als auswaehlbare Buttons.
- Ein separater Apply-Button schreibt erst nach Bestätigung in den bestehenden Homebase-Member-Loadout-Pfad.
- Snapshots expose'n Auswahl, Apply-Bereitschaft, Feedback und Apply-Zaehler fuer Regressionen.
- Der laufende HTML-Report bleibt die aktualisierte Zwischenstands-Workbench.

## Nicht-Ziele
- Kein automatisches Anwenden beim Oeffnen des Briefings.
- Kein neuer Loadout-Contract neben `LoadoutContract`.
- Kein `SimulationRoot`-Command; es bleibt Pre-Mission-Staging.
- Kein finales FullHD-Visual-Polish.

## Relevante Contracts / Dokumente
- `docs/dev/mission_briefing_contract.md`
- `docs/tasks/TASK_532_briefing_background_loadout_recommendation_polish.md`
- `docs/tasks/TASK_528_rolling_html_status_report.md`

## Akzeptanzkriterien
- Auswahl einer Empfehlung mutiert noch keinen Loadout-State.
- Apply auf gestagte Operatoren nutzt bestehende Homebase-Member-Loadout-Syncs.
- Snapshot unterscheidet Auswahl, Apply-Bereitschaft und angewendete Empfehlung.
- TASK_532 bleibt gruen und sieht keine mutierenden Loadout-Command-Keys im reinen Briefing-Snapshot.

## Betroffene Dateien
- `scripts/mission/mission_briefing_panel_presenter.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_533_recommended_loadout_selection_bridge.gd`
- `docs/dev/mission_briefing_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_533_recommended_loadout_selection_bridge.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_532_briefing_background_loadout_recommendation_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_531_briefing_minimap_visual_renderer.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Bruecke wendet aktuell eine Empfehlung homogen auf die gewaehlten Operatoren an. Rollenfeinverteilung pro Fireteam-Mitglied bleibt Folgearbeit.
- Der manuelle Sichttest wurde bewusst uebersprungen; die UI ist regressionsgesichert, aber noch nicht final poliert.
