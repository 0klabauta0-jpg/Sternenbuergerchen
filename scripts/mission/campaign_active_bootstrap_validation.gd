extends RefCounted
## Narrow checks available before runtime owners exist. The full world and
## mission validators must still succeed before any active state is published.
const HOME = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const START = preload("res://scripts/meta/campaign_start_configuration.gd")

static func validate(payload: Dictionary) -> Dictionary:
	if payload.size()!=2 or payload.get("schema")!="campaign_active_checkpoint.v1" or not payload.get("components") is Dictionary: return _bad("active_checkpoint_invalid")
	var data: Dictionary = payload.components
	if typeof(data.get("home_sha256"))!=TYPE_STRING or data.home_sha256.length()!=64 or data.home_sha256!=FileAccess.get_sha256(HOME.DEFAULT_PATH): return _bad("active_home_mismatch")
	var loaded: Dictionary = HOME.load_checkpoint()
	if not loaded.get("ok",false): return loaded
	var home: Dictionary = loaded.payload.duplicate(true)
	START._migrate_known_main_starter(home)
	if home.has("hex_tactical"): return _bad("home_hex_checkpoint_unsupported")
	var run: Dictionary = START.resolve_checkpoint_run_id(home,false)
	if not run.get("ok",false) or data.get("campaign_run_id")!=run.id or not data.get("identity") is Dictionary or not data.get("roster") is Array or not data.get("active_ids") is Array: return _bad("active_home_mismatch")
	if JSON.stringify(data.roster,"",true)!=JSON.stringify(home.roster,"",true): return _bad("active_roster_changed")
	var craft: String = data.identity.get("craft_id", "")
	var home_craft: Variant = home.get("craft")
	var base: Variant = data.get("base_personnel")
	if not home_craft is Dictionary or not home_craft.get("definition") is Dictionary or home_craft.definition.get("craft_id")!=craft or craft.is_empty() or not base is Dictionary or base.size()!=2 or base.get("version")!=1 or not base.get("units") is Dictionary: return _bad("active_base_personnel_invalid")
	var ids: Array = []
	for person in data.roster:
		if not person is Dictionary or typeof(person.get("unit_id"))!=TYPE_STRING or ids.has(person.unit_id): return _bad("active_roster_changed")
		ids.append(person.unit_id)
	ids.sort()
	var active: Array = data.active_ids.duplicate(); active.sort()
	if active!=ids or not active.has(data.get("pilot_id")) or base.units.size()!=ids.size(): return _bad("active_roster_changed")
	for id in ids:
		var person: Variant = base.units.get(id)
		if not person is Dictionary or person.size()!=6 or person.get("status")!="aboard" or person.get("craft_id")!=craft or person.get("bed_id")!="" or not person.get("position") is Array or person.position.size()!=2 or typeof(person.get("auto_rest_enabled"))!=TYPE_BOOL or typeof(person.get("rest_automatic"))!=TYPE_BOOL: return _bad("active_base_personnel_invalid")
		for axis in person.position:
			if typeof(axis) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(axis)): return _bad("active_base_personnel_invalid")
	return {"ok":true}

static func _bad(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}
