# TASK_457 - Fireteam Contact Engage Runtime Pass

## Ziel / Problem
- Der naechste Playtest-Pass soll Kontakt und Engage sichtbar stabilisieren: Gegner muessen vollstaendig sichtbar sein, Kontakte muessen erkannt werden, Firelines sollen bei erkanntem Ziel rot werden, Muzzleflash soll beim Schuss sichtbar sein und Engage-/Take-Area-Befehle duerfen nicht haengen bleiben.

## Sinnhaftigkeit / Ursache
- Die Formation-Workbench, Stance-Werte und Segment-LOS sind jetzt als Basis vorhanden.
- Im manuellen Playtest sind aber noch Luecken im sichtbaren Kampfpfad aufgefallen: nicht alle Gegner werden dargestellt, Schuss-/Kontaktreaktion wirkt passiv, Aim-Bereitschaft ist noch nicht voll an Zielzeit/Animation gekoppelt und Area-Folgeauftraege koennen stocken.

## Umfang
- Mission-Tactical-Pfad ueber `MissionTacticalSandboxController`, `FireteamMovementController`, `SimulationRoot`, Combat-/LOS-Helfer und 2.5D-Visuals pruefen und gezielt reparieren.
- Gegnerteam im Fireteam-Drill vollstaendig sichtbar machen.
- Gegner-Patrouille und Kontaktreaktion im Drill stabilisieren.
- Kontaktlinien/Schusslinien bei erkanntem Gegner sichtbar rot markieren.
- Muzzleflash an reale Feuerentscheidung koppeln.
- `aim_readiness_percent` fuer Zielzeit und sichtbare Aim-Haltung wirksam machen.
- Engage Area -> Take Area -> Folgeauftrag gegen Haenger absichern.

## Nicht-Ziele
- Keine finale Sequenz-Workbench fuer raupenartiges oder ueberschlagendes Vorgehen.
- Keine grossen LimboAI-Umstellung.
- Keine Charakterbogen-Balance oder Skill-Skalierung.
- Kein neues Navigation-/Pathfinding-System.

## Relevante Contracts / Dokumente
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/terrain_truth_visual_audit_contract.md`
- `docs/tasks/TASK_451_fireteam_workbench_runtime_import.md`
- `docs/tasks/TASK_452_fireteam_runtime_baseline_visual_contact_pass.md`
- `docs/tasks/TASK_456_wall_segment_los_and_tile_truth_inspector.md`

## Akzeptanzkriterien
- Vier gegnerische Drill-NPCs sind in der Mission-Drillmap als Units sichtbar und nicht nur als Idle-/Kontaktmarker.
- Gegnerpatrouille oder mindestens ein klarer Enemy-Intent-Snapshot ist aktiv und testbar.
- Erkannter Gegner erzeugt eine rote Kontakt-/Schusslinie im sichtbaren Debugpfad.
- Ein tatsaechlicher Feuerentscheid erzeugt sichtbaren Muzzleflash.
- Hohe Aim-Bereitschaft reduziert die erste Ziel-/Feuerverzoegerung und haelt die Aim-Haltung sichtbar stabiler.
- Engage Area und anschliessendes Take/Move/Defend arbeiten weiter, ohne den aktiven Plan auf einem erledigten Area- oder Wegpunkt zu blockieren.
- Headless-Verifier decken die reparierten Pfade ab.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tactical/combat_fire_decision_resolver.gd`
- `scripts/tactical/enemy_limbo_behavior_adapter.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- Drillmap- und Szenario-Daten nach Bedarf

## Lokale Pruefung
- Neuer Task-Verifier fuer Kontakt-/Engage-Runtime.
- Relevante Regressionen aus TASK_438, TASK_440, TASK_452 und TASK_456.
- `git diff --check`.

## Risiken / offene Punkte
- Aim-Timing und Animation bleiben ein erster Runtime-Hook, keine finale Animations-Blend-Formel.
- Wenn Haenger aus Pathing/Local-Avoidance statt Area-Queue kommen, braucht das einen separaten Navigation-Slice.
