# Actual normal Main startup smoke

Driver: `scripts/tests/frontier_main_startup_verifier.gd`.
Final driver SHA256:
`d8d31ca036f880b854c1eaddce3972551f4da407c39cfe160bc77b73d8ac79b5`.
Production/UI code and mission data were not changed by this test driver.

## Observed result

- `headless_probe_r02.json`: **33 passed, 0 failed**, process exit 0; 71.041 s
  elapsed wall time. The first diagnostic, `headless_probe.json`, remains
  unchanged. It exposed premature inspection of deferred runtime nodes and an
  overly strict roster-byte-equality assertion. The driver now waits for actual
  runtime nodes and verifies profile/generator/unit identity, while separately
  recording the before/after file hashes. No roster reset is called.
- `native_final.json`: **45 passed, 0 failed**, 66.492 s elapsed wall time,
  Windows / Godot 4.6.2 official / Forward+ / Vulkan, 1920x1080. The driver prints
  its success marker and exits after the six recorded screenshots. Native exit
  status was not separately collected by the background launch wrapper; the
  JSON, completion marker and logs are retained. No native ERROR, SCRIPT ERROR,
  parse-error or leak lines were found.

Both runs take the real route: current project MainMenu -> pressed Singleplayer
button -> real scene change -> visible Homebase -> normal Start Mission action
without craft override -> original `grid_sweep` / Ground Mission 01 -> natural
craft-transfer timer -> authored `spawn_alpha` marker selected through normal
screen picking -> Drop -> natural complete team unloading -> ordinary Move and
GO -> advancing SimulationRoot tick and changed authoritative unit positions.
The stored map and scenario are used; no weaker demo map replaces them.

There is no release-fixture call, teleport, forced transfer/unloading completion,
timer acceleration, paused runtime, direct private simulation-state write,
Frontier test override, or roster reset. Camera focus is an existing read-side
operation used to view the authored LZ. Existing normal-start profile saves are
allowed; profile, generator and unit identity are guarded without exporting the
roster content.

The default mission reports `frontier_art_enabled=true`, override=-1,
profile=`frontier_illustrated_v1`, and its original `square8` topology. The actual
normal dropship instance is bound to Ref03 Cutlass bytes:
`21484195affa66a1bc503f34b20ae561312057e46e077250e8a772b6881e6daf`,
imported from `Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_03/cutlass_01.glb`,
at scale0.22. The proof includes the actual NodePath/resource identity, not only
a catalog string. Buccaneer source bytes are pinned, but this normal default
mission uses Cutlass; this driver does not claim a Buccaneer flight.

## Opened native evidence

All six original PNGs in `native_final_captures/` were opened individually:

1. `01_main_menu.png`: actual Frontier start image in the normal menu.
2. `02_homebase.png`: real boarded team, pilot and actionable Start Mission.
3. `03_default_mission.png`: existing default mission after the normal handoff.
4. `04_lz_approach.png`: actual Ref03 Cutlass visible in flight over the mission
   map with the ordinary HUD; stage state `inbound`, progress77.6589%.
5. `05_deployed.png`: three actual Kenney unit models deployed at the LZ.
6. `06_go_movement.png`: normal selected-team Move plan/GO and unit movement.

No gross new inverted/missing/detached spacecraft geometry or start-transition
blocker was identified in these captures. The existing Homebase briefing-map
preview appears as a very shallow horizontal strip; this separate UI limitation
was reported without changing UI code. Standbilder do not establish complete
UI, art, campaign, combat or performance acceptance. Other Godot work ran
concurrently; elapsed times are test durations, not performance measurements.

Native JSON binds all six PNG SHA256 values and mission camera transforms/sizes,
plus the runtime/scene/model/driver source hashes. All bindings were compared
against disk after the run: **0 source and 0 capture mismatches**.

## Warnings and preserved logs

Both real menu transitions expose existing UID fallback warnings in
`scenes/meta/homebase_test_screen.tscn` at lines3/4, for `homebase_screen.gd` and
`homebase_team_drop_panel.gd`. Godot loads their text paths. They remain visible
in the unmodified logs; no clean-warning or clean-import claim is made here.

- First diagnostic: `headless_probe_20261101T223246657/`.
- Successful headless run: `headless_probe_r02_20261101T223550409/`.
- Successful native run: `native_final_20261101T224024538/` (stdout/stderr/engine).

## Reproduction

Use a fresh output basename on every invocation. Existing JSON files or capture
directories are rejected instead of overwritten. No historical evidence is
deleted. Run after project import, from the project directory:

```powershell
godot_console.exe --headless --path . --script res://scripts/tests/frontier_main_startup_verifier.gd -- --evidence-output=res://output/grafik_20261101/main_adoption_runtime/headless_NEW.json --startup-timeout-seconds=160
godot_console.exe --path . --script res://scripts/tests/frontier_main_startup_verifier.gd --rendering-driver vulkan --rendering-method forward_plus --resolution 1920x1080 -- --evidence-output=res://output/grafik_20261101/main_adoption_runtime/native_NEW.json --startup-timeout-seconds=170
```

The successful headless run precedes the final driver metadata/camera additions;
its ordinary gameplay-command route is unchanged. The final frozen driver was
compiled and exercised by the successful native run. Root's independent matrix
and integration/commit/Main status are recorded separately.
