# Authored hex plateau/ramp integration

A/B/C remain512x256. Source and opened 2D reference hashes and data plots:
art/hex_terrain_composition_20261111. The frozen candidate files were copied
byte-identically to maps/ after root visual review. Source IDs/markers,
resources, buildings and108Cbridge cells remain. Ramp counts75/85/65,
five-cell-wide bands, level landings and curved side joins. Height rangesH0-H8.

Only narrow data authoring checks, a tiny ramp contract50/0 and a few native
art views were run; no large gameplay/performance/save regression. The editor
has its own19-case small fixture. Old B62/0 acceptance belongs to the previous
maps, not these new maps. Source:97e00aba1 ramp foundation plus this integration.
Version3 is now accepted by MapData's height-step reader (same0.75units).

Images are actual native Godot Forward+1280x720. Root opened A/B/C and the
C-corner closeup. A was captured before terrain-only low LOS-edge placeholder
suppression; bright diagnostic cubes there were found and fixed in the view.
B/C show the corrected omission. Ccorner uses the final authoritative midpoint
join. These are art checks, not complete gameplay or user style approval.

Intentional open points: full A/B/C unit travel, editor native controls/layout,
Save/Continue, whole-map prefill/memory after new composition, encounter/FoW
and performance acceptance are deferred by explicit user request.
