# TASK_648 - Homebase Next Sortie Action Cue

## Ziel / Problem
Nach Debrief-Return soll die Homebase nicht nur das Ergebnis zeigen, sondern dem Spieler den naechsten wirklich handelbaren Schritt nennen. Aktuell kann `review_roster_gains` als aktueller Schritt stehen bleiben, obwohl der Spieler als naechstes ein Fireteam stagen, Loadout pruefen oder den Dropship-Start vorbereiten muss.

## Sinnhaftigkeit / Ursache
XP-/Skill-Gains sind wichtig, aber in diesem Slice kein blockierender Gameplay-Schritt. Wenn die Readiness-Zeile dauerhaft `now: Review gains` zeigt, wirkt der Loop klebrig und fuehrt nicht sauber zur naechsten Sortie.

## Umfang
- Next-Sortie-Resolver so anpassen, dass `Review gains` sichtbar bleibt, aber nicht die naechste blockierende Aktion verdeckt.
- Snapshot um einen Read-only-Hinweis ergaenzen, dass Review-Gains informational/non-blocking ist.
- Verifier fuer Debrief-Return mit Awards, aber ohne gestagte Payload: aktueller Schritt muss `stage_fireteam` sein.
- Status, Roadmap, Contract und HTML-Berichte aktualisieren.

## Nicht-Ziele
- Kein neuer Button und kein neuer Homebase-Navigationscommand.
- Kein Acknowledge-/Dismiss-State fuer Progression.
- Keine Aenderung an Progression, MissionResult, Staging, Loadout oder Launch-Wahrheit.
- Kein Layout-Rework nach TASK_647.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_647_homebase_missionpanel_density_findings.md`
- `docs/tasks/TASK_641_frontier_probe_homebase_next_sortie_readiness.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Mit Frontier-Probe-Resultat und Awards bleibt der Schritt `Review gains` in der Liste sichtbar.
- Wenn noch keine Payload gestaged ist, zeigt `current_next_step_id = stage_fireteam`.
- Die gerenderte Readiness-Zeile nennt `now: Stage fireteam`.
- Snapshot und Manifest bleiben read-only und erzeugen keine Commands.
- Bestehende Homebase-Density-Gates bleiben gruen.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_641_frontier_probe_homebase_next_sortie_readiness.gd`
- `scripts/tests/task_648_homebase_next_sortie_action_cue.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`
- `docs/reports/project_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_648_homebase_next_sortie_action_cue.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_641_frontier_probe_homebase_next_sortie_readiness.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_647_homebase_missionpanel_density_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
Dieser Task macht den naechsten Handlungsschritt klarer, fuehrt aber noch keinen echten Progression-Review-Dialog oder Acknowledge-State ein. Wenn spaeter ein echter Roster-Gains-Screen gebaut wird, kann dieser Schritt wieder interaktiv werden.
