# TASK_N007 — First Ten Minutes Release Gate

## Goal / problem

Prove the product outcome from a clean exported Windows build, without a deeplink, through the first complete Commander journey and the first shared multiplayer engagement.

## Cause / value

Focused verifiers cannot replace a player starting at the main menu. The release gate makes the current truth evidence correspond to the actual product entry, authored mission, visual semantics, command/GO interaction, combat outcome, debrief, and return loop.

## Scope

- Export a Windows build from an N002-clean checkout.
- Run main menu → team/loadout → dropship → command/GO → authored contact/fire → objective/result → debrief → return with no deeplink.
- Run a two-process host/client path through the first shared engagement.
- Update current truth/evidence with exact commit, date, commands, artifacts, results, and caveats.

## Non-goals

- Do not add features, hide a failed stage with a deeplink/test helper, claim production completeness, or clean up worktrees before captured evidence is preserved.

## Relevant contracts / documents

- `docs/CURRENT_GAME_STATE.md`, `docs/qa/CURRENT_EVIDENCE.md`, and manifest from N001
- `docs/tasks/TASK_N002_reproducible_godot_checkout.md`
- `docs/tasks/TASK_N003_command_authority_parity.md`
- `docs/tasks/TASK_N004_canonical_product_mission.md`
- `docs/tasks/TASK_N005_frontier_desert_outpost.md`
- `docs/tasks/TASK_N006_combat_cadence_boundary.md`

## Acceptance criteria

- A clean-checkout Windows export starts at main menu and completes every listed singleplayer stage without deeplink.
- Two processes complete the first shared engagement through the public host/client command path.
- Evidence records identify commit, date, commands, artifacts, outcome, owning paths, and caveats.
- Failures are attributed to a specific stage and kept visible in current truth.

## Affected areas

Export pipeline, release/playtest harnesses, capture artifacts, current-state/evidence manifest, and final player-path regression reports. No unplanned product behavior change.

## Verification

Use the N002 clean checkout; export Windows build; record a no-deeplink singleplayer run and a two-process run; validate evidence manifest; rerun required architecture, parity, path, landscape-semantic, and performance gates; run `git diff --check`.

## Risks / open points

The complete path spans the most systems and can be slow. An automated success still needs a readable visible capture; conversely, a visual issue must not be reported as a simulation result without the corresponding artifact.

## Dependency / exit gate

Requires N001 through N006 evidence gates. N008 may begin only after both player-path runs and their current-evidence updates are committed, with any remaining caveat explicit.
