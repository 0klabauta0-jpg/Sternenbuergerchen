# TASK_534 - Pre-Mission Readiness Checklist

## Status: IMPLEMENTIERT

## Ziel / Problem
Nach Briefing, Minimap und bestaetigter Loadout-Empfehlung ist noch nicht auf einen Blick sichtbar, ob die Mission wirklich startklar ist oder was fehlt.

## Sinnhaftigkeit / Ursache
Der Startbutton nutzt bereits vorhandene Homebase-/Dropship-Guards. Fuer den Spieler fehlt aber ein kompakter, erklaerender Readiness-Block, der Briefing, Team, Loadout, Pilot, Cargo, Dropship, Boarding und Startstatus zusammenfasst.

## Umfang
- Neuer read-only Presenter fuer Pre-Mission-Readiness aus vorhandenen Homebase-Snapshots.
- Homebase rendert eine kompakte Checkliste im bestehenden Mission-Brief-Bereich.
- Snapshot expose't Items, Ready-/Warn-/Blocked-Zaehler, Summary und den bestehenden Start-Guard.
- Der laufende HTML-Report nennt TASK_534 und verschiebt den naechsten Vorschlag auf sichtbares FullHD-/Startflow-Polish.

## Nicht-Ziele
- Kein neuer Start-Guard.
- Keine neue Mission-, Loadout-, Pilot-, Cargo- oder Dropship-Wahrheit.
- Kein automatisches Starten oder Umverdrahten von `request_mission_start()`.
- Kein finaler visueller FullHD-Polish.

## Relevante Contracts / Dokumente
- `docs/dev/mission_briefing_contract.md`
- `docs/tasks/TASK_533_recommended_loadout_selection_bridge.md`
- `docs/tasks/TASK_382_homebase_direct_mission_flightdeck_display.md`
- `docs/tasks/TASK_528_rolling_html_status_report.md`

## Akzeptanzkriterien
- Checkliste ist read-only und setzt `ui_sets_gameplay_truth = false`.
- Leerer Homebase-Startzustand zeigt Blocker fuer Team/Dropship/Boarding/Start.
- Geboardeter Direct-Payload zeigt Ready fuer Team, Dropship, Boarding und Start.
- Loadout-Empfehlungsapply wird sichtbar als Ready/Warning unterschieden.
- Startstatus folgt weiter `can_request_mission_start()`.

## Betroffene Dateien
- `scripts/mission/pre_mission_readiness_presenter.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_534_pre_mission_readiness_checklist.gd`
- `docs/dev/mission_briefing_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_534_pre_mission_readiness_checklist.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_533_recommended_loadout_selection_bridge.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_382_homebase_direct_mission_flightdeck_display.gd`
- `git diff --check`

## Risiken / offene Punkte
- Cargo ist aktuell ein lesbares optionales Item; missionsspezifische Cargo-Pflichten brauchen spaeter Szenario-Gate-Daten.
- Die Darstellung ist kompakt und testbar, aber noch kein finaler FullHD-Visual-Pass.
