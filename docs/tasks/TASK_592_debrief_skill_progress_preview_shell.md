# TASK_592 - Debrief Skill Progress Preview Shell

## Ziel / Problem
Der Core Loop nennt nach dem Einsatz explizit Rueckkehr und Skillentwicklung. Im sichtbaren Debrief gibt es inzwischen Ergebnis, Teamstatus, Mini-AAR und Return-Handoff, aber noch keine kompakte Vorschau, welche Fireteams/Units aus dem Einsatz wahrscheinlich Fortschritt ziehen.

## Sinnhaftigkeit / Ursache
Ohne Fortschrittsvorschau endet der Missionsflow gefuehlt zu hart bei Ergebnis/AAR. Echte XP- und Skillvergabe ist ein groesseres System und soll nicht nebenbei entstehen. Ein read-only Preview-Shell macht den naechsten Core-Loop-Schritt sichtbar, ohne Gameplay-Wahrheit im UI zu speichern.

## Umfang
- `DebriefTestScreen` zeigt eine kompakte `Skill Preview`-Zeile aus vorhandenen `team_states` und `fireteam_tactical_debrief`.
- Preview nennt maximal vier Unit-/Fireteam-Tokens und bleibt ehrlich als Vorschau markiert.
- Neuer Snapshot `get_debrief_skill_progress_preview_snapshot()` prueft Text, Token-Anzahl, Style, Compactness und read-only-Grenze.
- Laufender HTML-Bericht, Status, Roadmap und Contract werden aktualisiert.

## Nicht-Ziele
- Keine echte XP-Vergabe.
- Keine Skill-Level-Mutation.
- Kein neues Charakter- oder Progressionssystem.
- Keine MissionResult-Mutation.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/tasks/TASK_591_debrief_aar_player_review_notes_pass.md`

## Akzeptanzkriterien
- Debrief zeigt eine sichtbare, kompakte Skill-Preview-Zeile.
- Snapshot meldet Schema `sternenbuergerchen.debrief_skill_progress_preview.v1`.
- Snapshot bleibt read-only und setzt keine Gameplay-Wahrheit.
- Preview unterscheidet Unit-Status und FTL-/Fireteam-Taktikfeedback zumindest als Text-Tokens.
- TASK_590 Debrief-AAR-Layout-Gate bleibt gruen.

## Betroffene Dateien
- `scripts/meta/debrief_screen.gd`
- `scripts/tests/task_592_debrief_skill_progress_preview_shell.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_592_debrief_skill_progress_preview_shell.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_590_debrief_aar_layout_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
Die Preview ist bewusst nur ein Lesbarkeits-/Core-Loop-Anker. Echte XP, Skillpunkte, Persistenz und Balance muessen spaeter als eigener Progressions-Task gebaut werden.
