# TASK_546 - Mission Combat Feedback HUD Density Polish

## Ziel / Problem
Nach TASK_545 kommt Fire-/Cover-Feedback im echten Homebase-Dropship-Mission-Engagement-Flow an. Die Panels zeigen diesen Kontext aber noch zu breit: Mission Control und Selected Fireteam koennen Combat-, Cover-, LOS- und Range-Information schwerer scannen als noetig.

Ziel ist ein kompakter HUD-Dichte-Slice: eine kurze Combat-Zeile, die vorhandene ContactDecision-, Cover- und FireEvent-Snapshots zusammenfasst, ohne Gameplay-Wahrheit im HUD zu erzeugen.

## Sinnhaftigkeit / Ursache
Der Spieler muss im Kampf schnell sehen, ob gerade gefeuert, gewartet oder blockiert wird und warum. Lange Diagnosezeilen sind fuer Tests gut, aber im Spielbild zu schwerfaellig. Der bestehende Datenpfad ist schon da; er braucht eine dichtere Darstellung.

## Umfang
- `MissionTacticalSandboxController` erzeugt einen read-only Combat-HUD-Density-Snapshot.
- Mission Control nutzt eine kompakte Combat-Zeile, wenn Contact-/Cover-Daten vorhanden sind.
- Selected Fireteam zeigt dieselbe verdichtete Kampfzeile unter dem Execution-Status.
- `get_command_feedback_snapshot()` liefert die verdichteten HUD-Daten fuer Tests und spaetere UI-Verbraucher.
- Der integrierte Testpfad aus TASK_545 prueft die HUD-Dichte nach Homebase, Dropship, LZ, Deboarding, Move, Contact und Engagement.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue Zielwahl, Trefferlogik oder Damage-Entscheidung.
- Keine neue UI-Wahrheit im HUD.
- Kein manueller F6-/Screenshot-Sichttest in diesem Task.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_545_mission_fire_cover_integrated_flow_smoke.md`
- `docs/tasks/TASK_544_mission_fire_cover_visual_polish_pass.md`

## Akzeptanzkriterien
- Der Snapshot `get_mission_combat_feedback_hud_density_snapshot()` ist read-only und setzt `ui_sets_gameplay_truth = false`.
- Eine kompakte Combat-Zeile ist aktiv, sobald ContactDecision-/Cover-Kontext vorhanden ist.
- Die Zeile bleibt innerhalb eines kleinen HUD-Zeichenbudgets.
- Fire-/Wait-/No-Fire-/Contact-State ist sichtbar.
- Cover, LOS und Range bleiben trotz Verdichtung sichtbar.
- Mission Control und Selected Fireteam zeigen die kompakte Zeile.
- Der integrierte TASK_546-Smoke laeuft gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_546_mission_combat_feedback_hud_density_polish.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_546_mission_combat_feedback_hud_density_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_544_mission_fire_cover_visual_polish_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Task prueft Headless-Snapshots, keinen menschlichen Pixel-Sichttest.
- Die Combat-Zeile ist bewusst kompakt; spaeter kann ein Tooltip/Detailmodus sinnvoll sein, falls Debuginformationen im Spielbild fehlen.
- Der Controller bleibt breit. Weitere Schnitte sollten nur mit konkretem Spieler- oder Debugnutzen passieren.
