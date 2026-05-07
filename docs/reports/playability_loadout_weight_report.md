# Loadout Weight Playability Report

## Summary
TASK_260 verifies that the loadout selector only exposes gameplay items, keeps decorative weapon models out of active selection, and treats `none` as an intentional empty weapon slot.

## Inventory Separation
- Playable IDs are owned by `WeaponData`: `smg`, `rifle`, `sniper`, `rocket_launcher`, `medictool`, and `none`.
- Visual-only IDs from `data/npc_unit_visual_mapping.json`, such as `compact_blaster`, `heavy_blaster`, `sniper_rifle`, and `medictool_blaster`, are not selector metadata IDs.
- `rocket_launcher` remains selectable because it is both a gameplay weapon ID and a visual loadout ID.

## Weight Findings
- `none` has zero weapon weight.
- Medium armor with `none`/`none` weighs less than medium armor with two SMGs.
- Heavy armor with a rocket launcher weighs more than the standard SMG loadout.
- FOB loadout status shows fireteam weight; the character overlay shows the same member weight.

## Mission Snapshot
- Units with `none`/`none` expose no active combat weapon.
- `SimulationRoot` omits active weapon/range fields for empty weapon slots.
- `TerrainMap3DView` treats empty weapon slots as intentional and does not attach hidden default blaster visuals.

## UI Findings
- The FOB loadout selector can preselect `none`.
- The empty slot hides preview art and carries an explicit empty-slot tooltip.
- Character overlay text names the empty slot as `Keine Waffe`.

## Manual Remainder
- Recheck the visual dropdown in a live build after adding a large unlock list.
- Revisit balance numbers after real weapon progression and inventory gating exist.
