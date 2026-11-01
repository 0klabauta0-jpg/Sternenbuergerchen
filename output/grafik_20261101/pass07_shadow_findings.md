# P07 isolated P06 road-edge diagnosis

Godot 4.6.2 official, Forward+/Vulkan, RTX 4070 Ti SUPER, 1600x900.
The preview's actual crew camera is identical in all 19 captures (orthographic
size 2.5, pitch12, origin12.15/4.04241/27.00666). The private unmodified P06
dressing snapshot SHA256 is
`86fc88c484dbe82e0f989edea7c0c58a38388ad70bf7e5c5b8410295ff1c74b0`.
Only diagnostic output files were changed for this investigation. Any normal
variants exist solely as in-memory replacement ArrayMeshes.

## Confirmed cause and minimal correction

The black lower road edge is caused by generated interpolated normals around
reversed very thin union-triangulation faces in the two lower road layers.
The three road meshes are completely planar at7/10/12mm; all vertices are finite.
The7mm layer contains20 reversed thin triangles, total area0.0000529189m²,
and the10mm layer20, area0.0000624680m². The12mm layer has no reversed triangles.
Default smooth normal generation spreads the conflicting normal directions
into adjacent larger triangles. Generated normals include-1Y in both lower
layers; the top layer is consistently+1Y.

Changing only the three planar layers' normal arrays to UP, retaining every
original vertex, removes the black band. Flat normal generation and consistent
winding plus UP produce the same pixels in the inspected strip. Key pairs were
actually opened: `pass07_shadow_baseline.png` and
`pass07_shadow_{up_only,flat_generated,up_and_winding}.png`.

For the visually located strip x430..1014/y650..682, the baseline has3388 dark
pixels (maximum RGB channel<90); each normal correction has0. Each changes4243
pixels by more than12 levels in at least one channel. This small ROI is a
diagnostic measurement, not a general visual acceptance metric.

Actual SSAO starts enabled (radius0.22, intensity1.35): the profile overrides
the view's earlier default. SSAO OFF, global directional shadows OFF, road casts
OFF, ground cast OFF, and combined road+ground/dressing+ground casts OFF each
change0 ROI pixels by more than12 levels. SSAO OFF changes the dark count only
to3377. These variants do not correct the band, so disabling shadows globally
would hide unrelated evidence without fixing the mesh-normal defect.

Orange rectangular areas beside the narrow connection are projected uncovered
ground. They persist under the lighting ablations; they are not upright orange
triangles or an abnormal vertex-Y range. Their shape is a separate path layout
issue handled by Root's entrance/approach revision.

## Reproduction and evidence

- `probe_pass07_shadow_layers.gd`: native19-variant experiment, frozen dressing
  replaced only in memory; no authoritative map state changes.
- `pass07_shadow_report.json`: actual renderer/environment/camera and triangle
  statistics; all19 PNG writes returnedOK, no script/runtime errors in logs.
- `probe_pass07_shadow_pixels.py` and `pass07_shadow_pixels.json`: pixel counts.
- `pass07_shadow_probe.log` / `pass07_shadow_probe.stderr.log`: native log.

Launch with `godot_console.exe --path <project> --script
res://output/grafik_20261101/probe_pass07_shadow_layers.gd --rendering-driver
vulkan --rendering-method forward_plus --resolution 1600x900`.
The normal-array experiment is diagnostic evidence; Root owns the production
road fix and its fresh integration tests/captures. No general art acceptance.
