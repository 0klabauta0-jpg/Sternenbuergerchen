# TASK_1168 - Left Tactical Stack Air And Anchor Polish

## Ziel / Problem
TASK_1167 hat den linken taktischen Stack fuer den naechsten Spielbarkeits-Slice akzeptiert, aber eine kleine Restreibung benannt: Fireteam-Mini-Cards und Eventlog sind noch randnah und wirken eng.

## Sinnhaftigkeit / Ursache
Der Stack funktioniert, braucht aber etwas mehr Luft und einen stabileren linken Anker, damit der Spieler im 1280er Host-/Client-Bild schneller zwischen Fireteam-Karten, Fokus und Ereignislog unterscheiden kann. Die Flaeche soll sichtbar luftiger werden, ohne die HUD-Architektur neu zu schneiden.

## Umfang
- Linken Mission-HUD-Stack im bestehenden Drop-Light-Layout leicht nach innen ziehen.
- Fireteam-Karten, Card-Host und Eventlog mit stabilen Air-/Anchor-Metadaten versehen.
- Einen Read-only Snapshot `get_left_tactical_stack_1280_air_anchor_polish_snapshot()` liefern.
- TASK_1167 als Quelle beibehalten und die Restreibung als abgeschlossen markieren.

## Nicht-Ziele
- Kein neues HUD-System.
- Keine neuen Commands, Effects, Fire-/Damage-Events oder Movement-Logik.
- Keine Multiplayer-Wahrheit im UI.
- Keine automatische Pixelanalyse.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1167_left_tactical_stack_1280_detail_visual_acceptance.md`
- `scripts/meta/drop_light_layout_contract.gd`

## Akzeptanzkriterien
- Snapshot `get_left_tactical_stack_1280_air_anchor_polish_snapshot()` existiert.
- Snapshot meldet Schema `sternenbuergerchen.left_tactical_stack_1280_air_anchor_polish.v1`.
- Linker Stack nutzt mindestens 32 px linken Rand im Mission-HUD-Layout.
- Fireteam-Mini und Eventlog teilen denselben linken Anker.
- Zwischen Fireteam-Mini und Eventlog liegen mindestens 24 px Luft.
- Mini-Card-Host nutzt mindestens 8 px Kartenabstand.
- Eventlog bleibt oberhalb des Bottom-Docks.
- Snapshot erzeugt keine Commands, Effects oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/meta/drop_light_layout_contract.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1168_left_tactical_stack_air_anchor_polish.gd`
- `docs/tasks/TASK_1168_left_tactical_stack_air_anchor_polish.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- Neuer Verifier: `scripts/tests/task_1168_left_tactical_stack_air_anchor_polish.gd`
- Regression: TASK_1167, TASK_1166, TASK_1165
- `git diff --check`

## Risiken / offene Punkte
Der Task ist bewusst klein: er verbessert die Lesbarkeit des vorhandenen linken Stacks, ersetzt aber keine spaetere echte HUD-Kompositionsarbeit fuer groessere Spielmodi.
