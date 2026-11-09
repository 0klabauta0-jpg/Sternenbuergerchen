# Campaign onboarding — final source review

Reviewed current worktree against baseline `6bf468a4c`, approved design and plan. Task 1 commit `106cdb1c1`, Task 2 menu boundary, current Task 3 Flow/adapter/start configuration, compact-base map selection, tutorial presenter, and associated tests. Review is source-only: no engine runs, visible UI, focus changes, product edits or commits. Root's real-time loop validation remains separate.

## Current actionable findings

No additional confirmed source blocker remains in the inspected snapshot after the fixes below. This is not full feature acceptance: actual two-sortie completion, milestone reloads and the retry regression must pass before integration.

## Findings resolved during review

- **P2 impossible onboarding restores:** previously accepted `stage_index=2,facts={trade_home:true}` and complete-but-uncommitted factsets. `campaign_onboarding_state.gd:63–70` now rejects both before mutation; tests cover them. Task 1 finding closed.
- **P2 invalid campaign checkpoint roles:** initial two-ID-only roster passed validation. `campaign_checkpoint_store.gd:16–21` now requires operator leader, qualified pilot, distinct identity ordering and dropship/pilot correspondence. Optional staged/loadout/fireteam references are checked. Task 1 finding closed.
- Cross-owner consistency improved: reward/completion receipt sets must agree; completed onboarding requires persisted successful purchase/refuel receipts. Store writes remain separate from `user://profiles`, and validation precedes replacement.
- **P2 retry while away destroys the return binding:** initial new retry path allowed Homebase job-board abandon/reaccept during an active sortie; `_retry_failed` erased its departure, and subsequent `authorize_return` rejected `no_campaign_departure`. Current `singleplayer_runtime_adapter.gd:123–128` rejects retries while a mission/transit exists or any craft is away. This closes the identified source path; a focused regression still needs execution by root.

## Scope checks

- Menu modes are explicit one-shot requests. MP/editor clear stale requests. Campaign creation/replacement confirmation and Continue validation stay in menu/entry boundary; campaign state is not mutated there.
- Campaign configuration selects exactly the leader/pilot pair and bypasses Skirmish roster-floor repairs. Mission handoff now carries actual selected campaign profiles. Campaign progression updates use the campaign roster and do not call the default roster store.
- Ordered progression reads boarding/pilot readiness, completed campaign job, real home/transport state and real trader service proof. Buy/refuel facts follow successful owner commits. Tutorial dismissal/reopen only changes presentation.
- Stage 3 removes the tutorial location locks. Selecting a completed satellite site uses an empty job ID, avoiding a second completed-job activation/reward; home exports clear transient departure/selection state and retain resource/request receipts.
- Checkpoint writes are gated on no active mission, no mission transfer, no preparation transfer and home craft location. Continue consumes a validated checkpoint and returns to a base state; mid-sortie state is not serialized.
- Compact-base map selection is received through runtime snapshot before normal base activation. The integration test currently checks selected map path, not actual terminal reachability or native presentation. Compact map has one pad and existing terminal/asset references; no new art pipeline.
- Tutorial is a separately layered read-only presenter and refreshes on onboarding snapshot changes. Native overlap/readability is not established by source review or headless tests.

## Validation boundaries and corrections

Domain implementer report records focused domain GREEN and existing campaign33/supply41/departure15/authority regressions; menu report records 29 focused checks and roster/team/release regressions. These are implementer-run results, not independently rerun here.

Root owns the ongoing full-loop diagnosis. Earlier failed logs are not proof of a remaining source defect after changes. The second completed log reports a real first-approach timeout; this review did not isolate its source cause and cannot approve the full loop. A zero `interaction_count` in the driver's runtime-progress snapshot counts committed states, so it does not by itself establish missing scenario configuration.

Retracted review message: `ensure_roster("campaign-profile-isolation")` does NOT choose a different profile. Its first argument is the seed (`player_roster_store.gd:21`), so the existing isolation test correctly targets default local_player. Explicit nonempty-fixture assertion remains useful, but there is no different-profile defect.

Final acceptance still requires root's passing real two-sortie/continue evidence plus retry-away protection regression. Interrupted-sortie rollback and free-roam behavior were source-reviewed; no new live evidence claimed.

