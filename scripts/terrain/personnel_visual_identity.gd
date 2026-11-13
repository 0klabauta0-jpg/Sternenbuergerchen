extends RefCounted
## Authored appearance for existing portraits, never an identity/state owner.
const PORTRAITS = preload("res://scripts/meta/portrait_identity_catalog.gd")
const PALETTE = preload("res://shaders/personnel_identity_palette.gdshader")
const PALETTE_PATH := "res://data/personnel_appearance_palette.json"
const SOURCE_SKIN := "res://Assets/used/npc/animated_characters/skins/astroFemaleA.png"
static var _loaded := false
static var _palettes: Dictionary = {}
static var _aliases: Dictionary = {}
static var _materials: Dictionary = {}

static func _ensure_loaded() -> void:
	if _loaded: return
	_loaded = true
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(PALETTE_PATH))
	if not source is Dictionary: return
	var entries: Dictionary = source.get("entries", {})
	for portrait: Dictionary in PORTRAITS.load_catalog().get("entries", []):
		var id := String(portrait.id)
		if not entries.has(id): continue
		_palettes[id] = Dictionary(entries[id]).duplicate(true)
		_aliases[String(portrait.path)] = id
		for path in portrait.get("legacy_paths", []): _aliases[String(path)] = id

static func resolve(identity: Dictionary = {}, actor: Node = null) -> String:
	_ensure_loaded()
	var portrait_id := String(identity.get("portrait_id", ""))
	var path := String(identity.get("portrait_path", ""))
	if portrait_id.is_empty() and path.is_empty() and is_instance_valid(actor) and actor.has_method("get_portrait_path"):
		path = String(actor.call("get_portrait_path"))
	# Do not use the portrait UI fallback: an unknown identity must not silently
	# acquire portrait_001's appearance. Explicit canonical IDs take precedence.
	if not portrait_id.is_empty(): return portrait_id if _palettes.has(portrait_id) else ""
	return String(_aliases.get(path, ""))

static func material_for(appearance: String) -> ShaderMaterial:
	_ensure_loaded()
	if not _palettes.has(appearance): return null
	if not _materials.has(appearance):
		var material := ShaderMaterial.new()
		material.shader = PALETTE
		material.set_shader_parameter("skin_texture", load(SOURCE_SKIN))
		for field in ["skin", "hair", "cloth", "plate"]:
			material.set_shader_parameter(field + "_color", Color(String(_palettes[appearance][field])))
		_materials[appearance] = material
	return _materials[appearance] as ShaderMaterial

static func apply_to_model(model: Node3D, identity: Dictionary) -> bool:
	var appearance := resolve(identity)
	if String(model.get_meta("portrait_appearance", "uninitialized")) == appearance: return false
	var material := material_for(appearance)
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		# The original character UV is shared by the tactical FBX and base GLB.
		# Equipment/armor surfaces retain their own authored materials.
		if not String(mesh.name).to_lower().contains("character"): continue
		if not mesh.has_meta("identity_source_material"):
			mesh.set_meta("identity_source_material", {"material": mesh.material_override})
		mesh.material_override = material if material != null else mesh.get_meta("identity_source_material").material
	model.set_meta("portrait_appearance", appearance)
	return true
