# Unwired prepared Fleet/Travel area transition

Base 916c388a9; additive product files only:
- scripts/core/singleplayer_fleet_travel_state.gd
- scripts/core/singleplayer_space_travel_state.gd

Public Fleet APIs are prepare_space_area_transition, validate_prepared_space_area_transition and commit_prepared_space_area_transition. Explicit trusted in-process Object identity setup and registered full root context precede these calls. There is no new command routing or production caller. Actual supported operations are finishing an existing quantum via adequate advance delta, and existing surface/approach enter_orbit. Source area is empty; target comes from the actual definition body via orbit_approach layout ID.

owner_check.gd / owner_check.log: PREPARED_AREA_RESULT checks=15 failures=0 runtime_wired=false. Uses actual Fleet and Travel owners, normal setup travel commands, and private in-process context registration. Covers context/owner/revision/tamper binding, no-op same-key receipt collision without revision change, correct body, mutation-free prepare, pose-free commit, successful retry after changed phase, release/rebind serial invalidation, reset, Surface/Approach routing and no new global RNG consumption. Setup assertions are not counted as scenario checks.

Both individual --check-only logs contain engine banner only. No Root, Flight, registry, UI, Surfacegate/Fuel/Campaign bridge, save/restore, production migration or real atomic multi-owner transition is claimed. Future Root must validate all owners first and use the no-await/no-callback silent tails before events; this candidate alone does not make a paid approach atomic. No GPU, battle, old broad matrix, commit or push.

QA boundary: the owner fixture used the default Godot user directory, not a private --user-data-dir. It directly constructs stateless in-memory Fleet/Travel owners and reads definition files; it does not call campaign/profile save or restore. No user-profile canary/hash guard was run or claimed. Individual check-only logs preceded the final context-serial amendment; the final successful 15-check fixture itself imports and compiles the current Fleet/Travel source. No additional test round was run after freeze review.
