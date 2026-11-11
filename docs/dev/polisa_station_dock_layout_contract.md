# Polisa station dock layout: technical value descriptor

The pure helper scripts/mission/polisa_station_dock_layout.gd implements only the explicit offset schema agreed in SPACE_POLISA_LOCAL_DOCK_2026_11_12.md. build() returns a fresh Dictionary of values on every call, without SceneTree, camera, runtime, graphics, RNG, file or owner mutation.

Canonical fields: schema space_station_dock_layout.v1, revision polisa_glut2_dock_v1, body_id glut_2, area_id orbit_approach:glut_2, station_id polisa, target_id polisa_station_dock. Bounds512x256, coordinate_system offset_hex; anchor(256,124), station block[244,268)x[116,128), gate(256,133). No surface_location_id exists. These are game-grid values, not physical SC metres or R08 pad dimensions.

Build validates the existing OrbitApproachLayout identity/bounds, station containment and anchor, gate bounds and separation, and block/gate exclusion from the body mask and lower arrival band. It visits only the existing bounded body mask once, never a whole512x256 grid. Invalid upstream geometry rejects with ok=false/reason instead of returning a usable descriptor.

Callers cache this static result by area/revision. The helper is not a per-frame job, collision/Claims validator, docking authorization or station visit/pad owner. Root must later validate real actor footprint, current owner/revisions, gate/Claims, pilot/crew, existing visit/pad/fuel rules. UI may later render only the explicit target_id/revision supplied by its owner DTO. No caller or route is wired here.

Status: technical initial geometry only, no visual approval. The existing Polisa R08 location and live strategic station route remain unchanged. Six small geometry/value checks and one isolated compile are the complete evidence scope; native rendering, broad maps and gameplay acceptance remain open.
