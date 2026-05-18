# Loadout Playability Rules

## Playable Items
Playable loadout items are defined in `scripts/core/weapon_data.gd` and normalized through `scripts/command/loadout_contract.gd`. The current selectable weapon IDs are `smg`, `rifle`, `sniper`, `rail_gun`, `rocket_launcher`, `medictool`, and `none`. Sniper and rocket launcher previews must come from project-local `res://Assets/used/npc/...` assets; visual attachment loadouts remain display-only and must not replace the gameplay weapon IDs.

## Visual-Only Items
Visual loadout IDs in `data/npc_unit_visual_mapping.json` are not gameplay item IDs unless the same ID also exists in `WeaponData`. Decorative IDs such as `compact_blaster`, `heavy_blaster`, `sniper_rifle`, and `medictool_blaster` must not appear as active selector metadata.

## None Slot
`none` means `Keine Waffe`. It has no attack stats, no preview path, no visual loadout ID, and no weapon model attachment. A unit with `none` in both weapon slots must not expose an active combat weapon.

## Weight
Weight is calculated by `LoadoutModifierResolver` from armor plus both weapon slots. `none` contributes zero. Weight may influence the intended loadout modifiers, but it must not inject any hidden item or visual-only asset into gameplay state.

## Replication
Multiplayer and simulation snapshots may replicate gameplay loadout values such as active weapon and effective range only when an attack weapon exists. Preview paths, visual loadout IDs, socket names, and decorative model paths remain local/catalog data.
