# TASK_1186 - SimulationRoot Command Authority

## Ziel

`SimulationRoot` bleibt die einzige Commit-Stelle für Unit-Commands sowie
Combat-Facing- und -Posture-Mutationen. Tactical- und Combat-Producer bauen nur
noch Commands beziehungsweise Effects und stellen sie in die autoritative Queue.

## Ursache

Der sichtbare Mission-Tactical-Pfad setzte einzelne `UnitCommand`-Instanzen und
Enemy-Runtime-Postures bereits im Producer. Das machte einen Zustand vor dem
nächsten Physics-Tick sichtbar und umging damit die deterministische Queue.

## Akzeptanz

- Ein Producer verändert `get_current_unit_command()` nicht vor dem Root-Tick.
- Ein gültiger Command wird durch den Root committed; ein stale Token bleibt
  verworfen und unsichtbar.
- Facing und Enemy-Posture sind vor dem Root-Tick unverändert, werden als genau
  ein Effect eingereiht und im Root committed.
- Bestehende Multiplayer-, Combat- und Movement-Contracts bleiben grün.

## Abgrenzung

Kein neuer Bewegungs-, Combat- oder Multiplayer-Algorithmus und kein UI-Umbau.
Die bestehenden Legacy-Adapter bleiben bestehen.

## Betroffene Dateien

- `scripts/core/simulation_root.gd`
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `scripts/tests/task_1186_simulation_root_command_authority.gd`
- `scripts/tests/task_1186_combat_posture_effect.gd`

## Lokale Pruefung

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_1186_simulation_root_command_authority.gd
godot_console.exe --headless --path . --script scripts/tests/task_1186_combat_posture_effect.gd
godot_console.exe --headless --path . --script scripts/tests/task_162_combat_authority_contract_verifier.gd
godot_console.exe --headless --path . --script scripts/tests/task_166_multiplayer_authority_command_contract_verifier.gd
godot_console.exe --headless --path . --script scripts/tests/task_168_multiplayer_snapshot_contract_verifier.gd
godot_console.exe --headless --path . --script scripts/tests/task_501_integrated_movement_command_lifecycle_hardening.gd
```

## Risiken

Ein bislang vorab gesetzter Command-Token könnte beim Wechsel eines aktiven
Commands fälschlich als stale gelten. Der Root führt deshalb Queue- und
Commit-Token pro Unit, statt Producer-Mutationen als Supersession-Signal zu
verwenden.
