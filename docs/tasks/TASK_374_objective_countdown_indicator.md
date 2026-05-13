# TASK_374 - Objective Countdown Indicator

## Ziel
Missionen mit Zeitlimit, Hold-Timer, Exfil-Fenster oder Objective-Countdown sollen einen klaren, kompakten Timer im Mission-HUD erhalten.

## Status: IMPLEMENTIERT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll, aber nur fuer Szenarien mit echter Timer-Wahrheit. Das aktuelle Objective-System liefert Capture-State; ein Countdown darf nicht frei im HUD erfunden werden.

## Problem
Zeitkritische Missionsziele waeren ohne sichtbaren Timer schwer spielbar und schlecht planbar.

## Ursache
Objective-Snapshots enthalten Objective-Status, aber keinen einheitlichen Mission-Timer-/Countdown-Vertrag.

## Umfang
- Objective-/Scenario-Timer-Vertrag definieren: `countdown_seconds`, `timer_state`, `objective_id`, `source`.
- Anzeige nur sichtbar machen, wenn das Szenario einen Timer liefert.
- Farbe/Dringlichkeit ab Schwellenwerten, aber keine blinkende Dauerablenkung.
- Multiplayer-Snapshot-Kompatibilitaet pruefen.
- Kein Timer in Szenarien ohne Zeitlimit.

## Akzeptanzkriterien
- [x] Timer erscheint nur bei valider Countdown-Quelle.
- [x] Gruen/Gelb/Rot oder vergleichbare Dringlichkeit ist testbar und dezent.
- [x] Objective-Capture-Snapshots bleiben kompatibel.
- [x] Headless-Test prueft aktive, pausierte/fehlende und abgelaufene Timer.
- [x] Mission-HUD-Layout bleibt fixed und nicht ueberlappt.

## Umsetzung
- `ObjectiveStatus` enthaelt jetzt einen optionalen Countdown-Vertrag mit `countdown_seconds`, `countdown_total_seconds`, `timer_state`, `timer_source/source`, `timer_label`, `urgency` und `visible`.
- `SimulationRoot` repliziert diese Objective-Timer-Felder im Multiplayer-Snapshot und wendet sie auf Clients wieder auf `ObjectiveStatus` an.
- `MissionCombatLoopDriver` speist vorhandene `mission_time_limit_seconds` und Objective-Defense-Hold-Timer in den ObjectiveStatus ein. Szenarien ohne Timer erzeugen keinen Countdown.
- `MissionObjectiveStatusView` zeigt den Timer nur bei gueltiger Quelle kompakt in der bestehenden zweizeiligen Objective-Anzeige und exponiert einen HUD-Snapshot fuer Tests.

## Erwartete Dateien
- `scripts/core/objective_status.gd`
- `scripts/core/simulation_root.gd`
- `scripts/tests/mission_objective_status_view.gd`
- `scripts/tests/task_374_objective_countdown_indicator.gd`
- `scripts/multiplayer/multiplayer_snapshot_contract.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_test_setup.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_374_objective_countdown_indicator.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_279_lz_security_air_asset_tactical_playability_smoke.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Wenn Missionsszenarien noch keinen Timer speichern, braucht dieser Task zuerst einen minimalen Scenario-Vertrag statt eine HUD-only Uhr.
