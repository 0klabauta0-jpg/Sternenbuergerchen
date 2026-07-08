# TASK_846 - Release First Exchange Visual Findings

## Ziel / Problem
TASK_845 hat den echten Release-Fensterblick nach TASK_844 gecaptured. Das Manifest ist `review_ready`, aber der Screenshot zeigt weiter `CONTACT PRESSURE` und `NO FIRE NO_LOS`, obwohl TASK_844 headless einen echten `fire_exchange` nachweist.

Ziel ist ein kleiner, maschinenlesbarer Findings-Schnitt: Was ist technisch akzeptabel, was widerspricht der erwarteten Spielerlesbarkeit, und welcher konkrete naechste Polish-Task macht den ersten Feuerwechsel im Fenster verstaendlich?

## Sinnhaftigkeit / Ursache
Der Spieler bewertet nicht den Headless-Snapshot, sondern das sichtbare Fenster. Der echte Capture belegt eine Divergenz: Die Gameplay-/QA-Evidence existiert, aber #17, #18 und #19 rahmen den Moment noch als Pressure-/Korrekturzustand. Daraus soll kein pauschaler Combat-Rewrite entstehen, sondern ein enger Sichtbarkeits-Fix.

## Umfang
- Neuer read-only Analyzer `ReleaseFirstExchangeVisualFindings`.
- Auswertung des TASK_845-Manifests und der Zwischenbericht-/Sichtnotizen.
- Positive Findings: Release-Pfad ist capturebar, Layout bleibt bedienbar, Command Matrix bleibt sichtbar.
- Offene Findings:
  - `first_exchange_not_visible_in_window`: erwartetes `CONTACT FIRE` kommt im Fenster nicht an.
  - `hud_surfaces_stale_pressure`: #17/#18 priorisieren weiter `NO FIRE`/LOS-Korrektur.
  - `fire_trace_or_impact_not_obvious`: FireEvent-/Trace-/Impact-Evidence ist fuer den Spieler nicht offensichtlich.
- JSON-Manifest unter `tmp/release_first_exchange_visual_findings.json`.
- Folgeempfehlung: TASK_847 - Release Fire Exchange Visibility Persistence.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein automatischer Pixelentscheid.
- Kein neues FireEvent- oder Damage-Verhalten.
- Kein Markieren des manuellen Sichtreviews als erledigt.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_845_release_first_exchange_real_window_recapture.md`
- `docs/tasks/TASK_844_release_first_exchange_tension_tuning.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- Snapshot nennt Schema `sternenbuergerchen.release_first_exchange_visual_findings.v1` und `task_id = TASK_846`.
- Snapshot bleibt `read_only=true` und `ui_sets_gameplay_truth=false`.
- TASK_845-Manifest mit `review_ready`, TASK_844-Quelle und TASK_844-Style-ID erzeugt keine technischen Blocker.
- Findings nennen `first_exchange_not_visible_in_window` als primaeres offenes Polish-Problem.
- Findings nennen `hud_surfaces_stale_pressure` und `fire_trace_or_impact_not_obvious` als konkrete Folgeprobleme.
- Manifest nennt `recommended_next_task = TASK_847 - Release Fire Exchange Visibility Persistence`.

## Betroffene Dateien
- `scripts/mission/release_first_exchange_visual_findings.gd`
- `scripts/tests/task_846_release_first_exchange_visual_findings.gd`
- `docs/tasks/TASK_846_release_first_exchange_visual_findings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_846_release_first_exchange_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_845_release_first_exchange_real_window_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_846 ist bewusst ein Befund-Task. Die sichtbare Verbesserung folgt in TASK_847, damit der Code-Eingriff eng an den belegten Fensterbefund gebunden bleibt.
