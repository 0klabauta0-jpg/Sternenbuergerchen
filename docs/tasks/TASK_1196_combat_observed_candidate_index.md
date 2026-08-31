# TASK_1196 - Combat observed candidate index

## Acceptance criteria
- The index is rebuilt from real contact observations for every combat tick.
- It contains only attacker/target IDs and is absent from mission/multiplayer snapshots.
- With the index enabled and disabled, 600 deterministic 16v12 ticks produce identical contacts, fire events, hit results, unit vital states and mission result.
- The indexed path evaluates no more target pairs than the legacy path.
- TASK_1193 budgets remain unchanged.
