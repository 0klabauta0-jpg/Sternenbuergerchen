# Performance and Warning Gate

## Zweck
TASK_170 haelt die schnellen lokalen Smokes fuer 2.5D-Rendering, Navigation und Godot-Exit-Warnungen greifbar. Das Gate ist bewusst klein: Es misst vorhandene Debug-Snapshots und blockiert bekannte Leak-Muster, ohne ein globales Profiling-System einzufuehren.

## Lokale Kommandos
```powershell
godot_console.exe --headless --path . --script scripts/tests/task_170_performance_warning_gate_verifier.gd
powershell -ExecutionPolicy Bypass -File scripts/tests/run_task_170_warning_gate.ps1
godot_console.exe --headless --path . --script scripts/tests/task_159_verifier.gd
godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd
godot_console.exe --headless --path . --script scripts/tests/task_131_verifier.gd
```

## Blockierte Warnungen
Diese Muster gelten im Gate als Fehler:
- `ObjectDB instances leaked`
- `RID allocations ... leaked`
- `Resources still in use at exit`
- `Resource ... still in use at exit`
- `Leaked instance`

Normale Godot-Banner, `PASS:`-Zeilen und konkrete Budget-Zusammenfassungen sind akzeptiert. Erwartete strikte Missing-Asset-Tests duerfen nur in einem gezielten Guard-Test auftauchen, nicht in den normalen Primary-3D-Smokes.

## Budgets
- 2.5D-Primary-Render: `map_render_duration_msec < 8000` fuer Live- und Render-Spike-Smokes.
- Primary-3D-Fallbacks: `missing_asset_mapping_count`, `asset_texture_count`, `placeholder_object_count`, `unit_texture_count`, `tile_texture_count` und `height_edge_texture_count` muessen bei erwarteten Maps `0` bleiben.
- Navigation: Der Budget-Probe muss `new_path_queries_this_tick <= budget_limit` halten und gleichzeitig `delayed_this_tick > 0`, `pending_query_count > 0` sowie `last_delay_reason == "budget_exhausted"` melden.
- Snapshot-/Apply-Zaehler: `render_snapshot_request_count`, `order_payload_apply_count`, `contact_payload_apply_count`, `drop_payload_apply_count` und `mission_status_payload_apply_count` sind Diagnosewerte der View. Sie duerfen keine Gameplay-Wahrheit ersetzen.
