# TASK_463 - Fireteam Auto Defend Guard And Enemy Model Visibility

## Ziel / Problem
- Fireteams fallen nach einem neuen `Move`/`Engage`/`Take`-Befehl zu frueh wieder in `DEF 360`, obwohl der neue Befehl sichtbar erst angelaufen ist.
- `DEF 360` soll nach echtem Abschluss sichern, aber laufende Movement-Auftraege nicht ueberstimmen.
- In der Drillmap sollen alle vier gegnerischen NPCs als 3D-Unit-Modelle sichtbar sein, nicht nur als rote Marker/Labels.

## Sinnhaftigkeit / Ursache
- TASK_462 hat eine weiche Abschlusspruefung eingefuehrt. Diese darf nur als Unstick-/Completion-Schutz greifen, nicht als sofortige Abkuerzung fuer aktive Movement-Zielslots.
- Der Default-Defend richtet die Einheit aktuell ueber feste Sektorwinkel aus. Fuer das sichtbare `DEF 360` ist ein ruecken-an-ruecken-artiges Outward-Facing vom aktuellen Teamzentrum plausibler.
- Die Enemy-Visuals muessen gegen den realen Drill-Szenario-Pfad abgesichert werden, inklusive der aus dem Szenario duplizierten Enemy-Slots.

## Umfang
- Abschlusslogik fuer aktive Fireteam-Wegpunkte enger machen.
- Weiche Completion nur nach einer Mindestlaufzeit und nur gegen aktuelle Movement-Zielslots zulassen.
- Anchor-/Center-Fallback nicht mehr waehrend aktiver Movement-Execution nutzen.
- Default-`DEF 360`-Facing fuer Hold-Commands vom aktuellen Teamzentrum nach aussen ableiten.
- Drill-Szenario-Verifier fuer vier sichtbare Enemy-Animated-Model-Proxies ergaenzen.

## Nicht-Ziele
- Keine neue Pathfinding-Architektur.
- Keine neue Enemy-KI oder Patrouillenlogik.
- Keine neue Sequence-/Workbench-Integration fuer `DEF 360`.
- Keine Balance-Aenderung an C/N/A.

## Relevante Contracts / Dokumente
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_462_fireteam_auto_defend_completion_release.md`
- `docs/tasks/TASK_461_fireteam_engage_visual_stuck_hotfix.md`
- `docs/tasks/TASK_438_fireteam_contact_visibility_attack_visuals.md`

## Akzeptanzkriterien
- Ein laufender Movement-Wegpunkt wird nicht innerhalb der ersten Sekunden durch die weiche Completion in `DEF 360` beendet.
- Wenn alle Units nach der Mindestlaufzeit an ihren aktuellen Movement-Zielslots stehen, darf der Auftrag weiter abschliessen.
- Ein neuer Folgebefehl bleibt aktiv und wird nicht sofort durch Auto-Defend ueberschrieben.
- Default-`DEF 360` setzt unterschiedliche Outward-Facing-Winkel, ohne die Units durch neue Bewegungsziele zu kreuzen.
- Die Fireteam-Drillmap meldet vier Enemy-Proxy-IDs, vier sichtbare Enemy-Proxies und vier Enemy-Proxies mit Animated-Character-Model.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `data/npc_unit_visual_mapping.json`
- `scripts/tests/task_463_fireteam_auto_defend_guard_enemy_model_visibility.gd`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_463_fireteam_auto_defend_guard_enemy_model_visibility.gd`
- Relevante Regressionen TASK_462/TASK_461/TASK_438.
- `git diff --check`

## Risiken / offene Punkte
- Dieser Task stabilisiert Abschluss und Sichtbarkeit. Wenn danach Units weiter in Engstellen haengen, muss das als Zielslot-/Pathfinding-/Avoidance-Slice separat untersucht werden.
