# Landed craft bound profile / rendered yaw — frozen narrow seam

Base d1ba65920. Product edits ONLY MissionTacticalSandboxController._build_mission_dropship_visual_entry; TerrainMap3DView._get_dropship_rotation_y_for_payload plus new get_landed_craft_body_projection. Existing bound profile helper is read unchanged. No Homebase builder, Source Arrival/Deploy/Pilot/Admission bodies, mesh, asset, scale, gameplay path, Root, Ground or flight logic edits. No git stage/commit.

Parked enums verified: landed, unloading, complete. Controller validates the exact existing _field_landing_by_craft[craft_id].ground_body_profile through read_bound(card,...) and returns detached profile values only for parked states. Renderer validates payload identity using the same helper and uses its TOTAL yaw directly. It does not add root asset offset again. Missing/foreign/invalid profiles or inbound/outbound preserve all previous heading logic.

get_landed_craft_body_projection(craft,payload,world_position) returns actual existing asset bounds/model_scale/cell_size and the actual current _get_dropship_rotation_y_for_payload angle, validated as a value profile. It checks matching craft/model/asset identity, finite values and landed-shaped payload. Unbound input needs finite, nondegenerate real flight_heading_origin and dropship_target_position, avoiding a new camera-fallback physics binding. Existing valid bound profile can supply its already committed orientation. No position is stored or owner mutated.

This is a PLANNED/CURRENT geometry projection, never runtime presence/landing proof. Before _try_start_drop_sequence writes, Source may provide craft_id,model_id,state=landed,dropship_target_position=resolved_lz,flight_heading_origin=existing _get_drop_staging_position_for_lz(resolved_lz,approach_angle), optional real visual_asset_id; world_position=resolved_lz. It requires no live Actor/sequence phase, temporary sequence mutation or copied invented angle. Source binds only after its real producer commit.

Current canonical output.log/report.json: LANDED_CRAFT_RENDER_YAW_RESULT checks=7 failures=0 producer_wired=false native_visual_approved=false. Real Controller/3DView methods; startup suppressed only. Actual shipped Cutlass model is imported/read in a fresh private project, no scene render/GPU. Scenarios: actual catalog bounds/scale/current heading; no turn at binding; three parked states stable under camera plus simulated37-degree offset (bound73 stays73); legacy/foreign/invalid/inbound/outbound fallback; identity/nonfinite/airborne/degenerate getter rejection; detached real Controller projection; missing/foreign/flight profile omission. The simulated offset is a test-only returned-entry variant after reading the actual asset entry; no product asset/catalog edit.

controller_compile.log and renderer_compile.log: isolated individual --check-only Godot4.6.2 Exit0. report.json records private canary=true, real_profile_unchanged=true, source_unchanged=true and dependency/model hashes. No game main scene/autoload; existing isolation guard validates actual private user://. Reproduce the one narrow case:

```powershell
python output/native_glut_maps/landed_craft_body_render_yaw_20261112/run.py
```

Canonical integration files are the top-level check.gd/run.py/output.log/report.json/two_compile_logs/README/SHA256SUMS/.gdignore only. Nested private project/run folders are historical diagnostic copies, not product sources or manifests to stage. No native aesthetics, ship appearance/landing animation, broad suite, GPU battle/performance, end-to-end Source producer or final gameplay acceptance is claimed.
