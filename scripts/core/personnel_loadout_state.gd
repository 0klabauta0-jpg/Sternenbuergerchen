class_name PersonnelLoadoutState
extends RefCounted
## Canonical personnel equipment. SimulationRoot owns mutations; UI/mission
## callers receive copies and fireteam data is only an export projection.

const LOADOUT = preload("res://scripts/command/loadout_contract.gd")

var _loadouts: Dictionary = {}
var _defaults: Dictionary = {}


func configure_roster(roster: Array) -> void:
	for entry: Dictionary in roster:
		var id: String = String(entry.get("unit_id", "")).strip_edges()
		if id.is_empty():
			continue
		_defaults[id] = LOADOUT.make_member_loadout(
			String(entry.get("armor", entry.get("armor_id", LOADOUT.DEFAULT_ARMOR_ID))),
			String(entry.get("weapon_1_id", entry.get("weapon_1", LOADOUT.DEFAULT_PRIMARY_WEAPON_ID))),
			String(entry.get("weapon_2_id", entry.get("weapon_2", LOADOUT.DEFAULT_SECONDARY_WEAPON_ID))))


func has_unit(unit_id: String) -> bool:
	return _loadouts.has(unit_id) or _defaults.has(unit_id)


func get_snapshot() -> Dictionary:
	return _loadouts.duplicate(true)


func restore_snapshot(loadouts: Dictionary) -> void:
	_loadouts.clear()
	for key in loadouts:
		var id: String = String(key).strip_edges()
		if not id.is_empty() and typeof(loadouts[key]) == TYPE_DICTIONARY:
			_loadouts[id] = LOADOUT.normalize_member_loadout(loadouts[key])


func get_loadout(unit_id: String, fallback: Dictionary = {}) -> Dictionary:
	if _loadouts.has(unit_id):
		return Dictionary(_loadouts[unit_id]).duplicate(true)
	if not fallback.is_empty():
		return LOADOUT.normalize_member_loadout(fallback)
	return Dictionary(_defaults.get(unit_id, LOADOUT.make_member_loadout("medium", "rifle", "none"))).duplicate(true)


func set_loadout(unit_id: String, loadout: Dictionary) -> void:
	var id: String = unit_id.strip_edges()
	if not id.is_empty():
		_loadouts[id] = LOADOUT.normalize_member_loadout(loadout)


func set_slot(unit_id: String, key: String, value: String) -> void:
	var loadout: Dictionary = get_loadout(unit_id)
	match key.strip_edges().to_lower():
		"armor", "kit":
			loadout.armor = LOADOUT.normalize_armor_id(value)
		"weapon_1", "primary":
			loadout.weapon_1 = LOADOUT.normalize_weapon_id(value, LOADOUT.DEFAULT_PRIMARY_WEAPON_ID)
		"weapon_2", "sidearm", "secondary":
			loadout.weapon_2 = LOADOUT.normalize_weapon_id(value, LOADOUT.DEFAULT_SECONDARY_WEAPON_ID)
		_:
			return
	set_loadout(unit_id, loadout)


func import_fireteam_loadouts(definitions: Array, members: Dictionary) -> void:
	for definition: Dictionary in definitions:
		var id: String = String(definition.get("id", "")).strip_edges().to_lower()
		var imported: Dictionary = Dictionary(definition.get("member_loadouts", {}))
		for unit_id in PackedStringArray(members.get(id, [])):
			if imported.has(unit_id):
				set_loadout(String(unit_id), Dictionary(imported[unit_id]))


func reconcile_context(defaults: Dictionary, definitions: Array, members: Dictionary, retained_unit_ids: PackedStringArray) -> void:
	for id in defaults:
		_defaults[id] = LOADOUT.normalize_member_loadout(defaults[id])
	var next: Dictionary = {}
	for id in retained_unit_ids:
		if _loadouts.has(id):
			next[id] = Dictionary(_loadouts[id]).duplicate(true)
	for definition: Dictionary in definitions:
		var fireteam_id: String = String(definition.get("id", "")).strip_edges().to_lower()
		var imported: Dictionary = Dictionary(definition.get("member_loadouts", {}))
		for member_id in PackedStringArray(members.get(fireteam_id, [])):
			var id: String = String(member_id).strip_edges()
			if id.is_empty():
				continue
			# Once equipped, the runtime owner wins over stale FOB/UI exports.
			# Definition equipment is imported only for a previously unknown slot.
			if _loadouts.has(id):
				next[id] = Dictionary(_loadouts[id]).duplicate(true)
			elif imported.has(id):
				next[id] = LOADOUT.normalize_member_loadout(imported[id])
			else:
				next[id] = get_loadout(id)
	_loadouts = next


func project_fireteam_definitions(definitions: Array, members: Dictionary) -> Array:
	var result: Array = []
	for source: Dictionary in definitions:
		var definition: Dictionary = source.duplicate(true)
		var id: String = String(definition.get("id", "")).strip_edges().to_lower()
		var unit_ids: PackedStringArray = PackedStringArray(members.get(id, []))
		var loadouts: Dictionary = {}
		for unit_id in unit_ids:
			loadouts[unit_id] = get_loadout(String(unit_id))
		definition["loadout"] = LOADOUT.normalize_armor_id(String(definition.get("loadout", "medium")))
		definition["member_unit_ids"] = unit_ids.duplicate()
		definition["member_loadouts"] = loadouts
		result.append(definition)
	return result
