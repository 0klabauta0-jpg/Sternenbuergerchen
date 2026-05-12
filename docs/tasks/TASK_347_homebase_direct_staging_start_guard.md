# TASK_347 - Homebase Direct Staging Start Guard

## Ziel
Der direkte Homebase-Bypass aus TASK_346 muss einen gestagten Homebase-Dropship-Payload tatsaechlich starten koennen. Wenn die Homebase `Homebase dropship ready` anzeigt und der Startbutton aktiv ist, muss `mission_start_requested` auch emittiert werden.

## Status: IMPLEMENTIERT

## Problem
`HomebaseTestScreen._update_mission_info()` aktiviert den Startbutton bereits ueber `direct_payload_ready`. `request_mission_start()` prueft aber weiterhin nur `_mission_launch_ready`.

## Ursache
Die UI-Anzeige und der eigentliche Start-Guard nutzen zwei unterschiedliche Wahrheiten:

- Anzeige: `_mission_launch_ready or direct_payload_ready`
- Start-Guard: nur `_mission_launch_ready`

Dadurch kann der Button aktiv wirken, aber kein Missionsstartsignal senden.

## Umfang
- Gemeinsame Homebase-Startbereitschaft ableiten, z. B. ueber `can_request_mission_start()` oder einen privaten Helper.
- `request_mission_start()` muss denselben Direct-Payload-Zustand akzeptieren wie der Button.
- Die Anzeige in `_update_mission_info()` darf keinen anderen Zustand verwenden als der Start-Guard.
- Kein Umbau des FOB-Starts in diesem Task, ausser fuer Regressionstests.

## Akzeptanzkriterien
- [x] Homebase-Direct-Payload im Flightdeck aktiviert den Startbutton.
- [x] Klick/Call auf `request_mission_start()` emittiert `mission_start_requested`, wenn Direct-Payload bereit ist.
- [x] Ohne Direct-Payload und ohne `_mission_launch_ready` bleibt Start blockiert.
- [x] Bestehender FOB-/Preview-Missionsstart bleibt unveraendert.
- [x] Headless-Verifier deckt die Button/Guard-Konsistenz ab.

## Erwartete Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_347_homebase_direct_staging_start_guard.gd`
- optional: bestehender TASK_346-Verifier, falls dort die Regression sinnvoll ergaenzt wird.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_347_homebase_direct_staging_start_guard.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_346_homebase_direct_staging_character_popup.gd`
- [x] `git diff --check`

## Umgesetzt
- `HomebaseTestScreen` hat jetzt `can_request_mission_start()` als gemeinsame Guard-Wahrheit fuer Button, Snapshot und `request_mission_start()`.
- Direct-Homebase-Payloads aus dem Flightdeck passieren denselben Guard wie der aktive Startbutton.
- `task_347_homebase_direct_staging_start_guard.gd` prueft Direct-Payload, leeren Homebase-State und den bestehenden `_mission_launch_ready`-Pfad.

## Risiken / offene Punkte
- Der Fix darf nicht einfach den Button immer durchlassen; die Missionsplanung muss weiterhin einen echten Payload bekommen.
- Falls TASK_349 noch offen ist, muss klar bleiben, ob ein synthetischer Homebase-Dropship fuer diesen Task noch toleriert wird oder bewusst blockiert werden soll.
