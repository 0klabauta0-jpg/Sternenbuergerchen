# TASK_532 - Briefing Background / Loadout Recommendation Polish

## Status: IMPLEMENTIERT

## Ziel / Problem
Nach TASK_531 zeigt das Briefing eine Minimap, aber das `background_image_path`-Asset und die Loadout-Empfehlungen bleiben noch zu textuell. Der Spieler soll vor Missionsstart schneller verstehen, warum der Einsatz gefaehrlich ist und welche Ausruestung sinnvoll waere.

## Sinnhaftigkeit / Ursache
`MissionScenarioData.briefing` enthaelt bereits `background_image_path` und `recommended_loadout`. Ohne visuelle und strukturierte Darstellung wirken diese Daten wie Debugtext statt wie ein Briefing. Gleichzeitig duerfen sie keine echte Loadout- oder Mission-Wahrheit im UI werden.

## Umfang
- `MissionBriefingPanelPresenter` normalisiert Hintergrundbild- und Loadout-Card-Daten fuer UI.
- `HomebaseTestScreen` rendert das Briefing-Bild als TextureRect im bestehenden Briefing-Panel.
- Loadout-Empfehlungen erscheinen als kompakte Card-Zeilen mit Label, Waffen, Armor und Begruendung.
- Der laufende HTML-Bericht wird aktualisiert.

## Nicht-Ziele
- Kein automatisches Anwenden empfohlener Loadouts.
- Kein neues Loadout-Economy- oder Inventarsystem.
- Kein kompletter Pre-Mission-Dialog.
- Kein manueller FullHD-Sichttest in diesem Task.

## Relevante Contracts / Dokumente
- `docs/dev/mission_briefing_contract.md`
- `docs/tasks/TASK_531_briefing_minimap_visual_renderer.md`
- `docs/tasks/TASK_530_briefing_panel_renderer_mvp.md`
- `docs/tasks/TASK_528_rolling_html_status_report.md`

## Akzeptanzkriterien
- Briefing-Panel-Snapshot enthaelt `background_image_exists`, `background_image_status_text` und strukturierte `loadout_card_entries`.
- Homebase rendert das Hintergrundbild, wenn der `res://`-Pfad existiert.
- Homebase rendert mindestens zwei Loadout-Card-Zeilen fuer den Frontier-Slice.
- Alle neuen UI-Daten setzen beziehungsweise erhalten `ui_sets_gameplay_truth = false`.
- Bestehende Briefing-/Minimap-/Teamicon-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/mission/mission_briefing_panel_presenter.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_532_briefing_background_loadout_recommendation_polish.gd`
- `docs/dev/mission_briefing_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_532_briefing_background_loadout_recommendation_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_531_briefing_minimap_visual_renderer.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_530_briefing_panel_renderer_mvp.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_529_mission_hud_team_icon_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
Das Bild ist eine kleine Vorschau, keine finale Briefing-Hero-Komposition. Empfohlene Loadouts bleiben bewusst passiv; eine spaetere Loadout-Bruecke sollte erst gebaut werden, wenn die Auswahl-/Bestaetigungs-UX klar ist.
