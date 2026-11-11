# Explicit hex ramps and joined banks

Confirmed user contract: docs/dev/explicit_hex_ramps_contract.md. Versioned
maps only. Plateau H/H+1 cliff is blocked. One ramp cell spans H toH+1;
logical centreH+.5. Axis endpointsH/H+1, lateralH+.5 lets matching ramps join
without allowing sideways entry from integer-height plateaus. Corner/midpoint
samples are shared for broad banks and 60-degree corners. Closed sidewalls,
picking, actors, selection, grid and FoW overlay read the same surface.
FoW custom-data packs signed quartersteps; no visibility/targeting redesign.

Initial runtime worker41/0 is in ../explicit_hex_ramp_runtime_20261111; its
hashes describe the first stage before the user requested lateral joins.
Root final narrow fixture49/0 includes shared straight/turned seams and
reciprocal bank movement. Native345-cell form capture exit0/noenginewarnings;
Root opened the native image. Earlier bad probe attempts are not gameplay
proof. Large A/B/C, battles, editor interaction and save matrix deferred by
explicit user request. This is not a performance or complete gameplay pass.

Existing unversioned maps retain their original rules. Actual A/B/C art
candidates and editor followup are separate integrations. Ramp logical height
precision connects to existing LOS/cache/snapshot consumers only; Tabletop
sight/occupancy redesign is coordinated in the other chat.
