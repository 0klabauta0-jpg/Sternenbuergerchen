# Native runtime navigation

Windows x64 GDExtension for Godot 4.6.2, enabled by default in SimulationRoot.
The extension implements stable A*, directed local Dijkstra cost maps, the existing
HPA portal search/assembly and Main's incremental RegionalHexSearch. It is not a
new globally optimal HPA algorithm.

The same library also contains two stateless kernels: `NativeTerrainBuilder`
constructs directed adjacency from packed effective terrain fields, and
`NativeVisibilityKernel` generates the exact canonical Hex ray cells. LOS still
reads current terrain and applies blocker/height rules in GDScript; Square wall
segments keep their original path. Neither kernel owns gameplay state.
Older or missing kernel APIs retain GDScript fallbacks. See
`docs/dev/native_visibility_runtime_contract.md` and
`docs/qa/native_terrain_visibility_20261114/README.md` for the bounded contract
and paired measurements. Terrain revisions still rebuild a full snapshot.

## Build

From the repository root in PowerShell:

```powershell
./native/navigation/build.ps1
```

Requires Python, Git and MSVC C++ Build Tools. The script installs SCons **4.11.1**
in a dedicated venv, and uses godot-cpp **godot-4.5-stable** at
`e83fd0904c13356ed1d4c3d09f8bb9132bdc6b77`. This is deliberately a pinned older
compatible API floor, tested with Godot `4.6.2.stable.official.71f334935`.
The published repository had no 4.6 branch/tag at implementation time.
No custom engine is built. Third-party license is included.

Both debug/editor and release Godot select the same optimized template_release DLL.
This makes the measured native build explicit. Floating-point contraction/fast math
are disabled for the project kernel (`/fp:strict` on MSVC). Godot vectors retain
single precision; accumulated path costs use double, like GDScript floats.
Only Windows x64 is built/packaged here; other platforms require their own builds
and differential runs before extending the manifest.

## API and ownership

`scripts/terrain/native_navigation.gd` exposes:

- `find_path_with_options(from, to, registry, options = {}) -> Array`
- `find_path_with_status(from, to, registry, graph, options = {}) -> Dictionary`
- `prepare(registry, options = {}, graph = null) -> bool`
- `create_regional_search(from, to, registry, options = {})` with a budgeted `advance()`
- `clear_result_cache()`, `clear_prepared_data()` and `get_debug_snapshot()`

SimulationRoot selects this adapter for normal HexGround incremental searches,
legacy HPA/direct A* and reachability fallbacks.
The mission loader calls `prewarm_navigation(registry)` after initial scenario/door
overrides and before gameplay starts. Thus the first command reuses the prepared
terrain. Only the legacy HPA path prebuilds an HPA graph. Actual homebase HexGround
movement uses the same adapter; its AStar2D clearance/target projection remains.
Base loading and successfully finalized checkpoint restores also prewarm terrain.
See `docs/dev/native_navigation_runtime_contract.md` for ownership and lifecycle.

`SimulationRoot.native_navigation_enabled = false` retains the GDScript reference
for developer comparisons. Without the DLL, navigation falls back automatically.
The previous `native_navigation_prototype.gd` name remains a compatibility wrapper
for existing differential benchmarks.

The adapter retains terrain data by registry identity/revision and HPA geometry by
registry/graph identity/revision. Terrain preparation uses the **unchanged**
TerrainPathfinder traversal rules and stores directed base costs before diagonal
multiplication, cover values, walkability and LOS/height data. Directed base costs
use Main's canonical ramp stand heights (including half levels). An option change no
longer rebuilds either snapshot.

Each real search calls the kernel's `begin_query(options)`. Native A*, Dijkstra and
HPA then share lazily evaluated directed costs, including cover, exposure/LOS,
corridor, lane and clearance. Generation stamps discard previous query costs
without a map-wide reset. Arithmetic order and Godot Vector2 precision match the
GDScript reference. `blocked_grids` is respected by membership, including false
values. No per-neighbor callbacks into GDScript are used.

