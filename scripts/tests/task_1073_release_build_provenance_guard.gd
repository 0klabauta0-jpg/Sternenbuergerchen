extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_1073_release_build_provenance_guard.md"
const CONTRACT_PATH: String = "res://data/export_runtime_package_contract.json"
const DEV_CONTRACT_PATH: String = "res://docs/dev/export_runtime_package_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const EXPORT_SCRIPT_PATH: String = "res://scripts/tools/export_runtime_release.ps1"
const START_CHECK_PATH: String = "res://scripts/tools/release_runtime_start_check.ps1"
const OUTPUT_ROOT: String = "res://tmp/task_1073_release_provenance_guard"
const RELEASE_DIR: String = OUTPUT_ROOT + "/release"
const TEST_CONTRACT_PATH: String = OUTPUT_ROOT + "/export_contract.json"
const PROVENANCE_FILE: String = "release_build_provenance.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1073 Release Build Provenance Guard ===")
	_test_static_contract_wiring()
	_test_start_check_accepts_matching_provenance()
	_test_start_check_rejects_mismatching_provenance()
	_cleanup_output()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_static_contract_wiring() -> void:
	var export_contract: Dictionary = _read_json(CONTRACT_PATH)
	var export_script: String = _read_text(EXPORT_SCRIPT_PATH)
	var start_check_script: String = _read_text(START_CHECK_PATH)
	var dev_contract: String = _read_text(DEV_CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1073 task file exists")
	_assert(String(export_contract.get("runtime_provenance_file", "")) == PROVENANCE_FILE, "Runtime export contract names provenance file")
	_assert(export_script.contains("Write-ReleaseBuildProvenance") and export_script.contains("tracked Git changes"), "Export writes provenance only from a clean tracked worktree")
	_assert(start_check_script.contains("missing_release_provenance") and start_check_script.contains("release_provenance_git_commit_mismatch") and start_check_script.contains("release_provenance_pck_mismatch"), "Start check enforces provenance presence, commit and PCK hash")
	_assert(dev_contract.contains("release_build_provenance.json"), "Export contract documents release provenance")
	_assert(_read_text(STATUS_PATH).contains("TASK_1073 - Release Build Provenance Guard"), "Implementation status tracks TASK_1073")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_1073 - Release Build Provenance Guard (implementiert im Arbeitsstand)"), "Roadmap tracks TASK_1073")
	_assert(_read_text(REPORT_PATH).contains("Release-Provenance: TASK_1073") and _read_text(REPORT_PATH).contains('data-export-key="reentry_handbook.release_provenance_task"'), "Current handbook reports and exports TASK_1073")


func _test_start_check_accepts_matching_provenance() -> void:
	_write_mock_release("matching")
	var result: Dictionary = _run_start_check()
	_assert(int(result.get("exit_code", -1)) == 0, "Matching provenance start check exits successfully")
	var manifest: Dictionary = _parse_json_output(String(result.get("output", "")))
	_assert(String(manifest.get("gate", "")) == "pass", "Matching provenance start check passes")
	_assert(bool(Dictionary(manifest.get("release_provenance", {})).get("valid", false)), "Matching provenance is reported valid")


func _test_start_check_rejects_mismatching_provenance() -> void:
	_write_mock_release("mismatch")
	var provenance_path: String = ProjectSettings.globalize_path(RELEASE_DIR.path_join(PROVENANCE_FILE))
	var provenance: Dictionary = _read_json(RELEASE_DIR.path_join(PROVENANCE_FILE))
	provenance["git_commit"] = "0000000000000000000000000000000000000000"
	_write_json(provenance_path, provenance)
	var result: Dictionary = _run_start_check()
	_assert(int(result.get("exit_code", -1)) == 2, "Mismatching provenance start check hard-fails")
	var manifest: Dictionary = _parse_json_output(String(result.get("output", "")))
	_assert(Array(manifest.get("hard_failures", [])).has("release_provenance_git_commit_mismatch"), "Mismatch names the provenance commit failure")


func _write_mock_release(_label: String) -> void:
	_cleanup_output()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RELEASE_DIR))
	var pck_bytes: PackedByteArray = "task_1073_mock_pck".to_utf8_buffer()
	_write_bytes(RELEASE_DIR.path_join("Sternenbuergerchen_rel.exe"), "mock exe".to_utf8_buffer())
	_write_bytes(RELEASE_DIR.path_join("Sternenbuergerchen_rel.console.exe"), "mock console".to_utf8_buffer())
	_write_bytes(RELEASE_DIR.path_join("Sternenbuergerchen_rel.pck"), pck_bytes)
	_write_bytes(RELEASE_DIR.path_join("liblimboai.windows.template_release.x86_64.dll"), "mock limbo".to_utf8_buffer())
	_write_bytes(RELEASE_DIR.path_join("libterrain.windows.release.x86_64.dll"), "mock terrain".to_utf8_buffer())
	var git_head: String = _get_git_head()
	var provenance: Dictionary = {
		"schema": "sternenbuergerchen.release_build_provenance.v1",
		"task_id": "TASK_1073",
		"exported_at_utc": Time.get_datetime_string_from_system(true),
		"branch": "test",
		"git_commit": git_head,
		"runtime_export_path": "tmp/task_1073_release_provenance_guard/release/Sternenbuergerchen_rel.exe",
		"exe_name": "Sternenbuergerchen_rel.exe",
		"pck_name": "Sternenbuergerchen_rel.pck",
		"pck_size_bytes": pck_bytes.size(),
		"pck_sha256": _sha256(pck_bytes),
		"tracked_worktree_clean": true,
		"read_only_consumer_required": true,
	}
	_write_json(ProjectSettings.globalize_path(RELEASE_DIR.path_join(PROVENANCE_FILE)), provenance)
	var contract: Dictionary = {
		"runtime_export_path": "tmp/task_1073_release_provenance_guard/release/Sternenbuergerchen_rel.exe",
		"runtime_provenance_file": PROVENANCE_FILE,
	}
	_write_json(ProjectSettings.globalize_path(TEST_CONTRACT_PATH), contract)


