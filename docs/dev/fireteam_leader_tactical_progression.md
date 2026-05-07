# Fireteam Leader Tactical Progression

## Purpose
TASK_273 defines how a fireteam leader (FTL) can become tactically better without turning the Character Sheet or command UI into gameplay truth.

The visible result is compact: better plan quality, clearer communication, steadier contact reports, more useful breakout judgement, slightly better spacing and fair tempo changes.

## Authority Boundary
Gameplay truth remains in `SimulationRoot`, runtime units, registries and tactical resolvers.

`CharacterSheetFormatter` only displays derived profile data. UI panels may show `FTL Impact`, but they may not set plan quality, unit positions, command outcomes, damage, cohesion or progression.

## Data Contract
The FTL tactical snapshot uses schema version `1`.

Required public fields:

- `unit_id`
- `fireteam_id`
- `plan_quality`
- `communication_clarity`
- `breakout_judgement`
- `spacing_quality`
- `contact_report_quality`
- `reaction_delay_seconds`
- `tempo_modifier`
- `effect_label`

Private or roster-only fields such as mission history, relationship links, biography text and raw profile data are not part of multiplayer tactical snapshots.

## Competencies
The resolver derives FTL competence from:

- `leadership`
- `tactical_sense`
- `communication`
- `discipline`
- `initiative`
- `team_cohesion`

When explicit `progression.ftl_tactical` data exists, it is used as the persistent growth layer. Otherwise, the resolver derives a deterministic baseline from `skill_values`, `communication_values`, `behavior_axes`, morale, frustration and fireteam cohesion.

## Runtime Effects
`FireteamBehaviorResolver` blends the FTL snapshot into:

- order fidelity
- reaction delay
- execution cohesion
- fire discipline
- contact stability
- initiative
- cohesion threshold

`MultiFireteamPlanResolver` uses the same snapshot when assigning `lead`, `support`, `security`, `reserve` and `recon` roles. It passes normalized skill factors into `FireteamExecutionPlan`.

Effects are capped by fair bounds. A good FTL helps plans feel cleaner, but does not create a super AI or direct hit-bonus explosion.

## Progression
`MissionProgressionResolver` updates `progression.ftl_tactical` only for fireteam-lead contexts:

- deployed FTL
- issued orders
- coordinated plan
- contact report
- breakout decision

Mission success, objective participation and good cohesion can improve growth. Downed state, role mismatch, frustration and poor cohesion slow it. Per-mission growth is capped by `MAX_FTL_TACTICAL_GAIN_PER_MISSION`.

## Character Sheet and Debrief
The Character Sheet adds a compact `FTL Impact` row with help id `character_sheet.ftl_tactical_impact`.

Debrief events may include `ftl_tactical_progression` when a mission created a meaningful FTL gain.

## Multiplayer Snapshot
`MultiplayerSnapshotContract` normalizes the optional `fireteam_tactical` array. It keeps only public tactical display numbers and identifiers.

Forbidden in multiplayer tactical snapshots:

- `mission_history`
- `fireteam_history`
- `relationship_links`
- `biography_text`
- `leader_profile`
- raw `effect_text`

## Non Goals
This task does not add a skill tree, new relationship system, automatic command authoring, combat damage changes or UI-managed tactical truth.

## Follow-Up Tasks
TASK_274 can use the public snapshot and effect labels to build the visible tactical communication feedback layer.
