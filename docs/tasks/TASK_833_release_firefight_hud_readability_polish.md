# TASK_833 - Release Firefight HUD Readability Polish

## Ziel / Problem
Der Release-Pfad ist wieder bis zum ersten Firefight erreichbar, aber die wichtigste `NEXT ... | WHY ...`-Entscheidungszeile steht im Selected-Fireteam-Panel zu weit unten. Im echten Fenster muss der Spieler den naechsten sinnvollen Griff sofort sehen, ohne die dichten Statuszeilen lesen zu muessen.

## Sinnhaftigkeit / Ursache
TASK_817 hat die Decision-Line bereits korrekt erzeugt und in Mission Control sowie Selected Fireteam sichtbar gemacht. Die Selected-Fireteam-Zeile sortiert jedoch zuerst technische Zusammenfassung, Befehl/Bewegung und Combat-Readout, bevor sie die Spielerentscheidung zeigt. Das ist funktional korrekt, aber im Playtest zu wenig fuehrend.

## Umfang
- Die vorhandene `NEXT ... | WHY ...`-Zeile bleibt read-only.
- Im Selected-Fireteam-Status wird die Decision-Line bei aktivem Firefight zur ersten sichtbaren Zeile.
- Combat-Readout, Fireteam-Zusammenfassung und Lead-/Drop-Status bleiben erhalten.
- Ein Snapshot prueft, dass die Zeile oben steht und keine Gameplay-Wahrheit setzt.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen Commands, FireEvents oder DamageEvents.
- Keine neue Multiplayer- oder Mission-Wahrheit im HUD.
- Kein Umbau des Bottom-Dock-Layouts.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_817_station_reentry_release_candidate_targeted_firefight_polish.md`
- `docs/tasks/TASK_832_release_first_go_firefight_deeplink_evidence.md`

## Akzeptanzkriterien
- Der First-GO/Firefight-Pfad liefert weiter einen gruenen TASK_817-Snapshot.
- Selected Fireteam beginnt bei aktivem Firefight mit der `NEXT ... | WHY ...`-Zeile.
- Die Combat-Zeile bleibt im selben Statusblock sichtbar.
- Snapshot und Test bestaetigen `read_only`, `ui_sets_gameplay_truth = false` und keine erzeugten Commands/FireEvents/DamageEvents.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_833_release_firefight_hud_readability_polish.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_833_release_firefight_hud_readability_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_817_station_reentry_release_candidate_targeted_firefight_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_832_release_first_go_firefight_deeplink_evidence.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Task verbessert die Textprioritaet, nicht die gesamte visuelle Gestaltung des Mission-HUDs. Ein echter Fenster-Capture bleibt fuer Schriftgroesse, Paneldichte und Kontrast sinnvoll.