func _run_start_check() -> Dictionary:
	var output: Array = []
	var exit_code: int = OS.execute(
		"powershell",
		PackedStringArray([
			"-NoProfile",
			"-ExecutionPolicy",
			"Bypass",
			"-File",
			ProjectSettings.globalize_path(START_CHECK_PATH),
			"-ContractPath",
			ProjectSettings.globalize_path(TEST_CONTRACT_PATH),
			"-JsonOnly",
		]),
		output,
		true
	)
	return {"exit_code": exit_code, "output": "\n".join(PackedStringArray(output))}


func _get_git_head() -> String:
	var output: Array = []
	var exit_code: int = OS.execute("git", PackedStringArray(["rev-parse", "HEAD"]), output, true)
	if exit_code != 0 or output.is_empty():
		return ""
	return String(output[0]).strip_edges()


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _parse_json_output(output: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(output.strip_edges())
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _write_bytes(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write %s" % path)
		return
	file.store_buffer(bytes)
	file.close()


func _write_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write JSON %s" % path)
		return
	file.store_string(JSON.stringify(value, "\t"))
	file.close()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""


func _cleanup_output() -> void:
	var root_path: String = ProjectSettings.globalize_path(OUTPUT_ROOT)
	if not DirAccess.dir_exists_absolute(root_path):
		return
	for file_path in [
		"release/Sternenbuergerchen_rel.exe",
		"release/Sternenbuergerchen_rel.console.exe",
		"release/Sternenbuergerchen_rel.pck",
		"release/liblimboai.windows.template_release.x86_64.dll",
		"release/libterrain.windows.release.x86_64.dll",
		"release/release_build_provenance.json",
		"export_contract.json",
	]:
		var absolute_path: String = ProjectSettings.globalize_path(OUTPUT_ROOT.path_join(file_path))
		if FileAccess.file_exists(absolute_path):
			DirAccess.remove_absolute(absolute_path)
	var release_path: String = ProjectSettings.globalize_path(RELEASE_DIR)
	if DirAccess.dir_exists_absolute(release_path):
		DirAccess.remove_absolute(release_path)
	DirAccess.remove_absolute(root_path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
