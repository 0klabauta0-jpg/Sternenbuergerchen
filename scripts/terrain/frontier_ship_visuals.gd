extends RefCounted
## Shared visual identities only. Does not create units, flight or combat state.
const CATALOG_PATH: String = "res://data/frontier_ship_visual_catalog.json"
static var _catalog: Dictionary = {}

static func get_ship(asset_id: String) -> Dictionary:
	var canonical_id: String = asset_id.strip_edges().to_lower().trim_suffix(".glb")
	var ships: Dictionary = Dictionary(_read_catalog().get("ships",{}))
	return Dictionary(ships.get(canonical_id,{})).duplicate(true)

static func get_for_role(role: String) -> Dictionary:
	var roles: Dictionary = Dictionary(_read_catalog().get("roles",{}))
	return get_ship(String(roles.get(role.strip_edges().to_lower(),"")))

static func get_catalog_snapshot() -> Dictionary:
	return _read_catalog().duplicate(true)

static func _read_catalog() -> Dictionary:
	if not _catalog.is_empty():
		return _catalog
	var file: FileAccess = FileAccess.open(CATALOG_PATH,FileAccess.READ)
	if file==null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_catalog = Dictionary(parsed)
	return _catalog
