# TASK_478 - Fireteam Soft Completion Final Stage Guard

## Ziel / Problem
- Fireteams fallen nach `Take`/`Engage`/nicht-direkten Bewegungen wieder in `DEF 360`, obwohl sie nur einen Zwischenhalt, Bound oder Cover-/Stage-Ziel erreicht haben.
- Auto-`DEF 360` soll weiter nach echtem Abschluss greifen, aber keine laufenden Zwischenphasen beenden.

## Sinnhaftigkeit / Ursache
- Die weiche Zielslot-Completion aus TASK_462/TASK_463 war als Unstick-Schutz gedacht.
- Sie pruefte bisher nur, ob die aktuellen Movement-Zielslots erreicht sind.
- Bei Bounding/Caterpillar/Take/Engage koennen diese Zielslots aber Zwischenziele sein. Dadurch meldete die Mission-Schicht "Waypoint fertig" und loeste Auto-Defend aus.

## Umfang
- Weiche Completion auf aktive Movement-Snapshots nur erlauben, wenn der aktuelle Movement-Anchor bereits auf dem finalen Wegpunktziel liegt.
- Zwischenziele bleiben aktive Movement-Ausfuehrung und duerfen nicht Auto-Defend ausloesen.
- Regressionstest fuer Zwischenstage vs. finale Stage.

## Nicht-Ziele
- Keine neue Pathfinding-Architektur.
- Keine neue Cover-Auswahl.
- Keine neue Take-/Engage-Doktrin.
- Keine UI-Umbauten.

## Relevante Contracts / Dokumente
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_462_fireteam_auto_defend_completion_release.md`
- `docs/tasks/TASK_463_fireteam_auto_defend_guard_enemy_model_visibility.md`
- `docs/tasks/TASK_477_fireteam_contact_cover_decision_v1.md`

## Akzeptanzkriterien
- Ein soft-reached Zwischenstage schliesst den gesamten Waypoint nicht ab.
- Ein soft-reached finaler Movement-Stage kann weiter abschliessen.
- Auto-`DEF 360` bleibt der Zustand nach echtem letzten Zielabschluss.
- Der bestehende TASK_462/TASK_463 Completion-Schutz bleibt erhalten.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_478_fireteam_soft_completion_final_stage_guard.gd`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_478_fireteam_soft_completion_final_stage_guard.gd`
- Relevante TASK_462/TASK_463/TASK_477-Regressionen.
- `git diff --check`

## Risiken / offene Punkte
- Wenn ein finaler Stage selbst durch falsche Zielslot-Auswahl schlecht liegt, kann Auto-Defend weiterhin korrekt nach "final erreicht" folgen. Das ist dann ein Zielslot-/Formationsthema, nicht dieser Completion-Guard.
- Contact-Flicker kann weiterhin zu neuen Stage-Commands fuehren; dieser Task verhindert nur, dass Zwischenziele als ganzer Waypointabschluss zaehlen.
