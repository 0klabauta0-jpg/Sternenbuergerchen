# Tactical Command Doctrine Game Abstraction

Status: TASK_269

## Safety Note
This document is a game-design abstraction for Sternenbuergerchen. It is not a real tactical handbook, does not teach real combat procedures, and must not copy national doctrine, battle drills, live fire control, legal ROE or training sequences.

The game needs readable command intent, bounded Fireteam Leader behavior and clear UI feedback. It does not need real doctrine fidelity.

## Design Purpose
Tactical commands should feel alive without asking the player to click every NPC step. The player acts as Commander. The Fireteam Leader interprets intent. Individual units execute only through FTL/team/runtime logic.

The guiding rule is:

`Commander intent -> FTL execution plan -> Unit actions -> Visible feedback`

UI is never the source of gameplay truth. UI writes player intent and displays snapshots. Runtime authority remains in `SimulationRoot`, tactical resolvers, registries and existing command paths.

## Command Levels
| Level | Owns | Does Not Own | Example Data |
| --- | --- | --- | --- |
| Commander | Intent, objective, area, priority, risk, tempo, fire rule, coordination timing. | Individual step routes, per-frame targeting, hidden NPC state. | `command_id`, `verb`, `target_area_id`, `priority`, `tempo`, `fire_rule`, `sync_group_id`. |
| Fireteam Leader | Execution style, route bias, cover/security posture, contact response, short reports, controlled breakouts. | Strategic objective changes, legal ROE, direct damage truth, UI-only state. | `plan_id`, `movement_style`, `security_mode`, `cover_priority`, `contact_response`, `breakout_state`. |
| Unit | Concrete runtime actions produced by team logic. | Independent strategic decisions, UI commands, global mission state. | `unit_id`, `action_id`, `target_position`, `stance`, `fire_permission`, `follow_plan_id`. |

## Commander Intent Vocabulary
These are game verbs, not national doctrine labels.

| Verb | Player Meaning | FTL Freedom | Typical Feedback |
| --- | --- | --- | --- |
| `move` | Relocate to a point or lane. | Pick route, spread and tempo within rules. | `moving`, `routing`, `blocked`, `arrived`. |
| `take` | Capture or occupy an objective. | Choose approach style and security split. | `taking`, `contested`, `secured`. |
| `defend` | Hold an area or protect a point. | Place arcs, cover bias and fallback point. | `holding`, `watching`, `contact`. |
| `engage` | Prioritize known contact or target area. | Choose fire posture and cover use within fire rule. | `engaging`, `cannot fire`, `range bad`. |
| `secure` | Make area safe enough for follow-on action. | Probe, cover, scan, report risks. | `sweeping`, `secure`, `risk remains`. |
| `recon` | Probe without committing. | Stay cautious, report, avoid heavy commitment. | `probing`, `spotted`, `withdrawing`. |
| `withdraw` | Leave pressure or return to safer area. | Pick safe path and casualty handling. | `falling back`, `regrouping`. |
| `support` | Help another fireteam. | Set support position, overwatch or suppress depending rules. | `supporting`, `line blocked`. |
| `bypass` | Avoid a blocked/dangerous feature. | Reroute or request permission if objective changes. | `bypassing`, `needs route`. |
| `hold` | Pause and keep security. | Face likely threat, maintain cohesion. | `holding`, `ready`. |

## Tactical Rule Vocabulary
TASK_271 should implement these as compact game rules.

| Rule Group | Values | Notes |
| --- | --- | --- |
| Tempo | `cautious`, `normal`, `rapid` | Affects movement pacing and willingness to expose. |
| Fire rule | `hold`, `return`, `free`, `suppress` | Game-safe fire permission. It is not real ROE. |
| Contact response | `avoid`, `report`, `fix`, `assault`, `withdraw` | Tells the FTL what to do after contact. |
| Cover priority | `low`, `normal`, `high` | Affects route and stop-point choices. |
| Security | `none_in_transit`, `facing`, `sector`, `all_round` | Maps to existing security/overwatch systems. |
| Spread | `tight`, `standard`, `wide` | Must respect TASK_187 spacing and map readability. |
| Coordination | `independent`, `support_lead`, `sync_on_go`, `reserve` | TASK_272 multi-team plan vocabulary. |

## FTL Execution Styles
Existing movement styles remain useful, but they should be framed as FTL choices under Commander rules.

| Style | Use | Commander Controls | FTL Controls |
| --- | --- | --- | --- |
| `rush` | Fast relocation or short push. | Goal, allowed risk, fire rule. | Route and short pauses. |
| `bounding` | Advance with movement/support split. | Intent, tempo, contact response. | Which members move or cover first. |
| `caterpillar` | Slow cohesive advance. | Area and security need. | Step rhythm and cohesion. |
| `hold` | Stay and secure. | Area, arcs, priority. | Cover points and facing. |
| `probe` | Find risk without full commitment. | Recon area, avoid/report rule. | Stop distance and report timing. |

