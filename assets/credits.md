# Curated model credits

The 10 environment `.glb` models under `assets/curated/` are original,
unmodified Kenney models, copied from the locally owned
**Kenney Game Assets All-in-1 3.4.0** collection. The astronaut is a derivative
assembled from the same collection's Animated Characters Bundle.
They are distributed under **Creative Commons Zero (CC0)**. Original package
licenses are reproduced under `assets/licenses/`. Source files were not changed.

Creator: **Kenney**, <https://kenney.nl/>. License: <https://creativecommons.org/publicdomain/zero/1.0/>.

| Original pack | Selected models | Use |
| --- | --- | --- |
| Space Station Kit | floor, wall, bed-single, door-single, computer, computer-wide | Cutaway base, beds, contract and trade consoles |
| Survival Kit | workbench | Crafting station |
| Space Kit | craft_cargoA | Shuttle fallback when the local Entersäbel derivative is absent |
| Blaster Kit | crate-small, crate-wide | Storage and market cargo |
| Animated Characters Bundle | characterMedium + astroMaleA skin + astroHelmet; idle, walk, interactStanding animations | White helmet crew Ida and Jaro |

Environment models are scaled and positioned by the game rendering layer. Terrain,
landing pad, satellite wreck, selection markers, and set dressing use original
procedural Godot geometry in `scripts/world/`. No previous runtime assets are copied.

`tools/prepare_crew.py` fits and attaches the original astro helmet to the medium
rig, assigns the white astro skin, corrects legacy FBX alpha, and retargets the
three original animations to the medium rest skeleton. The GLB embeds its skin;
the editable packed Blender derivative is in `crew/source/` (ignored by Godot).
The original Kenney source files remain unchanged. Ida and Jaro share this model,
with distinct name/selection colors in the renderer.

The renderer can additionally load the user's private prototype shuttle at
`assets/local/entersaebel.glb`; this is separate from the CC0 curated subset and
is not distributed with it. When absent, the original Kenney cargo shuttle is used.
