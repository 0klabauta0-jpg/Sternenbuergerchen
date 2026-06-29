# TASK_591 - Debrief AAR Player Review Notes Pass

## Ziel / Problem
Nach TASK_590 ist der Debrief-AAR-Block technisch lesbarer, aber der echte Spielerblick ist weiter nicht strukturiert erfasst. Damit fehlt ein sauberer Ort, um Screenshot, Pflichtchecks, Lesbarkeits-Ratings und konkrete Folgeentscheidungen fuer den Debrief-AAR-Block festzuhalten.

## Sinnhaftigkeit / Ursache
Automatische Gates koennen Prefix, Textlaenge und Layout-Rects pruefen, aber nicht beantworten, ob der Debrief beim Spieler als angenehm, schnell und eindeutig lesbar ankommt. Fuer die bisherigen visuellen Slices gibt es im HTML-Bericht bereits exportierbare Review-Notizbloecke; der Debrief-AAR braucht denselben Workflow.

## Umfang
- Einen TASK_591-Debrief-AAR-Player-Review-Block im laufenden HTML-Bericht ergaenzen.
- Screenshotpfad, Viewport, Pflichtchecks, Ratings, Folgeprioritaet und freie Notizen exportierbar machen.
- Den Bericht, Status, Roadmap und Contract auf TASK_591 aktualisieren.
- Einen statischen Verifier fuer Export-Keys, Contract, Status, Roadmap und Follow-up-Kette ergaenzen.

## Nicht-Ziele
- Kein neues Debrief-Gameplay.
- Keine XP-, Skill-, Ammo- oder Suppression-Wirkung.
- Kein automatischer menschlicher Sichtentscheid.
- Keine Mutation von MissionResult, Combat-State oder Mini-AAR-Daten.

## Relevante Contracts / Dokumente
- `docs/dev/html_report_workbench_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_590_debrief_aar_layout_polish_findings.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Der HTML-Bericht enthaelt einen sichtbaren TASK_591-Debrief-AAR-Player-Review-Block.
- Export-Keys erfassen mindestens Screenshotpfad, Viewport, Summary-/Chip-/Rows-/Limit-/Return-Checks, Ratings und Follow-up.
- Ein `contenteditable`-Freitextfeld exportiert freie Debrief-AAR-Review-Notizen.
- Roadmap und Status markieren TASK_591 als implementiert und nennen TASK_592 als Folge-Review-Findings-Slice.
- Der Verifier prueft, dass der Bericht weiterhin `JSON exportieren` anbietet.

## Betroffene Dateien
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_591_debrief_aar_player_review_notes_pass.md`
- `scripts/tests/task_591_debrief_aar_player_review_notes_pass.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_591_debrief_aar_player_review_notes_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_590_debrief_aar_layout_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Block macht den echten Debrief-AAR-Sichttest leichter auswertbar, fuehrt ihn aber nicht selbst aus. Wenn der Export konkrete Reibungen zeigt, sollte TASK_592 die belegten Player-Review-Findings anwenden.
