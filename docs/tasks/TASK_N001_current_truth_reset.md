# TASK_N001 — Current Truth Reset

## Goal / problem

Create one short, human-facing source of current product truth and a machine-readable evidence manifest without deleting the historical ledgers that existing verifiers reference.

## Cause / value

The project has substantial historical documentation, but a task number or dated report cannot safely express present readiness. A current evidence contract lets players, reviewers, and later tasks distinguish implemented behavior, fresh proof, caveats, and vision.

## Scope

- Create `docs/DOCS_INDEX.md`, `docs/CURRENT_GAME_STATE.md`, `docs/PRODUCT_MILESTONES.md`, `docs/qa/CURRENT_EVIDENCE.md`, and schema-v1 `data/project_evidence_manifest.json`.
- Update project brief/rules/architecture with Commander fantasy, complete loop, V1 limits, Frontier Low-Poly pillar, current-truth precedence, and anti-monolith guidance.
- Add compatibility banners to `docs/IMPLEMENTATION_STATUS.md` and `docs/TASK_ROADMAP.md` without removing history.
- Index dated reports and handbooks as snapshots without rewriting the TASK-1181 HTML.

## Non-goals

- Do not claim a fresh `TASK_1179` objective/debrief rerun.
- Do not integrate recovered `TASK_1180`, alter runtime behavior, or prune legacy documentation.

## Relevant contracts / documents

- `docs/history/TASK_HISTORY_SUMMARY.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `AGENTS.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Acceptance criteria

- Exactly one document is declared canonical current game state and exactly one milestone is marked `now`.
- The manifest contains `delivery_state`, `product_maturity`, `scope`, and `evidence[]`; each record has `id`, `commit`, `run_at`, `type`, `result`, `artifact`, `caveat`, and `owning_paths`.
- Current claims classify `TASK_1179` as historical 18/18 evidence with a fresh-rerun caveat and `TASK_1180` as recovered but unintegrated.
- A docs-contract verifier fails before the hierarchy exists and passes after; the current documents meet their declared line budgets.

## Affected areas

Documentation indexes, evidence manifest, project guidance, status/roadmap compatibility banners, and a focused documentation verifier. No gameplay scene, runtime script, map, or legacy task file.

## Verification

Run the new docs-contract verifier red then green; validate the JSON manifest; inspect canonical/`now` uniqueness; run `git diff --check`.

## Risks / open points

Compatibility ledgers are consumed by legacy tools, so edits must be additive. Evidence wording must not turn a recovered file or historical green run into a current release claim.

## Dependency / exit gate

This is the first active task. `TASK_N002` may start only after the canonical index, manifest, uniqueness checks, and compatibility banners are committed.
