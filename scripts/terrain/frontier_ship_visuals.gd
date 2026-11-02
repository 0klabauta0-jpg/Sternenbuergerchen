extends RefCounted
## Shared visual identities only. Does not create units, flight or combat state.
const CATALOG_PATH: String = "res://data/frontier_ship_visual_catalog.json"
static var _catalog: Dictionary = {}
static var _ui_preview_cache: Dictionary = {}

static func get_ship(asset_id: String) -> Dictionary:
	var canonical_id: String = asset_id.strip_edges().to_lower().trim_suffix(".glb")
	var ships: Dictionary = Dictionary(_read_catalog().get("ships",{}))
	return Dictionary(ships.get(canonical_id,{})).duplicate(true)

static func get_for_role(role: String) -> Dictionary:
	var roles: Dictionary = Dictionary(_read_catalog().get("roles",{}))
	return get_ship(String(roles.get(role.strip_edges().to_lower(),"")))

static func get_catalog_snapshot() -> Dictionary:
	return _read_catalog().duplicate(true)

static func get_ui_identity(craft: Dictionary, role: String = "") -> Dictionary:
	# The declared visual identity or existing 3D role wins, never a name guess.
	var visual_id: String = String(craft.get("visual_asset_id", "")).strip_edges()
	if not visual_id.is_empty():
		return get_ship(visual_id)
	var craft_role: String = String(craft.get("craft_type", role)).strip_edges().to_lower()
	return get_for_role("dropship") if craft_role == "dropship" else {}

static func get_ui_preview_texture(craft: Dictionary, role: String = "") -> Texture2D:
	var identity: Dictionary = get_ui_identity(craft, role)
	var path: String = String(identity.get("ui_preview_path", "")).strip_edges()
	# A preview of another model revision must not impersonate this model.
	if path.is_empty() or String(identity.get("ui_preview_model_sha256", "")) != String(identity.get("sha256", "")):
		return null
	if _ui_preview_cache.has(path):
		return _ui_preview_cache[path] as Texture2D
	if not ResourceLoader.exists(path):
		return null
	var texture: Texture2D = load(path) as Texture2D
	if texture != null:
		_ui_preview_cache[path] = texture
	return texture

static func get_ui_display_name(craft: Dictionary, role: String = "") -> String:
	var original: String = String(craft.get("display_name", craft.get("craft_id", ""))).strip_edges()
	var identity: Dictionary = get_ui_identity(craft, role)
	var class_name_text: String = String(identity.get("display_name", "")).strip_edges()
	if class_name_text.is_empty():
		return original
	if original.is_empty() or original.to_lower() == "dropship":
		return class_name_text
	if original.to_lower().contains(class_name_text.to_lower()):
		return original
	if original.to_lower().begins_with("dropship "):
		var suffix: String = original.substr(9).strip_edges()
		if suffix.is_valid_int():
			return "%s %s" % [class_name_text, suffix]
	# Keep player names verbatim. This is a class caption, never a rename.
	return "%s · %s" % [class_name_text, original]

static func decorate_ui_title(title: String, craft: Dictionary, role: String = "") -> String:
	var original: String = String(craft.get("display_name", "")).strip_edges()
	var projected: String = get_ui_display_name(craft, role)
	if projected.is_empty() or projected == original:
		return title
	if not original.is_empty() and title.contains(original):
		return title.replace(original, projected)
	var class_name_text: String = String(get_ui_identity(craft, role).get("display_name", "")).strip_edges()
	if class_name_text.is_empty() or title.to_lower().contains(class_name_text.to_lower()):
		return title
	return "%s · %s" % [class_name_text, title] if not title.is_empty() else projected

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
