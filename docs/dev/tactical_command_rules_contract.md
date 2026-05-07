# Tactical Command Rules Contract

Status: TASK_271

## Purpose
This contract defines the small rule set a Commander can attach to a Fireteam command. The rules affect `CommanderIntent` and `FireteamExecutionPlan`; they never mutate individual NPCs from UI.

The word `fire_rule` is intentionally game-safe. This is not a real ROE simulation.

## Rule Groups
| Group | Values | Meaning |
| --- | --- | --- |
| `tempo` | `cautious`, `normal`, `rapid` | How much speed versus caution the FTL should prefer. |
| `fire_rule` | `hold`, `return`, `free`, `suppress` | Game fire permission and pressure preference. |
| `contact_response` | `avoid`, `report`, `fix`, `assault`, `withdraw` | What the FTL should do after contact. |
| `cover_priority` | `low`, `normal`, `high` | How strongly route and stop points favor cover. |
| `security_mode` | `360`, `facing`, `sector`, `none_in_transit` | How much security the team keeps while executing. |

## Data Structure
`scripts/tactical/tactical_command_rules.gd` defines `TacticalCommandRules`.

Required fields:
- `tempo`
- `fire_rule`
- `contact_response`
- `cover_priority`
- `security_mode`

Derived fields:
- `normalized_from_conflict`
- `warnings`

The class exposes:
- `get_rule_catalog()`
- `normalize_dict()`
- `to_intent_payload()`
- `to_plan_overrides()`
- `get_feedback_snapshot()`
- `get_help_ids()`

## UI Contract
Rules should be compact controls:
- Segmented controls for tempo, fire rule and contact response.
- Small buttons or compact toggles for cover and security.
- Context hides irrelevant groups instead of showing a wall of disabled text.

The UI may write rule values into a `CommanderIntent` payload. The UI may not build `UnitAction`, call `assign_unit_command`, enqueue SimulationRoot commands or decide combat effects.

## Runtime Contract
`TacticalCommandRules.to_intent_payload()` writes rule fields into a CommanderIntent payload:
- `tempo`
- `fire_rule`
- `contact_response`
- `cover_priority`
- `security_mode`
- `tactical_rules`

`FireteamExecutionPlan.from_intent()` reads these fields:
- `tempo` can alter movement style and duration.
- `fire_rule` stays in `tactical_rules` for TASK_272/TASK_276/TASK_281.
- `contact_response` stays in `tactical_rules` and helps breakout choice later.
- `cover_priority` maps to the numeric plan cover priority.
- `security_mode` maps to facing, sector, all-round or none-in-transit plan security.

## Conflict Rules
Invalid combinations are normalized visibly:
- `contact_response = avoid` plus `fire_rule = free` or `suppress` becomes `fire_rule = hold`.
- `contact_response = withdraw` plus `fire_rule = suppress` becomes `fire_rule = return`.
- `tempo = rapid` plus `security_mode = 360` becomes `security_mode = facing`.
- `contact_response = assault` plus `fire_rule = hold` becomes `contact_response = fix`.

Every normalization adds a stable warning ID and sets `normalized_from_conflict = true`.

## Feedback Contract
#17 Selected Fireteam can show:
- `TMP <tempo>`
- `FIRE <fire_rule>`
- `CNT <contact_response>`
- `COV <cover_priority>`
- `SEC <security_mode>`

#18 Mission Control can show a short normalized warning or rule summary. Map overlay only shows strong changes such as `SUPPRESS`, `AVOID`, `WITHDRAW` or `360`. Bubbles/radio use short phrases like `rules copy`, `rules adjusted`, `avoid contact` or `suppress ready`.

## Help IDs
TASK_271 prepares these catalog entries:
- `mission.command.roe_fire_rules`
- `mission.rule.tempo`
- `mission.rule.tempo_cautious`
- `mission.rule.tempo_normal`
- `mission.rule.tempo_rapid`
- `mission.rule.fire_rule`
- `mission.rule.fire_rule_hold`
- `mission.rule.fire_rule_return`
- `mission.rule.fire_rule_free`
- `mission.rule.fire_rule_suppress`
- `mission.rule.contact_response`
- `mission.rule.cover_priority`
- `mission.rule.security_mode`

## Non Goals
- No real ROE or legal/political modelling.
- No new weapon values.
- No damage, ammo or objective mutation from the rules class.
- No new command-button layout overhaul; TASK_275 owns that.
- No multiplayer authority rewrite; TASK_281 owns transport.

## Follow-Up Tasks
- TASK_272 uses rules in multi-fireteam plans.
- TASK_274 reports rule conflicts through bubbles/radio.
- TASK_275 arranges the visible command hierarchy.
- TASK_276 consumes rules for breakout and exception behavior.
- TASK_281 serializes rule snapshots under multiplayer authority.
