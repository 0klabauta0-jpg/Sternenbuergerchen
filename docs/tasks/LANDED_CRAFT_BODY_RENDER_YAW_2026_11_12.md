# Landed craft: bound ground profile equals rendered yaw

## Goal / cause
The existing candidate body getter uses camera fallback yaw, while real landed payloads carry flight_heading_origin and render at the actual incoming heading. The existing bound ground_body_profile must be forwarded to visuals and used exactly once, without adding the asset yaw offset again.

## Scope / boundaries
Only MissionTacticalSandboxController._build_mission_dropship_visual_entry, TerrainMap3DView._get_dropship_rotation_y_for_payload and new readonly get_landed_craft_body_projection(craft,payload,world_position). Own task/QA. No mesh, asset, scale, gameplay, path, deploy/pilot/admission producer, Root or Homebase builder edits. Parent/Source owns regular arrival binding; local station purchases already have a validated start profile. No stage/commit.

## Contract / acceptance
Actual parked states are landed/unloading/complete. Controller reads only the existing _field_landing_by_craft[craft_id].ground_body_profile and validates exact identity through polisa_ground_body_profile.read_bound. Accepted payload is detached. Renderer uses its already-total yaw_degrees directly only for those states; unbound/foreign/invalid profiles and inbound/outbound keep the existing heading calculation unchanged.

New landed getter requires matching actual craft/payload identity, parked state, finite position/used heading inputs and real existing asset bounds/scale/cellsize. It reads actual _get_dropship_rotation_y_for_payload, validates the resulting value profile through the existing contract and stores no position. An unbound regular arrival must have a real nondegenerate heading; no invented camera repair becomes a physics fact. A valid existing bound profile may already supply its current orientation. Source can call this getter once before explicit binding, preserving visual heading at that boundary.

## Sources / checks / risks
Read required project docs, graphics_reference_revision_contract.md and polisa_bound_ground_body_profile_contract.md. Small true method tests: prebind getter matches rendered heading; total bound yaw stable across camera and no double offset; foreign/invalid/airborne fallback unchanged; controller forwards owner profile detached only when parked. No GPU/native aesthetic claim, broad suite or EXE. Existing model catalog/identity and scale remain authoritative; cached assets may be read but no mesh edits. Regular arrival producer wiring remains outside this slice.

## Planned/current projection API boundary
get_landed_craft_body_projection accepts a planned/current landed-shaped payload, not proof of live runtime presence. The Source preflight can pass craft_id/model_id/state=landed, dropship_target_position=resolved_lz and flight_heading_origin from the existing _get_drop_staging_position_for_lz(resolved_lz,approach_angle), plus visual_asset_id only when actually supplied; world_position=resolved_lz. No live Actor/sequence phase is inspected, no temporary sequence write, angle copy or binding is performed. Only after the actual existing producer commit may Source bind the returned validated profile through its existing owner path.

## Frozen result
Base d1ba65920. Seven focused actual method checks7/0, both isolated individual compiles Exit0; real profile/source/canary guards true. Actual existing Cutlass GLB/catalog are read/imported privately. One explicit nonzero37-degree asset-offset test variant proves total bound73-degree yaw is not offset a second time; no source asset/catalog mutation. Producer remains unwired. Canonical QA files live directly under output/native_glut_maps/landed_craft_body_render_yaw_20261112; private copied projects beneath it are diagnostic run folders, not integration sources. No Runtime/Ground/Root/Homebase/Source-producer/asset/scale/path edits; no staging/commit.