## Breakout Contract
Breakouts are controlled exceptions. They make teams feel alive, but they must stay visible to the player.

| Trigger | Default Class | FTL May Do | Needs Player When |
| --- | --- | --- | --- |
| `contact` | `auto_adapt` or `hold_and_report` | Take cover, report, return fire if allowed. | Contact response conflicts with fire rule or objective. |
| `suppressed` | `hold_and_report` | Stop, seek cover, mark pinned status. | Plan cannot continue safely. |
| `casualty` | `hold_and_report` | Pause, protect, call adjacent medic logic. | Medic route or withdrawal changes mission priority. |
| `blocked_path` | `auto_adapt` | Try small reroute. | No path, or reroute leaves assigned area. |
| `low_ammo` | `hold_and_report` | Reduce fire posture, request support. | Team cannot perform assigned engage/support role. |
| `leader_down` | `request_orders` | Trigger leader succession path if available. | No valid successor or cohesion drops too low. |
| `lz_threatened` | `request_orders` | Mark LZ risk, hold or secure if assigned. | Air asset is threatened and no LZ security intent exists. |
| `air_asset_threatened` | `abort_to_safe` or `request_orders` | Warn, mark threat source, protect/withdraw if rules permit. | Dropship/freighter loss risk is high. |

Breakout status labels must be short: `adapting`, `pinned`, `blocked`, `needs orders`, `abort`, `regroup`.

## UI Feedback Vocabulary
| Surface | Shows | Does Not Show |
| --- | --- | --- |
| #16 Command Matrix | Verbs, rule groups, GO/confirm, selected team scope. | Long explanations or hidden state. |
| #17 Selected Fireteam | Current plan, FTL response, movement style, rules, breakout reason. | Full doctrine text or per-frame unit internals. |
| #18 Mission Control | Mission-level intent, sync groups, blocked plans, next player choice. | Individual NPC micromanagement. |
| Mission Map | Objective area, route preview, support/lead markers, compact status tags. | Tutorial paragraphs or real tactical symbols. |
| Bubbles/Radio | `copy`, `cannot`, `adapting`, `complete`, `needs orders`, short reason. | Nation-specific command language. |
| Help Popups | One to three compact lines explaining game effect. | Real-world guidance. |

## Status Response Vocabulary
Use these as FTL-facing game responses.

| Response | Meaning |
| --- | --- |
| `copy` | Plan accepted and queued. |
| `moving` | Team is executing relocation. |
| `set` | Team is in position and ready. |
| `complete` | Intent is complete enough for game state. |
| `cannot` | FTL cannot build a valid plan under current rules. |
| `adapting` | FTL is using an allowed breakout. |
| `needs_orders` | Player decision is required. |
| `abort` | Critical threat or rule breach stopped plan. |

## Game-Safe Abstraction Rules
- Every command must carry a `command_id` and every FTL plan must carry a `plan_id`.
- A FireteamExecutionPlan may adjust route, stance, spread, security and contact response within Commander rules.
- A FireteamExecutionPlan may not change mission objective, mutate combat truth or create UI-only state.
- Unit actions are produced by tactical/runtime systems, not by screen scripts.
- Breakouts must include `trigger_id`, `class`, `reason_label`, `source_plan_id` and `requires_player`.
- Multiplayer snapshots may display plan and response state, but clients do not decide outcomes from UI.
- Help/catalog text must call these "game fire rules" or "fire rules", not real ROE.

## Follow-Up Contracts
- TASK_270: define `CommanderIntent`, `FireteamExecutionPlan` and `UnitAction` data contracts.
- TASK_271: implement tactical rule values, conflict handling and compact help IDs.
- TASK_272: define multi-fireteam roles: `lead`, `support`, `security`, `reserve`, `recon`.
- TASK_273: let FTL skill affect planning quality, timing, early warning and communication clarity.
- TASK_274: map status responses into bubbles/radio without storing gameplay truth in UI.
- TASK_275: arrange #16 commands around verbs first, rules second, confirmation last.
- TASK_276: implement breakout resolver classes and return-to-plan checks.
- TASK_277: define air-asset threat/damage states and LZ security influence.
- TASK_278: define meta recovery loop for damaged or lost transport assets.
- TASK_279: smoke-test LZ security and air-asset tactical playability.
- TASK_280: expose tactical profiles in editor/scenario authoring.
- TASK_281: serialize tactical command state through multiplayer authority/snapshots.
- TASK_282: close tactical-overhaul playability, performance and contextual-help gates.

## Source Matrix Link
The detailed source review is in `docs/research/tactical_doctrine_source_matrix.md`.
