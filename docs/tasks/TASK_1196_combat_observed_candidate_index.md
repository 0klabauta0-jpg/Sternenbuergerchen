# TASK_1196 - Combat observed candidate index

## Acceptance criteria
- The index is rebuilt from real contact observations for every combat tick.
- It contains only attacker/target IDs and is absent from mission/multiplayer snapshots.
- With the index enabled and disabled, 600 deterministic 16v12 ticks produce identical contacts, fire events, hit results, unit vital states and mission result.
- The indexed path evaluates no more target pairs than the legacy path.
- TASK_1193 budgets remain unchanged.

## Task 3 measurement evidence (2026-08-31)
- Production SHA `0b5fbbf32b317282938a9cbb850b17261f34ed1e`; the original cold run and first 3-cold/5-warm series ran on a clean code/test stand, while the repeat series ran on the same code SHA with only the two evidence documents dirty.
- Machine: Ryzen 7 7800X3D, 64 GB, Windows 10 19045; Godot 4.6.2 official.
- Cold diagnostic exit 0; combat total p99 110.311 ms and simulation total p99 111.492 ms exceeded 8 ms budgets; harness checks passed.
- Gate passed: TASK-1196 12/12, TASK-1191 12/12, TASK-162 23/23, TASK-208 57/57; resolver pairs `legacy=3535`, `indexed=3535` (non-degradation, not speedup); fire-find-contact-pair p99 36.523 ms versus prior 37.813–42.701 ms; no new script/harness/leak/authority errors. The 37.813 ms lower bound is the smallest/best prior observation and thus the conservative no-regression comparison.
- 3-cold/5-warm completed: eight exitcode-0, SHA-identical stdout JSON results. Exact ranges (usec): combat total `107998–111972`; simulation total `109227–113078`; fire-find-contact-pair `36057–40881`; contact tracking `19240–20403`; combat fire decision `42386–47341`.
- Next package: `CombatVisibilityCache` key/allocation-cost specification. Dynamic Overlay and FoW remain separate renderer tasks.
- Same-series enemy-team-tactics p99 values (usec): `26351, 23876, 25094, 24608, 23346, 22949, 25116, 24689`; exact range `22949–26351`. Fire-find-contact-pair `36057–40881` remains larger than enemy-team-tactics `22949–26351` and contact-tracking `19240–20403`, so Rule 1 selects the sole next package `CombatVisibilityCache`.
- Rule 4 remains deferred: an independent cold plausibility run measured `command_queue` p99 53255 usec, but Combat has not fallen in the release/budget sense while combat total remains far above 8000 usec. Rule 1 therefore takes precedence because fire-find-contact-pair remains the largest exclusive Combat scope; command-type attribution becomes mandatory before any SimulationRoot optimization after a budget-relevant Combat reduction.

Status: DONE_WITH_CONCERNS; no release claim because Combat/Simulation total budgets remain exceeded.
