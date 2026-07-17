# TASK_N008 — Workspace Cleanup and Integration

## Goal / problem

Finish the active sequence with recoverable workspace hygiene, a broad final review, full evidence, and a controlled integration handoff.

## Cause / value

Multiple worktrees and recovered directories can obscure what is authoritative. Cleanup without provenance risks losing useful evidence; integration before final review risks promoting a clean-looking but incomplete player slice.

## Scope

- Hash and archive ambiguous old-checkout files before any deletion.
- Delete only verified regenerable caches/duplicates under resolved approved paths, reporting every material removed path and recoverability.
- Preserve recovered TASK 1064 as a historical candidate and the public integrated `TASK_1180` trace.
- Remove merged local worktrees/branches, leave remote branches untouched, and align the primary checkout with `integration/core-foundation` only after recovery checks.
- Run broad code review, full verification, merge to integration, push, and publish the final evidence report.

## Non-goals

- Do not delete remote branches, remove ambiguous recovery evidence, rewrite legacy task history, or merge while Critical/Important findings remain.

## Relevant contracts / documents

- `docs/tasks/README.md`
- `docs/history/TASK_HISTORY_SUMMARY.md`
- `docs/CURRENT_GAME_STATE.md`, `docs/qa/CURRENT_EVIDENCE.md`, and evidence manifest
- `docs/tasks/TASK_N007_first_ten_minutes_release_gate.md`
- Git/worktree policy in `AGENTS.md` and `docs/CODEX_RULES.md`

## Acceptance criteria

- Active worktrees are clean and every removed material path is recorded with hash/archive/recoverability information.
- Fresh checkout, architecture, command parity, authored player path, landscape semantics, performance, documentation, and two-process tests have fresh passing evidence.
- Recovered TASK 1064 remains historical candidate; TASK 1180 is preserved as the integrated public trace, not a recovery-only file.
- No Critical or Important broad-review findings remain.
- Integration merge and push succeed; remote branches are untouched by cleanup.

## Affected areas

Worktree/branch inventory, archive manifests and final report, current evidence documents, integration branch, and all gate outputs. Deletion is limited to pre-approved resolved paths.

## Verification

Resolve every cleanup target read-only; hash/archive ambiguous files; verify only approved regenerable targets before removal; run full gate matrix and review; inspect clean worktrees; verify merge/push; run `git diff --check` before integration.

## Risks / open points

Cleanup is destructive if target resolution is wrong. Broad review may reveal a blocker that requires a new active task rather than a quiet scope expansion; in that case stop integration and document the finding.

## Dependency / exit gate

Requires committed N007 first-ten-minutes evidence. The sequence exits only after all acceptance gates pass, integration/push are confirmed, all local worktrees are clean, and the final report names evidence plus recoverability.
