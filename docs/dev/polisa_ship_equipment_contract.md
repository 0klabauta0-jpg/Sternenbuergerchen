# Polisa ship equipment: pending owner and consumer boundary

Status: concrete follow-up contract, not implemented ship equipment.

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

## Local ship pickup is separate and still open
Current Polisa purchases explicitly deliver Cutlass/Buccaneer to free built home
pads. Station pickup requires an authoritative location/pad-occupancy/arrival and
crew handoff, plus persistence for the newly local craft; it cannot be achieved
by changing UI text or a receipt destination. No local-pickup option is offered
until those owners support the full handoff. No new vehicle models in this scope.
