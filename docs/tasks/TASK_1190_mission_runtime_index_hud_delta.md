# TASK_1190 - Mission Runtime Index und HUD-Deltas

## Ziel

Der taktische Controller liest Missionseinheiten über einen kleinen
Membership-Index statt pro Lesezugriff den gesamten Mission-Root zu scannen und
zu sortieren. HUD-Lesesurfaces erhalten voneinander getrennte Revisionen, damit
ein Zustand eines Fireteams keine breiten, unveränderten Flächen aktualisiert.

## Architekturgrenzen

- `SimulationRoot` und die bestehenden Runtime-Komponenten bleiben die
  autoritativen Besitzer von Gameplay-State.
- `MissionRuntimeIndex` ist ein abgeleiteter Lookup. Er mutiert keine Unit und
  wird ausschließlich durch Root-Membership invalidiert.
- `MissionHudReadModel` ist ein read-only Surface-Revision-Tracker. Er hält
  weder Command- noch Combat- noch Mission-Wahrheit vor.
- Direkter Command-/Tile-Feedback bleibt ein synchroner UI-Leseweg.
- JSON bleibt für Export und Diagnose erlaubt, jedoch nicht mehr als
  Gleichheitsprüfung im wiederkehrenden Fireteam-Security-Hotpath.

## Akzeptanz

- Wiederholte Friendly-, Enemy- und Fireteam-Lookups ohne Membership-Änderung
  lösen keinen weiteren Child-Scan und keine weitere Sortierung aus.
- Eine Änderung für Fireteam `blue` erhöht nur dessen schwere Surface-Revision;
  die Revision von `gold` bleibt stabil.
- Tile-/Command-Feedback wird im selben UI-Aufruf sichtbar und ist nicht an die
  periodische Heavy-HUD-Cadence gekoppelt.
- Bestehende HUD- und Command-Matrix-Verifier bleiben grün.

## Verifikation

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_1190_mission_runtime_index_hud_delta.gd
godot_console.exe --headless --path . --script scripts/tests/task_1152_mission_hud_heavy_refresh_budget_pass.gd
godot_console.exe --headless --path . --script scripts/tests/task_1157_command_matrix_1280_readability.gd
pwsh -NoProfile -File scripts/tests/run_task_1187_tactical_map_frame_budget.ps1 -Mode Measure -ColdRuns 3 -WarmRuns 5
git diff --check
```
