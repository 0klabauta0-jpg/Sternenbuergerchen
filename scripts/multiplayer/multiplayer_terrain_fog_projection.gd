extends RefCounted
## Pure, team-scoped transport projection of the existing FogOfWarSystem.
const MODE = preload("res://scripts/core/fog_of_war_mode_contract.gd")
const SCHEMA := "multiplayer.terrain_fog.v1"

static func project(owner: Dictionary) -> Dictionary:
	var knowledge: Dictionary = owner.get("terrain_knowledge", {})
	var result: Dictionary = {"schema":SCHEMA,"team_id":owner.get("team_id",""),"mode":owner.get("mode",""),
		"visibility_revision":owner.get("visibility_revision",0),
		"terrain_knowledge":{"known_all":knowledge.get("known_all",false),
			"unknown_policy":knowledge.get("unknown_policy",""),
			"explored_tile_ids":PackedStringArray(knowledge.get("explored_tile_ids",[])),
			"visible_tile_ids":PackedStringArray(knowledge.get("visible_tile_ids",[]))}}
	var delta: Dictionary = owner.get("visibility_delta",{})
	var changed: Array = delta.get("changed_tiles",[])
	result["delta_complete"] = not delta.is_empty() and not delta.get("full_scan",true) and changed.size() <= 4096
	result["changed_tile_ids"] = PackedStringArray()
	if result.delta_complete:
		for entry: Dictionary in changed: result.changed_tile_ids.append(String(entry.tile_id))
	return result

static func validate(value: Variant, team: String) -> bool:
	if not value is Dictionary or value.get("schema") != SCHEMA or value.get("team_id") != team or team.is_empty(): return false
	var mode = value.get("mode")
	if not mode is String or mode not in MODE.VALID_MODES: return false
	if not value.get("visibility_revision") is int or value.visibility_revision < 0: return false
	if not value.get("terrain_knowledge") is Dictionary: return false
	var knowledge: Dictionary = value.terrain_knowledge
	var canonical: Dictionary = MODE.normalize_team_state({"mode":mode,"team_id":team}).terrain_knowledge
	if not knowledge.get("known_all") is bool or knowledge.known_all != canonical.known_all or knowledge.get("unknown_policy") != canonical.unknown_policy: return false
	var sets: Dictionary = {}
	for key in ["explored_tile_ids","visible_tile_ids"]:
		var ids = knowledge.get(key)
		if typeof(ids) not in [TYPE_ARRAY,TYPE_PACKED_STRING_ARRAY] or ids.size() > 262144: return false
		var unique: Dictionary = {}
		for id in ids:
			if not id is String or id.is_empty() or id.length() > 96 or unique.has(id): return false
			unique[id] = true
		sets[key] = unique
	for id in sets.visible_tile_ids:
		if not sets.explored_tile_ids.has(id): return false
	if not value.get("delta_complete") is bool or typeof(value.get("changed_tile_ids")) not in [TYPE_ARRAY,TYPE_PACKED_STRING_ARRAY]: return false
	var changed = value.changed_tile_ids
	if changed.size() > 4096 or (not value.delta_complete and not changed.is_empty()): return false
	var seen: Dictionary = {}
	for id in changed:
		if not id is String or seen.has(id) or not sets.explored_tile_ids.has(id): return false
		seen[id] = true
	return true

static func for_view(snapshot: Dictionary, visible_ids: PackedStringArray) -> Dictionary:
	var result: Dictionary = snapshot.duplicate(true)
	result["current_visibility"] = {"visible_target_ids":visible_ids,"visible_event_ids":PackedStringArray()}
	if result.get("delta_complete",false):
		var changed: Array = []
		for id: String in result.changed_tile_ids: changed.append({"tile_id":id})
		result["visibility_delta"] = {"visibility_revision":result.visibility_revision,"changed_tiles":changed}
	return result
