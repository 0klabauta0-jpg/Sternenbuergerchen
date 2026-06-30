# TASK_647 - Homebase MissionPanel Density Findings

## Ziel / Problem
TASK_646 hat gezeigt, dass das Homebase-`MissionPanel` nach Debrief-Return zwar korrekt bleibt, aber mit Briefing, Readiness, Follow-up und alter MissionSummary nahe an der Dichte-Warnschwelle liegt.

## Sinnhaftigkeit / Ursache
Die neue Follow-up-Box aus TASK_645 transportiert bereits Ergebnis und naechsten Schritt. Die alte `MissionSummaryLabel` wiederholt in genau diesem Post-Debrief-Zustand viel Kontext und nimmt Scanraum weg.

## Umfang
- Legacy-`MissionSummaryLabel` nur dann kollabieren, wenn der Frontier-Probe-Post-Debrief-Follow-up-Block sichtbar ist.
- TASK_646-Snapshot um Density-Findings-Felder erweitern.
- Verifier fuer reduzierte Sektionen und Textbudget; die vertikale Fuellung bleibt als Review-Warnwert sichtbar.
- Status, Roadmap, Contract und HTML-Berichte aktualisieren.

## Nicht-Ziele
- Kein Rework des gesamten Homebase-Layouts.
- Keine Aenderung an MissionResult, Progression, Staging, Navigation oder Commands.
- Kein neuer Gameplay-State im HUD.
- Kein Entfernen der MissionSummary ausserhalb des Post-Debrief-Follow-up-Zustands.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_646_homebase_missionpanel_density_playfeel_review.md`
- `docs/tasks/TASK_645_frontier_probe_homebase_summary_next_sortie_polish.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- `MissionSummaryLabel` ist im Post-Debrief-Follow-up-Zustand kollabiert und per Meta als TASK_647-Finding markiert.
- Follow-up, Briefing und Readiness bleiben sichtbar und in der Reihenfolge Briefing -> Readiness -> Follow-up.
- Sichtbare Sektionen und Textmenge sinken gegenueber TASK_646-Warnlage.
- Vertikale Fuellung bleibt innerhalb der harten Panel-Grenzen und wird weiter fuer den echten Fensterblick protokolliert.
- Snapshot und Verifier bleiben read-only und erzeugen keine Commands.
- Lokales Manifest dokumentiert die Werte fuer den naechsten echten Fensterblick.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_647_homebase_missionpanel_density_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`
- `docs/reports/project_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_647_homebase_missionpanel_density_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_646_homebase_missionpanel_density_playfeel_review.gd`
- `git diff --check`

## Risiken / offene Punkte
Das reduziert die belegte Dichte strukturell. Der echte Geschmackstest im Fenster bleibt trotzdem wichtig, weil grobe Werte nicht entscheiden, ob der Block fuer Menschen wirklich angenehm wirkt.
