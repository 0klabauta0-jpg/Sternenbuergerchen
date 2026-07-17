# Task documentation precedence

## Active work

`TASK_N###` files are the active, outcome-oriented execution specifications. They define the next sequenced work, current acceptance gates, and the dependencies required before a later task can start. `TASK_N001` is the first active task; IDs are contiguous and are not reused.

## Legacy evidence

`TASK_####` files are immutable historical evidence. They may be cited for contracts, regressions, benchmarks, decisions, and prior outcomes, but they do not by themselves declare current product truth or schedule future work. Do not rename, move, edit, or renumber them while executing the active sequence.

## Current-truth rule

After `TASK_N001`, the canonical current-state and evidence documents it creates take precedence for present-tense product claims. A legacy result remains historical until a current evidence record identifies its commit, run date, command, artifact, result, owning paths, and caveat. Recovered material outside the active checkout is a candidate, not integrated evidence.

## Sequence

1. `TASK_N001` — current truth and evidence contract.
2. `TASK_N002` — reproducible Godot checkout.
3. `TASK_N003` — command authority and parity.
4. `TASK_N004` — canonical product mission and public first-contact trace.
5. `TASK_N005` — Frontier Desert Outpost visual slice.
6. `TASK_N006` — combat cadence and public release-playtest boundary.
7. `TASK_N007` — first-ten-minutes release gate.
8. `TASK_N008` — workspace cleanup and integration.

Later tasks must not skip an unmet dependency or rewrite the work of an earlier task. The tracked cross-task checklist is [`docs/superpowers/plans/2026-07-17-project-forward-strangler.md`](../superpowers/plans/2026-07-17-project-forward-strangler.md).
