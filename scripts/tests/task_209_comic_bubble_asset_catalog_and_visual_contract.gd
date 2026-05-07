extends SceneTree

const CATALOG_PATH: String = "res://data/comic_bubble_asset_catalog.json"
const INVENTORY_PATH: String = "res://docs/assets/comic_bubble_inventory.md"
const CONTRACT_SCRIPT_PATH: String = "res://scripts/ui/comic_bubble_visual_contract.gd"
const COMIC_ROOT: String = "res://Assets/Comic/"
const PREVIEW_PATH: String = "res://Assets/Comic/preview.png"
const CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_visual_contract.gd")
const REQUIRED_PURPOSES: PackedStringArray = [
	"ftl_response",
	"npc_thought",
	"warning",
	"quiet_status",
	"short_command",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_209 Comic Bubble Asset Catalog and Visual Contract ===")
	_test_catalog_rules_and_inventory()
	_test_runtime_bubble_entries_are_stable_and_loadable()
	_test_preview_is_documentation_only()
	_test_visual_contract_payload_is_display_only()
	_test_no_absolute_local_paths()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_catalog_rules_and_inventory() -> void:
	var catalog: Dictionary = _load_json(CATALOG_PATH)
	var inventory_text: String = _read_text_file(INVENTORY_PATH)
	var loaded: Dictionary = Dictionary(CONTRACT_SCRIPT.call("load_catalog"))
	var snapshot: Dictionary = Dictionary(CONTRACT_SCRIPT.call("get_contract_snapshot"))
	_assert(not catalog.is_empty(), "Comic bubble catalog is valid JSON")
	_assert(not inventory_text.is_empty(), "Comic bubble inventory doc exists")
	_assert(PackedStringArray(loaded.get("diagnostics", PackedStringArray())).is_empty(), "ComicBubbleVisualContract loads catalog without diagnostics")
	_assert(String(Dictionary(catalog.get("rules", {})).get("runtime_contract", "")) == "visual_only_no_gameplay_truth", "Catalog documents visual-only runtime contract")
	_assert(String(snapshot.get("runtime_contract", "")) == "visual_only_no_gameplay_truth", "Contract snapshot mirrors the visual-only runtime contract")
	_assert(Vector2i(snapshot.get("max_canvas_size", Vector2i.ZERO)) == Vector2i(220, 132), "Contract exposes max canvas size")
	_assert(int(snapshot.get("text_lines_max", 0)) == 2, "Contract caps text at two lines")
	_assert(int(snapshot.get("text_chars_per_line_max", 0)) == 26, "Contract caps text line length")
	_assert(not bool(snapshot.get("preview_runtime_bubble", true)), "Contract keeps preview.png out of runtime bubble use")
	for purpose in REQUIRED_PURPOSES:
		_assert(_catalog_has_purpose(catalog, purpose), "Catalog covers bubble purpose '%s'" % purpose)
		_assert(inventory_text.contains(purpose) or inventory_text.to_lower().contains(purpose.replace("_", "-")), "Inventory documents purpose '%s'" % purpose)


func _test_runtime_bubble_entries_are_stable_and_loadable() -> void:
	var catalog: Dictionary = _load_json(CATALOG_PATH)
	var bubbles: Array = Array(catalog.get("bubbles", []))
	var runtime_ids: PackedStringArray = PackedStringArray(CONTRACT_SCRIPT.call("get_runtime_bubble_ids"))
	var seen_ids: Dictionary = {}
	var seen_variants: Dictionary = {}
	_assert(bubbles.size() == 10, "Catalog contains exactly ten runtime bubble definitions")
	_assert(runtime_ids.size() == 10, "Contract exposes exactly ten runtime bubble IDs")
	for index in range(1, 11):
		_assert(runtime_ids.has(_expected_id_for_variant(index)), "Runtime IDs include stable variant %d ID" % index)
	for entry_variant in bubbles:
		_assert(typeof(entry_variant) == TYPE_DICTIONARY, "Bubble catalog entry is a dictionary")
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var bubble_id: String = String(entry.get("id", "")).strip_edges()
		var variant: int = int(entry.get("variant", 0))
		var path: String = String(entry.get("path", "")).strip_edges()
		_assert(not seen_ids.has(bubble_id), "Bubble ID is unique: %s" % bubble_id)
		_assert(not seen_variants.has(variant), "Bubble variant number is unique: %d" % variant)
		seen_ids[bubble_id] = true
		seen_variants[variant] = true
		_assert(path == "%scomic-%d.png" % [COMIC_ROOT, variant], "Variant %d maps to comic-%d.png" % [variant, variant])
		_assert(path.begins_with(COMIC_ROOT), "Bubble path is project-local: %s" % path)
		_assert(ResourceLoader.exists(path), "ResourceLoader sees bubble texture: %s" % path)
		var texture := load(path) as Texture2D
		_assert(texture != null and texture.get_width() > 0 and texture.get_height() > 0, "Bubble texture loads with dimensions: %s" % bubble_id)
		_assert(CONTRACT_SCRIPT.call("validate_entry", entry, Dictionary(catalog.get("rules", {}))).is_empty(), "Bubble entry validates against visual contract: %s" % bubble_id)


func _test_preview_is_documentation_only() -> void:
	var preview: Dictionary = Dictionary(CONTRACT_SCRIPT.call("get_preview_entry"))
	var runtime_ids: PackedStringArray = PackedStringArray(CONTRACT_SCRIPT.call("get_runtime_bubble_ids"))
	_assert(String(preview.get("path", "")) == PREVIEW_PATH, "Catalog documents preview.png")
	_assert(not bool(preview.get("runtime_bubble", true)), "preview.png is not marked as a runtime bubble")
	_assert(ResourceLoader.exists(PREVIEW_PATH), "ResourceLoader sees preview.png")
	_assert(load(PREVIEW_PATH) is Texture2D, "preview.png loads as documentation texture")
	_assert(not runtime_ids.has("comic_bubble_preview_sheet"), "Runtime IDs exclude preview sheet")


func _test_visual_contract_payload_is_display_only() -> void:
	var payload: Dictionary = Dictionary(CONTRACT_SCRIPT.call(
		"build_display_payload",
		"bubble_ftl_warning",
		"This is deliberately much too long for a mission-map bubble and must be shortened by the visual contract",
		Vector2(128.0, 64.0),
		"unit_alpha",
		{"duration_seconds": 99.0}
	))
	_assert(bool(payload.get("ok", false)), "Contract builds a display payload for a known bubble")
	_assert(String(payload.get("display_type", "")) == "comic_bubble", "Payload is explicitly a comic-bubble display payload")
	_assert(String(payload.get("path", "")).begins_with(COMIC_ROOT), "Payload carries project-local texture path")
	_assert(_text_within_limits(String(payload.get("text", "")), 2, 26), "Payload text is capped to the visual text contract")
	_assert(float(payload.get("duration_seconds", 0.0)) <= 3.0, "Payload duration is clamped to contract max")
	for forbidden_key in ["command_type", "effect_type", "unit_command", "simulation_effect", "damage", "heal"]:
		_assert(not payload.has(forbidden_key), "Display payload carries no gameplay key '%s'" % forbidden_key)
	var missing: Dictionary = Dictionary(CONTRACT_SCRIPT.call("build_display_payload", "missing_bubble", "Ack", Vector2.ZERO))
	_assert(not bool(missing.get("ok", true)), "Unknown bubble ID returns a diagnostic payload instead of fallback art")


func _test_no_absolute_local_paths() -> void:
	for path in [CATALOG_PATH, INVENTORY_PATH, CONTRACT_SCRIPT_PATH, "res://scripts/tests/task_209_comic_bubble_asset_catalog_and_visual_contract.gd"]:
		var text: String = _read_text_file(path)
		_assert(not _contains_absolute_local_path(text), "No absolute local path in %s" % path)


func _expected_id_for_variant(variant: int) -> String:
	match variant:
		1:
			return "bubble_ftl_ack"
		2:
			return "bubble_ftl_short_order"
		3:
			return "bubble_ftl_warning"
		4:
			return "bubble_ftl_contact"
		5:
			return "bubble_npc_thought_quiet"
		6:
			return "bubble_npc_thought_focus"
		7:
			return "bubble_npc_alert"
		8:
			return "bubble_npc_status_low"
		9:
			return "bubble_command_confirm"
		_:
			return "bubble_warning_large"


func _catalog_has_purpose(catalog: Dictionary, purpose: String) -> bool:
	for entry_variant in Array(catalog.get("bubbles", [])):
		if typeof(entry_variant) == TYPE_DICTIONARY and String(Dictionary(entry_variant).get("purpose", "")) == purpose:
			return true
	return false


func _text_within_limits(text: String, max_lines: int, max_chars_per_line: int) -> bool:
	var lines: PackedStringArray = text.split("\n", false)
	if lines.size() > max_lines:
		return false
	for line in lines:
		if String(line).length() > max_chars_per_line:
			return false
	return true


func _contains_absolute_local_path(text: String) -> bool:
	return text.contains("C:" + "\\" + "Users" + "\\") or text.contains("C:" + "/" + "Users" + "/") or text.contains("file:///" + "C:" + "/" + "Users" + "/")


func _load_json(path: String) -> Dictionary:
	var text: String = _read_text_file(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
