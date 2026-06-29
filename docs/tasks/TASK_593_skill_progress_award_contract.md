# TASK_593 - Skill Progress Award Contract

## Ziel / Problem
TASK_592 macht Skillentwicklung im Debrief sichtbar, aber bewusst nur als Preview. Der Core Loop braucht jetzt eine klare Grenze, wann diese Vorschau zu echten XP-/Skill-Fortschritten wird und welche Schicht dafuer autoritativ ist.

## Sinnhaftigkeit / Ursache
Es gibt bereits `MissionProgressionResolver`, `progression_unit_updates`, `character_events` und persistierte Roster-Updates im Meta-Layer. Ohne einen kleinen Award-Contract koennte die Debrief-UI spaeter versehentlich eigene Progressionswahrheit erzeugen oder die Preview mit echten Awards vermischen.

## Umfang
- `MissionProgressionResolver` erzeugt eine kompakte `award_summary` aus den bereits angewendeten `unit_updates`.
- `MetaLayerFlow` reicht diese Summary als `progression_award_summary` ins MissionResult weiter.
- `DebriefTestScreen` zeigt eine kompakte read-only Award-Zeile, wenn echte Progressionsdaten vorhanden sind.
- Ein Snapshot prueft Quelle, Schema, Totals, sichtbare Debrief-Zeile und read-only-Grenzen.
- Laufender HTML-Bericht, Status, Roadmap und Contract werden aktualisiert.

## Nicht-Ziele
- Kein neues XP- oder Skill-Balancing.
- Keine neue Persistenzschicht.
- Keine Skill-Tree-UI.
- Keine Award-Mutation im Debrief.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/fireteam_leader_tactical_progression.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_592_debrief_skill_progress_preview_shell.md`

## Akzeptanzkriterien
- Award-Summary meldet Schema `sternenbuergerchen.skill_progress_award_summary.v1`.
- Authority ist `MissionProgressionResolver`.
- Summary enthaelt XP-, Skill-, FTL- und Recovery-Zaehler aus `unit_updates`.
- Debrief zeigt echte Awards nur aus `progression_award_summary`, nicht aus Preview-Daten.
- Debrief-Snapshot meldet Schema `sternenbuergerchen.debrief_skill_award_contract.v1`.
- TASK_592 Skill-Preview und TASK_237/TASK_273 Progression bleiben gruen.

## Betroffene Dateien
- `scripts/meta/mission_progression_resolver.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/meta/debrief_screen.gd`
- `scripts/tests/task_593_skill_progress_award_contract.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_593_skill_progress_award_contract.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_592_debrief_skill_progress_preview_shell.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_237_mission_progression_xp_morale_frustration.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_273_fireteam_leader_skill_tactical_progression.gd`
- `git diff --check`

## Risiken / offene Punkte
Die Werte bleiben das bestehende V1-Balancing. TASK_593 macht sie nur sauber zusammenfassbar und im Debrief sichtbar. Ein spaeterer Skill-Tree, detaillierte Award-Animationen oder Balance-Tuning bleiben eigene Tasks.
