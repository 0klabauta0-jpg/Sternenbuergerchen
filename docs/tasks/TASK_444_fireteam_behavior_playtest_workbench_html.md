# TASK_444 - Fireteam Behavior Playtest Workbench HTML

## Ziel / Problem

Die Fireteam-Behavior-Regeln fuer `Move`, `Engage`, `Take` und `Defend` sollen in einer uebersichtlichen HTML-Arbeitsseite zusammengefasst werden. Die Seite soll zeigen, was aktuell umgesetzt ist, was noch getestet werden muss, welche Entscheidungen offen sind und wie die naechsten manuellen Playtests strukturiert werden.

## Sinnhaftigkeit / Ursache

Nach den Slices fuer `Engage` und `Take` ist die Runtime-Logik im Code weiter als die manuelle Playtest-Dokumentation. Gleichzeitig sind mehrere Beobachtungen aus dem Godot-Fenster noch offen: Defend-Sektoren, Kontaktreaktion, Gegnerverhalten, Muzzle Flash, Sicht-/Schusslinien, Formationen und Area-Flows. Ein bedienbares HTML hilft, diese Punkte kontrolliert abzuarbeiten, bevor weitere Behavior-Regeln in Code wandern.

## Umfang

- Neues Report-HTML unter `docs/reports/`.
- Split nach `Move`, `Engage`, `Take` und `Defend`.
- Kleine CSS-Beispielbilder fuer Maennchen, Formationen, Sektoren und Area-Ziele.
- Zusammenfassung des aktuellen Stands: Move manuell getestet, Engage/Take implementiert aber noch separat zu testen, Defend als Baseline vorhanden aber als eigener Behavior-Schnitt offen.
- Vorschlag fuer Defend-Regeln inklusive C/N/A, Sektorlogik und Auto-Defend nach abgeschlossenen Befehlen.
- Testmatrix mit lokalen Browser-Checkboxen.
- Offene Entscheidungen und Folgeaufgaben.
- JSON-Export fuer Playtest-Status, Entscheidungen und Notizen, damit der Stand aus dem Browser wieder in Codex eingelesen werden kann.

## Nicht-Ziele

- Keine Runtime-Aenderung.
- Kein neuer Combat- oder Pathfinding-Code.
- Keine zweite Gameplay-Wahrheit in der UI.
- Kein finaler LimboAI-Architekturentscheid.

## Relevante Contracts / Dokumente

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/tasks/TASK_442_fireteam_engage_behavior_control.md`
- `docs/tasks/TASK_443_fireteam_take_behavior_control.md`
- `docs/reports/fireteam_map_tool_drill_rebuild_status.html`

## Akzeptanzkriterien

- Das HTML ist lokal ohne Build-Schritt im Browser lesbar.
- Die vier Commands sind separat navigierbar.
- Die Seite benennt klar, dass Defend noch kein finaler neuer Slice ist.
- Die Seite enthaelt konkrete Defend-Vorschlaege.
- Die Seite enthaelt eine Testmatrix fuer Move, Engage, Take, Defend und Visuals.
- Die Seite enthaelt offene Fragen/Entscheidungen fuer die naechsten Schritte.
- Die Seite kann den aktuellen Arbeitsstand als JSON herunterladen oder kopierbar anzeigen.

## Betroffene Dateien

- `docs/reports/fireteam_behavior_playtest_workbench.html`
- `docs/tasks/TASK_444_fireteam_behavior_playtest_workbench_html.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung

- HTML im Browser oeffnen.
- `git diff --check`

## Risiken / offene Punkte

- Die Defend-Regeln sind bewusst Vorschlag, nicht finaler Contract.
- Die Playtest-Haken speichern nur lokal im Browser und sind keine Projekt-Wahrheit.
- Die Beispielbilder sind schematisch und ersetzen keine Godot-Screenshots.
