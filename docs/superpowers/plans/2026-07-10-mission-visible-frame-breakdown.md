# Mission Visible Frame Cross-System Timing Breakdown

**Goal:** Make the actual expensive part of one visible mission frame observable before making another performance change.

**Architecture:** Existing `SimulationRoot` tick profiling remains authoritative for simulation. The mission controller and TerrainMap3DView get opt-in, local visual diagnostics only. A headless verifier coordinates the three snapshots and makes no gameplay mutations.

## Steps

1. Add a red verifier requiring opt-in controller/terrain timing APIs and a combined read-only result.
2. Add default-off timing scopes around controller process/UI work and terrain process work.
3. Enable all profilers in the live mission fixture, capture several frames and report the slowest named scope.
4. Publish evidence and select the next measured fix.
