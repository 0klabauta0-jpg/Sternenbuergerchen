# Project Forward Strangler Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the historically accumulated SternenBuergerchen work into a reproducible, evidence-backed Commander player slice without a big-bang runtime rewrite.

**Architecture:** Preserve `SimulationRoot` as the sole gameplay mutation authority. Strangle legacy test-path coupling behind compatibility wrappers while public mission, command, and playtest paths become explicit and independently verified. Keep `TASK_####` immutable as evidence; use `TASK_N001`–`TASK_N008` for active outcomes.

**Tech Stack:** Godot 4.6.2, GDScript, `.tscn`/JSON resources, PowerShell, Git, existing headless and two-process verifier harnesses.

## Global constraints

- Work only in the designated task worktree and branch.
- Never replace the migration with a big-bang rewrite; product runtime exits `scripts/tests`/`scenes/tests` through compatibility wrappers.
- Every behavior change is red-green-refactor with a failing verifier before production code.
- Preserve `SimulationRoot` mutation authority; UI/visual layers submit/read state only.
- Existing `TASK_####` files are immutable legacy evidence; current truth is organized by player outcome, not task count.
- Do not delete remote branches. Archive/hash ambiguous files before cleanup; use existing CC0 Kenney/Nature Kit assets first.

## Execution sequence

### Task 1: TASK_N001 — Current Truth Reset

**Files:** Create the current-state/index/milestone/evidence documents and manifest specified in `docs/tasks/TASK_N001_current_truth_reset.md`; modify guidance only additively.

- [ ] Write and run a docs-contract verifier that fails without the hierarchy.
- [ ] Implement the hierarchy, manifest schema-v1 records, and compatibility banners.
- [ ] Run the verifier green, JSON validation, uniqueness/line-budget checks, and `git diff --check`.
- [ ] Commit N001 with its evidence.

### Task 2: TASK_N002 — Reproducible Godot Checkout

**Files:** `.gitignore`, tracked UID sidecars, sanitized `export_presets.cfg`, fresh-checkout verifier, and N001 evidence records.

- [ ] Write and run the configuration contract test red.
- [ ] Track required config/UID inputs and implement external fresh-checkout import/start/export validation.
- [ ] Run clean-checkout validation, minimal headless start, and `TASK_1179` twice; record a distinct defect rather than masking it.
- [ ] Commit N002 only with reproducible evidence and `git diff --check`.

### Task 3: TASK_N003 — Command Authority and Parity

**Files:** Intent/result contracts, command entry adapter, gateway, visible controls, and parity tests as defined in `docs/tasks/TASK_N003_command_authority_parity.md`.

- [ ] Write tests that demonstrate pre-tick mutation and host/client divergence.
- [ ] Implement plan → validation/transport → GO → `SimulationRoot` commit with compatibility driver retained.
- [ ] Run parity matrix plus movement, authority, and objective regressions.
- [ ] Commit N003 after authority-path inspection and `git diff --check`.

### Task 4: TASK_N004 — Canonical Product Mission

**Files:** Product mission scene, mission/tactical adapters, lobby entry, test-scene wrapper, public TASK_1180 trace, architecture test, and evidence documents.

- [ ] Write architecture test that fails while product graph depends on test paths.
- [ ] Extract/wrap the public mission graph and retain test-scene compatibility.
- [ ] Port recovered TASK_1180 to public commands and authored `grid_sweep`; run it twice with legacy regressions.
- [ ] Commit N004 after product graph and first-contact evidence pass.

### Task 5: TASK_N005 — Frontier Desert Outpost

**Files:** Landscape catalog, focused terrain render modules, map theme reference, semantic validator, capture/metric evidence.

- [ ] Capture baseline semantic hash and render metrics; write semantic validation to fail on gameplay drift.
- [ ] Implement deterministic visual composition with existing local assets only.
- [ ] Run semantic/locality/map gates, capture three zoom-level before/after views, and compare p95 performance.
- [ ] Commit N005 only if semantic hash matches and p95 regression is at most 10 percent.

### Task 6: TASK_N006 — Combat Cadence Boundary

**Files:** Combat metrics/coordinator/systems, public release-playtest adapter, deterministic and mutation-boundary tests, performance evidence.

- [ ] Write tests that fail for absent phase metrics and private release mutation; capture a fresh baseline.
- [ ] Extract explicit-cadence state-light phases under a thin coordinator and public adapter.
- [ ] Run deterministic, combat/objective/snapshot/host-client/release regressions and compare p95.
- [ ] Commit N006 only if p95 improves by at least 50 percent with no output drift.

### Task 7: TASK_N007 — First Ten Minutes Release Gate

**Files:** Clean-checkout Windows export, player-path/two-process artifacts, current evidence updates.

- [ ] Export from an N002-clean checkout.
- [ ] Run no-deeplink main-menu-to-return player journey and a two-process first shared engagement.
- [ ] Update exact evidence metadata and rerun architecture, parity, path, semantic, performance, and documentation gates.
- [ ] Commit N007 with visible artifacts and all caveats.

### Task 8: TASK_N008 — Workspace Cleanup and Integration

**Files:** Cleanup inventory/archive hashes, final review/evidence report, integration branch state.

- [ ] Resolve targets read-only; hash/archive ambiguous material and identify only approved regenerable caches/duplicates.
- [ ] Run broad review and the full fresh gate matrix; stop for any Critical/Important finding.
- [ ] Remove only approved local targets, report recoverability, merge to integration, push, and verify clean worktrees.
- [ ] Commit N008/final report after integration evidence is confirmed; do not alter remote branches during cleanup.

## Plan self-review

- Sequence is explicit: evidence → reproducibility → authority → public mission → visuals/cadence → player release gate → cleanup/integration.
- Every task has an independent verifier gate and a commit boundary; N005 and N006 can occur after N004 but N007 waits for both.
- No task treats historical TASK_1179 or recovery-only TASK_1180 as fresh current truth without the specified reruns.
- The plan contains no runtime behavior change itself and adds no scope beyond the active task specifications.
