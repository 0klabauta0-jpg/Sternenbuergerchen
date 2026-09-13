# N2 Rooms / Orbit — binding integration contract

All positions remain world X/Z arrays. No height input. Only the current region is rendered. Core owns all gameplay changes, including discovery and space combat.

## Snapshot schema 2 (additive to N1)

- Existing fields remain. Inventory/cargo gain `helmet`; crew gains `skills:{pilot,gunnery,tech}` and `equipment:{helmet:String,tool:String}`.
- `base:{workbench_tier:1|2}`. Work recipe `upgrade_workbench` reserves existing worker/material slots and raises tier on completion. Recipe dictionaries gain `tier`.
- `ship` additionally has `mode:landed|flying`, `position:[x,z]`, `target:[x,z]`, `roles:{pilot:"ida",gunner:"jaro"}`. When aboard, crew assignment is `aboard`, positions follow ship. Rust local launch first uses normal crew boarding; flight then moves planar at 42 units/s. Space ship speed36. Render Y is fixed, chosen by renderer.
- `discovery:{radar_scanned:bool,satellite_found:bool,signals:Array}`. Radar initially returns no contacts. After scanning: contacts `{id,position,identified:bool,label,kind}`. Before proximity identification `label="Unbekanntes Signal"`, `kind="unknown"`; satellite model/name is not in hidden snapshot contacts. Use `satellite_found` to hide the satellite mesh and interaction entirely. Proximity within30 units in flying ship identifies contacts.
- `encounter:{active:bool,status:none|active|won|escaped|rescued,pending_destination:String,enemy:Dictionary,turret_target:String,fire_cooldown:float,enemy_cooldown:float,escape_remaining:float}`. Enemy only exists on encounter: `{id:"pirate",name:"Freibeuter",model:"buccaneer",position,target,hull,max_hull}`. Pilot Ida belongs to Host; Jaro operates the turret (Host in Solo, guest in Koop). `fire_turret` toggles a firing order that shoots on cooldown while in range; empty target stops. Weak pirate can be defeated. `flee` starts timed withdrawal then continues original destination. Defeat rescues both crew and ship to base, with usable ship condition; no permanent losses.
- `travel` additionally has `kind:intermap|launch`, `encounter_decided:bool`, `encounter_roll:int (-1..99)`. A station-bound intermap journey rolls once at acceptance; `<35` triggers space after the flight transition. Roll and pending destination persist in save. Encounter victory/escape proceeds to original destination without another roll.

## Commands (all still require unique request_id)

- Existing N1 commands remain, with the deliberate new mission discovery and recipe-tier prerequisites.
- `launch {}`: Host only, rust, landed and no active work; crew walks to ship before flight.
- `ship_move {position:[x,z]}`: Host pilot, rust/space, flying; bounds checked.
- `radar_scan {}`: Host, airborne rust; reveals anonymous contacts.
- `land {}`: Host, airborne rust; lands at current ship location, crew exits beside hull.
- `upgrade_workbench {unit_id}`: Host, base; internally reserves an upgrade work recipe.
- `equip {unit_id,item}`: owned idle crew at base, actual inventory equipment consumed and previous equipment returned where applicable.
- `fire_turret {target_id:"pirate"|""}`: owned gunner Jaro during active space contact. Automatic cooldown shots while in range.
- `flee {}`: Host, active space contact, timed escape with original destination preserved.

## Final coordinates agreed with integration owner

Bounds half-width: base160, rust320, station80, space240.

Base rooms (`Catalog.rooms()`): quarters center[-10,-12], storage center[-10,3], workshop center[10,3], lounge center[8,-12], each approximately12x12, central corridor x0. Openings face central corridor. Main entrance to south. NPC start corridor[0,0]/[1,1]. Landmarks: bed_ida[-12,-14], bed_jaro[-8,-14], storage[-10,3], workbench[10,3], contracts[10,-14], kitchen[5,-12], shuttle[25,22], expansion_a[27,-12], expansion_b[27,3]. Workbench approach offset[0,1.3].

Rust shuttle[-210,180], satellite[145,-125], radar contacts at satellite and[-55,-175],[90,155]. Satellite approach offset[0,3.8]. Render anonymous radar markers only from snapshot, never derive identified content from marker location.

Station shuttle[0,28], market[-12,-8]; secondary visual wings allowed. Space starts player[-85,0], pirate[55,-25]. Orbit ship footprint and map scale are presentation details.

## Save compatibility

New files use schema2. Schema1 saves are migrated before strict validation: preserve career funds/items/receipts/contract/work progress, add catalog-based crew profiles and default gear, infer already visited/recovered mission discovery, and preserve old craft access for existing cutter blueprints/active cutter work by upgrading migrated workbench tier. Old active interaction targets move to new canonical locations without losing reserved materials. No normal user save is used in tests.

## Core delivery evidence — 13.09.2026

Implemented in `simulation_root.gd`, `orbit_operations.gd`, `stage_state.gd`, `catalog.gd`, `save_validator.gd`. Strict original v1 validation is kept in `legacy_validator_v1.gd` plus its frozen `legacy_catalog_v1.gd`; only then is a v1 payload migrated. This prevents accepting malformed legacy input just because migration adds defaults.

Fresh Godot4.6.2 checks:
- `tests/next_stage_core_test.gd`:67 checks,0 failures. Complete real command/time path for discovery, flight, landing, salvage, equipment, upgraded workbench; saved one-time RNG; combat/pilot/gunner permissions/pause/reload; victory/escape/rescue; v1 in-progress and paid-career migration, preserved rejected receipts.
- `tests/core_flow_test.gd`:100 checks,0 failures after deliberate adaptations to the accepted new player path. Added real launch/radar/ship_move/land preparation and upgrade before cutter, updated canonical coordinates and longer boarding. Existing economy, work reservations, cancellation, payout, save integrity and ownership assertions retained.

An optional constructor seed `RestartSimulation.new(seed:int)` makes the same production random sequence reproducible. Ordinary `.new()` uses a random initial seed. Initial seed1 gives first station roll71 (peaceful); seed3 gives13 (contact). Sampling first100 seeds yields35 encounters. Non-station travel never rolls. Tests use only separate `user://n2-*.json` files, never `campaign.json`.

Balance values:42units/s local rust flight,36 in space; pirate40hull,18units/s,5damage/2.5s within105; turret10damage/0.8s within125; flee7s; rescue ship50condition and both crew intact. Fire orders auto-repeat on cooldown until cancelled/resolved; feedback can derive visible shots from cooldown reset or damage change. There are no shot-event/shot-sequence snapshot fields.

Boundaries: walls and rooms remain renderer-defined open passages without navigation blockers. Hull uses existing ship.condition. Equipment changes real inventory/profile state; ground armor/combat is not introduced. Encounter victory/escape immediately arrives at the preserved station destination, while rescue immediately reaches base; the encounter result remains visible in snapshot. Root owns final window and two-process acceptance for the new controls.
