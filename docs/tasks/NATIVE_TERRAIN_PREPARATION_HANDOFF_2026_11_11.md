# Native terrain preparation and real B battle handoff

## Goal / cause
The resource-prefill headless gates prove static geometry reuse. They do not
prove that normal MissionSetup receives the full cache after visible approach,
or that the real B/1x battle still works. Add one opt-in native integration probe.

## Scope / non-goals
Subclass the unchanged native_glut_battle_profile.gd. Use the real post-A
checkpoint, boarding, quantum/abort/restart, approach, landing and B guard
encounter. No production, base-profile, navigation or armor changes. No fake
mission readiness, direct cache injection, smaller map or fabricated combat.

## Sources / contracts
AGENTS.md; PROJECT_BRIEF; ARCHITECTURE; CODEX_RULES;
TERRAIN_RESOURCE_PREFILL_2026_11_11; STAR_MAP_TERRAIN_PREPARATION_UI_2026_11_11;
combat_frame_accounting_20261111; inherited actual-sortie profile and verifier.

## Acceptance
- Observe lightweight preparation/travel owner getters each pending frame.
  Approach remains active, active mission and its timer remain absent until
  readiness; hence no destination mission UnitRegistry/actors exist early.
- Capture an actual native StarMap frame with nonzero incomplete preparation.
- Actual MissionSetup view reports ready 2161/2161, zero geometry builds and
  nonzero resource restores. Three distant camera positions settle with no
  replacement geometry, identical actual resource-ID digest, cache instance
  and context, and bounded scene nodes (active chunk set + 64 retained).
- Restore original camera focus. Inherited genuine B exchange clears its guard
  at 1x and fires at least eight actual shots.
- Separate JSON contains loading transitions, allocator/video-counter maxima,
  handoff and camera receipts. No full runtime snapshots per frame.

## Files / local verification
scripts/tests/native_terrain_preparation_battle_test.gd;
docs/qa/native_terrain_preparation_handoff_20261111/README.md.
Godot 4.6.2 --headless --check-only compilation is authorized; no native run
until Root coordinates the exclusive renderer window. Root runs with private
APPDATA under output/native_glut_maps, --continue-chapter --1x, using a copied
valid post-A checkpoint. Existing B_battle_profile.json is inherited output;
archive each run separately to avoid overwriting prior evidence.

## Risks / open acceptance
Native execution, screenshot aesthetics, whole preparation memory and real
battle remain pending. Renderer video counters are not total driver allocation;
allocator static memory is not process RSS. Camera probes add pre-battle work,
so report this integration run separately from clean performance A/B runs.
Test-only private resource-ID introspection is explicit and occurs at four
camera receipts, never per frame. No runtime cache lifetime behavior changes.

## Native monitor correction
Root's first native run reported 57/1: the sole failure came from rereading
the expired fire-event ring (six remaining), whereas the inherited fresh
profile recorded max eight shots and B clear. Finish now uses that profile,
matching private user path, map hash and scale. Before launch, only the fixed
generated profile output is removed under the inherited private APPDATA guard,
ensuring no previous run can satisfy the check. Screenshot threshold is 10%.
Headless check-only passes; Root performs repeat native acceptance separately.

Root final: native62/0, eightshots1x,2161/2161 handoff and zero far geometry rebuild.
Initial57/1 and59/2 were diagnostic lifetime bugs, preserved inQA; inherited
profile writer now closes before subclass read. Frame tails remain open.
