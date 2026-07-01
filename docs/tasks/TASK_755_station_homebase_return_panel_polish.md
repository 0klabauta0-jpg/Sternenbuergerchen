# TASK_755 - Station Homebase Return Panel Polish

## Ziel / Problem
Nach Cargo-Ende, Debrief und Rueckkehr zur Homebase soll der Spieler nicht nur eine kompakte Textzeile sehen, sondern einen klaren Rueckkehrzustand: Ergebnis angekommen, naechste Homebase-Aktion sichtbar, Vorbereitungsschritte als kleine Orientierung.

## Sinnhaftigkeit / Ursache
TASK_754 routet vollstaendige Homebase-Recapture-Findings auf diesen Polish. Der bestehende Follow-up-Pfad ist technisch korrekt, liest sich aber noch wie zwei Diagnosezeilen. Fuer den naechsten Playtest braucht die Homebase einen ruhigen Panel-Kopf und eine einfache Schrittspur, ohne daraus einen neuen Gameplay-State zu machen.

## Umfang
- `PostDebriefFollowupPanel` erhaelt einen stabilen Return-Panel-Style-Marker.
- Das Panel zeigt `Rueckkehr abgeschlossen` als Kopfzeile.
- Eine Aktionszeile nennt den aktuellen naechsten Homebase-Schritt.
- Die bestehenden Next-Sortie-Steps werden als kompakte, deutsche Chips gespiegelt.
- `get_station_homebase_return_panel_polish_snapshot()` fasst Sichtbarkeit, Texte, Chips, Bounds und Read-only-Grenzen zusammen.

## Nicht-Ziele
- Kein neuer Homebase-Command.
- Kein automatisches Starten, Navigieren oder Stagen.
- Kein Ersatz fuer den echten Host/Client-Fenster-Recapture.
- Kein Umbau des Mission-/Debrief-/Homebase-Handoffs.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_754_station_homebase_recapture_findings.md`
- `docs/tasks/TASK_749_station_homebase_followup_microcopy_polish.md`
- `docs/tasks/TASK_747_station_scenario_homebase_visible_readiness_review.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Station-Homebase-Return-Panel ist sichtbar und besitzt den Style `task_755_station_homebase_return_panel_v1`.
- Titel lautet `Rueckkehr abgeschlossen`.
- Aktionszeile nennt `Naechster Auftrag` und den aktuellen Step.
- Alle fuenf Station-Steps erscheinen als deutsche Chips.
- Der aktuelle Step wird als `current` markiert.
- Snapshot meldet `read_only = true`, `ui_sets_gameplay_truth = false`, `creates_navigation = false`, `creates_command = false`.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_755_station_homebase_return_panel_polish.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_755_station_homebase_return_panel_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_749_station_homebase_followup_microcopy_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_747_station_scenario_homebase_visible_readiness_review.gd`
- `git diff --check`

## Risiken / offene Punkte
Der echte sichtbare Host/Client-Homebase-Recapture bleibt weiter ein manueller Folgecheck. TASK_755 verbessert den Runtime-/Visual-Pfad, behauptet aber keine menschliche Sichtabnahme.
