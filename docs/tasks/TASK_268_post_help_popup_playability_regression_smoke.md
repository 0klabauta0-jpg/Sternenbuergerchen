# TASK_268 - Post Help Popup Playability Regression Smoke

## Ziel
Nach der Hilfe-Popup-Integration soll ein Playability-Smoke pruefen, ob alles weiterhin bedienbar ist: Buttons, feste Fenster, Scrollbars, Charakterkarten, Loadout, Befehle, Settings, Editor, Mission und Multiplayer-Vorbereitung.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_262 - Playability Regression Gate and Manual Open Items
- TASK_263 - Contextual Help Popup UX Contract
- TASK_264 - Contextual Help Popup Component Settings Toggle
- TASK_265 - Character Sheet Loadout Help Content Pass
- TASK_266 - Command Mission Editor Settings Help Content Pass
- TASK_267 - Contextual Help Coverage Layout Verifier

## Kontext
Hilfe-Popups sind nuetzlich, koennen aber leicht neue Probleme erzeugen: Hover blockiert Klicks, Popups verdecken Buttons, Settings greifen nicht, Character Card wird unruhig, oder der Mission-HUD-Flow bekommt neue Clipping-Probleme. Deshalb folgt nach der Hilfe ein erneuter Playability-Check.

## Umfang
1. Gate-Wiederholung:
   - TASK_262-Playability-Gate ausfuehren.
   - TASK_267-Help-Gate ausfuehren.
   - Harte Fehler zusammenfassen.
2. Bedienbarkeit:
   - Hilfe an, kompakt.
   - Hilfe erweitert/long-hover.
   - Hilfe aus.
   - In allen Modi bleiben Buttons klickbar.
3. Screen-Flows:
   - Hauptmenue und Settings.
   - Homebase/Roster/Character Card.
   - FOB/Loadout/Gewicht.
   - Mission-HUD/Befehlsplatten.
   - Editor-Werkzeuge.
   - Multiplayer Host/Join-Vorbereitung.
4. Layout:
   - Popups verschieben keine festen Fenster.
   - Popups erzeugen keine neuen Scroll-/Clipping-Fehler.
   - Globaler Help-Button verdeckt keine Topbar-Aktionen.
5. Report:
   - Vorher/Nachher gegen TASK_262.
   - Hilfe-spezifische Regressionen.
   - Kurze manuelle Restcheckliste fuer Lesbarkeit und subjektive Textqualitaet.

## Nicht-Ziele
- Kein finales Copy-Editing aller Hilfetexte.
- Kein Tutorial- oder Onboarding-System.
- Kein neuer Feature-Fix ausser kleinen offensichtlichen Regressionen.

## Akzeptanzkriterien
- [x] Playability-Gate laeuft mit Hilfe an und Hilfe aus.
- [x] Hilfe-Popups blockieren keine Pflichtbuttons.
- [x] Feste Fenster bleiben fest und werden nicht durch Popups verschoben.
- [x] Charakterbogen, Loadout, Befehlsplatten, Editor und Settings bleiben bedienbar.
- [x] Help-Coverage-Report und Playability-Report sind verknuepft.
- [x] Manuelle Restcheckliste ist kurz und benennt nur nicht automatisierbare Punkte.

## Erwartete Dateien
- `scripts/tests/task_268_post_help_popup_playability_regression_smoke.gd`
- optional `scripts/tests/run_task_268_post_help_playability_gate.ps1`
- `docs/reports/post_help_popup_playability_regression_report.md`
- `docs/manual_checks/post_help_popup_manual_readability_checklist.md`
- `docs/tasks/TASK_268_post_help_popup_playability_regression_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_268_post_help_popup_playability_regression_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_262_playability_regression_gate_and_manual_open_items.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_267_contextual_help_coverage_layout_verifier.gd`
- [x] Manueller kurzer Hilfe-Lesbarkeitscheck als Checkliste dokumentiert.
- [x] `git diff --check`

## Risiken
- Der Smoke kann subjektive Textqualitaet nicht ersetzen.
- Hilfeinhalte koennen fachlich schnell altern; Katalog und Verifier muessen bei Gameplay-Aenderungen mitgezogen werden.

## Naechster Schritt
Nach TASK_268 kann Hilfe als Standardanforderung fuer neue UI-, Character-, Loadout-, Mission- und Editor-Controls gelten.
