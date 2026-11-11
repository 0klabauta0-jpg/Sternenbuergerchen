# Orbit area UI seam â€” frozen narrow integration

Source base2f57968d8. Product scope ONLY scripts/ui/star_map_screen.gd and scripts/meta/meta_layer_flow.gd. Own task ORBIT_AREA_UI_SEAM_2026_11_11.md and this QA package. No Adapter/Travel/Root/Grid/data or existing Canvas edits; no live V2 catalog change.

Screen.configure retains its original two arguments and accepts optional third area_provider Callable. Flow._get_star_map_area_projection(craft_id) delegates to existing adapter get_space_area_projection(craft_id), if available; missing method, empty ID or non-Dictionary fails closed. Expected result is directly the Root get_space_area_snapshot DTO. The UI manufactures no actor, Flight, area identity, geometry permission or authority.

Explicit Fleetpicker selection supplies the Orbit UI craft ID and sends existing space_focus_craft. Default Fleetfocus never implicitly selects Orbit. Location service selection remains separate and unchanged. An exact matching local+tactical actor enables the Orbit button. System remains reachable. Area absence/lost actor falls back to System. Orbit ticks read only the narrow provider every0.1s while visible; System uses its existing coarse refresh. Availability rechecks occur after explicit selection/coarse route revision change rather than background Area polling. No per-frame full snapshots or Control rebuilding was added.

Canvas move intent enters existing _send('space_move') with exactly craft_id,target_hex,request_id. Request IDs have per-screen instance/session and sequence uniqueness. No UI Hull/Power/authority or additional command fields. Root evaluates all gameplay rules. Move completion refreshes only the narrow DTO.

check.log: ORBIT_AREA_UI_SEAM_RESULT checks=10 failures=0 real_gameplay_activation=false. Actual Screen and Canvas with controlled full/Area/Command Callables; actual Flow method in a subclass whose startup/process/exit are stubbed, and controlled missing/present AdapterAPI Nodes. Checks: no default focus fallback; explicit picker/focus command; valid local Canvas visibility; narrow-only visible tick; exact Move command; wrong craft/hidden screen; persistent System/no hidden Area polling; lost actor; missing API/empty selection; Flow chosen-ID delegation. The synthetic local actor is not proof of actual Root entry, pilot/crew, travel or simulation movement.

screen_compile.log and flow_compile.log are Godot4.6.2 individual --check-only, Exit0. Commands from worktree root:

```powershell
godot_console --headless --path . --script output/native_glut_maps/orbit_area_ui_seam_20261111/check.gd
godot_console --headless --path . --script scripts/ui/star_map_screen.gd --check-only
godot_console --headless --path . --script scripts/meta/meta_layer_flow.gd --check-only
```

Default user-data directory. No save/profile writes or canary claim; no native visual, GPU, mission, battle, broad matrix, aesthetic acceptance, commit or push. Parent subsequently authorized one selective UI-slice commit. The .gitattributes line168 warning '(feat:' was reported to Parent and resolved by Parent during its AP6 import; not changed by this slice. Parent/source must supply the actual narrow owner API and genuine local activation; this seam does not grant final gameplay activation. Hashmanifest records this exact scope and logs.
