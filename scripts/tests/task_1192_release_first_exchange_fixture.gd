extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_1192_release_first_exchange_fixture.md"
const FIXTURE_PATH := "res://scripts/tests/release_first_exchange_fixture.gd"
const META_LAYER_PATH := "res://scripts/meta/meta_layer_flow.gd"
const RELEASE_FIXTURE_SCRIPT: GDScript = preload("res://scripts/tests/release_first_exchange_fixture.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1192 Release First Exchange Fixture Isolation ===")
	_test_fixture_delegation_and_evidence()
	_test_deeplink_scanner_rejects_injected_mutation()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		quit(1)
		return
	quit(0)


func _test_fixture_delegation_and_evidence() -> void:
	var task_text := _read_text(TASK_PATH)
	var meta_text := _read_text(META_LAYER_PATH)
	_assert(task_text.contains("Release First Exchange Fixture Isolation"), "TASK_1192 task contract exists")
	_assert(FileAccess.file_exists(FIXTURE_PATH), "Explicit release first-exchange fixture exists")
	var fixture = RELEASE_FIXTURE_SCRIPT.new()
	_assert(fixture.has_method("prepare"), "Fixture parses and exposes the explicit setup entrypoint")
	_assert(meta_text.contains("release_first_exchange_fixture.gd"), "Meta deeplink delegates to the explicit fixture")
	_assert(meta_text.contains("\"synthetic_fixture\": true"), "Meta evidence labels the synthetic fixture")
	for forbidden_token in [
		"_position_release_first_enemy_near_fireteam(",
		"_force_release_first_engagement_decision(",
		"_update_release_contact_tracking(",
	]:
		_assert(not _function_body(meta_text, "_apply_release_first_go_firefight_deeplink").contains(forbidden_token), "Normal deeplink body does not contain %s" % forbidden_token)


func _test_deeplink_scanner_rejects_injected_mutation() -> void:
	var injected_source := "func _apply_release_first_go_firefight_deeplink() -> void:\n\tenemy.global_position = Vector2.ZERO\n\nfunc harmless() -> void:\n\tpass\n"
	var violations := _collect_synthetic_runtime_mutations(injected_source)
	_assert(violations.has(".global_position ="), "Focused scanner rejects an injected teleport in the deeplink body")
	_assert(_collect_synthetic_runtime_mutations("func _apply_release_first_go_firefight_deeplink() -> void:\n\tpass\n").is_empty(), "Focused scanner permits a clean deeplink body")


func _collect_synthetic_runtime_mutations(source: String) -> PackedStringArray:
	var body := _function_body(source, "_apply_release_first_go_firefight_deeplink")
	var violations := PackedStringArray()
	for token in [
		"_position_release_first_enemy_near_fireteam(",
		"_prepare_release_fireteam_for_first_engagement(",
		"_stabilize_release_first_exchange_target_enemy(",
		"_force_release_first_engagement_decision(",
		"_update_release_contact_tracking(",
		".global_position =",
		".set(\"_detection_progress\"",
		".set(\"_current_tick\"",
		".set(\"_next_attack_tick\"",
		"._try_enqueue_attacks",
	]:
		if body.contains(token):
			violations.append(token)
	return violations


func _function_body(source: String, function_name: String) -> String:
	var start := source.find("func %s(" % function_name)
	if start < 0:
		return ""
	var finish := source.find("\n\nfunc ", start + 5)
	if finish < 0:
		finish = source.length()
	return source.substr(start, finish - start)


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
