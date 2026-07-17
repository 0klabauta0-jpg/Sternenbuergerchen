# TASK_N005 — Frontier Desert Outpost

## Goal / problem

Deliver the first coherent Frontier Desert Outpost landscape for the canonical ground mission without turning rendering into gameplay truth.

## Cause / value

The product needs a distinctive, readable visual pillar, but visual polish is unsafe if it silently changes navigation/LOS semantics or makes decorative props look like cover/blockers. The player path proved in N004 must remain semantically identical.

## Scope

- Add `data/landscape_style_catalog.json` with `frontier_desert_outpost_v1`.
- Add focused environment, surface, edge, static-prop, setpiece, and semantic-validation render modules while `TerrainMap3DView` remains composition root.
- Add existing `terrain_visual_theme_id` to `Ground_Mission01_32x32.json`.
- Use one desert surface family, one cliff family, 12–20 deterministic Nature Kit/curated props, station/factory landmark, warm industrial accents, sky, tonemapping, light distance fog, and subtle dust.

## Non-goals

- Do not change walkability, LOS, cover, height, objective geometry, authored enemy geometry, runtime authority, or import new assets before exhausting existing CC0 Kenney/Nature Kit assets.

## Relevant contracts / documents

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/tasks/TASK_N004_canonical_product_mission.md`
- terrain/map semantic contracts and existing asset locality/license checks
- `maps/Ground_Mission01_32x32.json`

## Acceptance criteria

- Gameplay/tile semantic hash is identical before and after visual work.
- The semantic validator and asset path/license/locality/map gates pass.
- Props neither float nor visually promise gameplay cover/blocking absent from tile truth.
- Fixed before/after captures at three zoom levels are manually readable.
- Draw calls, instances, VRAM, and p95 frame time are captured; p95 regresses no more than 10 percent.

## Affected areas

Landscape catalog, terrain render composition/modules, ground-map visual theme reference, asset validation, capture tooling, and performance evidence. No simulation semantics or tactical resolver.

## Verification

Capture baseline semantic hash and render metrics; run red/green semantic validation; run asset/map gates; take six fixed comparison views; manually inspect readability; compare performance against baseline; run `git diff --check`.

## Risks / open points

Asset references can be local but still have license or import issues. A pretty scene that obscures contacts, landmark direction, or true tile boundaries fails the player-facing goal even if hashes match.

## Dependency / exit gate

Requires the canonical product mission and integrated player path from N004. N007 cannot claim a release route until visual semantics, locality, performance limit, and manual capture gate all pass.
