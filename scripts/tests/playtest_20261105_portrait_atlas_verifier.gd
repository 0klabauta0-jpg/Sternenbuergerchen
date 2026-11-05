extends SceneTree

const CATALOG: GDScript = preload("res://scripts/meta/portrait_identity_catalog.gd")
const BASELINE_PATH: String = "res://art/portraits_20261105/catalog_before_refresh.json"
const MANIFEST_PATH: String = "res://art/portraits_20261105/manifest.json"
var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("PORTRAIT_ATLAS_VERIFY_BEGIN")
	CATALOG.clear_cache_for_tests()
	var baseline: Dictionary = _json(BASELINE_PATH)
	var manifest: Dictionary = _json(MANIFEST_PATH)
	var loaded: Dictionary = CATALOG.load_catalog()
	var entries: Array = Array(loaded.get("entries", []))
	var old_entries: Array = Array(baseline.get("entries", []))
	var by_id: Dictionary = Dictionary(loaded.get("entries_by_id", {}))
	var validation: Dictionary = CATALOG.validate_catalog()
	_assert(old_entries.size() == 42 and entries.size() == 42, "Exactly all 42 existing identities remain")
	_assert(bool(validation.get("valid", false)), "Active catalog validates")
	_assert(int(validation.get("loadable_count", 0)) == 42, "All 42 portraits are loadable")
	_assert(int(validation.get("candidate_count", 0)) == 42, "All 42 candidates remain")
	_assert(CATALOG.get_candidate_entries().size() >= 30, "Minimum start-roster candidate pool remains")
	_assert(Dictionary(loaded.get("entries_by_legacy_path", {})).size() == 42, "Every old portrait path has one alias")
	for old_variant in old_entries:
		var old: Dictionary = Dictionary(old_variant)
		var id: String = String(old.get("id", ""))
		var entry: Dictionary = Dictionary(by_id.get(id, {}))
		var path: String = String(entry.get("path", ""))
		var legacy: String = String(old.get("path", ""))
		_assert(not entry.is_empty(), "Existing ID retained: %s" % id)
		_assert(PackedStringArray(entry.get("tags", [])) == PackedStringArray(old.get("tags", [])), "Tags unchanged: %s" % id)
		_assert(bool(entry.get("candidate", false)) == bool(old.get("candidate", false)), "Candidate flag unchanged: %s" % id)
		_assert(FileAccess.file_exists(legacy), "Legacy source remains on disk: %s" % id)
		_assert(CATALOG.resolve_path(id, legacy) == path, "ID resolves current atlas over saved old path: %s" % id)
		_assert(CATALOG.resolve_path("", legacy) == path, "ID-less old path resolves same identity: %s" % id)
		_assert(CATALOG.resolve_path("missing_id", legacy) == path, "Unknown ID retains known path identity: %s" % id)
		_assert(CATALOG.load_texture(id, legacy) is AtlasTexture, "Actual catalog texture is an AtlasTexture: %s" % id)
	var faces: Array = Array(manifest.get("faces", []))
	var sheets: Array = Array(manifest.get("sheets", []))
	_assert(faces.size() == 44 and sheets.size() == 11, "Manifest retains 44 faces on eleven source sheets")
	var seen_regions: Dictionary = {}
	var assigned: int = 0
	var reserves: int = 0
	for face_variant in faces:
		var face: Dictionary = Dictionary(face_variant)
		var path: String = String(face.get("path", ""))
		var texture := ResourceLoader.load(path) as AtlasTexture
		_assert(texture != null, "AtlasTexture loads: %s" % path)
		if texture == null:
			continue
		var region_values: Array = Array(face.get("region", []))
		_assert(region_values.size() == 4, "Region has four components")
		if region_values.size() != 4:
			continue
		var expected := Rect2(float(region_values[0]), float(region_values[1]), float(region_values[2]), float(region_values[3]))
		_assert(texture.region == expected, "Loaded region matches provenance")
		_assert(texture.get_size() == Vector2(627, 627), "Individual texture has exact 627x627 size")
		_assert(texture.filter_clip, "Atlas filtering clips to own region")
		_assert(texture.atlas != null, "Source atlas exists")
		if texture.atlas == null:
			continue
		_assert(texture.atlas.resource_path == String(face.get("sheet_path", "")), "Atlas points to project PNG")
		_assert(texture.atlas.get_size() == Vector2(1254, 1254), "Loaded original atlas stays 1254x1254")
		_assert(FileAccess.get_sha256(path) == String(face.get("sha256", "")), "Atlas resource source hash matches manifest")
		var key: String = "%s:%s" % [texture.atlas.resource_path, texture.region]
		_assert(not seen_regions.has(key), "No assigned or reserve face repeats an atlas region")
		seen_regions[key] = true
		var id: String = String(face.get("portrait_id", ""))
		if bool(face.get("assigned", false)):
			assigned += 1
			_assert(String(Dictionary(by_id.get(id, {})).get("path", "")) == path, "Manifest face uses existing catalog identity")
		else:
			reserves += 1
			_assert(id.is_empty() and not by_id.has(String(face.get("asset_id", ""))), "Reserve does not add a roster identity")
	_assert(assigned == 42 and reserves == 2, "Exactly 42 assigned and two reserve regions")
	for sheet_variant in sheets:
		var sheet: Dictionary = Dictionary(sheet_variant)
		var path: String = String(sheet.get("path", ""))
		_assert(FileAccess.get_sha256(path) == String(sheet.get("sha256", "")), "Actual PNG matches reviewed source hash")
		_assert(ResourceLoader.load(path) is Texture2D, "Actual source PNG imports as Texture2D")
		_assert(FileAccess.get_sha256(String(sheet.get("prompt_path", ""))) == String(sheet.get("prompt_sha256", "")), "Exact prompt receipt is retained")
	var first: Dictionary = Dictionary(entries[0]) if not entries.is_empty() else {}
	var last: Dictionary = Dictionary(entries[-1]) if not entries.is_empty() else {}
	var first_path: String = String(first.get("path", ""))
	_assert(CATALOG.resolve_path(String(first.get("id", "")), String(last.get("path", ""))) == first_path, "Known ID takes priority over conflicting valid path")
	_assert(CATALOG.resolve_path("", String(last.get("path", ""))) == String(last.get("path", "")), "Explicit current resource path stays usable")
	_assert(CATALOG.resolve_path("missing", "res://missing_portrait_fixture.png") == first_path, "Missing identity retains existing fallback")
	_test_cache_and_custom_catalog(first, last)
	CATALOG.clear_cache_for_tests()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	print("PORTRAIT_ATLAS_VERIFY_PASS" if _failed == 0 else "PORTRAIT_ATLAS_VERIFY_FAIL")
	quit(0 if _failed == 0 else 1)


