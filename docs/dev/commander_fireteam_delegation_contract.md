# Commander Fireteam Delegation Contract

Status: TASK_270

## Purpose
This contract turns the TASK_269 game abstraction into data boundaries. The player commands as Commander, Fireteam Leaders interpret the intent, and unit-level runtime commands remain produced by tactical/runtime systems.

The contract chain is:

`CommanderIntent -> FireteamExecutionPlan -> UnitAction -> UnitCommand/SimulationRoot`

UI may create or display `CommanderIntent` data. UI must not write individual NPC truth.

## Authority Boundary
| Layer | Owns | Writes | Reads |
| --- | --- | --- | --- |
| Commander UI | Player selection and command intent. | `CommanderIntent` only. | Snapshots, selected fireteam, help text. |
| Fireteam Leader / tactical resolvers | Execution plan and bounded adaptation. | `FireteamExecutionPlan`, breakout status, UnitAction dictionaries. | Commander intent, FTL skill, terrain/contact snapshots. |
| Unit runtime | Concrete current action. | `UnitCommand` through SimulationRoot queue/effects. | Plan-scoped UnitAction. |
| SimulationRoot | Gameplay truth and command/effect application. | Authoritative unit state, damage/heal/respawn/objective. | Validated runtime command dictionaries. |

## CommanderIntent
`CommanderIntent` lives in `scripts/command/commander_intent.gd`.

Required fields:
- `command_id`
- `verb`
- `fireteam_id`
- `priority`
- `tempo`
- `fire_rule`
- `contact_response`
- `risk`
- `phase`

Optional fields:
- `team_id`
- `target_position`
- `target_area_id`
- `sync_group_id`
- `metadata`

Allowed verbs:
- `move`
- `take`
- `defend`
- `engage`
- `flank`
- `secure`
- `recon`
- `withdraw`
- `support`
- `bypass`
- `hold`

Rules:
- `fireteam_id` is mandatory.
- `unit_id` from legacy payloads is ignored and never serialized from `CommanderIntent`.
- Every intent carries a stable `command_id`.
- `hold` may omit a target; all other verbs need a position or area.
- `to_legacy_command_dict()` keeps Move/Defend/Take/Engage/Flank compatible with existing command paths.

## FireteamExecutionPlan
`FireteamExecutionPlan` lives in `scripts/tactical/fireteam_execution_plan.gd`.

Required fields:
- `plan_id`
- `command_id`
- `fireteam_id`
- `status_response`
- `movement_style`
- `security_mode`
- `cover_priority`
- `route_bias`
- `communication_state`
- `expected_duration_seconds`
- `tactical_rules`
- `ftl_skill_factors`
- `allowed_breakout_classes`
- `source_intent`

Status responses:
- `copy`
- `cannot`
- `adapting`
- `complete`
- `needs_orders`

The FTL may adjust movement style, security mode, cover priority, route bias and communication state. The FTL may not change the objective, mutate unit state directly or bypass SimulationRoot.

## UnitAction
`UnitAction` is a plan-scoped dictionary convention, not a new source of gameplay truth.

Required fields:
- `action_id`
- `plan_id`
- `command_id`
- `fireteam_id`
- `unit_id`
- `action_type`
- `runtime_command_type`
- `source`

Optional fields:
- `team_id`
- `target_position`
- `target_area_id`

Allowed `action_type` values:
- `move_to_position`
- `hold_position`
- `engage_area`
- `seek_cover`
- `retreat`

Rules:
- Every UnitAction points back to one `plan_id` and `command_id`.
- UnitAction does not enqueue itself.
- `unit_action_to_runtime_command()` only builds a valid `UnitCommand` dictionary; SimulationRoot or existing tactical systems remain responsible for queuing.
- UnitAction must not contain `ui_control_path` or other UI authority fields.

## Existing Command Mapping
| Existing Command | CommanderIntent Verb | Default Plan | Default UnitAction |
| --- | --- | --- | --- |
| `move` | `move` | `rush` or `caterpillar` by tempo | `move_to_position` |
| `defend` | `defend` | `hold` with `all_round` security | `hold_position` |
| `take` | `take` | `bounding` with `sector` security | `engage_area` |
| `engage` | `engage` | `bounding` with `sector` security | `engage_area` |
| `flank` | `flank` | `bounding` with direct/balanced route | `move_to_position` |

## FTL Skill Influence
FTL skill influences execution quality, not UI truth.

Skill inputs:
- `leadership`
- `discipline`
- `cohesion`
- `communication`
- `initiative`

Derived factors:
- `planning_quality`
- `reaction_delay_seconds`
- `communication_clarity`
- `cohesion_modifier`
- `fire_discipline_modifier`

These factors may tune route choice, delay, status clarity and cohesion. They must not create damage, objective progress or unit state by themselves.

## Snapshot and Feedback
Every `FireteamExecutionPlan.to_snapshot()` includes:
- `plan_id`
- `command_id`
- `fireteam_id`
- `ftl_response`
- `status_response`
- `movement_style`
- `security_mode`
- `tactical_rules`
- `planning_quality`
- `reaction_delay_seconds`
- `communication_clarity`
- `runtime_authority`
- `ui_sets_unit_truth`

#17 can show plan status, FTL response, movement style and rule summary. #18 can show blocked plans and next player choice. Map labels stay short.

## Breakout Boundary
Allowed breakout classes:
- `auto_adapt`
- `hold_and_report`
- `request_orders`
- `abort_to_safe`

Breakouts must stay tied to `plan_id` and `command_id`. If a breakout changes objective, fire rule or air-asset risk, it becomes `request_orders` or `abort_to_safe`.

## Non Goals
- No new pathfinding engine.
- No new autonomous AI architecture.
- No UI code that assigns individual unit truth.
- No Multiplayer netcode rewrite.
- No replacement of existing Move/Defend/Take/Engage flows.

## Follow-Up Tasks
- TASK_271 turns `tempo`, `fire_rule`, `contact_response`, `cover_priority` and `security` into selectable rules.
- TASK_272 adds multi-fireteam roles and sync groups.
- TASK_273 expands FTL skill progression and quality.
- TASK_274 maps FTL status responses into bubbles/radio.
- TASK_276 implements breakout resolution and return-to-plan.
- TASK_281 carries plan/snapshot state through multiplayer authority.
