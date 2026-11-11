# Quantum-drive slot: audit and implementation boundary

Status: audit/proposal only, no product code changed. Baseline b3f9ab26d on
native-glut-maps-20261110. Read PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES,
IMPLEMENTATION_STATUS, TASK_ROADMAP and polisa_ship_equipment_contract.

## Problem / usefulness
The station ship-equipment page has no functional component. Existing travel
is a real repeatable consumer: start_quantum -> _advance -> arrival, and its
snapshot exposes duration_seconds. Add exactly one quantum_drive slot without
inventing weapons, vehicles, an external loadout or station-born ships.

## Verified current sources
- core/singleplayer_space_travel_state.gd: configure reads star_system.json;
  get_snapshot and _advance both independently read jump_duration_seconds
  (currently 3.0). _start_quantum validates route/marker then mutates phase.
  apply_command deduplicates request signatures before mutation. No save API.
- core/singleplayer_fleet_travel_state.gd: register_craft creates per-craft owners,
  apply_command routes exact craft or advances all active owners; no equipment.
- core/simulation_root.gd: configure_singleplayer_owners registers four owners;
  request_singleplayer_command dispatches category, then emits committed signal.
  Infantry inventory_equip is existing synchronous two-owner precedent.
- core/singleplayer_supply_state.gd: credits/stock/cargo/receipts are authoritative.
  apply_command deduplicates first, writes receipts only on success. _station_buy_ship
  demonstrates a trusted synchronous fulfillment callback after every debit gate,
  before no-fail wallet/stock assignments; not a general rollback framework.
- mission/inventory_transfer_contract.gd: known() is a closed infantry/resource
  item list; arbitrary component IDs fail saved-container validation. Current craft
  container is craft:<id> with capacity48, base is base:homebase. Components must
  be explicitly recognized by shared catalog; never accepted as arbitrary strings.
- meta/singleplayer_runtime_adapter.gd: configure creates/restores campaign/supply;
  sync_crafts handles real fleet; request_operation checks actual service/park/pending
  gates and optional service_location_id; space_start_quantum currently supplies
  no trusted equipment effect. export_campaign_checkpoint exports schema_version1.
- meta/campaign_start_configuration.gd: Continue validates through checkpoint store
  before writing Flow roster/fleet; save_home_checkpoint rejects travel, mission,
  pending transfers/preparation and non-home/non-waiting_pad fleet, appends roster/
  fleet then stores atomically. This restriction stays.
- meta/campaign_checkpoint_store.gd: schema1 only, validates cloned campaign/supply/
  onboarding owners before fleet/cross-owner checks. Fleet IDs must match Supply
  fuel registrations; station ship receipts prove purchased models. Supply restore
  validates definitions, inventory, request signatures, recipe receipts then adopts.
  Additive polisa_* offers are already an explicit _compatible_definitions exception.
- Generic _build_homebase_aircraft_definition has craft_type but NO model_id.
  Do not treat a transport role or rendered ship as a verified canonical model.
- data/reference/erkul_cutlass_black_20261110.json is reference_only_not_runtime_balance;
  no quantum parts, slot sizes, compatible components, component prices or effects.

## Concrete proposed APIs (not implemented)
New core/singleplayer_ship_equipment_state.gd, SimulationRoot-bound RefCounted:
- configure(craft_definitions:Array, catalog:Dictionary) -> Dictionary
- register_craft(definition:Dictionary) -> Dictionary (idempotent same identity)
- get_snapshot(craft_id:String='') -> Dictionary, read-only
- prepare_install(craft_id, slot_id, item_id, expected_revision) -> Dictionary
- commit_prepared_install(prepared:Dictionary) -> Dictionary; recheck sealed owner
  revision/identity, no writes on failure, success publishes one prepared state.
- get_quantum_effect(craft_id:String) -> Dictionary (catalog-derived, no UI values)
- export_state() -> Dictionary; restore_state(data, craft_definitions, catalog)
  validates a temporary candidate and swaps only on complete success.

New mission/ship_equipment_catalog.gd + data/singleplayer/ship_equipment.json:
versioned exact model/slot/item compatibility and finite positive gameplay effect.
One slot_id quantum_drive, no weapon hardpoints. Reject unsupported model IDs;
unknown/generic legacy ships retain baseline travel, no guessed SC compatibility.
Internal baseline means no purchased component and existing configured duration,
NOT an invented free Star Citizen drive. Catalog sale entries require sourced
component/model fit and explicit approved game price/effect; fixture values are
injected test-only and must not leak into production catalog.

Command path proposal:
station_install_ship_component {craft_id, slot_id, item_id, source_container_id,
expected_equipment_revision, request_id, service_location_id:'polisa'}.
Purchase uses existing finite-stock buy into craft cargo, then explicit install.
No mandatory new install fee. UI displays both operations and actual fitted part.
Supply retains all item quantity ownership; Equipment holds installed identities
and revision only. Replaced item goes back to the same real craft cargo container.

## Atomic boundary and exact Root coordination request
Add optional fifth equipment owner to configure_singleplayer_owners, or one
configure_ship_equipment(owner) method to avoid changing existing call arity.
No new simulation tick/Tree scan. Root binds a trusted prepare/commit callable
in authority_context for the new Supply install operation; never accept a UI
Callable or UI-authored effect. Supply:
1. Replay/conflict lookup first; validate actual Polisa context, registered craft,
   approved catalog item, source==craft:<id>, finite quantity, replacement-space
   and equipment candidate. Derive returned item from owner, never UI payload.
2. Compute candidate inventory with new part removed and old part returned BEFORE
   first write; net capacity matters, including full cargo and same-item/no-op.
