# Polisa ship equipment and local pickup boundary

Status: first functional Cutlass Warp slot implemented on the isolated taskbranch.
Odyssey C / Hemera A, finite cargo purchase, separate atomic installation,
actual per-craft travel-duration consumer and validated home checkpoint.
Quality D to A follows warp_drive_quality_contract.md. Weapon slots and local
ship pickup remain open. The earlier audits below record the implementation
boundary; they are not a claim of native end-to-end acceptance.

Small integrated checks:42 Warp/Store,14 Skirmish return,7 Root trust-boundary,
30 local-service regression; four Root-owned files freshly compile. Independent
review found and corrected JSON numeric roundtrip and return-lifecycle gaps.
Skirmish return after any drive-install history is explicitly blocked until
a receipt-consistent retrofit retirement path exists; untouched ships unregister
and refund normally. No large native/flight/save/performance acceptance yet.
Evidence: docs/qa/warp_drive_integration_20261111 and warp_drive_slot_20261111.

## Read-only follow-up audit / 2026-11-11
The smallest repeatedly reachable consumer is quantum travel duration:
SingleplayerSpaceTravelState currently advances and projects the configured
jump_duration_seconds. The bounded first-contact CampaignSpaceEncounter is
not a reliable post-Polisa upgrade consumer. Prefer one quantum-drive slot
before weapon hardpoints: dedicated per-craft equipment state, validated
catalog compatibility, duration frozen at jump start, same duration in the
travel snapshot, versioned home-checkpoint defaults/validation, then atomic
installation through the real station Supply/service path. This is a concrete
next-slice proposal, not an implemented slot or validated Erkul loadout.

Existing location runtime already shares missions, dropcards and people across
craft at a place; do not replace that architecture for local ship pickup.
Missing station-birth operations must initialize travel at surface/polisa,
allocate a real free pad, transfer pilot/crew uniquely, and authorize a return
without inventing a prior outbound home token. Checkpoints currently require
all craft at homebase/waiting_pad and reject active departures. Preserve that
restriction explicitly or implement and validate location-aware persistence;
do not label current away-state saves as supported. Coordinate Root/lifecycle
and checkpoint edits with the Tabletop AP5-8 owner before shared-file changes.

## Verified current ownership / 2026-11-11
SingleplayerFleetTravelState indexes per-craft SingleplayerSpaceTravelState;
it does not own ship hardpoints, components or combat. SingleplayerSupplyState
owns credits, finite stock/cargo, fuel and idempotent purchase receipts.
CampaignSpaceEncounter owns its bounded scripted encounter with fixed damage;
it has no equipped-item consumer. Existing craft definitions are identities and
transport definitions, not installed-component inventories. The Polisa UI only
projects the adapter and requests existing runtime commands.

The dated data/reference/erkul_cutlass_black_20261110.json is explicitly
reference_only_not_runtime_balance. It contains dimensions, speeds and thrust,
no validated compatible hardpoint or component catalog. No Erkul numbers become
runtime balance or installed parts by implication.

## Required next implementation boundary
A dedicated SimulationRoot-bound per-craft equipment owner must hold installed
slot/item identities and revision; FleetTravel remains a travel index. A shared
validated catalog must define canonical ship model, slot identity, compatible
item class/size and the actual chosen gameplay effects. A concrete existing
consumer must read its snapshot (travel or a deliberately revised space encounter)
before that component may be sold as usable equipment. Pick one functional slot
first; no inventory-only or visual-only sale advertised as a working component.
No tacit change to infantry Combat, MapData, LOS/FoW or tactical owners.

Supply remains credit/stock/cargo/receipt owner. Installation must validate real
landed craft and service access, compatible empty/replaced slot and finite item
quantity before committing; replaced items return to an authoritative container.
Repeated request IDs must not charge, consume or install twice. A stale craft,
airborne craft, invalid slot/item or failed effect application leaves both
inventory and equipment unchanged. UI stores selection only.

## Persistence and acceptance required before sale
Versioned equipment state must be included in campaign export/restore with
canonical craft references, slot uniqueness, compatible catalog IDs, and an
explicit legacy default. Invalid restored loadouts fail before state mutation.
Small owner tests must prove compatibility, stock/credits rollback, request
idempotence, replacement return, and the actual consumer effect before broader
native service/flight/save-continuation acceptance. Existing old saves remain
valid through the explicit default, not an invented external loadout.

## Local ship pickup: bounded implementation
Polisa now offers home delivery or actual local Cutlass/Buccaneer pickup. A real
uncrewed parked card/sequence, free compatible R08 pad, exact local visit, fresh
surface travel owner and versioned acquisition receipt are connected. A free
built home pad remains reserved. Explicit crew/pilot handoff updates both visits,
the base personnel transport binding and global pilot assignment before signals.
Boarding/flight guards still require real presence. Existing model projection
selects the actual Buccaneer asset. Home-only checkpoints validate old/new receipts.
Contract polisa_local_ship_pickup_contract.md and QA polisa_local_pickup_integration_20261111
define the tested boundary. Tiny vertical18/0, Flow23/0, Backend43/0; presence is
explicit_owner_endpoints_not_flight_motion, not native travel/save acceptance. No new vehicle models.

## Local pickup follow-up plan / 2026-11-11
Historical audit and now implemented task: [POLISA_LOCAL_SHIP_PICKUP_2026_11_11](../tasks/POLISA_LOCAL_SHIP_PICKUP_2026_11_11.md). Scope is existing Cutlass/Buccaneer only; no equipment/warp consumer changes. The following paragraphs preserve its original boundary and design rationale.

All seven polisa_pad_01..07 already exist as product MapData markers. Their canonical R08 source is art/polisa_r08_20261111/author_layout.py:39-42 and layout.json/layout_compiled.json: two M12x12, one L16x24, four S8x6. build_candidate.py:28-29,59-63 adds origin_plane [0,-70], snaps to a walkable hex and writes iso marker coordinates. Runtime reads each real MapData marker; local centers or visual transforms are not substitute gameplay positions. spawn_alpha/ship_return alias pad_01; current Tactical authored-pad getter uses that single alias. Missing functionality is shared local pad selection/reservation and a real parked craft, not missing art markers. Art reserve_envelope alone does not prove model compatibility.

Use existing Supply receipts/stock/fuel, local Tactical card/sequence/presence, Flow location/visit bindings and per-craft Travel owners. New craft needs authorized surface/polisa initialization and an explicit legitimate local departure/return identity. Do not fabricate a home outbound token. Service context currently depends on campaign departure destination and must recognize actual station birth. Local pilot/crew handoff must uniquely update source/target visits and use existing SimulationRoot embark effects; whole-location sortie enumeration is not a safe craft-membership substitute.

Keep checkpoints home-only. Proposed minimal delivery scope reserves an existing built free home return pad while acquiring on a distinct real local pad; this limitation must be agreed before implementation. Version purchase receipts with separate acquisition location/pad and home return pad; old home-delivery receipts retain explicit compatibility. Receipt history must not become pad-occupancy authority. No local pickup UI option before the complete authoritative handoff, retry/failure consistency and eventual home-checkpoint reconstruction work. No product edits or tests performed for this documentation follow-up.
