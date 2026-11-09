# Campaign Onboarding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Separate the approved two-NPC campaign introduction from existing Skirmish and preserve location-specific maps.
**Architecture:** Reuse Flow/SimulationRoot owners and transport. A trusted onboarding owner reads actual evidence; presentation only reads snapshots. Campaign checkpoint and roster are separate from local_player.
**Tech Stack:** Godot 4.6.2, GDScript, local JSON.
**Spec:** docs/tasks/CAMPAIGN_START_2026_11_09_DESIGN.md (approved 09.11.2026).

## Global Constraints
- Exactly two NPCs total: pilot and one deployable leader.
- Three stages: base preparation, satellite recovery/home, trade/purchase/refuel/home.
- No push; local commits and Main integration authorized in this session.
- Headless private-profile background checks only, below-normal priority; no visible windows/focus changes.
- Existing local_player and MP roster/map handoff remain independent.

## Review Focus
- Bootstrap silently adds fallback NPCs: assert exactly two across returns.
- Restart/continue touches Skirmish saves: compare original profile bytes.
- Early trade or replay advances progress: owner rejects out-of-order facts and duplicates.
- Interrupted flight persists partial debit: only stable home checkpoints, resume coherent pre-sortie state.
- MP/location choice receives stale campaign map: explicit entry context, preserve legacy scene defaults.

### Task 1: Domain progression and durable checkpoint
Files: create scripts/core/campaign_onboarding_state.gd, scripts/meta/campaign_checkpoint_store.gd; modify scripts/core/singleplayer_campaign_state.gd, singleplayer_supply_state.gd, simulation_root.gd; test scripts/tests/campaign_onboarding_state_test.gd.
Interfaces: onboarding configure(), get_snapshot(), apply_command(command, trusted_context), export_state(), restore_state(data); observe consumes context.runtime_evidence with base_ready, satellite_completed, satellite_home, trade_departed, trade_used, bought, refueled, trade_home. stage_index 0..3, next_step_id, completed, revision in snapshot. SimulationRoot configure_singleplayer_owners accepts optional third onboarding owner; category campaign_onboarding routes observe only with trusted context. Campaign/supply export_state/restore_state validate first then commit. Store load_checkpoint(path=DEFAULT_PATH), save_checkpoint(payload,path=DEFAULT_PATH) return {ok,payload/reason}; DEFAULT_PATH user://campaigns/introduction/checkpoint_v1.json.
- [x] Write/run failing tests for ordered transitions, early/replayed facts, invalid restores and independent checkpoint path.
- [x] Implement bounded authoritative owner and atomic validated checkpoint IO plus owner state roundtrip.
- [x] Run tests and existing campaign/supply verifier; commit only owned files.

### Task 2: Menu mode boundary
Files: create scripts/meta/game_start_contract.gd; modify scripts/ui/main_menu_screen.gd and contextual help catalog only as needed; test scripts/tests/campaign_menu_start_test.gd.
Interfaces: game_start_contract.request_start(tree, mode, action="new") stores one-shot root metadata; consume_start(tree) returns {mode,action}, defaults {mode:"skirmish",action:"new"}. Allowed modes campaign/skirmish; no persistence or campaign data mutation in menu. Existing _on_singleplayer_pressed starts skirmish. Campaign button opens New/Continue; new existing save requires confirmation. Continue only valid checkpoint. Label team tools Skirmish. Preserve release deeplinks and MP.
- [x] Write/run failing menu contract/button tests.
- [x] Implement explicit entry boundary, campaign dialog and Skirmish labels/help.
- [x] Run focused menu/roster regressions and commit only owned files.

### Task 3: Actual campaign Flow and tutorial
Files: modify meta_layer_flow.gd, singleplayer_runtime_adapter.gd; create campaign_start_configuration.gd, campaign_tutorial_presenter.gd, campaign tutorial help data/contract/tests as appropriate.
Interfaces: consume entry before roster load; configure_campaign_start(new/continue) supplies exactly two stable units, one craft and one leader payload. Runtime owns onboarding bound to SimulationRoot; observe actual readiness, mission/job/home arrival and successful trade receipts. request_operation enforces stage location/job prerequisites and supports retry failed satellite. Save only stable home checkpoints with Flow roster/loadout/IDs and owner state. Tutorial snapshots drive current/next action, dismissible first hints and reopen help; no game truth in UI.
- [x] Write/run failing integrated start test (two NPCs, separate profile, explicit mode), then implement campaign setup without old roster floor.
- [x] Wire trusted runtime evidence and actual stage gates; verify true one-leader movement/Use in both authored maps.
- [x] Add milestone saves and continue; verify two home milestones survive reload without overwriting local_player.
- [x] Add contextual popup/focus help, run catalog checks and real full-loop test at time_scale 1 with private profiles.
- [x] Review complete diff, fix confirmed defects, update implementation/QA docs, commit; integrate tested result locally into Main without push, der separate EXE-Auftrag folgt nach dem dokumentierten Main-Smoke.

