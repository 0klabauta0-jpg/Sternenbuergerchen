# TASK_587 - Debrief Visual Polish Pass

## Ziel / Problem
TASK_586 macht den Rueckweg vom Debrief in die Homebase pruefbar. Der Debrief selbst ist aber noch roh: Ergebnis, Teamstatus und Rueckkehraktionen liegen als lange Textbloecke ohne klare visuelle Hierarchie vor.

## Sinnhaftigkeit / Ursache
Der Core Loop endet fuer den Spieler nicht mit einem internen MissionResult, sondern mit einem lesbaren Debrief. Wenn der Spieler nach dem Einsatz nicht sofort erkennt, was passiert ist und wohin er als naechstes klicken soll, fuehlt sich der Flow unfertig an.

## Umfang
- Kompakte Summary-Chips fuer Resultat, Gewinner, Dauer, Siegbedingung und Objective-Status.
- Kuerzerer Ergebnistext statt grossem mehrzeiligem Block.
- Kuerzerer Teamstatus mit Statuszaehlern und maximal vier Member-Tokens.
- `Return to Homebase` als primaere Aktion, `Return to FOB` als sekundaere Aktion.
- Read-only Snapshot `DebriefTestScreen.get_debrief_visual_polish_snapshot()` fuer Verifier und Bericht.
- Laufender HTML-Zwischenbericht wird auf TASK_587 aktualisiert.

## Nicht-Ziele
- Kein XP-/Skill-System.
- Kein Ammo- oder echtes Suppression-AAR.
- Kein neues Missionsresultat-Modell.
- Kein neuer Meta-Navigationspfad.
- Keine Gameplay-Wahrheit im Debrief.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_586_debrief_return_homebase_handoff.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Snapshot-Schema ist `sternenbuergerchen.debrief_visual_polish.v1`.
- Snapshot setzt `read_only = true` und `ui_sets_gameplay_truth = false`.
- Mindestens fuenf Summary-Chips sind sichtbar.
- Ergebnistext bleibt kompakt und scanbar.
- Teamstatus bleibt kompakt genug fuer den Debrief-Panel-Kontext.
- Homebase-Rueckkehr ist als primaere Aktion markiert, FOB-Rueckkehr als sekundaere Aktion.
- Hintergrund-/Panel-Lesbarkeit aus dem vorhandenen Debrief-Background-Contract bleibt erhalten.

## Betroffene Dateien
- `scripts/meta/debrief_screen.gd`
- `scripts/tests/task_587_debrief_visual_polish_pass.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_587_debrief_visual_polish_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_586_debrief_return_homebase_handoff.gd`
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_debrief_background_and_main_menu_team_library.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_587 poliert die Lesbarkeit, aber noch nicht den vollstaendigen AAR-Inhalt.
- Echte XP-/Skillentwicklung, Ammo-Verbrauch und Suppression-Wirkung bleiben Folgearbeit.
- Der naechste sinnvolle Schritt ist ein kleiner `TASK_588 - Debrief AAR Data Bridge`, wenn die Mini-AAR-Kampfmetriken in den sichtbaren Meta-Debrief hinein sollen.
