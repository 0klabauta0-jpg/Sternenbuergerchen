extends RefCounted
## Pure definition normalization; status is held only in CampaignState.
const DISPLAY = preload("res://scripts/mission/campaign_display_catalog.gd")
static var _issuer_catalog:Dictionary={}
static var _briefings:Dictionary={}
static var _system:Dictionary={}
static var _job_definitions:Dictionary={}
static var _location_definitions:Dictionary={}

static func get_briefing(job_id:String, campaign:Dictionary={}, travel:Dictionary={})->Dictionary:
	if _briefings.is_empty():
		var raw:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/job_briefings.json"))
		if typeof(raw)==TYPE_DICTIONARY:_briefings=raw
		var raw_system:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/star_system.json"))
		if typeof(raw_system)==TYPE_DICTIONARY:_system=raw_system
		var raw_jobs:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/jobs.json"))
		if typeof(raw_jobs)==TYPE_DICTIONARY:_job_definitions=raw_jobs
		var raw_locations:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/locations.json"))
		if typeof(raw_locations)==TYPE_DICTIONARY:_location_definitions=raw_locations
	var result:Dictionary=Dictionary(_briefings.get(job_id,{})).duplicate(true)
	if result.is_empty():return result
	# A briefing is a readout of the same location/orbit chain as the star map.
	# Optional snapshots keep the actual runtime authoritative; catalogs only
	# support callers without a running campaign, such as content inspection.
	var jobs:Dictionary=_job_definitions if campaign.is_empty() else Dictionary(campaign.get("jobs",{}))
	var locations:Dictionary=_location_definitions if campaign.is_empty() else Dictionary(campaign.get("locations",{}))
	var system:Dictionary=_system if travel.is_empty() else travel
	var location_id:String=String(Dictionary(jobs.get(job_id,{})).get("location_id",""))
	var orbit_id:String=String(Dictionary(system.get("location_orbits",{})).get(location_id,""))
	var body_id:String=String(Dictionary(Dictionary(system.get("orbits",{})).get(orbit_id,{})).get("body_id",""))
	var bodies:Dictionary=system.get("bodies",{})
	var body:Dictionary=bodies.get(body_id,{})
	var parent:Dictionary=bodies.get(String(body.get("parent_id","")),{})
	var kind:String="Himmelskörper"
	if body.get("kind","")=="station":kind="Raumstation"
	elif body.get("parent_id","")=="sun":kind="Planet"
	elif parent.get("parent_id","")=="sun":kind="Mond"
	result.merge({"location_id":location_id,"orbit_id":orbit_id,"body_id":body_id,"body_name":DISPLAY.body_name(body_id,body),"body_kind":kind,"site_label":DISPLAY.location_name(location_id,Dictionary(locations.get(location_id,{})))},true)
	return result

static func get_issuer_for_job(job_id:String)->Dictionary:
	if _issuer_catalog.is_empty():
		var value:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/job_issuers.json"))
		if typeof(value)==TYPE_DICTIONARY:_issuer_catalog=value
	var issuer_id:String=String(Dictionary(_issuer_catalog.get("jobs",{})).get(job_id,""))
	return Dictionary(Dictionary(_issuer_catalog.get("issuers",{})).get(issuer_id,{})).duplicate(true)

static func normalize_job(raw: Dictionary, locations: Dictionary) -> Dictionary:
	var id: String = String(raw.get("id", raw.get("job_id", ""))).strip_edges()
	var location_id: String = String(raw.get("location_id", ""))
	var scenario_id: String = String(raw.get("scenario_id", "")).strip_edges()
	if id.is_empty() or String(raw.get("title", "")).strip_edges().is_empty() or not locations.has(location_id) or scenario_id.is_empty():
		return {}
	var raw_steps: Variant = raw.get("required_step_ids", [])
	if typeof(raw_steps) != TYPE_ARRAY or raw_steps.is_empty():
		return {}
	var steps: Array = []
	for step in raw_steps:
		if typeof(step) != TYPE_STRING or String(step).strip_edges().is_empty() or steps.has(step):
			return {}
		steps.append(step)
	var reward: Variant = raw.get("reward", {})
	if typeof(reward) != TYPE_DICTIONARY or not typeof(reward.get("credits", 0)) in [TYPE_INT, TYPE_FLOAT]:
		return {}
	var credits: float = float(reward.get("credits", 0))
	if not is_finite(credits) or credits < 0.0 or credits != floor(credits) or credits > 1000000.0:
		return {}
	var prerequisite := String(raw.get("prerequisite_job_id", ""))
	var blueprint := String(reward.get("blueprint_id", ""))
	if prerequisite == id or typeof(raw.get("home_upload", false)) != TYPE_BOOL:
		return {}
	return {"id": id, "title": String(raw.title), "description": String(raw.get("description", "")), "location_id": location_id, "scenario_id": scenario_id, "required_step_ids": steps, "prerequisite_job_id":prerequisite, "home_upload":bool(raw.get("home_upload", false)), "reward": {"credits": int(credits), "blueprint_id":blueprint}}
