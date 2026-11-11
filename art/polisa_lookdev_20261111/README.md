# Polisa lookdev R02

Separate visual candidate on task/native-glut-maps-20261110. The functional
station remains the owner's source. No productive map, runtime, UI, scene or
shop catalog was edited by this lookdev task. No commit or push.

## Result
The previously thin pads and wire-like hoops now sit on chamfered hulls and
three structural arms. A compact lower machinery body connects two segmented
engineering rings, their inner webs and axial service drums. The hall uses a
rear canopy/header, inset panels and an open front cutaway. Four counters keep
their exact original positions and footprint, with integrated displays. The
three pads retain their coordinates and dimensions, with large identification
numbers, flush landing marks, restrained cyan markers and exterior utility
blocks. Handrails sit outside the original narrow walking strips.

The palette separates warm off-white hulls, steel, blue-grey decks, dark
machinery, muted yellow identification and a little cyan emission. No new
lights, particles, collisions or per-frame loops are present. Primitive
geometry is combined into eight static mesh groups by material.

## Sources and reference status
Editable source: polisa_station_visual_candidate.gd. Private scene:
polisa_station_visual_candidate.tscn. The private map is
output/native_glut_maps/polisa_lookdev_candidate/polisa_station_candidate.json.
It differs from maps/polisa_station.json only in the visual PackedScene path.
The functional saved map remains exactly867 deck cells,807 walkable cells;
every tile record, marker, shop location and other root field is unchanged.

Port Olisar is a form reference only. The official Galactapedia picture,
exterior side view and interior hub image were downloaded into the reference
subfolder and actually opened. Original URLs, SHA256 and usage status are in
references.json. No external model or texture was imported into the candidate.

- https://robertsspaceindustries.com/galactapedia/article/RvlgwMlEpr-port-olisar
- https://starcitizen.tools/File:Port_Olisar_Side.jpg
- https://starcitizen.tools/File:Port_Olisar_main_hub.png

## Native views and bounded evidence
Two final views were captured with Godot4.6.2, D3D12 Forward+,1280x720 and
actually opened. Overview: size54, yaw24,pitch50, same camera framing as the
original polisa_native_54.png. Hall: size26, same angles, focus at station0,0.

- output/native_glut_maps/polisa_lookdev_candidate/polisa_overview.png
- output/native_glut_maps/polisa_lookdev_candidate/polisa_hall.png

R02 reports7116 triangles,8 MeshInstance3D groups,0 collision nodes and0
dynamic lights. The actual mesh face count equals the build counter. Native
exit0, success marker present,0 errors and0 warnings. The hidden host remained
invisible. No native gameplay, travel, shop transaction, battle, benchmark or
large test matrix was run. Deck invariants are checked separately in
deck_invariants.json. The GPU window was explicitly returned to Root.

R01 images/logs are retained. That first native view exposed overly dark
primitive shading; R02 preserves primitive normals during batching and fixes
the ring face normals. R02 also adds restrained path handrails and wall detail.
There are two final viewpoints, not a further variant series.

## Visual assessment and limits
The native overview now reads as one supported orbital structure. Pad numbers,
yellow perimeter lines and the open hall are clear at game distance. The
front half of the ring assembly is visible below the hub; the hub hides its
upper parts at the current steep camera angle. The interior remains deliberately
compact, and the rear canopy leaves the service floor exposed. The material
style is a simplified Frontier/Kenney interpretation; it does not reproduce
Port Olisar. Aesthetic user approval, populated station views and the actual
travel/shop flow are still separate acceptance steps.

## Root integration
The candidate GD is standalone. Integrating it at
scripts/terrain/polisa_station_visual.gd can retain the original production
scene and map paths; no private map or art-path dependency is required.
Root owns that integration and the functional station checks.
