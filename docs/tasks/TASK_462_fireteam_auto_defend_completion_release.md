# TASK_462 - Fireteam Auto Defend Completion Release

## Ziel / Problem
- Fireteams bleiben nach sichtbarem Erreichen eines Zielbereichs teilweise in `Move`/`Engage` aktiv haengen und nehmen danach GO-/Folgebefehle nicht sauber an.
- Wenn nach einem erreichten Ziel kein weiterer Befehl existiert, soll das Fireteam automatisch in `DEF 360` gehen.
- Der Default-Defend darf nicht alle Mitglieder in dieselbe Richtung schauen lassen.

## Sinnhaftigkeit / Ursache
- Wegpunktabschluss prueft bisher zu eng gegen einzelne Runtime-Zielslots oder den Fireteam-Leader als Anchor. Bei Formation-/Avoidance-Zielslots kann die sichtbare Gruppe am Ziel stehen, waehrend ein Runtime-Slot noch nicht exakt innerhalb des harten Radius liegt.
- Der Default-Fallback existiert bereits, setzt aber keine sofort sichtbare 360-Facing-Verteilung auf die Unit-Metas/Commands.
- GO-Continue nutzt denselben Abschlussentscheid und blockt dadurch weiter als `ACTIVE`, wenn der Auftrag nur noch weich erreicht ist.

## Umfang
- Weiche Zielabschlusspruefung fuer aktive Fireteam-Wegpunkte ergaenzen.
- GO-Continue denselben Abschlussentscheid nutzen lassen.
- Nach letztem Wegpunkt ohne Folgeauftrag automatisch `DEF 360` anwenden.
- Default-Defend-Hold-Commands mit 360-Sektor-Facing und Security-Metadaten ausgeben.
- Headless-Verifier fuer Abschluss, GO-Fortsetzung und 360-Default ergaenzen.

## Nicht-Ziele
- Keine neue Pathfinding-Architektur.
- Keine neue Enemy-KI.
- Keine neue Doctrine-Sequenz fuer Bounding/raupenartig.
- Keine Balance-Aenderung an C/N/A.

## Relevante Contracts / Dokumente
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_461_fireteam_engage_visual_stuck_hotfix.md`
- `docs/tasks/TASK_422_go_continue_fireteam_hud_cleanup.md`
- `docs/tasks/TASK_420_waypoint_completion_area_followup_hotfix.md`

## Akzeptanzkriterien
- Ein aktiver Wegpunkt kann abschliessen, wenn alle Movement-Zielslots weich erreicht sind, auch wenn der harte MovementController-Radius noch nicht `finished` meldet.
- GO akzeptiert einen weich erreichten aktiven Wegpunkt als Continue und startet den naechsten Wegpunkt.
- Wenn nach Abschluss kein weiterer Waypoint/Area-Auftrag existiert, erhaelt das Fireteam Hold-Commands mit `source_task_type = auto_defend` und `security_mode = 360`.
- Die sichtbaren Facing-Metas der vier Mitglieder verteilen sich im Default-Defend auf unterschiedliche 360-Sektoren.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_462_fireteam_auto_defend_completion_release.gd`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_462_fireteam_auto_defend_completion_release.gd`
- Relevante Regressionen TASK_422/TASK_461.
- `git diff --check`

## Risiken / offene Punkte
- Die weiche Abschlusspruefung ist bewusst ein kleiner Runtime-Schutz gegen sichtbares Kleben. Echte Engstellen, schlechte Pfade oder falsche Area-Auftraege bleiben separate Diagnose-Slices.
