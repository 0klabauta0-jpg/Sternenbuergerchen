# Polisa orbital trade station

## Goal / problem
User requests a compact independent orbital station inspired by old Port Olisar:
a new empty planet, connected exterior landing pads and accessible central hub,
left station navigation and separate infantry, armor, ship equipment, ships and
commodity services. Name follows the explicit spelling P-O-L-I-S-A: Polisa.

## Basis and contracts
Existing unmerged task/native-glut-maps-20261110, based on research integration
4e44521fd. Read PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
orbit_quantum_travel_contract, singleplayer_locations_jobs_contract,
graphics_reference_revision_contract and persistent location lifetime rules.
Gameplay remains in SimulationRoot-bound campaign/supply/travel/fleet owners.
No separate wallet, fleet, cargo, mission or travel truth in the station UI.

## Vertical implementation plan
1. Add Glut2 to the existing256x256 strategic definition and a free Polisa orbit
   destination. Existing sun/planet/moon/orbit IDs remain stable.
2. Add a96x96 peaceful space map with walkable connected decks, three landing
   pads, low hub walls and merchant kiosks. Reuse normal scenario, craft arrival,
   crew deployment, return-to-orbit and persistent-location lifecycle.
3. Add a station read-only screen over the actual active mission. Station services
   require the real landed craft and service interaction; selecting the menu
   alone never grants docking, stock, money or completion.
4. Existing purchases deliver to the actual landed craft container. Commodity
   sales use finite inventory and configured buy orders. Credits and idempotent
   request receipts remain in SingleplayerSupplyState.
5. Existing playable Cutlass/Buccaneer can be bought with explicit delivery to an
   existing free home pad. UI announces home delivery before purchase. Fleet
   owner creates the real craft; no relocation of an existing travelling ship.
6. Ship weapons/components without an existing functional equipment owner are
   explicitly unavailable with a reason. No decorative purchase with fake effects.
   Local pickup of newly bought ships is a later transport/equipment extension.

## Files and ownership
New station catalog/helper, station screen and visual builder, station map and
scenario. Existing locations/star_system/trade_offers definitions, adapter,
supply state/command contract, campaign free-visit gates, flow and the small
station-specific PackedScene visual hook (no frontier_place_props edit). Root owns terrain renderer/editor and
ABC authoring; those files are not changed by this station task.

## Acceptance / local verification
Reachable free destination without combat job; three orbit markers; real approach
and landed-only service gate; connected finite deck map; buying/selling updates
actual cargo/credits once; ship purchase rejects absent/full home pads and creates
one real fleet entry once. Older campaign saves/default definitions remain valid.
Only check-only and small pure/domain fixtures now. Larger native flow, cockpit/
landing/merchant interaction, save/continue, runtime visuals, full map and battle
regressions are explicitly deferred by user. No full release/FPS claim.

## Visual references / provenance
Port Olisar is a form reference, not imported mesh content. Native Polisa uses
own primitives and existing licensed local materials/assets, dark graphite,
off-white hulls and muted yellow pad markings in the current Kenney style.
Viewed web image search exterior/pad references and official Galactapedia image:
https://robertsspaceindustries.com/galactapedia/article/RvlgwMlEpr-port-olisar
https://static.robertsspaceindustries.com/galactapedia/upload/43778f99-9ce7-4bc5-8ab7-621a386625ea
https://starcitizen.tools/Category:Port_Olisar_images
No external copyrighted model is downloaded or used in-game.

## Risks / open points
Native station style and NPC/pad approach need later user review. Home delivery
is the intentionally limited ship purchase fulfillment; station pickup and an
actual ship component loadout owner remain open. Shop prices are first balance
values. Main integration and EXE packaging are not part of this subtask.


## Implemented candidate / 2026-11-11
- Glut 2, three selectable orbit markers and Polisa location, existing IDs retained.
- 96x96 authored sparse deck: 867 cells, 807 walkable, all walkable cells connected.
- Native cold-built open-pad hub, low concourse walls, technical rings, four counters.
- Read-only left station menu, landed service-use gate, infantry/armor purchase into
  actual craft inventory, existing authoritative equipment commands, commodity buy/sell,
  refuel and guarded return. A selected free visit does not require accepting a combat job.
- Functional Cutlass/Buccaneer purchases deliver to a free built home pad. No local
  new-ship pickup yet. Unknown ship equipment is explicitly unavailable.
- Necessary campaign capacity connection: existing BaseCapacityLayout projects pads3..6;
  200-credit sequential construction is gated by campaign pad2 progress and actual
  navigable clear footprint/person/path validation in BasePersonnel. Supply command
  receipts persist built capacity; restore projects layout without charging again.
- Campaign checkpoint validates larger fleets against canonical paid ship/pad receipts,
  preserving old one/two-craft saves and separating rescue progress from bought ships.

## Verification and exact integration scope
See docs/qa/polisa_station_20261111/source_manifest.json for all 24 source files,
SHA256, and paths. Domain fixture: 18 bounded assertions pass; compile.log contains
15 changed GDScript check-only exits0. map_data.json records deck connectivity.
These are domain/cold-scene checks, not a native travel, shop or equipment acceptance.
No commits/push by this agent. Root owns integration and native visual inspection.