func _test_cache_and_custom_catalog(first: Dictionary, last: Dictionary) -> void:
	var snapshot: Dictionary = CATALOG.load_catalog()
	Dictionary(snapshot.get("entries_by_id", {})).clear()
	Array(snapshot.get("entries", [])).clear()
	var next_snapshot: Dictionary = CATALOG.load_catalog()
	_assert(Dictionary(next_snapshot.get("entries_by_id", {})).size() == 42, "Caller mutation cannot corrupt cached ID map")
	_assert(Array(next_snapshot.get("entries", [])).size() == 42, "Caller mutation cannot corrupt cached entries")
	var fixture_path: String = "user://portrait_atlas_fixture_%d.json" % Time.get_ticks_usec()
	var fixture: Dictionary = {"schema_version": 1, "catalog_id": "portrait_identity_catalog_v1", "entries": [first]}
	_assert(_write_fixture(fixture_path, fixture), "Custom test catalog writes in isolated user data")
	_assert(CATALOG.resolve_path(String(first.get("id", "")), "", fixture_path) == String(first.get("path", "")), "Custom catalog initially reads its own resource")
	fixture["entries"] = [last]
	_assert(_write_fixture(fixture_path, fixture), "Custom test catalog update writes")
	_assert(CATALOG.resolve_path(String(last.get("id", "")), "", fixture_path) == String(last.get("path", "")), "Custom catalog rereads changes without cache reset")
	_assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_path)) == OK, "Custom fixture cleaned up")
	CATALOG.clear_cache_for_tests()
	_assert(CATALOG.load_catalog().get("entries", []).size() == 42, "Explicit cache reset rereads shipped catalog")


func _write_fixture(path: String, value: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(value))
	file.close()
	return true


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if parsed is Dictionary else {}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
