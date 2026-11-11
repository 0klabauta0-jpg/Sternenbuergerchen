# Bounded location-view evidence

Run: Godot 4.6.2 --headless --path . --script output/native_glut_maps/parallel_location_view_20261111/view_fixture.gd
Result: LOCATION_VIEW_RESULT checks=44 failures=0; no SCRIPT ERROR.

Real Flow public APIs, focus/context/visibility/callback/departure/home-arrival functions and real StarMapScreen controls run against two lightweight fake location roots, fake Setup/Controller/Driver/runtime. Physics ticks prove hidden roots remain active. Actual approach orchestration runs, but heavy physical admission/transport helpers are spies. No real AI combat, rendering acceptance, boarding, travel state machine, purchasing, save/load or performance acceptance is implied.

Individual --check-only logs for meta_layer_flow.gd, star_map_screen.gd, star_map_canvas.gd and mission_tactical_sandbox_controller.gd contain only engine banner. Diff whitespace check passed. No GPU or broad suites run.
