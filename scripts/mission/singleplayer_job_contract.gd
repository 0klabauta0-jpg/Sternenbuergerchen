extends RefCounted
## Pure definition normalization; status is held only in CampaignState.
static var _issuer_catalog:Dictionary={}
static var _briefings:Dictionary={}
static var _bodies:Dictionary={}

static func get_briefing(job_id:String)->Dictionary:
	if _briefings.is_empty():
		var raw:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/job_briefings.json"))
		if typeof(raw)==TYPE_DICTIONARY:_briefings=raw
		var system:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/star_system.json"))
		if typeof(system)==TYPE_DICTIONARY:_bodies=system.get("bodies",{})
	var result:Dictionary=Dictionary(_briefings.get(job_id,{})).duplicate(true)
	result["body_name"]=String(Dictionary(_bodies.get(String(result.get("body_id","")),{})).get("name",""))
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
