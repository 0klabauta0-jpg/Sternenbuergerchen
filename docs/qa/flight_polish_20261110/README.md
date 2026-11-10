# Cutlass exhaust and display maneuver polish — 10.11.2026

Target: user's visible exhaust and smoother approach/landing/departure request.
Existing paired Cutlass 2D targets remain `docs/reports/assets/grafik-2026-11-01/08_cutlass_vorne_wimmel.png` and `09_cutlass_hinten_wimmel.png`; no new generated target. Active unchanged source: Ref03 Cutlass GLB; SHA-256 sources in source_hashes.json. Mesh, scale, nozzle layout and model materials unchanged. No gameplay timers, payload, travel owner or flight duration changed by this helper.

Changes: four actual nozzle locations now have a pale luminous core plus fading blue outer jet. Cylinder pulse keeps its mouth anchored instead of shifting the visible origin. The read-only maneuver sample holds horizontal position for the initial lift and final vertical descent; quintic easing has zero endpoint velocity/acceleration, with small transient pitch. Caller must apply the sampled presentation transform using existing source progress. These curves do not change the authority's route or speed.

Native evidence: before/after pairs landing, hover and cruise, same unchanged model, camera (10,8,-13), orthographic12.5, 1100x760, ambient0.65, sun1.4, OpenGL Compatibility / RTX4070TiSUPER. All six images opened and inspected. Landing pair correctly identical and has no active exhaust. Hover/cruise after shows a clearer pale core with softer blue edge attached to all four nozzle mouths; no opaque long cone or detached source. The fixture's plain pad is a rendering test, not the actual authored base scene. Images are native imported geometry, not concepts. Reverse-facing fixed engines remain reverse-facing; no invented VTOL nozzle or source-model articulation has been added. Actual base/mission integration and perceived timing require their separate native check.

Verification: new verifier failed6/6 on the old code, then passed412/0. It tests actual instantiated geometry, all eight mouth anchors under pulse, lift-before-forward motion, final vertical settle, and100 sampled points per direction for continuity/monotonic route. Existing `playtest_20261105_flight_grid_verifier.gd` passed21/0, including input payload immutability, grounded exhaust shutdown, unknown-phase suppression and service-drone anchor restoration. New native probe completed without script/shader/runtime errors. This is bounded graphics evidence; no overall frame-rate, subjective art or release acceptance.

Reproduce:
- `godot_console.exe --headless --path . --script scripts/tests/playtest_flight_polish_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/playtest_20261105_flight_grid_verifier.gd`
- `godot_console.exe --path . --rendering-method gl_compatibility --script scripts/tests/playtest_flight_native_probe.gd` (after-only unless documented baseline script exists).
