# TASK_N006 — Combat Cadence Boundary

## Goal / problem

Reduce the measured combat-subscriber bottleneck while preserving deterministic outcomes, `SimulationRoot` authority, and a public release-playtest setup path.

## Cause / value

The legacy profile identifies combat subscriber cadence as the dominant remaining cost after route-cache work. Private release setup through `MetaLayerFlow` also makes release evidence less trustworthy and risks mutating state outside the public player boundary.

## Scope

- Capture phase-level metrics in the current combat tick before cadence changes.
- Extract state-light Detection/Contact, Enemy Tactics, Fire Decisions, and Objective/Result systems with explicit cadence under a thin coordinator.
- Move CLI release setup from `MetaLayerFlow` into a public mission/simulation playtest adapter that labels setup evidence as mutating.

## Non-goals

- Do not alter combat balance, create a second simulation authority, use private controller/field mutation in release setup, or optimize without a freshly captured baseline.

## Relevant contracts / documents

- `docs/ARCHITECTURE.md`
- `docs/tasks/TASK_N004_canonical_product_mission.md`
- existing combat, objective, snapshot, host/client, release, and performance contracts
- historical station-route phase-profile evidence

## Acceptance criteria

- Tests first fail for missing phase metrics and private-field release mutation.
- Coordinator cadence preserves deterministic output and routes mutations only through `SimulationRoot`.
- Existing combat, objective, snapshot, host/client, and release gates pass.
- Fresh baseline-to-result evidence shows at least 50 percent p95 combat-subscriber improvement with no deterministic output drift.
- The public playtest adapter identifies its setup evidence as mutating.

## Affected areas

Combat tick instrumentation and coordinator, state-light tactical systems, public playtest adapter, CLI/release harnesses, performance evidence, and regression verifiers.

## Verification

Run metric and private-mutation tests red then green; record a fresh baseline; run deterministic comparisons, broad combat/objective/snapshot/host-client/release gates, and p95 comparison; inspect mutation call paths; run `git diff --check`.

## Risks / open points

Cadence changes can subtly reorder detection, tactical, fire, and objective state. Performance gains are invalid without equivalent deterministic outputs and a comparable baseline environment.

## Dependency / exit gate

Requires N004 public scene/command path. N007 may start only once phase evidence, public setup boundary, full regressions, and the 50-percent p95 gate are committed.