3. Owner commit validates revision/token and either rejects without mutation or
   performs exactly one no-fail installed-state swap. No signal, await or callback
   reentry. Supply then publishes already-computed quantities/revision/receipt using
   no-fail assignments. Root emits committed signal only after both owners finish.
Do not debit Supply then attempt an effect that can fail. If this narrow no-fail
commit cannot be guaranteed, use a staged transaction coordinator; no compensating
'refund' advertised as atomic. Authoritative Supply install receipt must contain
craft, slot, before/after item, source, quantities, equipment revision and request.
Cross-owner restore must prove installed state against these receipts.

Travel hook: on start_quantum ONLY, Root derives effect from bound equipment
owner for exact command craft and passes trusted effect in authority_context.
Travel validates finite positive effect before changing route/phase, freezes
_active_jump_duration_seconds (and optional component/revision provenance) at
jump start; _advance and get_snapshot read that same frozen value. Payload effect
fields are rejected/ignored, never authoritative. No read-per-tick equipment query.
Retry retains original duration; another ship/start never changes ongoing jump.
No equipment -> existing definition duration; old owner unit fixtures remain valid.

Root file belongs to Tabletop: ask that owner to apply only these registration,
trusted context and post-commit publication hooks after interface agreement. No
Root/Ground/Driver/Nav/Combat edits in this audit or without coordination.

## Versioned home-checkpoint boundary
Keep outer schema_version1 and home-only restrictions. Add explicit optional
ship_equipment subsection with schema_version1, catalog_version, revision and exact
craft->canonical model->quantum_drive installed IDs. Absent subsection is the ONLY
legacy default: generate baseline slots for validated fleet, no inventory item,
no debit and no external loadout claim. Present malformed/unknown version rejects,
never silently defaults. Reject unknown/missing/duplicate craft, slot duplication,
wrong canonical model/compatibility, forged revisions/effects or receipt mismatch.
Validator must validate equipment against normalized fleet and cloned Supply before
CampaignStart writes Flow state. Runtime creates/restores equipment before exposing
its snapshot/commands; sync_crafts registers genuinely new purchased fleet once.
New Supply receipts require explicit schema validation in restore_state; old real
buy/fabrication receipts stay accepted. Do not persist naked duration as equipment
truth; derive from current validated catalog, or reject incompatible catalog version.

## Intended files / non-goals
New owner/catalog/command helper + tiny tests; edits Supply, supply command contract,
inventory known-item catalog bridge, SpaceTravel, Adapter, CheckpointStore, Polisa UI
and shared catalog data. FleetTravel only if needed to bind/read effect (context
already forwards through, so likely zero source change). CampaignStart likely no
source edit because it forwards payload and pre-validates store. Root only approved
small hooks. No generic hardpoint system, station pickup, vehicle models, infantry
combat, away saving, broad test matrix, global status or commit/push.

## Acceptance / small local checks before later native testing
- Default/new and absent-section legacy save preserve existing jump behavior.
- Two craft can have different test-only drives; real start/advance/snapshot arrive
  at their own frozen duration; abort/restart/replay and invalid effect are bounded.
- Exact local service + compatibility required; pending/airborne/remote/stale intent
  deny with byte-equivalent inventory/equipment/credits/requests on every failure.
- Finite stock purchase, source consumption, replacement return, full-net-cargo,
  same-item operation, duplicate request and conflicting ID are proved.
- Valid JSON home checkpoint roundtrip; absent section legacy default; malformed
  versions, foreign craft, wrong model/slot/item, forged install receipts and
  cross-owner mismatch rejected before mutation. Existing saves remain readable.
- Targeted owner/consumer/validator fixtures and touched-script compile only.

## Concrete missing inputs / risks
Production sale is blocked on a trustworthy component catalog AND chosen game
price/effect. No approved part names/fit/sizes/effect/price exist in current source.
Existing three-second jump is game duration, not an Erkul performance figure.
A backend slice can be tested with injected fixture components; without real data
it must keep ship-equipment sale unavailable and must not claim a player upgrade.
Generic starting craft model identity must be explicitly normalized before offering
model-specific parts. Receipt tampering and atomic two-owner publication deserve
review. Home checkpoint size budget4MiB and schema1 compatibility remain enforced.


## Parent evidence update after audit (same day)
Parent independently verified normal Erkul browser DATA4.10.2-LIVE.12913470 and
is saving a dated reference: Cutlass Black stock Odyssey/Tarsus S2 C,
238314km/s; compatible Hemera/RSI S2 A,326114km/s; observed spools6.9s/6.2s.
Buccaneer stock Rush/ArcCorp S1 C,209236km/s is reference only for this slice.
This supersedes the missing Cutlass-component-source blocker above once the
reference is present in repository. Proposed production scope ONLY canonical
Cutlass Odyssey <-> Hemera. No inferred compatibility for generic transports,
Buccaneer, other models or components. Game multiplier explicitly simplifies
relative duration to238314/326114 (Odyssey1.0), not physical SC travel/spooling.
No engine-size or spool simulation added. Game price remains an explicit internal
balance decision, never attributed to Erkul.

Root must decide explicit canonical starting-craft migration to cutlass. If
approved, old Cutlass equipment defaults to documented stock Odyssey without a
cargo grant or charge; provenance initial_stock is distinct from paid install
receipt. Otherwise generic legacy baseline remains unsaleable. New purchased
cutlass definitions already carry model_id via station fulfillment. Former
current-source/no-components assertions describe pre-update repository evidence,
not a rejection of the parent's new dated browser finding.
