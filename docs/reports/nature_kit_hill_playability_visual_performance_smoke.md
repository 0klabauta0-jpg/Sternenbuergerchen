# Nature Kit Hill Playability Visual Performance Smoke

## Summary
TASK_255 closes the Nature Kit terrain slice with a headless 32x32 smoke fixture. The gate covers import locality, editor-style Save/Load, 2.5D Nature cliffs/slopes/ground/props, FoW and tactical overlays, gameplay semantics and the existing render budget.

## Covered Assets
- Nature Kit Classic subset from `Assets/used/terrain/nature_kit_classic/`.
- Brown cliff/step height-edge visuals from TASK_252.
- Nature ground surface visuals from TASK_253.
- Tree, rock, bush, cactus and deco prop roles from TASK_254.

## Performance Gate
- Uses `data/performance_budget_contract.json`.
- Requires zero missing map asset mappings.
- Requires no texture fallback in the strict 3D primary path.
- Requires the 32x32 fixture render duration to stay below the project render budget.
- Keeps the curated smoke prop count small; larger biome maps should consider instancing, batching or stricter authoring budgets.

## Open Manual Items
- Final art/scale judgement for cliff corners, slope steps and vegetation silhouettes.
- Camera rotate/zoom/pitch readability in the editor and live mission.
- Longer play session with real unit movement around dense Nature props.
