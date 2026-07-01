# TASK_748 - Station Scenario Homebase Readiness Visual Polish Findings

## Ziel / Problem
TASK_747 hat den Station-Homebase-Zustand nach dem Debrief technisch sichtbar gemacht: Summary und Next-Sortie-Zeile sind vorhanden, liegen korrekt und bleiben read-only. Der eigentliche Geschmackstest ist damit aber noch nicht erledigt. TASK_748 schneidet daraus die konkreten Visual-Polish-Findings heraus, damit der naechste Griff klein und begruendet bleibt.

## Sinnhaftigkeit / Ursache
Der Homebase-Return ist ein wichtiger Spielmoment: Nach dem Einsatz soll der Spieler sofort verstehen, was passiert ist und was als Naechstes zu tun ist. TASK_747 belegt Geometrie und Bounds, aber das Evidence-Manifest sagt auch: Headless-Evidence, manueller Review offen, lange englisch-lastige Next-Sortie-Zeile. Diese Reibung soll nicht im Chat versanden, sondern als Task-/Manifest-Fund dokumentiert werden.

## Umfang
- TASK_747-Manifest und aktuellen Station-Homebase-Snapshot auswerten.
- Findings-Manifest `tmp/station_scenario_homebase_readiness_visual_polish_findings.json` schreiben.
- Konkrete Befunde festhalten: Geometrie gruen, Read-only gruen, manueller sichtbarer Review offen, Next-Sortie-Microcopy zu lang/englisch-lastig fuer den naechsten Polish.
- Contract, Status, Roadmap und HTML-Handbuch fortschreiben.
- Naechsten kleinen Task empfehlen: `TASK_749 - Station Homebase Follow-up Microcopy Polish`.

## Nicht-Ziele
- Kein Runtime-Layout-Umbau.
- Keine neue Homebase-Navigation.
- Kein Startbutton-Commit, kein Command, keine Staging-Mutation.
- Keine Progression-, XP- oder MissionResult-Aenderung.
- Kein echter Host/Client-Fenster-Recapture.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_747_station_scenario_homebase_visible_readiness_review.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Verifier bestaetigt, dass TASK_747-Manifest und Snapshot gruen sind.
- Findings-Manifest liefert `schema = sternenbuergerchen.station_scenario_homebase_readiness_visual_polish_findings.v1`.
- `source_task_id = TASK_747`, `source_gate = pass`, `geometry_gate = pass`.
- `manual_review_required = true`, `manual_review_done = false`.
- `microcopy_followup_needed = true` fuer die lange/englisch-lastige Next-Sortie-Zeile.
- `actionable_followup_count >= 1`.
- `read_only = true`, `ui_sets_gameplay_truth = false`, `creates_navigation = false`, `creates_command = false`.
- `recommended_next_task = TASK_749 - Station Homebase Follow-up Microcopy Polish`.

## Betroffene Dateien
- `scripts/tests/task_748_station_scenario_homebase_readiness_visual_polish_findings.gd`
- `docs/tasks/TASK_748_station_scenario_homebase_readiness_visual_polish_findings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_747_station_scenario_homebase_visible_readiness_review.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_748_station_scenario_homebase_readiness_visual_polish_findings.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
TASK_748 ist bewusst ein Findings-/Planungsanker. Die echte sichtbare Verbesserung kommt erst mit TASK_749 oder mit einem echten Host/Client-Fenster-Recapture, falls dort eine andere Reibung staerker auffaellt.
