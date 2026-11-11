# Whole-map terrain resource preparation

Basis 7ef57c931, Godot4.6.2 stable. Changes are working-tree candidates, not a release. Source and accepted-log SHA256 are in manifest.json. The manifest does not cover parent-owned StarMap UI or armor changes.

## Accepted functional evidence

| Gate | Result | Log |
|---|---:|---|
| Static cache, actual B geometry/props/owners |41/0|cache_final.log|
| Approach gate/cancel/stale worker/timeout |13/0|approach_final.log|
| Existing FoW publication |13/0|fow_regression.log|
| Existing streaming/reversal/node bound |PASS|streaming_regression.log|
| Full A, including actual prop/ramp/cliff/grid geometry |18/0|prefill_A.log|
| Full B |18/0|prefill_B.log|
| Full C |18/0|prefill_C.log|

All accepted logs have no engine/script errors or leaked-object warning. Each full-map test declares and prepares all2161 chunks, retains zero chunk nodes in the completed preloader, hands identical resources to a fresh view, pans to three far targets, and verifies geometry_build_count remains0 and active-node bounds remain. Context/grid mismatch fails closed before a synchronous fallback. One-byte budget failure and cancel never produce ready.

| Map | Accounted resource payload bytes | Engine static baseline bytes | Engine static peak bytes | Delta bytes |
|---|---:|---:|---:|---:|
| A |149115384|380199380|616778088|236578708|
| B |213117380|382489948|684196632|301706684|
| C |151662728|382042376|619963728|237921352|

The256MiB bound is on deduplicated geometry arrays, configured MultiMesh capacity and descriptors. It excludes driver allocations, textures, engine bookkeeping and unrelated runtime state. Godot headless dummy renderer cannot read back MultiMesh buffers; configured capacity is the explicit accounting basis. MEMORY_STATIC samples are engine measurements, not process working set or VRAM. No FPS or hardware memory acceptance follows from this table.

## Implementation boundaries

The existing approach phase waits for actual data worker and full static resource set before mission admission. At most one hidden actor-free view prepares resources at a time, using up to2 chunks per process callback and a soft4ms budget. One temporary hidden chunk is attached to the disabled preloader view while building because existing authored prop bounds use global_transform; that chunk is freed immediately after resource capture. Whole-map scene nodes are never retained.

The cache retains Mesh/MultiMesh/Material references, transforms and rendering flags. Unknown metadata/scripts/skin and owner/interaction/FoW metadata are rejected. A narrow inspected geology build-only script and scalar render-only metadata are allowed; restored nodes have no scripts. Actual multi-cell visual owner/picking objects remain outside cache. Live FoW discovery and units never enter resource descriptors. R02 static overlay layout remains owned by each actual view.

Map tile inputs, externally owned prop cells, terrain-only art/build code and grid/height configuration determine context. Character/armor revision is unrelated. Actual MissionSetup handoff validates full context before adopting; mismatched grid context produces prepared_cache_context_mismatch and no reconstruction. Cancellation retires unfinished data workers without blocking, restores craft projection and returns through existing orbit owner. Timeout or payload failure returns explicit failure to orbit rather than partial readiness.

## Lightweight native observation

Flow.get_surface_preparation_snapshot(craft_id) reads the actual job, retained after completion. StarMap consumes top-level snapshot.map_preparation from the same source. Root owns player display and its independent tests.

Actual primary TerrainMap3DView.get_terrain_resource_preparation_snapshot() should report ready, expected_chunks2161, prepared_chunks2161, geometry_build_count0, resource_restore_count>0. It also exposes retained_scene_nodes, reason and memory/payload counters. Cache.get_debug_snapshot() exposes context_fingerprint and geometry_resource_count. Node bound uses _regional_chunk_nodes.size() <= _visual_streaming_active_chunks.size()+64. No full runtime snapshot per frame is needed.

## Remaining acceptance / rejected development evidence

Root owns actual native approach/MissionSetup transition, whole-load latency/RAM/VRAM and real B battle at1x. These are pending and are not replaced by headless results. No native/GPU run was performed by this worker.

Earlier RED logs document missing API, metadata retention and context-object rejection. prefill_candidate.log contains engine global-transform errors from an off-tree builder and is rejected as acceptance even though assertions reached17/0. prefill_tree_bounds_fixed.log was the first clean17/0 proof, superseded by final18/0 A/B/C with fail-closed handoff. Forced startup diagnostics and incomplete-run logs are not accepted gates.

## P2 stale preparation result on new journey

Read-only UI review found that a previous failed/cancelled approach result could
reappear after a successful new quantum journey reached another orbit.
Flow now removes only the affected craft result after the runtime adapter
accepts space_start_quantum. Rejected starts and other craft feedback remain.
No UI state or travel authority is added. RuntimeProbe accepts configurable
request results. approach_stale_result_red.log proves16/2 before the fix;
approach_stale_result_green.log proves18/0 after, exit0 without engine errors.
This supersedes the earlier13/0 lifecycle gate, preserving those assertions.

## P2 stale preparation result on new journey

A previous failed/cancelled approach result could reappear after a successful
new quantum journey reached another orbit. Flow removes only the affected
craft result after the runtime adapter accepts space_start_quantum. Rejected
starts and other craft feedback remain. No UI state/travel authority is added.
RuntimeProbe has configurable request results. approach_stale_result_red.log
proves16/2 before the fix; approach_stale_result_green.log proves18/0 after,
exit0 without engine errors. This supersedes the earlier13/0 lifecycle gate.


Root combined native proof: ../native_terrain_preparation_handoff_20261111/README.md.
62/0, realB1x/eightshots,2161/2161, no distant geometry rebuild. Lifecycle now18/0
after stale-result cleanup. Native memory/tail limits are explicitly retained;
this is not a broad FPS pass.
