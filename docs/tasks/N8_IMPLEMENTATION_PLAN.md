# N8 Implementation Plan

> For agentic workers: use superpowers:executing-plans. Native execution authorized by user: „ja passt, leg los“.

Goal: implement docs/tasks/N8_HEIGHTS_SITES_ENERGY_DESIGN.md in working increments.
Architecture: one deterministic terrain source; stable shared site identity; authoritative infrastructure state using existing work transactions. Godot 4.6.2. Preserve N7 and existing saves, private assets, 2x8 team limits.

## Review focus
Terrain seam crossing; landing hull spanning a ramp; loaded active work during power shortage; duplicate blackbox claims across teams; two teams visiting different variants and returning.

## 1 Terrain and inhabited locations
- [ ] Create scripts/core/terrain_layout.gd: patches(region), height_at(region, Vector2), traversable(region,a,b), level_landing(region,Rect2).
- [ ] Test three elevations, ramp ascent, rejected cliff shortcut and uneven landing in tests/terrain_levels_test.gd; execute headless before and after implementation.
- [ ] Integrate ground navigation, landing, world terrain mesh and ray hit, static structures/props, crew/enemies/ship/markers. Existing snapshots retain planar coordinates; heights are derived from stable layout.
- [ ] Enrich base/bunker/depot composition from shared collision footprints. Capture native views and compare reference. Re-run navigation, product and flight checks; commit.

## 2 Site identities and mission variations
- [ ] Add SiteCatalog with four authored variants per seven mission families; preserve legacy IDs as variant one. Stable site key includes planet.
- [ ] Extend travel UI/state, save validation and TeamCampaign world ownership to site identity, with shared resources and one-time objective claims. Use deterministic layout transforms plus genuinely different terrain/access/site composition.
- [ ] Test same-site shared depletion, other-site independence, return/save/load, duplicate claims and each objective reachability; run real team processes; commit.

## 3 Energy and progression
- [ ] Add infrastructure catalog/state/validation and power budget; starter solar24, basic6, sender4, active work6/12, research6. Authoritative priorities pause work when short without recharging resources.
- [ ] Extend work recipes for solar and sender upgrades plus prerequisite research and one-time blueprint findings. Visible installed modules and actionable power view.
- [ ] Test initial playable path, shortage/resume, save/load active reservation, cancellation and repeated request id; native crafting path; commit.

## 4 Delivery
- [ ] One fresh final reviewer, regressions for findings, native sequential screenshots and exact tested build.
- [ ] Update acceptance/status/report with reference comparisons and actual limits; preserve N7 package, create N8 package and update private mobile report. Commit and push own branch.
