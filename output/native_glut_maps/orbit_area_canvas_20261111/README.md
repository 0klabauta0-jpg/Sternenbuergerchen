# Orbit area canvas — frozen, unwired candidate

New files only: scripts/ui/orbit_area_canvas.gd, docs/tasks/ORBIT_AREA_CANVAS_2026_11_11.md, this QA package. Source reading: Root DTO commit ff47d1c1e; existing Flight snapshot/SpaceAreaGrid/StrategicHexGrid/HexGrid/OrbitApproachLayout. Parent HEAD at start c5e43fa91. No existing product file, screen, provider, route, input router or owner was edited.

API: set_projection(snapshot, selected_craft_id='', body_visual={}); move_requested(craft_id:String,target_hex:Vector2i). Body visual accepts optional name and Color. Camera helpers are UI-only. Root remains responsible for authority, revisions, full footprint, collision, Claim, wing and movement validity. A body-free picked cell is not permission to move. No first-craft fallback, enemy invention, movement/pose owner, interpolation or tick exists.

Static child CanvasItem caches Grid/Body/Gates draw commands separately from ships/footprints. Pure Ship DTO updates neither rebuild Layout/mask nor invalidate the static layer. Camera, area, size and bodyvisual changes invalidate static commands. Visible offset ranges and adaptive stride keep grid samples <=5000; fit uses sparse dots, not 131072 full hexes. No process loop or SceneTree scan.

check.log: ORBIT_AREA_CANVAS_RESULT checks=10 failures=0 runtime_wired=false visual_acceptance=false. Actual Control component and actual shared geometry; synthetic DTO shaped exactly like ff47d1c1e. Tests cover absent selection, axial/plane/screen inverse, two-field signal and source immutability, deep copy, anchored zoom/pan, explicit recenter, same mask/gate/bounds, missing/foreign craft, static cache retention plus bounded LOD/no process, unavailable DTO. This is not a Root integration test or gameplay movement evidence.

compile.log: individual Godot4.6.2 --check-only, Exit0, banner only. Commands from worktree root:

```powershell
godot_console --headless --path . --script output/native_glut_maps/orbit_area_canvas_20261111/check.gd
godot_console --headless --path . --script scripts/ui/orbit_area_canvas.gd --check-only
```

Graphics status: native 2D component candidate. Existing StarMapCanvas palette and StarMapWorldView projected tilt are the 2D/3D source references; no new concept imagery, meshes or textures. The fixed top limb and gates come from the current orbital layout contract. No screenshot/rendering harness or native visual inspection was performed, so no aesthetic acceptance is claimed. Default user-data directory; fixture neither writes profiles/saves nor claims a profile canary. No GPU, mission, battle, broad matrix, commit or push. Future narrow Root-area provider/product wiring and native visual review remain open.
