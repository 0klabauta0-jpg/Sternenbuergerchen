extends SceneTree

const TASK_START: int = 269
const TASK_END: int = 282
const TASK_PATH: String = "res://docs/tasks/TASK_283_post_tactical_docs_consistency_audit.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reviews/post_tactical_docs_consistency_audit.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_283 Post Tactical Docs Consistency Audit ===")
	_test_task_status_and_roadmap_alignment()
	_test_link_targets_and_task_numbers()
	_test_tactical_term_consistency()
	_test_source_abstraction_guard()
	_test_report_status_and_cleanup()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_task_status_and_roadmap_alignment() -> void:
	var roadmap: String = _read_text(ROADMAP_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	for task_number in range(TASK_START, TASK_END + 1):
		var task_path: String = _find_task_path(task_number)
		var task_text: String = _read_text(task_path)
		_assert(not task_path.is_empty(), "TASK_%03d task file exists" % task_number)
		_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_%03d task file status is implemented" % task_number)
		_assert(not task_text.contains("- [ ]"), "TASK_%03d checklist has no unchecked items" % task_number)
		_assert(_roadmap_marks_implemented(roadmap, task_number), "Roadmap marks TASK_%03d implemented" % task_number)
		_assert(_implementation_status_marks_implemented(status_text, task_number), "Implementation status marks TASK_%03d implemented" % task_number)
	_assert(roadmap.find("TASK_269") < roadmap.find("TASK_282"), "Roadmap keeps Tactical Overhaul task order")
	_assert(status_text.find("### TASK_269") < status_text.find("### TASK_282"), "Implementation status keeps Tactical Overhaul task order")


func _test_link_targets_and_task_numbers() -> void:
	var task_files: Dictionary = {}
	var directory := DirAccess.open("res://docs/tasks")
	_assert(directory != null, "Task directory is readable")
	if directory == null:
		return
	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.begins_with("TASK_") and file_name.ends_with(".md"):
			var task_number: int = int(file_name.substr(5, 3))
			if task_number >= TASK_START and task_number <= TASK_END:
				task_files[task_number] = int(task_files.get(task_number, 0)) + 1
		file_name = directory.get_next()
	directory.list_dir_end()
	for task_number in range(TASK_START, TASK_END + 1):
		_assert(int(task_files.get(task_number, 0)) == 1, "TASK_%03d has exactly one task file" % task_number)
	var missing_targets: PackedStringArray = PackedStringArray()
	for task_number in range(TASK_START, TASK_END + 1):
		var task_path: String = _find_task_path(task_number)
		var task_text: String = _read_text(task_path)
		for target_path in _extract_local_paths(task_text):
			if not _local_path_exists(target_path):
				missing_targets.append("%s -> %s" % [task_path, target_path])
	_assert(missing_targets.is_empty(), "Task docs have no missing local file targets")


func _test_tactical_term_consistency() -> void:
	var checks: Dictionary = {
		"res://docs/dev/commander_fireteam_delegation_contract.md": ["CommanderIntent", "FireteamExecutionPlan", "UI may create or display", "SimulationRoot"],
		"res://docs/dev/multi_fireteam_plan_contract.md": ["CommanderIntent", "MultiFireteamPlanResolver", "FireteamExecutionPlan", "ui_sets_gameplay_truth"],
		"res://docs/dev/tactical_command_rules_contract.md": ["TacticalCommandRules", "CommanderIntent", "FireteamExecutionPlan", "not a real ROE"],
		"res://docs/dev/tactical_breakout_exception_contract.md": ["Breakout", "FireteamExecutionPlan.allowed_breakout_classes", "ui_sets_gameplay_truth = false"],
		"res://docs/dev/air_asset_threat_damage_contract.md": ["AirAssetStatus", "SimulationRoot", "ui_sets_gameplay_truth = false"],
		"res://docs/dev/air_asset_loss_recovery_meta_loop.md": ["AirAssetRecoveryState", "MetaLayerFlow", "AirAssetStatus"],
		"res://docs/dev/tactical_multiplayer_authority_snapshot.md": ["CommanderIntent", "breakout_states", "air_asset_status", "ui_sets_gameplay_truth = false"],
	}
	for path in checks.keys():
		var text: String = _read_text(path)
		_assert(not text.is_empty(), "Dev doc exists: %s" % path.get_file())
		for token in Array(checks[path]):
			_assert(text.contains(String(token)), "%s keeps term '%s'" % [path.get_file(), String(token)])
	var command_doc: String = _read_text("res://docs/dev/commander_fireteam_delegation_contract.md")
	_assert(command_doc.contains("unit_id") and command_doc.contains("ignored"), "CommanderIntent legacy unit_id is documented as ignored")
	var multiplayer_doc: String = _read_text("res://docs/dev/tactical_multiplayer_authority_snapshot.md")
	_assert(multiplayer_doc.contains("Host-only") or multiplayer_doc.contains("Host-only role override"), "Role override authority is documented as host-only")


func _test_source_abstraction_guard() -> void:
	var doctrine_task: String = _read_text("res://docs/tasks/TASK_269_tactical_doctrine_source_review_game_abstraction.md")
	var doctrine_doc: String = _read_text("res://docs/dev/tactical_command_doctrine_game_abstraction.md")
	var research_doc: String = _read_text("res://docs/research/tactical_doctrine_source_matrix.md")
	_assert(doctrine_task.contains("Keine reale Ausbildung") and doctrine_task.contains("Game-Abstraktion"), "TASK_269 keeps source safety boundary")
	_assert(doctrine_doc.contains("not a real tactical handbook") and doctrine_doc.contains("not real ROE"), "Doctrine abstraction doc avoids real tactical instruction")
	_assert(research_doc.contains("game abstraction") or research_doc.contains("Game-Abstraktion"), "Source matrix frames research as game abstraction")
	_assert(not doctrine_doc.contains("battle drill steps"), "Doctrine doc avoids step-by-step battle-drill wording")
	var stale_help_report: String = _read_text("res://docs/reports/contextual_help_coverage_layout_report.md")
	_assert(not stale_help_report.contains("mission.command.roe_fire_rules` stays `todo` until TASK_271"), "Stale ROE help exception was removed")


func _test_report_status_and_cleanup() -> void:
	var report: String = _read_text(REPORT_PATH)
	_assert(report.contains("## Findings"), "Audit report has Findings section")
	for severity in ["blocker", "important", "cleanup"]:
		_assert(report.to_lower().contains(severity), "Audit report contains severity '%s'" % severity)
	for token in ["docs/reports/contextual_help_coverage_layout_report.md", "TASK_284", "TASK_285", "TASK_286", "TASK_287", "TASK_288"]:
		_assert(report.contains(token), "Audit report references %s" % token)
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_283 implemented")
	_assert(not task_text.contains("- [ ]"), "Task checklist is complete")
	_assert(status_text.contains("### TASK_283 - Post Tactical Docs Consistency Audit") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_283 implemented")
	_assert(roadmap_text.contains("TASK_283 - Post Tactical Docs Consistency Audit (implementiert)"), "Roadmap marks TASK_283 implemented")


func _roadmap_marks_implemented(roadmap: String, task_number: int) -> bool:
	for line in roadmap.split("\n"):
		if line.contains("TASK_%03d" % task_number):
			return line.contains("(implementiert)")
	return false


func _implementation_status_marks_implemented(status_text: String, task_number: int) -> bool:
	var marker: String = "### TASK_%03d" % task_number
	var start: int = status_text.find(marker)
	if start < 0:
		return false
	var next: int = status_text.find("\n### TASK_", start + marker.length())
	var section: String = status_text.substr(start, next - start) if next > start else status_text.substr(start)
	return section.contains("- Status: implementiert")


func _find_task_path(task_number: int) -> String:
	var prefix: String = "TASK_%03d_" % task_number
	var directory := DirAccess.open("res://docs/tasks")
	if directory == null:
		return ""
	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.begins_with(prefix) and file_name.ends_with(".md"):
			directory.list_dir_end()
			return "res://docs/tasks/%s" % file_name
		file_name = directory.get_next()
	directory.list_dir_end()
	return ""


func _extract_local_paths(text: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var regex := RegEx.new()
	regex.compile("`((?:scripts|docs|data|maps|scenes)/[^` ]+)`")
	for match_result in regex.search_all(text):
		var path: String = String(match_result.get_string(1)).strip_edges()
		if path.contains("...") or path.ends_with("/"):
			continue
		if not result.has(path):
			result.append(path)
	return result


func _local_path_exists(path: String) -> bool:
	return FileAccess.file_exists("res://%s" % path) or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://%s" % path))


func _read_text(path: String) -> String:
	if path.is_empty() or not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
