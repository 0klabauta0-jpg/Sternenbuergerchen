# Independent final whole-branch review — 2026-11-09

Reviewed base `ed77c105854bf11b3abfd2c90e32a99bcf62f753` through HEAD `e6b4bd92c1d4defcb0da0d99122f7773b34daf20`, branch `task/singleplayer-loop-20261109`. Review is of this frozen implementation, not any subsequent fix. Read-only for product source, Git index and HEAD. No native window/input, push, integration, or subagents. The only reviewer writes are this report and ignored scratch probes/logs/private profiles alongside it.

## Current actionable findings

### P1 — Reject a trip that cannot afford its mandatory return before departure

Location: `scripts/meta/singleplayer_runtime_adapter.gd:198–201`; consequence at `scripts/meta/meta_layer_flow.gd:4595–4598` and `4173–4185`.

`validate_departure` checks only the outward route. A ship with 12 fuel can depart for satellite_crash, spend all 12, and then cannot afford the fixed reverse route. The satellite has no refuel service. When the mission resolves, `_begin_mission_craft_transfer` silently rejects the return, while `_on_mission_combat_resolved` still frees the mission and resets its planning state. The craft remains at location `mission`, with no active mission or transfer and no recovery/service route. This is a permanent campaign dead end, rather than a visible launch rejection. The current contract explicitly excludes adding a stranding mechanic.

Reproduction: real Flow + real Screen operation bridge, valid normal bootstrap craft/crew/boarding, set only supply fuel to the reachable boundary 12; accept/select satellite; request `start`. Departure accepts and fuel becomes 0. Apply the existing arrival handlers as an isolated arrival fixture, then invoke the actual result handler with a defeat fixture. Observed: `active=false`, `locations={dropship_1:mission}`, `transfers=[]`, `fuel={dropship_1:0}`. This focused test validates the failure transaction, not a fresh end-to-end played defeat. A natural route to low fuel is repeated visits using the same finite tank; 60 permits two 24-unit satellite round trips and leaves 12.

Evidence: `final-review-low-fuel.gd`, `final-review-low-fuel-arrived.log`, headless exit 0; no engine/parse/script errors in the final run. An earlier inbound fixture also showed the mission released with its outward transfer still pending. Temporary waiting variants were interrupted; they are not claimed as successful tests.

Required correction: ensure the authored outward+reverse budget is available before any launch mutation/debit, and keep failed return handling from discarding the only recoverable state. Preserve once-per-trip reverse debit and replay semantics.

### P2 — Bind satellite return proof to the actual landed job craft

Location: `data/mission_scenarios/satellite_recovery.json:74–81` (fixed `ship_return` Use binding); related unchanged free-LZ entry `scripts/tests/mission_tactical_sandbox_controller.gd:3541` and new parked-return behavior at `13583–13614` / `13922–13943`.

The new objective calls its fixed map marker “Rückkehr am Schiff bestätigen” and grants the `crew_returned` step there, but the craft can use the normal LZ controls to land elsewhere. The Use path resolves the authored marker and does not bind it to the job craft's real parked position or presence. Thus actually returning to the ship can fail the objective, while walking to the empty original pad can satisfy it. The new early return action also permits the parked ship to depart before recovery, with its deployed crew still present; the fixed return marker itself has no craft-presence gate.

Reproduction: choose a different valid satellite LZ near satellite_data, deploy and secure data, then attempt the return objective at the real ship. The fixed target remains approximately 391 world units away, beyond its 96-unit Use radius. The focused actual mission/primary+parallel flight-sequence probe accepted the alternate LZ and parked the real craft there: actual LZ `(2116.595,797.7025)`, fixed return marker `(1726.318,768.8409)`, distance `391.34259`. Both crafts deploy once and remain independently returnable. The probe checks the real flight sequence with advanced sequence deltas, not a new full real-time Use playthrough. Source inspection establishes that Use continues to resolve the unchanged marker.

Evidence: `final-review-relocated-lz.gd`, `final-review-relocated-lz.log`, headless exit 0 / 19 passed / 0 failed. Initial scratch indentation error was corrected before this final run and is not a product defect.

Required correction: make landing/return proof share the actual craft and pad identity. Either support a dynamic actual craft location, or explicitly validate an authored fixed-pad landing policy for these new campaign maps; in either case a missing/departed/wrong craft must not produce `crew_returned`. Keep legacy arbitrary-LZ behavior unaffected.

## Review coverage and bounded conclusions

Read the supplied plan/spec, repository owner rules and architecture/context, current implementation-status entries, new campaign/services contracts, ledger/rulings, immutable diff/stat and the corresponding immutable-base diff for changed production paths. Inspected all changed runtime/domain/command adapters, Operations navigation/drag/loadout bridges, job/map/services presenters, base/ship projection and lifecycle wiring, mission setup/driver/controller changes. Parsed all three changed maps for identity, dimensions, tile uniqueness and authored rooms/pads/terminals rather than treating thousands of tile lines as meaningful review evidence: base1008/1008, satellite396/396, trade360/360 unique tiles.

Focused on the five requested areas. No additional current actionable defect established in repeated Operations navigation/FOB blocking, existing membership/payload gates for empty/full/busy/transit and independent free group, job/selection separation, service request replay/finite stock/credits, or homebase room/pad projection. Snapshot deep copies, stable pad assignment on lifecycle events, per-trip reverse tokens, persistent campaign/supply owners, and cached UI rows/options were inspected. This is a bounded review result, not a general claim of defect absence.

Reviewed the actual loop test implementation and raw `docs/qa/singleplayer_20261109/raw/singleplayer-loop-second.log`: its 60/0 result corresponds to real Flow/Screen/mission movement/Use/result and second trade sortie, with only boarding fixture time advanced. It does not cover the two findings above (full-fuel startup and default spawn LZ). Inspected relevant domain, personnel, content and landed-craft test code to distinguish exercised behavior from fixture-only assertions. Did not rerun broad regression suites.

## Acceptance gaps, not additional source defects

- Native mouse/keyboard drag/drop, focus/scroll, actual screenshot legibility at the three requested resolutions, and human acceptance of the new roofless visual candidate remain open. Headless geometry/Controls and programmatic drag/press tests do not close these. User expressly required the PC to stay usable; no native capture/input was attempted by this reviewer.
- Final graphics/art judgement and any explicit user approval remain unreviewed. No general GPU/FPS acceptance or long-session resource/performance claim is made.
- Whole historical unmodified controller/Flow behavior, save migration (out of scope), exhaustive arbitrary future job definitions, and full multiplayer transport were not independently retested. The scope includes reading changed hooks and relevant callers, not re-certifying the entire game.
- Legacy346/388 layout failures were reported baseline-equivalent; TASK348 comparison was still pending in the handoff. This reviewer does not independently certify those baseline results.

Verdict for reviewed HEAD: changes requested for P1/P2. Native/user acceptance remains separate after correction. Root may perform the requested single verified fix pass; this report contains no assessment of such future fixes.
