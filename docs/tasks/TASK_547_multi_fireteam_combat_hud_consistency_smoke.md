# TASK_547 - Multi-Fireteam Combat HUD Consistency Smoke

## Ziel / Problem
TASK_546 macht Combat-Feedback in Mission Control und Selected Fireteam kompakt lesbar. Der naechste Risikopunkt ist Parallelitaet: Wenn mehrere Fireteams und mehrere Dropships sichtbar sind, darf die kompakte Kampfzeile nicht Fireteam-Auswahl, Ship-State oder Mission-Control-Daten durcheinanderbringen.

## Sinnhaftigkeit / Ursache
Die frueheren Dropship-Hotpath-Fixes haben gezeigt, dass parallele Dropships leicht zu breite UI-/Planning-Refreshes und falsche Fireteam-Anzeigen triggern. Nach dem neuen Combat-HUD-Density-Slice braucht es deshalb einen Multi-Fireteam-Smoke, der denselben HUD-Kontext unter paralleler Missionslage prueft.

## Umfang
- Zwei Fireteams bleiben gleichzeitig ausgewaehlt.
- Zwei Dropship-Karten bleiben gleichzeitig als eigenstaendige Mission-Cards sichtbar.
- Ein reproduzierbarer erster Combat-Kontext erzeugt eine kompakte HUD-Zeile.
- Ein read-only Snapshot prueft, dass Multi-Fireteam-Auswahl, Dropship-Karten und Combat-HUD-Zeile zusammen konsistent bleiben.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue Dropship-Logik.
- Kein echter Multiplayer-Netzwerklauf.
- Kein manueller F6-/Screenshot-Sichttest.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_546_mission_combat_feedback_hud_density_polish.md`
- `docs/tasks/TASK_399_dropship_flow_contract_performance_pass.md`

## Akzeptanzkriterien
- Der neue Snapshot ist read-only und setzt keine UI-Gameplay-Wahrheit.
- Mindestens zwei eindeutige Fireteams sind ausgewaehlt und im Feedback sichtbar.
- Mindestens zwei Dropship-Cards bleiben sichtbar und eindeutig.
- Die kompakte Combat-HUD-Zeile bleibt aktiv, innerhalb des Zeichenbudgets und mit Fire-/Cover-/LOS-/Range-Kontext.
- Mission Control und Selected Fireteam enthalten die kompakte Zeile auch im Multi-Fireteam-Kontext.
- Der neue TASK_547-Smoke laeuft gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_547_multi_fireteam_combat_hud_consistency_smoke.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_547_multi_fireteam_combat_hud_consistency_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_546_mission_combat_feedback_hud_density_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Smoke prueft Headless-Snapshots, nicht die menschliche Pixelwirkung.
- Der Test nutzt bewusst eine kontrollierte Mission-Testszene mit zwei Dropship-Cards, damit der Parallelzustand schnell pruefbar bleibt.
- Echter Netzwerk-Peer-Besitz bleibt ein spaeterer Multiplayer-Smoke.