Regional jobs retain their own sparse frontier, predecessor/cost maps and query
cost caches, sharing one kernel terrain snapshot by reference. An interleaved
job or ordinary A*/HPA call cannot overwrite another job's costs. Snapshot
generations invalidate obsolete jobs; owners restart them under their existing
revision rules. The existing expansion limits, stable ordering, nearest-reachable
result, reservations and authoritative arrival remain unchanged.

One terrain snapshot and one graph snapshot are retained; arrays grow with the map,
not with the number of previous queries. HPA results use a bounded 64-entry FIFO
cache with defensive copies. Authorities and mutations stay with existing owners.

Unsupported inputs use an explicitly reported GDScript fallback. The supported
coordinate and height domain is +/-1,000,000 per component. Native query flags use
bools; endpoints, hazards and exposure keys use Vector2i. Numeric cost options must
be finite with absolute value <=1e12, and clearance radius is limited to 64; values
below 1 retain the reference's clamp to 1. Unsupported values explicitly fall back
to GDScript. A rejected kernel load clears stale data; a rejected query cannot
reuse previous query costs. Callers must publish terrain and graph changes through
their existing revision contracts.

Gameplay equality means exact ordered paths, HPA status, edge costs and path scores.
Native diagnostic timing/counters are deliberately separate. Requested GDScript
`diagnostics` dictionaries are delegated to GDScript; its separate fallback-cache
history can differ after mixed native/fallback calls. Diagnostic work counts are
therefore not part of the gameplay-equivalence claim.

## Verification and timing

```powershell
python scripts/tests/run_native_navigation_prototype.py
python scripts/tests/run_native_navigation_prototype.py --script native_navigation_runtime_verifier.gd
python scripts/tests/run_native_navigation_prototype.py --script native_navigation_load_verifier.gd
python scripts/tests/run_native_navigation_prototype.py --script native_navigation_runtime_benchmark.gd
python scripts/tests/run_native_navigation_prototype.py --script native_navigation_main_verifier.gd
python scripts/tests/run_native_navigation_prototype.py --script native_navigation_main_benchmark.gd
python scripts/tests/run_native_navigation_prototype.py --script native_navigation_runtime_verifier.gd --without-native --script-arg=--expect-native=false
python scripts/tests/run_native_navigation_prototype.py --script native_navigation_prototype_benchmark.gd
python scripts/tests/run_native_navigation_prototype.py --script native_navigation_dynamic_costs_benchmark.gd
```

The runner copies the actual source bytes and navigation dependencies into a fresh
ignored minimal project, records SHA256, imports only that project and uses an
isolated user-data namespace. It fails on engine/parse errors and leaks. It copies
explicit preload resources required by the real loader; unrelated asset catalogs
are not imported. No player saves or full visual scene are loaded.

Fixed-options benchmarks distinguish cold solver/graph construction in a running
process, warm uncached queries, cached results and revision rebuilds. Preparation
and language transfer are included in cold calls and recorded separately for warm
reuse. Dynamic-option measurements use the original eight changing requests:
one phase includes a cold first request, another records explicit preparation and
also includes it in the reported series total. Each query must use native code,
miss the result cache, open a new cost context and retain one terrain/HPA snapshot.
These are navigation subsystem measurements, not frame-rate or actor-playthrough
proof. Current Main HexGround integration results are in
`docs/qa/native_navigation_main_20261114/README.md`; the earlier owner/loader results
are in `docs/qa/native_navigation_runtime_20261114/README.md`. Earlier lazy-cost measurements
remain in `docs/qa/native_navigation_dynamic_costs_20261114/README.md`.
The earlier `native_navigation_20261114` evidence belongs to
commit `7a7cf80e3`; its source hashes intentionally differ after this optimization.
The old dynamic-options command remains an alias for the current benchmark.
