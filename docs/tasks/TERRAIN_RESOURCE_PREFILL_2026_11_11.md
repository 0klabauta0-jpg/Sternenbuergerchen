# Terrain resources once per map lifetime â€” bounded prefill probe

## Problem / cause
512Ã—256 regional maps are fully loaded as simulation data, but the renderer
retains only64 inactive chunk nodes. Eviction frees unique meshes and instance
buffers. Revisiting a distant area can repeat SurfaceTool/raster and MultiMesh
construction. The user wants the whole map prepared once, with no recurring
terrain reconstruction during camera travel. Map dimensions/quality remain.

## Scope / non-goals
Deliver a resource/descriptors cache, approach readiness gate and a headless proof on
real created regional chunks. Store immutable static Mesh/MultiMesh resources,
materials, local transforms and rendering flags; never store scene nodes,
FoW, units, scripts, interactions or gameplay truth. Restore only an off-tree,
initially hidden static chunk. Active node range and FoW publication remain
with the existing view. No whole-map node tree, native/GPU run by this worker, global scene
refactor, armor change, Main/EXE/commit/push. Root separately owns the
read-only StarMap progress display and later native verification.
After the independently committed R02 fix (7ef57c931), ownership is
released for view/approach/setup integration. A hidden actor-free preloader
prepares the entire expected chunk set before the existing approach owner
starts the mission. Source files: terrain_map_3d_view.gd, the narrow
_begin/_finish_space_approach lifecycle in meta_layer_flow.gd, and
scripts/tests/mission_test_setup.gd for cache handoff. Root owns
star_map_screen.gd and consumes snapshot.map_preparation only.
Actual percentages come from prepared/expected chunks; no technical chunk
counts appear in normal player text. Cancel/failure returns through the
existing enter_space_orbit owner path. No partial-ready or endless approach.

## Contracts / sources
AGENTS.md; PROJECT_BRIEF.md; ARCHITECTURE.md; CODEX_RULES.md;
regional terrain/graphics ownership in terrain_map_3d_view.gd,
hex_ground_batch.gd and regional_hex_surface.gd;
graphics_reference_revision_contract.md;
REGIONAL_FIRST_GO_NAVIGATION_2026_11_11.md;
QA navigation_first_go_20261111, combat_frame_accounting_20261111.

## Acceptance
- Genuine regional chunk fixture contains nonempty mesh and MultiMesh geometry.
- Cache records contain no Nodes. Restored source/mesh/material identities,
  transforms, surface overrides and rendering flags match the original.
- Cached meshes survive original node deletion and repeated restores without
  SurfaceTool/MultiMesh-buffer rebuilding; no mutation of source resources.
- Map/terrain revision, art revision and grid revision invalidate independently.
  Expected chunk set and cache lifetime are explicit; malformed requests do not
  destroy an existing valid cache. Progress is ready only when every expected
  chunk is captured, never merely because active chunks are ready.
- Measure retained geometry-array/buffer and descriptor payload bytes, dedupe
  shared resources, and reject a capture before exceeding the configured bound.
  This is not a full process RAM/VRAM measurement or hardware acceptance.
- Reject script-bearing/skinned/FoW/dynamic unsupported content rather than
  silently caching stale gameplay projection.
- Cache clear releases its ownership but does not free caller-owned instances.

## Files / checks
New scripts/terrain/terrain_chunk_resource_cache.gd;
scripts/tests/terrain_chunk_resource_cache_test.gd;
docs/qa/terrain_resource_prefill_20261111/.
Godot4.6.2 headless with private APPDATA. No new renderer or performance run
while the armor agent owns the GPU. Inspect actual gate/load/GO contracts and
verify the complete expected set, actual handoff, cancellation and regression paths.

## Risks / open work
Packed geometry payload omits engine overhead, textures and driver allocation.
Full-map resource preparation must be budgeted with visible progress before
mission/GO readiness. Cached inputs require complete map/art/grid invalidation.
Complex scripted/interactable props stay with existing owners. No full-map
resident-memory/FPS claim follows from resource reuse alone.

## Helper proof
Missing API RED0/1; owner metadata RED28/4 and context extra object RED,
then actual B geometry/prop/multi-cell-owner probe GREEN41/0. Strict four
string context fields; default-deny unknown metadata, inspected render-only
metadata retained. Inspected build-only geology wrappers produce plain
script-free restored Node3D groups. Automatically generated invalid @ node
names are canonicalized consistently. Source node/owner references never
enter the cache. MultiMesh.buffer readback is unavailable in the headless
dummy renderer; payload accounting therefore counts configured buffer
capacity, not a claimed physical GPU allocation.
## Integrated proof and remaining acceptance
Basis: 7ef57c931; working-tree changes are intentionally uncommitted.
The approach gate, source context validation, MissionSetup handoff and static
resource restoration are implemented. Full A/B/C headless18/0 each, helper41/0,
lifecycle13/0, FoW13/0 and existing streaming gate PASS.
See docs/qa/terrain_resource_prefill_20261111/README.md and manifest.json.
Actual native whole-load, MissionSetup transition and B battle at1x remain
Root-owned acceptance. The 256MiB bound covers accounted resource payload;
engine static-memory samples are reported separately and do not approve GPU
residency or overall process memory.

## New-journey feedback acceptance
A successful space_start_quantum clears only that craft previous failed or
cancelled preparation result. Rejected start retains feedback; other craft
results remain untouched. Lifecycle verifier RED16/2 then GREEN18/0.

Root native acceptance62/0: actual B1x/eightshots, complete2161handoff, distant
geometry rebuild0. General frame-time acceptance remains open; see combined
native QA. Lifecycle final18/0 includes clearing stale results on new travel.
