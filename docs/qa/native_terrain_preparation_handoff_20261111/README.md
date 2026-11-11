# Native preparation handoff probe

Status: Godot 4.6.2 headless `--check-only` PASS (exit 0); native acceptance
pending Root's exclusive GPU window. Two existing scene ext_resource UID
fallback warnings remain; no script/compile error. See check_only.log and
manifest.json for source SHA256 and exact limitation.

Entry: `res://scripts/tests/native_terrain_preparation_battle_test.gd`.
Require isolated APPDATA below `output/native_glut_maps`, an actual valid
post-A campaign checkpoint, and user args `-- continue-chapter 1x`.
The inherited native profile retains its real 512x256 B encounter and exact
frame accounting. This subclass adds readiness, static-resource identity and
loading screenshot/memory receipts without altering production sources.

Artifacts after a future successful native run:

- `output/native_glut_maps/B_terrain_preparation.json`: separate loading,
  memory-counter, handoff and camera receipts.
- `output/native_glut_maps/B_terrain_preparation.png`: actual incomplete
  preparation on the visible StarMap, captured after native post-draw.
- `output/native_glut_maps/B_battle_profile.json`: unchanged inherited real
  battle output. Archive before running because names are intentionally fixed.

The small per-frame observer reads only preparation and craft travel state,
direct mission/timer references and memory counters. It stores status changes,
not repeated full snapshots. Cache resource IDs are sorted and hashed once
per settled camera receipt. Maxima are allocator static bytes and renderer
reported video bytes; neither is a claim of full physical RAM/VRAM allocation.
This camera-travel integration run is not a clean isolated FPS comparison.

## Monitor correction after Root's first native run

Root reported 57 passed / 1 failed: all product/handoff/camera paths passed,
and the inherited profile recorded eight shots plus B guard clear. The sole
monitor failure reread the expiring fire-event ring at finish, when only six
events remained. The monitor now removes only the fixed generated
`B_battle_profile.json` before starting, after the same private APPDATA guard
as the base profile. Finish reads that newly written receipt and verifies
private user path, B map SHA256 and scale before using its maximum shot count.
Missing/early-aborted/stale results cannot pass this check. No product or
base-profile change; one parse at finish, no extra per-frame combat tracking.
The loading screenshot now starts at >=10% progress. Check-only passes again;
Root owns the archived first-run evidence and repeat native acceptance.


## Root final native acceptance — 2026-11-11

battle_verified:62/0, exit0, engineerrors0, two known Homebase UID fallback
warnings. Forward+ D3D12,1280x720, private fresh post-A profile, actual B512x256,
1x. Eight actual shots clear the guard. First measured movement1189.378ms
(first crew person travels >1worldunit), GO dispatch36.277ms. This is the
combined after state, not an isolated before/after FPS or navigation benchmark.

Loading transitions relative to launch: data4067ms, resource preparation8690ms,
ready24532ms. Real MissionSetup receives2161/2161; zero geometry builds,
restores>0. Three far camera targets and original focus keep the same cache
instance, context and6748 actual geometry resources. Scene nodes remain bounded.
No mission, mission timer or mission units are created while readiness is false.
The progress screenshot shows the genuine UI (refresh lags snapshot slightly).

Preparation allocator-static peak1282957219bytes and renderer-video counter
1108410368bytes; neither is total process RSS or dedicated physical VRAM.
The B cache accounts213117380bytes. Resource payload alone understates the
whole process: an incidental external working-set sample during battle was
about3.14GB, not a systematically sampled peak or acceptance budget.

Combat210frames: median14.359ms, p95 52.632ms, p99 74.711ms, max94.604ms.
These tails remain visible hitches. No claim of general smooth battles or
sustained FPS. See summary.json and the full B_battle_profile.zip.

First run57/1 read a six-entry expired event ring despite eight maximum shots;
second59/2 read a still-buffered JSON receipt. Both are preserved as
first_monitor_* / second_monitor_*. The inherited diagnostic writer now closes
before its subclass reads. This changes test receipt lifetime only. Final
native run uses the corrected probe. No product defects hidden by deleting
those failing runs. Stale load-result cleanup is separately covered18/0.
