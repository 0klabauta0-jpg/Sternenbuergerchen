# Ref03 main adoption package

The user explicitly requested adoption of the latest Astra ships as starting graphics. The raw Ref03 candidate manifest and its historical review status remain byte unchanged; this separate manifest describes the current integration decision and selected files. It does not claim exact reconstruction of the illustrations or a new artistic acceptance.

`data/frontier_ship_visual_catalog.json` is shared by the regular Dropship visual and the synthetic art preview. Cutlass is the normal Dropship visual; existing mission flight state, authority, phases, altitude and FoW remain outside this catalog. Buccaneer is an active visual/reference catalog entry and static preview model. No productive fighter render path or new fighter gameplay was introduced. The legacy craft mapping remains fallback if the adopted resource is unavailable.

Both GLBs are unchanged Ref03 bytes, .22 scale, Godot +Z forward, root yaw0, ground pivot Y0. Cutlass: 22496 triangles; Buccaneer: 19672; eight original materials each. Their 16m/11m lengths are stylized working dimensions. The new versioned gate carries the explicit <25000 budget and all original P04 pad/shell/fact checks; the historical <20000 test is untouched. It additionally tests exact hashes, source/imported bounds and materials, normal Cutlass identity, eight actual flight directions and legacy fallback.

Run from repository root:

```powershell
& $godot --headless --path . --script res://scripts/tests/frontier_main_ship_adoption_verifier.gd
python art/frontier_illustrated_20261101/ships/main_adoption/write_adoption_manifest.py
```

The separate gate evidence is `output/grafik_20261101/main_adoption/ships/adoption_check.json` and `adoption.log` (86/86, clean Exit0 at source freeze). Root performs normal native mission/menu checks and the final joint suite separately. Preview capture defaults are new `engine_main_adoption/after` and `main_adoption_after_capture.json`; `--capture-output=` and `--capture-report=` allow explicit separate targets. Historical P07 targets are rejected.

`ref03_current_120_paths.txt` is exactly the 120 hash-verified current source-manifest records (112 files, 6 dependencies, 2 exports); it does **not** contain the full ancestry. `staging_paths.txt` adds frozen manifests, actual Ref02 comparison baseline blends/GLBs/audits, common QA tools, reference images, current integration sources and the reproduction adapter. Stage the listed files only; no files were deleted. The unchanged original Ref03 manifest writer demands 269 protected ancestor artifacts, so it is not claimed to rebuild from this deliberately smaller set. `write_adoption_manifest.py` is the reproducible curated hash path instead.

The frozen builders and tools retain their original environment-specific commands and paths. To route their QA imports to the two unchanged bundled dependencies, launch Blender with `-P art/frontier_illustrated_20261101/ships/main_adoption/run_blender_tool.py -- --tool <repository-relative frozen script> -- <existing tool args>`. The adapter preserves the target script file location and bytes. `vendor/blender_asset_qa/SKILL_LICENSE_DECLARATION.md` preserves the original author/version and MIT declaration; no standalone license text was supplied with that local skill. This adoption did not rerun or alter Blender geometry; original independent audits and native imported geometry are retained evidence. Paint/sheet generation also needs Pillow/numpy; absolute old Blender/font commands may require selecting local executables.
