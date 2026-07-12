# TASK_1145 - Player-Flow Regression Harness Trust Repair

## Ziel / Problem
Die breite Player-Flow-Pruefung liefert keine verlaessliche Ampel: TASK_257 verwechselt scrollbare oder kontextuell verborgene Controls mit unerreichbaren Buttons, TASK_096 und der historische Dropship-Verifier liefern bei Fehlern Exitcode 0, und der Dropship-Monolith laeuft mit veralteten Annahmen laenger als sechs Minuten.

## Ursache / Sinn
- Der Reachability-Helper kennt nur den aktuellen globalen Rect, nicht die Erreichbarkeit ueber sichtbare ScrollContainer.
- Mehrere Controls sind heute absichtlich nur im passenden Spielzustand sichtbar.
- Historische Verifier rufen am Ende immer `quit()` ohne Fehlercode auf.
- 26 gewachsene Dropship-Szenenfluesse teilen sich einen Prozess und alte Fixtures; aktuelle Transport-/Multiplayer-Vertraege liegen bereits in kleineren TASK_1112- bis TASK_1118-Verifiern.

## Umfang
- Scrollbare Controls als erreichbar werten, wenn ihr sichtbarer ScrollContainer im Zielviewport liegt und die benoetigte Scrollachse aktiv ist.
- TASK_257 an aktuelle kontextuelle Sichtbarkeit anpassen.
- TASK_096 an den aktuellen zweispaltigen Character-Sheet-Vertrag und `#15 EINSATZLAGE` anpassen.
- Fehler in TASK_096 und im historischen Dropship-Verifier mit Exitcode 1 beenden.
- Ein isoliertes Player-Flow-Gate mit Prozess-Timeout und aktuellen Dropship-/Multiplayer-Verifiern bereitstellen.
- Den historischen Dropship-Monolith explizit als vom neuen Gate abgeloest markieren.

## Nicht-Ziele
- Keine Gameplay-, Transport-, UI- oder Multiplayer-Regeln veraendern.
- Keine fehlgeschlagenen Assertions durch pauschales Ignorieren abschalten.
- Den historischen 26-Szenen-Monolith nicht innerhalb dieses Tasks fachlich neu schreiben.

## Akzeptanzkriterien
- TASK_257 unterscheidet feste, scrollbare und kontextuell verborgene Controls und laeuft gruen.
- TASK_096 prueft den aktuellen Character-Sheet-Aufbau und liefert bei einem Fehler garantiert Exitcode 1.
- Der alte Dropship-Verifier kann bei Fehlern nicht mehr Exitcode 0 liefern und verweist auf das neue Gate.
- Das neue Gate startet jeden aktuellen Verifier isoliert, beendet Zeitueberschreitungen und erkennt `FAIL` auch bei fehlerhaftem Test-Exitcode.
- Multiplayer-Perspektive, paralleler Dropship-Flow und Performance bleiben gruen.

## Betroffene Dateien
- `scripts/tests/playability/playability_test_harness.gd`
- `scripts/tests/task_257_button_reachability_and_interaction_verifier.gd`
- `scripts/tests/task_096_recovery_verifier.gd`
- `scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
- `scripts/meta/ui_block_labels.gd`
- `scripts/tests/run_task_1145_player_flow_regression_gate.ps1`
- `scripts/tests/task_1145_player_flow_regression_harness_trust_repair.gd`
- Status, Roadmap und HTML-Arbeitsbericht

## Lokale Pruefung
- TASK_1145 Contract-Verifier
- TASK_257
- TASK_096
- neues TASK_1145-Prozessgate
- TASK_222
- `git diff --check`

## Risiken / offene Punkte
Der alte Dropship-Monolith bleibt als historische Evidenz vorhanden, ist aber kein Release-Gate mehr. Fachlich neue Transportregressionen gehoeren in kleine aktuelle Verifier und in das isolierte TASK_1145-Gate.
