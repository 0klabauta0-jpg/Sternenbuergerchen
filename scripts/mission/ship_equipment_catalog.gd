extends RefCounted
## Shared canonical Warp catalog; no UI inference or mutable loadout state.
const PATH := "res://data/singleplayer/ship_equipment.json"
const ITEMS := ["warp_odyssey", "warp_hemera"]
static func known(item: String) -> bool: return ITEMS.has(item)
static func definition() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return raw if typeof(raw) == TYPE_DICTIONARY else {}
static func item(id: String) -> Dictionary: return Dictionary(definition().get("items", {}).get(id, {})).duplicate(true)
static func model(id: String) -> Dictionary: return Dictionary(definition().get("models", {}).get(id, {})).duplicate(true)
static func flight_profile(id: String) -> Dictionary:
	var data := definition()
	var model_data: Dictionary = data.get("models", {}).get(id, {})
	return Dictionary(model_data.get("flight_profile", data.get("flight_profiles", {}).get(id, {}))).duplicate(true)
static func compatible(model_id: String, slot: String, item_id: String) -> bool:
	var entry := model(model_id)
	return not entry.is_empty() and slot == String(entry.get("slot_id", "")) and Array(entry.get("compatible_item_ids", [])).has(item_id) and item(item_id).get("size") == entry.get("size")
static func multiplier(item_id: String) -> float:
	return float(item(item_id).get("quantum_duration_multiplier", 1.0))
