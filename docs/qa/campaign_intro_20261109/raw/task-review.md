# Tasks 1–2 review — campaign onboarding

Scope: read-only review against baseline `6bf468a4c`, approved campaign design and implementation plan. Domain owner/store, SimulationRoot routing, menu boundary and focused tests. Flow, adapter, start configuration and presenter are excluded while Task 3 is WIP. No product edits, commits, visible UI or new test runs by reviewer.

## Findings on initial snapshot

1. **P2 — Reject impossible restored onboarding facts.** `scripts/core/campaign_onboarding_state.gd:63` checks ordering for satellite_home, trade_used, bought and refueled, but not trade_home. `{schema_version:1,stage_index:2,facts:{trade_home:true},revision:1}` therefore restores successfully. Subsequent departure/use/purchase/refuel observations complete stage 3 without another home event because the previously accepted home fact survives (lines 42–48). Fully complete fact sets in stages 0–2 also restore despite never being emitted by normal transitions; an empty observe then advances them. Restore must reject both forms atomically. Domain implementer acknowledged and is fixing; re-review pending.

2. **P2 — Checkpoint accepts an unusable two-ID roster.** `scripts/meta/campaign_checkpoint_store.gd:9–15` initially validates only unique unit IDs, a craft ID and pilot membership. The existing domain fixture explicitly saves two dictionaries containing only unit_id and a craft definition containing only craft_id. This passes Continue validation although it does not establish the required deployable leader, qualified distinct pilot, usable craft or preserved equipment. Validate the campaign role pair and required craft/loadout references before enabling Continue. Domain implementer acknowledged and is hardening; re-review pending.

## Further consistency check requested

`campaign_checkpoint_store.gd:33–37` initially allows campaign completion receipts with no corresponding supply reward receipt, and completed onboarding with no purchase/refuel records. These are contradictory checkpoint states. Domain implementer was asked to cross-check persisted milestone evidence; awaiting final implementation before treating this as a remaining blocker.

## Menu result

No actionable defect found in reviewed Task 2 source. The one-shot request is validated and consumed, invalid requests clear stale state, MP/editor clear campaign context, New requires confirmation even for an invalid existing file, Continue revalidates on activation, and mode labels/safe-home rollback explanation match the spec. Campaign help catalog entry belongs to the ongoing Task 3 work.

Read Task 2 evidence report: 29 focused assertions, roster 42, team identity 11 and release-polish 28 reported passing in headless private profiles. These are implementer-run results, not independently rerun by reviewer. Native layout remains untested by design.

## Review disposition

Task 2 passes source review within this scope. Task 1 needs final validation-fix re-review before approval. No broad Task 3 or end-to-end approval implied.

## Follow-up
Task 1 findings closed by source re-review of106cdb1c1. See final-review.md for broader scope, retry finding/fix and remaining validation boundaries.
