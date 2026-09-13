# N3 Ground / Equipment / Geier — binding schema v3

Only SimulationRoot mutates state. Existing v2 commands/fields stay. X/Z arrays, one active map, unique request_id and normal host/crew ownership. v1 and v2 saves validate against frozen legacy validators before migration. Existing career/items/reservations/receipts persist.

## Regions, landmarks and navigation

Existing base/station/space positions stay. Rust half-bound grows to480; existing shuttle[-210,180], satellite[145,-125] stay. Additional `mining_site`[-300,-210], `derelict`[310,250].

- bunker_surface half320: shuttle[-65,70], bunker_entry[0,12], aa_turret[28,-12], surface_cache[-34,-15]. Entry is an open surface bunker lobby and lift to the separate depths map. Ground approach from shuttle remains open. AA fires12 damage/3s at airborne ships within100m until destroyed. Distant landing and approach on foot remain possible.
- bunker_depths half64: elevator[0,36], bunker_cache[-26,-8], bunker_terminal[26,-8]. Walkable central hall x[-8,8],z[-48,48], west room x[-40,-8],z[-24,24], east room x[8,40],z[-24,24]. Doors at[-8,0]/[8,0]; the core routes room transitions through those openings. No shuttle underground. `use_elevator` returns to the surface entry. Rendering must leave these door passages open.
- distribution half400: shuttle[-110,120], market[-25,20], distribution_cache[45,-35], distribution_wreck[90,15]. Large depot plus ground guards.
- tradepost half200: shuttle[-45,50], market[0,0], tradepost_cache[150,-120]. Small owned outpost; no hostile guards. Trade uses the same economy as station.

`Catalog.landmarks`, `bounds`, `ground_enemies(region)`, `resource_sites()`, `skill_effects(unit)` are authoritative data helpers. Model/presentation height is world-only.

Gather approach offsets from landmark root: +z8.5m for mining_site/derelict/distribution_wreck, +z3.2m for other resource sites. Keep the front of those models clear; root IDs/positions stay fixed. Elevator uses centre. Surface and underground navigation uses the shared obstacle rectangles; additional ground-unit/ship collision avoidance is outside this step.

## Snapshot additions

- crew gains `health`0..100, `respawn_remaining`0..20, `attack_target`String, `attack_cooldown`float; equipment gains `armor`=""|"armor". assignment also `gather`|`downed`.
- `ground:{enemies:{region:{id:{id,name,kind,position,target,health,max_health,cooldown,defeated}}},activity:{active,unit_id,site_id,remaining,total,phase}}`. Enemy kind `guard` or `aa`; corpses remain defeated, no duplicate rewards.
- `resources:{site_id:{remaining:int}}` persists all finite sites across maps. `activity.phase` idle|walking|working. Resource outputs enter cargo, except underground finds enter inventory. Completion never exceeds capacity; occupied capacity is rechecked. Cancellation yields nothing and depletes nothing.
- `rental:{active:bool,remaining:float,expired:bool}`; ship gains `model`="cutlass"|"vulture", `name`="Entersäbel"|"Geier". Rental900 credits at station,1200 unpaused simulation seconds; capacity40 and 3x derelict yield versus capacity12 Entersäbel. No purchase. Expiry ends bonuses but preserves cargo and active ship until safe return at base/station; then cargo unloads to base inventory before capacity resets. Manual return at base/station uses same safe handover.

## Commands

- Existing `equip {unit_id,item:"armor"}` consumes actual basis stock and enables35% incoming ground damage reduction; helmet item adds5%, max40%. Craft armor at tier1:3scrap+2parts,10s,min tech2. Buy220/sell110 at a market.
- `gather {unit_id,site_id}` starts owned idle worker walking to catalog site then timed extraction; `cancel_gather` requires worker owner. Sites: mining_site (ore,24 units,8s,base yield3); derelict (alloy,18,10s,2); surface_cache(parts,4,5s,2); bunker_cache(alloy,8,5s,2); bunker_terminal(parts,6,5s,2); distribution_cache(alloy,12,6s,3); distribution_wreck(scrap,24,8s,4); tradepost_cache(parts,6,5s,2). ore buy55/sell35; alloy buy160/sell120. Mining/derelict require their own identified radar contact; original `salvage` remains usable after Blackbox, consuming original wreck_remaining to zero.
- `rent_ship {ship_id:"vulture"}` Host at station; `return_rental {}` Host at base/station; no buy_ship command.
- `attack {unit_id,target_id}` owned conscious idle crew; empty target stops. Core moves into24m range and shoots every1s, damage10+2*gunnery. Enemy guards fire8damage/2s within22m, AA fires12/3s within30m; stationary guard anchors. Catalog obstacle rectangles block direct ground gunfire. Guard health45, AA health90. Enemy defeat pays once25credits (AA75).
- `use_elevator {}` Host; all conscious crew must be within8m of bunker_entry/elevator and no active job/flight/travel. Descends surface->depths or ascends depths->surface, preserving parked shuttle position. Intermap travel from depths rejected.
- Existing travel adds bunker_surface,distribution,tradepost. Host only; cannot depart with downed crew or active gathering. Launch/land/ship_move also work on bunker_surface, distribution and tradepost; radar remains rust-only. AA attacks actual airborne ships.

