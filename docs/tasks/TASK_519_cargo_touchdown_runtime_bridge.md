## Status: IMPLEMENTIERT

# TASK_519 - Cargo Touchdown Visual/Runtime Bridge

## Ziel / Problem
Der Frontier-Probe-Slice besitzt nach TASK_518 Runtime-Gates fuer Luftabwehr, Computer-Hold und Cargo-Touchdown/Extract. Der Cargo-Schritt hing aber noch an einem rohen `cargo_state`-String im Combat-Driver. Dadurch war nicht klar lesbar, welches Cargo-Asset betroffen ist, ob der Anflug durch AA geblockt wird, wie lange der Frachter am Boden ist und welche Daten UI/Playtest-Snapshots nur lesen duerfen.

## Sinnhaftigkeit / Ursache
Der Spieler-Flow braucht nach AA-Shutdown und Computer-Hold einen sichtbaren, runtime-nahen Frachterzustand: inbound, landed/hold, departing/departed. Die Mission-Gates sollen weiterhin bei `SimulationRoot`/Runtime-Contracts bleiben; HUD und Karten duerfen keine zweite Cargo-Wahrheit erzeugen.

## Umfang
- Kleiner `MissionCargoTouchdownBridge`-Service fuer Cargo-Asset-, Hold- und Gate-Snapshot-Daten.
- Combat-Driver konfiguriert die Bridge aus dem Scenario-Slice und gibt einen `mission_cargo_touchdown`-Snapshot aus.
- Bestehende `set_mission_scenario_cargo_state(...)`-Tests bleiben kompatibel und laufen ueber die Bridge.
- Cargo-Gates bekommen `cargo_state` und `cargo_hold_seconds` aus dem Bridge-Snapshot.

## Nicht-Ziele
- Keine neue Flugphysik.
- Kein grosses Missions-VFX-System.
- Keine UI-Komplettueberarbeitung.
- Kein Multiplayer-Ownership-Rewrite.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_518_mission_scenario_runtime_gates.md`
- `docs/tasks/TASK_517_mission_scenario_vertical_slice.md`
- `docs/dev/air_asset_threat_damage_contract.md`
- `docs/dev/combat_loop_authority_contract.md`

## Akzeptanzkriterien
- Cargo bleibt vor AA-Shutdown als geblockt lesbar.
- Cargo kann nach AA-Shutdown inbound/landed/departed melden.
- `departed` schliesst das Cargo-Gate und damit den Scenario-Slice ab.
- `get_playability_snapshot()` enthaelt Cargo-Touchdown-Daten, ohne UI-State zur Wahrheit zu machen.
- Regressionspruefung fuer TASK_518 bleibt gruen.

## Betroffene Dateien
- `scripts/mission/mission_cargo_touchdown_bridge.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_test_setup.gd`
- `scripts/tests/task_519_cargo_touchdown_runtime_bridge.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_519_cargo_touchdown_runtime_bridge.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_518_mission_scenario_runtime_gates.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Bridge liefert zunaechst Snapshot-/Gate-Wahrheit; sichtbare VFX/Map-Animation fuer den Frachter bleibt Folgearbeit.
- Multiplayer-Team-Ownership fuer Cargo-Ausloeser und Verteidiger/Angreifer-Slots sollte separat mit einem MP-Smoke gehaertet werden.
