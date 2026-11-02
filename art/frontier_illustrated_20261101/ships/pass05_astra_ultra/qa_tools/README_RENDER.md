# Matched Blender review renderer

`render_matched.py` reads a `.blend` or `.glb`, copies evaluated meshes into a separate temporary scene, and writes PNGs plus `render_manifest.json`. It never saves or modifies the input file. It does not import into Godot.

```powershell
& 'C:/Users/bjoer/AppData/Local/Programs/Blender Foundation/Blender 5.2/blender.exe' -b --factory-startup --python-exit-code 1 -P 'art/frontier_illustrated_20261101/ships/pass05_astra_ultra/qa_tools/render_matched.py' -- --input 'Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/buccaneer_01.glb' --output-dir 'art/frontier_illustrated_20261101/ships/pass05_astra_ultra/buccaneer/review/matched' --target-length 11 --views front,rear,side,top,game --modes material,clay,random,wire
```

Use the identical arguments with the R02 GLB and another output directory for matched before/after images. Cutlass uses `--target-length 16`. `.blend` inputs select collection `LOW` by default; use `--collection name` or `--collection ALL` when necessary.

The fixed world-space target is `(0,0,length*0.15)`; no per-model auto-centering or auto-fitting conceals pivot/proportion changes. Near orthographic width is `length*1.65`; the default 1200x900 camera renders front/rear at elevation31 degrees and azimuth -38/-142 degrees (nose lower-right / upper-right). Blender front is -Y. Side and top views plus strict front/rear orthographic views are available. Override cameras with `--front-az`/`--front-el`, `--rear-az`/`--rear-el`, or `--game-az`/`--game-el` only if the same arguments are used for both candidates. `--ortho-factor` controls the shared framing.

`game` is a 512x512 image at elevation48 degrees, orthographic width `length*4.5`, representing about 110-150 pixels of ship width depending on geometry. This is a controlled readability image, not a claimed native Godot game screenshot. The manifest records every camera transform, projection, resolution, light specification and PNG hash.

Material and clay use EEVEE with Khronos PBR Neutral, exposure0/gamma1, three neutral area lights, gray floor and ambient world. `--engine CYCLES` is available for machines without EEVEE; never mix engines in a comparison. `--transparent` omits the floor, or `--no-floor` keeps only the world. Polygon material indices are preserved across temporary mode changes.

`random` assigns one deterministic color per mesh object. A consolidated GLB is therefore one color; use the editable BLEND for assembly QA. `wire` adds a temporary wireframe modifier over clay; GLB is triangulated, whereas an editable BLEND may show larger original polygons. Neither is a hidden-surface/x-ray proof. Source numerical QA and GLB data comparison are separate requirements.

Self-test: existing R02 Buccaneer GLB rendered in material/clay/random/wire from front/rear/side/top/game with Blender5.2.3 LTS. Images under `selftest_renderer/` are tooling tests of the old candidate, not new model deliverables.