## Effects, injury, persistence

Tech gates recipes as before; gathering duration=base/(1+0.1*tech); equipped toolkit gives another20% speed, cutter another35%. Pilot gives local/space speed multiplier1+0.04*pilot (nominal42/36). Gunnery gives ground shot10+2*skill and turret damage7+skill. Catalog.skill_effects keys: ground_damage, turret_damage, flight_multiplier, gather_multiplier, armor_reduction (0..0.4), tech_level. Catalog.obstacles returns {id:{center:[x,z],size:[w,d]}}; navigation expands by0.6m, world renders the unexpanded dimensions. No passive XP claim.

At0health: cancel worker task (refund reserved crafting materials), stop attack/movement, assignment downed,20s respawn timer. Timer pauses and persists. On expiry unit restores100health beside current map arrival point (depths elevator); no permadeath/item loss. At base, conscious crew heal5health/s. No medical/evacuation career system beyond this first recovery rule.

Combat/gather/rental clocks advance only in authoritative simulation and freeze on pause. Enemy/resource depletion persists across visits and saves. Runtime network ownership is restored from the current session after loading.


## Core delivery and verified boundaries - 13.09.2026

Implemented in small authoritative modules: ground_catalog, ground_navigation, ground_state, ground_operations and ground_validator; SimulationRoot remains the only command/state gateway. Frozen legacy_catalog_v2 and legacy_validator_v2 preserve the old accepted format. stage_state uses that frozen catalog for v1 to v2 before v2 to v3 migration.

Fresh Godot4.6.2 headless evidence: tests/ground_stage_core_test.gd **151 checks, 0 failures**; tests/core_flow_test.gd **100, 0**; tests/next_stage_core_test.gd **67, 0**. The latter now expects schema3 and removes new inventory fields when constructing genuine v1-format fixtures. Previous assertions remain. output/ground-stage-core.json records the new core result. New tests use user://n3-* saves only.

Verified real command/time route: craft/equip armor; actual guard hit8 to5.2; attack/walk through doors; hostile surface/AA elimination and one-time bounty; underground lift both ways; finite underground finds; wound/movement/travel rejection, paused20s recovery and reload; AA airborne range and safe rescue; two12-ore freight tours yield1020 credits and fund900 rental; actual6-alloy Geier output; expiry away from dock preserves18 cargo; safe handover retains every item; new markets and distant owned/guest gathering; per-unit combat ownership; persistent rental receipt; v2 reserved-work migration; malformed v3 armor/health/resources/enemies/rental/activity/void/flight state rejected. All old v1 and orbital tests remain green.

This is a small deterministic combat/economy step. Guards are stationary anchors, not tactical AI; health recovery has no permanent injury or medical skill progression. Obstacle navigation and line-of-fire blocking follow Catalog rectangles, with0.6m clearance; visual rock clutter outside those rectangles and unit/ship separation are not physical blockers. Landing sites remain freely selected with core ground clearance checks. Only the active map advances hostile shooting. Resource stocks do not respawn. Rental duration is simulation time and pauses with the session. Resource values are a playable initial balance, not a human playtest result. Final product-window and real network acceptance belong to the integration owner.

Additional current-v3 regression acceptance: existing `tests/product_flow_test.gd` **63/63** and `tests/control_window_test.gd` **13/13** passed in actual Godot OpenGL windows without test changes. `tests/save_lifecycle_run.ps1` completed four independent real product launches, **10/10**; only its historical v1 fixture strips new v3 fields/items/blueprint and its restore assertion now expects schema3. Lifecycle evidence: `C:/Users/bjoer/AppData/Local/Temp/sternenbuergerchen-lifecycle-n2-af4de931dbe94e59b49b8783da8c43a9/result.json`. These are technical regressions, not human usability/play-fun validation. No normal campaign was used.
