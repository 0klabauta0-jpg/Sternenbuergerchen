extends RefCounted
const Catalog=preload("res://scripts/core/legacy_catalog_v2.gd")
static func empty_encounter() -> Dictionary:
	return {"active":false,"status":"none","pending_destination":"","enemy":{},"turret_target":"","fire_cooldown":0.0,"enemy_cooldown":0.0,"escape_remaining":0.0}
static func extend(s: Dictionary, seed_value: int=-1) -> void:
	s.schema_version=2
	s.base={"workbench_tier":1}
	s.random_seed=seed_value if seed_value>=1 else randi_range(1,2147483646)
	s.inventory.helmet=0;s.cargo.helmet=0
	s.blueprints.append("helmet");s.blueprints.append("upgrade_workbench")
	s.ship.mode="landed";s.ship.position=Catalog.landmarks(s.region).shuttle.duplicate();s.ship.target=s.ship.position.duplicate()
	s.ship.roles={"pilot":"ida","gunner":"jaro"}
	for id: String in s.crew:
		s.crew[id].skills=Catalog.profiles()[id].skills.duplicate(true)
		s.crew[id].equipment=Catalog.profiles()[id].equipment.duplicate(true)
	s.discovery={"radar_scanned":false,"satellite_found":false,"signals":[]}
	s.encounter=empty_encounter()
	s.travel.kind="intermap";s.travel.encounter_decided=false;s.travel.encounter_roll=-1
static func migrate(payload: Variant) -> Variant:
	if not payload is Dictionary or payload.get("schema_version")!=1:return payload
	# Validate the old shape in the existing legacy validator before calling migration.
	var result: Dictionary=payload.duplicate(true)
	var s: Dictionary=result.state
	extend(s)
	result.schema_version=2
	if s.region=="rust" or s.contract.status in ["recovered","claimed"] or s.salvage.active:
		s.discovery.radar_scanned=true;s.discovery.satellite_found=true;s.discovery.signals=Catalog.radar_contacts()
		s.discovery.signals[0].identified=true;s.discovery.signals[0].kind="satellite";s.discovery.signals[0].label="Satellit Signal 07"
	if s.blueprints.has("cutter") or (s.work.active and s.work.recipe_id=="cutter"):s.base.workbench_tier=2
	if s.work.active:s.crew[s.work.unit_id].target=Catalog.interaction_point("base","workbench")
	if s.salvage.active:s.crew[s.salvage.unit_id].target=Catalog.interaction_point("rust","satellite")
	if s.travel.active:
		for id: String in s.crew:s.crew[id].target=Catalog.landmarks(s.region).shuttle.duplicate()
		# A journey already accepted in N1 keeps its original peaceful route.
		s.travel.encounter_decided=true;s.travel.encounter_roll=99
	return result
