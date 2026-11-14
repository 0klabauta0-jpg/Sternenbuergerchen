# A*/HPA C++ prototype: behavior and measured performance

14.11.2026. **Prototype built and compared; keep opt-in.** C++ search is much
faster once costs are prepared, but full-map preparation makes cold requests,
revision changes and changing movement options slower. Do not enable this adapter
as the normal SimulationRoot navigation implementation in this form.

## Source and environment

- Base: `9e2e972a1010d10fa5cdc0c08bd588bea5128173`, deliberately the reviewed
  unintegrated playtest branch state; not the older integration/core-foundation.
- Branch: `task/native-navigation-prototype-20261114`. Tested uncommitted source
  bytes and DLL are pinned in every `source_manifest.json`; `build_manifest.json`
  binds the C++ sources and build recipe. Final Git commit is available in history.
- Godot `4.6.2.stable.official.71f334935`; Windows; Ryzen 7 7800X3D,16 logical CPUs.
- Windows x64 release-optimized DLL, MSVC 19.51.36243, SCons 4.11.1,
  godot-cpp 4.5-stable e83fd0904c13356ed1d4c3d09f8bb9132bdc6b77, single-precision
  Godot vectors, double cost arithmetic, kernel /fp:strict.
- Headless navigation-only minimal projects with exact copied source bytes and
  isolated user-data namespaces. No game assets, actors, save data, GPU/FPS timing.
  Native binary successfully loaded by the actual Godot process.
- Own engines/builds were serialized. Preliminary bench_a had a concurrent own
  Git discovery consuming CPU; it was stopped and A is retained but excluded.
  Accepted bench_b and bench_c ran afterwards, without concurrent own Godot/build.

## What was built

`native/navigation/src/native_navigation.cpp` implements stable A* and directed
forward/reverse Dijkstra. `native_hpa.cpp` implements the complete existing HPA
portal search, lower-bound pruning, tie rules and path assembly.
`scripts/terrain/native_navigation_prototype.gd` prepares compact directed costs
using unchanged GDScript rules and exposes explicit A*/HPA entry points.

The adapter retains one snapshot per identity/revision/options set, plus a 64-entry
FIFO HPA result cache. Gameplay authority remains in existing owners.
Production scripts and normal navigation selection are unchanged.

## Behavior evidence

- [Final verifier](verify_frozen/result.json): **921 passed / 0 failed**;
  native A* 74 and HPA 74 explicitly verified, plus FIFO queries, direct edge costs,
  forward/reverse Dijkstra dictionaries, option combinations, map/graph identity
  and revisions, blocked/unreachable/start-equals-goal cases, slopes/cliffs,
  square corner cuts, negative coordinates, malformed snapshots and fallbacks.
- Exact comparisons use complete ordered paths, status, score fields and directed
  costs against unchanged GDScript, not merely equal endpoints or approximate cost.
- [Existing Hex regression](regression_hex/run.log): **41/ 0**, including legacy
  square paths, ramp/cliff traversal, HPA portals and dirty graph rebuild.
- [Missing DLL negative control](verify_missing_extension/run.log): expected
  **0/ 1**, exit 1. Tests cannot pass by accidentally measuring GDS fallback only.
- Static accepted benchmarks: **486/486 paired results identical**. Every measured
  route is nonempty; HPA cache-hit rows confirm both implementations really hit.
- [Dynamic options](dynamic_options/result.json): **16/ 16 paired results identical**,
  including complete paths/status/scores with the actual per-request options;
  both caches miss, each native request rebuilds exactly one snapshot.

Earlier verify_first 858/ 0 and verify_final 913/ 0 are retained preliminary states;
verify_frozen 921/ 0 matches the final adapter/fixture/verifier hashes.
This is bounded differential evidence, not a proof for every possible map.
Diagnostic counters/time fields describe backend work. Requested diagnostics use
GDS fallback; mixed native/fallback history has separate cache accounting.

## Static cost options: accepted B/C timings

Paired ordering alternates GDS-first/native-first. Warm rows have 48 samples per
algorithm/fixture from two fresh processes; cold/revision rows have 6. Median values
below are milliseconds. Cold means fresh solver/snapshot (plus fresh HPA graph)
inside a running process, excluding engine startup/import and JSON parsing.

|GM01, 9408 cells|GDScript ms|C++ adapter ms|Interpretation|
|---|---:|---:|---|
|A*, warm new query|259.568|0.4225|~614x in prepared search case|
|HPA, warm new query|246.893|7.4465|~33.16x in prepared search case|
|A*, cold total|193.720|732.457|~3.78x slower|
|HPA, cold total|477.145|1046.925|~2.19x slower|
|HPA, terrain revision + graph rebuild|509.564|1089.905|~2.14x slower|
|HPA, existing result-cache hit|0.0125|0.015|No gain; tiny microsecond difference|

Warm measurements include public-call checks, native call and return conversion,
but amortize earlier full-map preparation. That preparation is separately recorded
in each result's `preparation` array (GM01 around 0.7–0.8s). The large warm ratios
combine compiled search with persistent precomputed edge costs; they must not be
described as a pure language-only speedup or as whole-game FPS improvement.

Other warm medians:

|Fixture|A* GDS→native ms|HPA GDS→native ms|
|---|---:|---:|
|square24, 576 cells|22.625→0.0335|11.722→0.176|
|hex24, 576 cells|11.579→0.032|16.386→0.346|

Full means/p95/max, sample counts, success counts and exact source hashes are in
[comparison.json](comparison.json), recomputed from raw
[B](bench_b/result.json) and [C](bench_c/result.json) with
`python scripts/tests/summarize_native_navigation.py`.
Six cold samples are too few for a stable tail-latency claim.

## Changing movement options: decisive integration limitation

Actual `FireteamMovementController` commands use cover, corridor, lane and
clearance values. `SimulationRoot._append_navigation_corridor_options` derives
endpoints and lane offsets from a command. These values can change between units
or commands, invalidating a snapshot keyed by the whole option set.

The additional fixture derives balanced Move weights with default cover_priority 0.4
and changes corridor endpoints/lane offsets on the same registry, graph and solver.
Hazard cells are empty. This is a command-shaped navigation fixture, not an actor
or UI replay. It has 8 queries per map, hence a small-sample warning.

|Changing options|GDS median ms|Native total median ms|Totals across 8 queries|
|---|---:|---:|---|
|hex24|26.641|57.734|228.745ms→462.857ms|
|GM01|149.7165|978.075|1506.698ms→8054.725ms|

For GM01 the native search itself has a 2.985 ms median; snapshot preparation
has a 974.5125 ms median. Therefore the prototype is **~6.53x slower by median**
and **~5.35x slower cumulatively** for these changing-cost requests.
Graph creation is outside both request timings and recorded separately.

## Decision and next implementation boundary

Keep this candidate as a reproducible opt-in prototype. The measured result supports
native search, but rejects a blanket production switch to the current adapter.
A follow-up should retain a compact terrain snapshot by terrain revision and compute
query-dependent costs natively/lazily, or update only affected data, preserving the
same directed costs and ordering. Re-run the dynamic-options case before considering
production enablement. Existing result caches remain valuable.

No main merge, game EXE, release acceptance, live multiplayer validation or
end-to-end FPS gain is claimed. Windows x64 is the only packaged/tested platform.

## Reproduction

See [native build/API README](../../../native/navigation/README.md).
The runner writes new evidence directories, refuses engine errors, and never
overwrites an existing evidence directory. The negative control uses
`--without-native` and is expected to fail. C++ sources, DLL, scripts and maps
are pinned; build dependencies are versioned in the build recipe.
