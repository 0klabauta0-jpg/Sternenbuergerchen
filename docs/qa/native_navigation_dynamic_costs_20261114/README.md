# Native Navigation: options changes without full-map preparation

14.11.2026. **Implemented and measured.** The prototype now retains terrain and
HPA geometry while computing query-dependent costs lazily in C++. The original
dynamic-options bottleneck is removed for the measured workload. It remains an
opt-in candidate; production navigation is unchanged.

## Change and source

Branch `task/native-navigation-dynamic-costs-20261114`, based deliberately on
unintegrated prototype `7a7cf80e3` and its playtest base `9e2e972a1`.
`native/navigation/src/native_costs.cpp` ports cover, exposure/LOS, corridor, lane
and clearance costs with the original arithmetic order and Godot vector precision.
A*, directed Dijkstra and HPA share the same lazy edge costs.

The adapter now separates three lifetimes:

- Terrain snapshot: registry identity/revision; includes allowed directed edges,
  base costs before diagonal multiplication, cover, walkability and LOS/heights.
- HPA snapshot: registry/graph identity/revision. Changing only the graph does not
  rebuild the terrain. Query-dependent pruning bounds are still updated each call.
- Query context: each real search; generation-stamped target/edge caches are reused
  within the whole HPA request, without clearing arrays or rebuilding map costs.

Registry/Simulation ownership remains unchanged. Result-cache hits remain bounded
to 64 FIFO entries with defensive copies. Native bounds and fallback behavior are
documented in [build/API README](../../../native/navigation/README.md).

## Behavior checks

- [Differential verifier](verify_first/result.json): **1381 passed, 0 failed**,
  including 106 explicit native A* and 106 native HPA comparisons. Existing parity
  checks are retained. New checks cover all directed edges on small maps, changing
  options on one adapter, hazards/LOS, exposure overrides, absent/degenerate
  corridor endpoints, clearance radii, runtime overrides, snapshot reuse, graph
  revision changes and rejected-query stale-state protection.
- [Unchanged Hex/HPA regression](regression_hex/run.log): **41 passed, 0 failed**.
- **550/550 benchmark pairs** have identical complete ordered paths, statuses
  and score fields. All measured routes are nonempty. Native execution and actual
  result-cache misses/hits are explicitly checked.
- Independent source review found no blocking issue. No engine errors or leaks
  occurred in the accepted runner logs.

This is bounded differential evidence, not proof for every possible map. Mutable
diagnostic counters remain a GDScript fallback, as in the first prototype.

## Dynamic movement options: primary result

Identical original eight query pairs and option dictionaries, GM01 with 9408 cells,
balanced Move weights, changing corridor endpoints/lane offsets, empty hazards.
Two fresh-process runs; paired ordering alternates GDS-first/native-first.
The summarizer verifies the original from/to/options bytes and resulting path
hashes/status/scores against the preserved earlier evidence.

|GM01 request group|GDScript median ms|Optimized native median ms|Samples|
|---|---:|---:|---:|
|All eight requests, including first cold request|137.775|4.173|16|
|First cold request only|131.090|284.410|2|
|Following seven requests, changing options|138.6715|3.5235|14|
|Explicitly prepared terrain, eight changing requests|173.955|4.0595|16|

The original native adapter took a 978.075 ms median on this workload; the optimized
series is about 234x faster by median. This is a historical before/after comparison
with identical inputs, not a simultaneously interleaved old/new native benchmark.
The fresh paired GDScript comparison gives about 33x by median for all eight requests.

Eight-request totals **including the first terrain/adapter preparation**:

|Run|GDScript total ms|Optimized native total ms|
|---|---:|---:|
|dynamic_a|1311.001|309.030|
|dynamic_b|1318.092|318.455|

Thus the whole sequence is about 4.19x faster than its paired GDScript sequence,
despite the slower first call. The earlier native sequence took 8054.725 ms.
The shared original HPA graph is created before both arms, excluded equally and
recorded separately (256.620/266.592 ms). Engine startup/import/map parsing are also
outside query timing. This table does not claim complete level-load latency.

Following requests spend only 0.0485 ms median in the adapter's preparation stage;
terrain and HPA snapshot counts remain exactly 1. The options and native call still
count in each request's total. The separately prepared phase records its initial
setup (318.151/304.841 ms) and adds it back to sequence totals (353.548/339.255 ms).
No setup is silently omitted from the cumulative result.

Small hex24 fixture: following-request medians 18.8295 ms GDS vs 0.3675 ms native.
All dynamic groups have fewer than 20 samples; cold-first has only 2. Tail latency
and statistical significance are not established.

## Fixed options and remaining costs

The unchanged static benchmark also ran twice: 486 exact paired results. Warm
groups have 48 samples; cold/revision groups have 6. GM01 medians:

|Case|GDScript ms|Optimized native ms|
|---|---:|---:|
|A*, warm new query|272.328|0.560|
|HPA, warm new query|235.823|7.6405|
|A*, cold total|179.970|256.5375|
|HPA, cold total including graph creation|523.382|597.433|
|HPA, terrain revision plus graph rebuild|474.810|610.5585|
|HPA, existing result-cache hit|0.012|0.016|

Cold/revision rebuilds remain slower, though much smaller than the previous
prototype's full-cost build. Existing result caches already make repeated
identical queries very cheap. The optimization targets changing requests on a
retained map; it does not justify replacing every short or cached GDScript call.
Terrain changes still trigger a full terrain snapshot; incremental dirty-region
updates and prewarming before the first movement command are future work.

## Environment, evidence and reproduction

Godot 4.6.2.stable.official.71f334935, Windows x64, Ryzen 7 7800X3D,16 logical CPUs,
headless navigation-only minimal projects with isolated user-data namespaces.
MSVC 19.51.36243, SCons 4.11.1, pinned godot-cpp 4.5-stable
`e83fd0904c13356ed1d4c3d09f8bb9132bdc6b77`, template_release optimize=speed,
single-precision Godot vectors, double scalar costs and `/fp:strict` for the kernel.
All own builds and engine runs were serialized; review agents only read source.

[build_manifest.json](build_manifest.json) binds source hashes, DLL and recipe;
each run's `source_manifest.json` pins the exact copied dependencies and DLL.
[comparison.json](comparison.json) recomputes timings, verifies current hashes,
and checks equality with the original dynamic workload. Raw accepted evidence:
[dynamic A](dynamic_a/result.json), [dynamic B](dynamic_b/result.json),
[static A](static_a/result.json), [static B](static_b/result.json).

```powershell
./native/navigation/build.ps1
python scripts/tests/run_native_navigation_prototype.py
python scripts/tests/run_native_navigation_prototype.py --script native_navigation_dynamic_costs_benchmark.gd
python scripts/tests/run_native_navigation_prototype.py --script native_navigation_prototype_benchmark.gd
python scripts/tests/summarize_native_dynamic_costs.py
```

The runner creates unique directories by default; use `--output-dir` for explicitly
named fresh repetitions. The summarizer verifies/recomputes the committed accepted
run names above. Previous prototype raw data remain unchanged in
`docs/qa/native_navigation_20261114`; reproduce that version from commit 7a7cf80e3.

Only Windows x64 is packaged/tested. Hazard/LOS behavior with a few hazards and
clearance radii1–3 are checked. Dense hazards and larger radii have no representative
performance evidence here.
No production activation, Main merge, game EXE, actor playthrough, multiplayer
acceptance or whole-game FPS gain is claimed.
