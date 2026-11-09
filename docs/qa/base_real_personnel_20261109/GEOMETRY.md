# Original furnished rooms: navigation and geometry evidence

09/10 November 2026. Task 1 of BASE_REAL_PERSONNEL_2026_11_09_PLAN.

- Coarse 36x28 render map and original furnished model sources remain unchanged.
  `base_interior_navigation.json` stores a separate static 144x112 hex navigation
  grid (0.25 physical spacing, pixel half-size 16x8). Asset placements/scales stay
  unchanged. `BaseInteriorNavigation.layout()` returns fine actor/terminal/bed grids
  and derivative GLB paths with original source provenance.
- Doorway derivatives preserve furniture, plinths and all twelve material slots.
  `Assets/curated/base_access_20261109/build_doors.py` separates welded loose
  components and cuts only thin upright architectural components. It never applies
  booleans to the entire overlapping furnished mesh. Editable blend sources remain
  under source/.gdignore. Blender 5.1.1 was available; required operations were
  supported. No live Blender UI was used.
- Authoring tests original imported geometry once offline: cylinder occupancy
  radius0.18, height0.65 from y0.22, then exact capsule sweeps on all six-neighbor
  edges. Four unsafe destination cells are removed. No runtime mesh/physics query.
- Independent verifier reconstructs imported GLB trimesh collision independently
  and checks every route plus all 1,452 walkable neighbor edges around both
  structures. Result: 14/14 exact targets reachable, zero body crossings.
  This includes exterior doors, working points, two distinct bedside approaches,
  pads and service point. Furniture-filled pockets without a safe body route stay
  blocked; a free mesh bounding box is never treated as a walkable room.
- The native operator at visual scale0.35 has misleading raw T-pose width0.599.
  Actual skin deformation was sampled at32 phases of each idle/walk clip (64
  poses, all mesh vertices). Every posed horizontal radius <=0.18 and height<=0.65.
  Detailed values are in posed-visual-clearance.json. Body-bottom0.22 clears the
  furnished floor/plinth; this is a locomotion body oracle rather than a check of
  every foot contact or every possible animation interpolation.
- Mattress surface measured with imported-mesh downward ray: y0.4763. Sleep
  anchors are feet at z5.35, yaw -PI/2 with view roll PI/2, root y0.61 to keep the
  rotated shoulder silhouette above the mattress. The standing position remains
  the distinct reachable bedside grid. Sleep pose is visual projection only.
- TerrainRegistry remains the navigation truth. A derived AStar2D cache contains
  its walkable six-neighbor graph and rebuilds on registry revision. Measured
  build50.246ms, complete map load/registration/cache624.045ms,14 path requests
  0.030..0.514ms. Earlier generic GDScript A* requests took up to~1.4s for
  disconnected goals; the base-specific cache removes that recurring cost.
  These are bounded headless measurements, not general FPS acceptance.
- Blender asset QA: both derivatives and both original sources PASS, zero errors.
  Accepted source-style warnings: split vertices/material seams and hidden
  back-to-back faces in the assembled furnished models. No new degenerate,
  inverted, floating or coplanar-overlap errors remain. `mesh-qa.json` records
  per-object counts. The four material/wire review sheets were opened and
  inspected: room/furniture silhouettes and palettes remain recognizable;
  apertures are intentional. Sheets are Blender asset reviews, not native game
  screenshots or a user's style approval.
- Original-room regression:22 passed/0 failed, including literal original SHA256
  checks, derivative source hashes and campaign/skirmish provenance.

Reproduce headless with private APPDATA and BelowNormal process priority:

```
godot_console.exe --headless --path . --script scripts/tests/base_real_personnel_geometry_verifier.gd
godot_console.exe --headless --path . --script scripts/tests/base_personnel_visual_clearance_verifier.gd
godot_console.exe --headless --path . --script scripts/tests/base_original_rooms_restore_test.gd
```

The authoring generator is scripts/tools/build_base_interior_navigation.gd.
Rebuild candidates first with background Blender and build_doors.py, import the
new GLBs with headless Godot, then regenerate navigation and run the independent
verifiers. `geometry.json`, `mesh-qa.json`, `posed-visual-clearance.json` and
`original-room-restore.log` record this run. Human native visual acceptance stays
separate from these technical results.
