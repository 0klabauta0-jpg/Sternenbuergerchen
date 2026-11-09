# Task 1 domain report — 2026-11-09

Implemented on task/campaign-onboarding-20261109 in the assigned shared worktree; no push or merge.

## APIs

- `CampaignOnboardingState.configure() -> {ok}` resets stage0. `get_snapshot()` returns `stage_index` 0..3, `next_step_id`, `completed`, `revision`, `facts`.
- `apply_command({contract_category:"campaign_onboarding",operation:"observe",payload:{}}, trusted_context)` consumes only `trusted_context.runtime_evidence`. Facts: stage0 `base_ready`; stage1 `satellite_completed`, then `satellite_home`; stage2 `trade_departed`, `trade_used`, `bought`+`refueled`, then `trade_home`. At most one stage transition per observation. Earlier-stage/early-trade facts do not survive stage boundaries. Replays with no new fact do not increment revision.
- Onboarding `export_state()` returns `{schema_version:1,stage_index,facts,revision}`. `restore_state()` validates all fields/order before mutation, rejects complete-but-uncommitted factsets.
- `SimulationRoot.configure_singleplayer_owners(campaign,supply,onboarding=null)` preserves the two-argument API. Category `campaign_onboarding` routes to this owner; queued UI commands receive no trusted evidence.
- Campaign adds operation `retry_failed_job` to existing builder/validator. Payload `{job_id}`; only failed/no-receipt job becomes accepted, stale craft binding removed. Existing dedupe semantics preserved; use a fresh request_id for each retry/result sortie.
- Campaign `export_state()` = campaign snapshot plus `schema_version:1,requests`. Restore rebuilds current locations/jobs, compares saved definitions, validates statuses, completion receipts, departures, request signatures and selection, then commits.
- Supply `export_state()` = `{schema_version:1,definitions,credits,item_quantities,fuel_by_craft_id,stock_by_offer_id,requests,reward_receipts,revision}`. Restore validates current definitions, bounded quantities/fuel/stock, real reward definitions and request signatures, then commits. Request and reward receipts survive JSON roundtrip.
- `CampaignCheckpointStore.validate_payload(payload)` is pure; `load_checkpoint(path=DEFAULT_PATH)` / `save_checkpoint(payload,path=DEFAULT_PATH)` return `{ok,payload}` or `{ok:false,reason}`. Default `user://campaigns/introduction/checkpoint_v1.json`; only `user://campaigns/...json` paths accepted, no parent traversal.

## Checkpoint payload / root responsibilities

`{schema_version:1,roster:Array,craft:Dictionary,campaign:owner-export,supply:owner-export,onboarding:owner-export}`. Extra presentation keys permitted.

Roster order is `[operator leader,pilot]`, exactly two distinct nonempty unit_ids. Leader needs positive `skill_leadership` or `skill_values.leadership`; pilot needs category `pilot` and positive `dropship_piloting`. Known profile dictionary fields must be dictionaries. `craft.definition` contains nonempty craft_id and craft_type `dropship`; `craft.pilot_id` matches second roster unit. Optional staged IDs/fireteam definitions/member_loadouts/cargo maps are structurally checked and unit references constrained. Preset roster representation accepted.

Root canonicalizes saved campaign selection to homebase, clears departure bindings and saves no active jobs. Accepted/failed jobs are allowed. Supply fuel must contain exactly the one craft. Campaign completion and supply reward sets must match. Stage2+ needs satellite receipt; stage3 additionally needs successful buy/refuel persisted request receipts. Continue validates the entire payload before Flow mutation. Write uses flush+close+same-directory temporary rename; atomic replacement verified on Windows, and invalid replacement preserves the old file. No mid-sortie resume.

## Validation

TDD RED: expected missing onboarding-owner failure (`domain-red.log`). GREEN: `campaign_onboarding_state_test.gd`, no failures (`domain-campaign_onboarding_state_test.log`), covering ordering, bounded transitions, forged UI facts, replay, malformed/atomic restore, JSON roundtrips, failed mission retry, exact-once restored reward, current-definition rejection, independent path, atomic replacement, stage2/3 checkpoints and missing-receipt rejection.

Existing regression gates: campaign 33/0, supply 41/0, departure validation 15/0, authority PASS. Final logs prefixed `domain-playtest_...`. All Godot4.6.2 runs headless, BelowNormal, private APPDATA, no visible window. Final matrix completed before root's real1x loop; no overlapping further engine runs.

`git diff --check` clean for owned tracked changes. Technical checks do not establish native UX or release acceptance.

## Preparation persistence correction — 58837e2fb

An intentionally cleared pilot assignment is valid at home (`craft.pilot_id = ""`); the qualified pilot still remains roster[1] and cannot be staged as an operator. Empty fireteam definitions are preserved with empty lead/member containers. A nonempty lead must reference the operator; member_unit_ids/members (native PackedStringArray or JSON Array) and member_loadouts validate roster references and exclude the pilot. Empty lead cannot mask a nonempty member container. Existing unique fireteam ID rules remain.

Domain RED3 expected preparation failures -> GREEN0 failures. Added unassigned pilot + empty fireteam checkpoint roundtrip, native packed member roundtrip, foreign member/loadout, pilot staging/member, nonempty leadless team and duplicate-ID rejection. Logs `domain-preparation-red.log` / `domain-preparation-green.log`. Only store and domain test committed; engine returned to root before integrated preparation/continue checks.
