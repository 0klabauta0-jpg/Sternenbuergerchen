# Polisa lookdev candidate

Problem: The first native station is visually sparse: thin decks, wire-like
engineering loops, four small counters. User requests a recognisable station
with a structural central body, readable open hall and detailed exterior pads.

Scope: own GDScript primitive/ArrayMesh revision, private scene and map copy,
two small native views. Only art/polisa_lookdev_20261111 and
output/native_glut_maps/polisa_lookdev_candidate are owned here. No productive
station files, gameplay, terrain data, shop positions, landing pads or saved
walkable/blocker footprints may change. No new active collisions, per-frame
loops, particles, lights or imported meshes. Aim below12000 triangles and
80static mesh nodes. Root owns integration. No commit or push.

Basis: task/native-glut-maps-20261110, terrain package5204312c0 plus frozen
functional Polisa station source. Contracts: graphics_reference_revision,
terrain_truth_visual_audit, existing POLISA_STATION_2026_11_11 task.

Direction: off-white structural hull, dark deck insets and service bays,
muted yellow identification strips, restrained cyan marker emission.
Three unchanged pads on a solid technical spine; twin segmented engineering
hoops with inner webs beneath the deck. Four existing counters are integrated
into an open hall with partial rear canopy and perimeter ribs.

Acceptance:867saved deck cells/807walkable byte-equivalent tile data;
only the visual PackedScene path changes in the private map. Pad/shop
coordinates stay exact. Bounded structural count, no errors in native log,
two captures opened and judged. Visual acceptance by user remains open.
