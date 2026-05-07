# Multi Fireteam Plan Contract

## Purpose
TASK_272 defines a small, readable coordination layer for two or more Fireteams that share one Commander intent or one Area Order target. The plan answers: who leads, who supports, who secures, who stays reserve, and what each Fireteam does next.

## Authority Boundary
The plan is not gameplay truth. It is a preview and execution hint for Fireteam leaders.

Flow:
`CommanderIntent -> MultiFireteamPlanResolver -> FireteamExecutionPlan -> existing Area/Waypoint/SimulationRoot paths`

UI may display and confirm the plan, but UI may not build individual NPC truth, assign `UnitCommand`s directly, or write unit positions.

## Roles
Allowed V1 roles:
- `lead`: moves on the objective or takes the area.
- `support`: holds a support/base position and covers the lead.
- `security`: watches a sector or likely contact direction.
- `reserve`: waits behind the active pair, recovers, or supports medics.
- `recon`: probes ahead when the intent is recon or low-contact probing.

## Plan Inputs
The resolver reads:
- `CommanderIntent` with shared target area or target position.
- Fireteam contexts: `fireteam_id`, position, leadership, discipline, cohesion, communication, speed, accuracy, awareness, stealth, readiness, weapon range, cover quality, medic count, contact pressure and blocked-path flag.
- Optional area context with tile/world positions from existing Area Order data.

## Plan Output
The output is a dictionary snapshot:
- `plan_id`, `command_id`, `sync_group_id`, `phase`, target data.
- `role_assignments`, one per Fireteam.
- `minimum_spacing` and `minimum_spacing_ok`.
- `selected_fireteam_lines` for #17.
- `mission_control_text` for #18.
- `map_role_labels` for compact map labels.
- `feedback_events` for later Bubble/Radio use.
- `runtime_authority = SimulationRoot`, `ui_sets_unit_truth = false` and `ui_sets_gameplay_truth = false`.

## Preview and Confirmation
New plans start as `preview` and `requires_player_confirmation = true`. GO or a later explicit action may call `confirm_plan`; this only changes the plan status. It still does not enqueue commands by itself.

## Role Swap
The player can swap roles between two Fireteams. Swapping changes role labels, next-step text and role metadata; it does not teleport units or rewrite SimulationRoot state.

## Phases
V1 uses clear coarse phases:
- Phase 0: support, security and recon prepare/cover/probe.
- Phase 1: lead moves or takes the area.
- Phase 2: reserve follows, recovers or fills gaps.

Each assignment still carries the existing live order phase so current Area/Waypoint execution can stay unchanged.

## Map and Feedback
Map labels must stay compact: `LEAD P1`, `SUP P0`, `SEC P0`, `RES P2`, `RCN P0`.

#17 should show role, phase, next step and local status per selected Fireteam.

#18 should show one compact total plan line with all roles and `PRE-GO` or `CONFIRMED`.

## Stability Rules
Contact and blocked paths do not delete the plan. They mark assignment or plan status as `contact_stable` or `blocked_path` and leave roles visible so the Commander can understand the interruption.

## Non Goals
- No perfect optimizer.
- No automatic win state.
- No direct control of individual Units.
- No new movement system.
- No UI redesign beyond compact role labels and snapshots.

## Follow-Up Tasks
TASK_273 may feed FTL skill progression into the scoring. TASK_274 may turn `feedback_events` into richer radio/bubble communication. TASK_276 may add breakout behavior when a Fireteam cannot continue the plan.
