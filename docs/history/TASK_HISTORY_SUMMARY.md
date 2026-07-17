# Legacy Task History Summary

## Purpose and status

The `TASK_####` files are an immutable evidence ledger of how the project grew. They are not the active product roadmap and task count is not a measure of player-ready progress. Active outcome-oriented work starts with `TASK_N001`; see [`docs/tasks/README.md`](../tasks/README.md).

## Player journey established by the legacy work

Legacy work established the intended Commander loop: Homebase staging, roster/loadout and dropship handoff, LZ/deboard, fireteam orders, mission objective, result/debrief, and return to the meta layer. The loop is meaningful evidence only where an authored route and its public runtime path have been exercised; isolated UI, snapshot, or probe-mission checks are supporting evidence, not a replacement for that journey.

`TASK_1179` is historical evidence of two complete 18/18 `grid_sweep` objective/debrief runs using the authored Homebase-to-Debrief path. A later isolated rerun stopped before its final Objective/Debrief assertions because of UID/autoload and already-instanced-runtime conditions. Therefore the historical result remains preserved, but is not a fresh full confirmation of the current checkout.

`TASK_1180` is a recovered, valuable first-contact/live-fire trace in `C:\dev\SternenBuergerchen-recovery\2026-07-17-project-forward`. It is not integrated in this checkout and must not be described as current product evidence until `TASK_N004` ports it to the public command and authored-map path and reruns it twice.

## Architecture growth

The project evolved from broad scene- and verifier-led experimentation toward explicit runtime boundaries: `SimulationRoot` owns gameplay mutation, `EventRouter` communicates state changes, registries provide lookup, and UI/visual layers read state and submit commands rather than owning parallel mission truth. The visible fireteam path is now intended to flow through mission/tactical adapters into `SimulationRoot.enqueue_command()`; compatibility harnesses remain because legacy verifiers still depend on them.

The next step is deliberately a strangler migration, not a rewrite: retain compatibility wrappers while moving product entry, command submission, and runtime controllers out of `scripts/tests` and `scenes/tests`. Each new boundary must be proven against existing player-path regressions.

## Verification maturity

Legacy verification spans focused contracts, deterministic headless harnesses, performance profiles, host/client checks, release captures, and some visible manual reviews. This is useful coverage, but the evidence varies in freshness and in how closely it follows the authored player path. Current truth must name the exact commit, command, artifact, outcome, and caveat instead of inferring readiness from a historical green task.

The active sequence starts by making that evidence legible (`TASK_N001`), then makes a fresh checkout reproducible (`TASK_N002`), restores command authority parity (`TASK_N003`), proves a product-scene player path including integrated `TASK_1180` (`TASK_N004`), and only then adds visual and cadence work.

## Unresolved risks carried forward

- A fresh isolated `TASK_1179` completion has not yet reached its final objective/debrief assertions; the checkout/import fault must be separated from any runtime defect.
- Product-visible mission flow still has legacy test-path coupling and command producers whose authority/parity must be made explicit.
- Recovered `TASK_1180` is unintegrated evidence, not a current-pass claim.
- The profiled combat subscriber cadence remains a performance risk; optimization must preserve deterministic output and `SimulationRoot` authority.
- Landscape polish must not alter map semantics or imply cover/blocking that the simulation does not own.
- A clean-checkout build, a no-deeplink first-ten-minutes route, and a two-process engagement still need fresh end-to-end evidence.
