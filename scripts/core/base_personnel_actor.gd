extends Node2D
## Runtime projection of one existing campaign roster identity. No health copy.
var unit_id: String = ""
var _simulation: WeakRef

func configure_equipment_source(simulation: Node) -> void:
	_simulation = weakref(simulation)

func get_personnel_loadout() -> Dictionary:
	var simulation: Node = _simulation.get_ref() if _simulation != null else null
	if simulation == null:
		return {"armor": "suit", "weapon_1": "none", "weapon_2": "none"}
	return simulation.call("get_personnel_loadout_state").call("get_loadout", unit_id)

func get_armor_id() -> String:
	return String(get_personnel_loadout().armor)

func get_weapon_1_id() -> String:
	return String(get_personnel_loadout().weapon_1)

func get_weapon_2_id() -> String:
	return String(get_personnel_loadout().weapon_2)

func get_unit_id() -> String:
	return unit_id
func get_team_id() -> String:
	return "homebase_local"
func get_vital_state() -> String:
	return "fit"