## Focused follow-up: insertion, singleton formation and save feedback

Reviewed the additional narrow source fixes without engine execution:

- `fireteam_movement_controller.gd:1528` calls the unchanged workbench path only for more than one member. One-member targeting falls through to the established zero-offset buddy slot (`:1613–1614`); parallel spacing already returns for one member. This addresses the measured one-leader interaction-distance mismatch without changing multi-member preset behavior. Inspected RED four failures and GREEN four passes in `single-formation-red.log` / `single-formation-green.log`.
- `mission_tactical_sandbox_controller.gd:1559` rejects manual GO while activation or post-drop security is pending, using the existing WAIT exit before command execution and network handoff. Existing `_flush_pending_drop_runtime_phase_starts` / `_maybe_start_active_phase_for_fireteam` clear those pending flags after deployment effects/security. This is a readiness guard, not a second movement authority.
- Shared loop readiness now waits for actual deploy effects and cleared pending flags, instead of just the earlier deployed-ID marker. Campaign loop attempts an early GO during the pending window. Suggested asserting `_insertion_guard_checked` at finish so the transient-window assertion cannot silently be skipped by polling; this is test hardening, not an additional confirmed product defect.
- Inspected `campaign_retry_boundary_test.gd` and its seven passing assertions. It is correctly labeled a focused boundary fixture (craft location is explicitly set), and confirms rejection preserves the original departure and authorized return, then accepts retry at home. Prior retry finding closed with bounded regression evidence.
- Flow now exposes actual checkpoint errors while filtering expected away/preparation deferrals; tutorial renders save status, and a failed Continue sends a one-shot menu status message. These remain presentation state and do not change campaign owners.

No new source blocker found. Approval remains conditional on root's full real two-sortie/Continue validation; the currently running fourth loop is not claimed to have passed here. No engine run, foreground UI or focus operation performed by reviewer.

## Closure after completed normal-time loop

Inspected complete `campaign-loop-fourth.log`: Godot4.6.2, `time_scale=1.0`, private `.scratch/campaign-loop-fourth` profile, **77 passed / 0 failed, returns=2**. The log explicitly exercises the early-GO WAIT guard, real single-leader movement and timed Use at satellite and trader, reward once, both reverse transits, stage progression, and both home checkpoint save/load + Flow-reinstantiation Continue paths. It verifies identities, exact two-NPC count, resources, inventory, pilot/craft/pad reuse, and bytes of a pre-existing nonempty Skirmish roster. Inspection of the harness confirms boarding preparation is accelerated explicitly; mission movement, Use and flights run at normal time. No fabricated victory or onboarding completion is used.

The added final `_insertion_guard_checked` assertion is present in current source. Fourth-run evidence already contains its successful early-GO assertion; the extra end assertion itself awaits the subsequent run (expected total78).

**Source review approved for the implemented campaign-onboarding scope. No actionable findings remain.** The previously conditional full two-sortie/Continue evidence is now satisfied within the described headless harness scope. Root's final quick regression matrix and Main integration verification remain separate required checks; this review does not claim they passed yet. No native visual/usability, general performance, release/export or broad MP gameplay acceptance is implied. Reviewer ran no engine or foreground UI.

## Preparation-preservation follow-up

Reviewed current `campaign_start_configuration.gd`, store commit `58837e2fb`, campaign bootstrap empty-team fallback, and `campaign_preparation_continue_test.gd`. No blocker found. Continue now restores saved staged arrays and intentionally empty pilot assignment; save reads the existing Homebase Direct fireteam snapshot instead of stale FOB definitions. Empty campaign staging no longer falls back to the Skirmish bootstrap team. Store permits an empty team/unassigned pilot while still requiring the same two qualified roster identities and rejecting foreign/pilot team members. These changes preserve unfinished preparation without introducing another roster or loadout owner.

Inspected `premerge3-campaign_preparation_continue_test.log`: ten passes/zero failures after actual UI operations (unboard, create ft2, assign leader, choose SMG, clear pilot) and Flow reinstantiation. Also inspected stage-start11/0 and domain0-fail reruns, plus final Skirmish loop60/0 tail. Source approval remains in place for the updated scope. No engine execution by reviewer; Main/post-integration verification remains root-owned.
