extends SceneTree

const CURRENT_DOCUMENTS := {
	"docs/DOCS_INDEX.md": 120,
	"docs/CURRENT_GAME_STATE.md": 220,
	"docs/PRODUCT_MILESTONES.md": 180,
	"docs/qa/CURRENT_EVIDENCE.md": 220,
	"docs/visual/WORLD_ART_DIRECTION.md": 180,
}

const REQUIRED_MANIFEST_FIELDS := [
	"delivery_state",
	"product_maturity",
	"scope",
	"evidence",
]

const REQUIRED_EVIDENCE_FIELDS := [
	"id",
	"commit",
	"run_at",
	"type",
	"result",
	"artifact",
	"caveat",
	"owning_paths",
]

const REQUIRED_CANDIDATE_FIELDS := [
	"id",
	"recovery_manifest",
	"source_path",
	"sha256",
	"recovery_status",
	"caveat",
]

var _failures: Array[String] = []
var _project_root := ""


func _init() -> void:
	_project_root = _get_project_root()
	_expect(not _project_root.is_empty(), "missing --project-root <absolute-path> argument")
	_expect(DirAccess.dir_exists_absolute(_project_root), "project root does not exist: %s" % _project_root)
	_check_required_files()
	_check_current_documents()
	_check_manifest()
	_check_compatibility_contracts()
	_finish()


func _check_required_files() -> void:
	for path in CURRENT_DOCUMENTS:
		_expect(_file_exists(path), "missing current document: %s" % path)
	_expect(_file_exists("docs/reports/README.md"), "missing report snapshot index")
	_expect(_file_exists("data/project_evidence_manifest.json"), "missing evidence manifest")


func _check_current_documents() -> void:
	for path in CURRENT_DOCUMENTS:
		if not _file_exists(path):
			continue
		var text := _read_text(path)
		_expect(_line_count(text) <= int(CURRENT_DOCUMENTS[path]), "%s exceeds its %d-line budget" % [path, CURRENT_DOCUMENTS[path]])

	if _file_exists("docs/CURRENT_GAME_STATE.md"):
		var current_state := _read_text("docs/CURRENT_GAME_STATE.md")
		_expect(current_state.contains("TASK_1179"), "current state must classify TASK_1179")
		_expect(current_state.contains("historische 18/18"), "current state must preserve the historical TASK_1179 result")
		_expect(current_state.contains("kein frischer"), "current state must keep the TASK_1179 freshness caveat")
		_expect(current_state.contains("TASK_1180"), "current state must classify TASK_1180")
		_expect(current_state.contains("nicht integriert"), "current state must keep TASK_1180 unintegrated")
		_expect(current_state.contains("hashgesicherter Kandidat"), "current state must call TASK_1180 a hash-secured candidate")

	_expect(_count_marker_in_docs("<!-- canonical-current-state: true -->") == 1, "exactly one document must declare canonical current state")
	_expect(_count_marker_in_docs("<!-- milestone: now -->") == 1, "exactly one milestone must be marked now")


func _check_manifest() -> void:
	var manifest_path := "data/project_evidence_manifest.json"
	if not _file_exists(manifest_path):
		return
	var json := JSON.new()
	_expect(json.parse(_read_text(manifest_path)) == OK, "evidence manifest must be valid JSON")
	if json.get_data() is not Dictionary:
		_expect(false, "evidence manifest root must be an object")
		return
	var manifest: Dictionary = json.get_data()
	for field in REQUIRED_MANIFEST_FIELDS:
		_expect(manifest.has(field), "evidence manifest is missing %s" % field)
	if not manifest.has("schema_version"):
		_expect(false, "evidence manifest is missing schema_version")
	else:
		_expect(manifest["schema_version"] == 1, "evidence manifest schema_version must be 1")
	if not manifest.has("evidence") or not manifest["evidence"] is Array:
		return
	for record in manifest["evidence"]:
		_expect(record is Dictionary, "every evidence record must be an object")
		if record is not Dictionary:
			continue
		for field in REQUIRED_EVIDENCE_FIELDS:
			_expect(record.has(field), "evidence record is missing %s" % field)
		_expect(record.get("owning_paths", []) is Array, "evidence owning_paths must be an array")
		_expect(_is_commit_sha(str(record.get("commit", ""))), "evidence commit must be a 7-40 hex SHA: %s" % record.get("id", "unknown"))
		if record.get("id", "") == "n001_documentation_baseline":
			_expect(record.get("commit", "") == "3d5ff09bc556dbf5e76a466c0dae3d7b1f54acaf", "N001 baseline must name the Current Truth commit")
		var artifact := str(record.get("artifact", ""))
		if _is_repo_relative(artifact):
			_expect(_file_exists(artifact), "repo-relative evidence artifact must exist: %s" % artifact)
		_expect(str(record.get("id", "")) != "task_1180_recovered_candidate", "TASK_1180 must be a candidate, not evidence")

	_expect(manifest.has("candidates") and manifest["candidates"] is Array, "evidence manifest must contain candidates[]")
	if not manifest.has("candidates") or not manifest["candidates"] is Array:
		return
	for candidate in manifest["candidates"]:
		_expect(candidate is Dictionary, "every candidate record must be an object")
		if candidate is not Dictionary:
			continue
		for field in REQUIRED_CANDIDATE_FIELDS:
			_expect(candidate.has(field), "candidate record is missing %s" % field)
		_expect(_is_sha256(str(candidate.get("sha256", ""))), "candidate sha256 must be 64 hex characters: %s" % candidate.get("id", "unknown"))
		if candidate.get("id", "") == "task_1180_recovered_candidate":
			_expect(candidate.get("sha256", "") == "D290C5115B3BE6044C2CFCD3086DBFDCF92EE55294FE7B0DED21EDDCB25119E6", "TASK_1180 candidate hash must match the recovered source")
			_expect(str(candidate.get("source_path", "")).contains("docs/tasks/TASK_1180_ground_mission_first_contact_live_fire_trace.md"), "TASK_1180 candidate must retain the exact recovery task path")
		var recovery_manifest := str(candidate.get("recovery_manifest", ""))
		_expect(_is_repo_relative(recovery_manifest) and _file_exists(recovery_manifest), "candidate recovery manifest must be versioned in this repo: %s" % candidate.get("id", "unknown"))
		if _is_repo_relative(recovery_manifest) and _file_exists(recovery_manifest):
			_check_recovery_manifest(candidate, recovery_manifest)


func _check_compatibility_contracts() -> void:
	for path in ["docs/IMPLEMENTATION_STATUS.md", "docs/TASK_ROADMAP.md"]:
		_expect(_read_text(path).contains("Kompatibilitaetsledger"), "%s must retain a compatibility-ledger banner" % path)
	_expect(_read_text("docs/reports/README.md").contains("TASK_1181"), "report index must classify TASK_1181")
	_expect(_read_text("docs/reports/README.md").contains("supersedes"), "report index must expose supersedes metadata")
	_expect(_read_text("AGENTS.md").contains("Current Truth"), "AGENTS.md must define current-truth precedence")
	_expect(_read_text("AGENTS.md").contains("docs/DOCS_INDEX.md"), "AGENTS.md must require DOCS_INDEX for claims")
	_expect(_read_text("AGENTS.md").contains("docs/PRODUCT_MILESTONES.md"), "AGENTS.md must require PRODUCT_MILESTONES for claims")
	_expect(_read_text("docs/ARCHITECTURE.md").contains("Monolith"), "architecture must forbid documentation monoliths")
	_expect(_read_text("docs/CODEX_RULES.md").contains("Current Truth"), "rules must define current-truth precedence")
	_expect(_read_text("docs/CODEX_RULES.md").contains("docs/DOCS_INDEX.md"), "rules must require DOCS_INDEX for claims")
	_expect(_read_text("docs/CODEX_RULES.md").contains("docs/PRODUCT_MILESTONES.md"), "rules must require PRODUCT_MILESTONES for claims")
	_expect(_read_text("docs/qa/CURRENT_EVIDENCE.md").contains("hashgesicherter Kandidat"), "QA evidence must call TASK_1180 a hash-secured candidate")


func _count_marker_in_docs(marker: String) -> int:
	return _count_marker_in_directory("docs", marker)


func _count_marker_in_directory(path: String, marker: String) -> int:
	var directory := DirAccess.open(_rooted(path))
	if directory == null:
		return 0
	var count := 0
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		var entry_path := path.path_join(entry)
		if directory.current_is_dir():
			if not entry.begins_with("."):
				count += _count_marker_in_directory(entry_path, marker)
		elif entry.ends_with(".md") and _read_text(entry_path).contains(marker):
			count += 1
		entry = directory.get_next()
	directory.list_dir_end()
	return count


func _read_text(path: String) -> String:
	var file := FileAccess.open(_rooted(path), FileAccess.READ)
	return "" if file == null else file.get_as_text()


func _check_recovery_manifest(candidate: Dictionary, path: String) -> void:
	var json := JSON.new()
	_expect(json.parse(_read_text(path)) == OK, "candidate recovery manifest must be valid JSON: %s" % path)
	if json.get_data() is not Dictionary:
		_expect(false, "candidate recovery manifest root must be an object: %s" % path)
		return
	var recovery: Dictionary = json.get_data()
	_expect(recovery.get("schema_version", 0) == 1, "candidate recovery manifest schema_version must be 1: %s" % path)
	_expect(recovery.get("candidate_id", "") == candidate.get("id", ""), "candidate recovery manifest id must match: %s" % path)
	_expect(recovery.get("source_path", "") == candidate.get("source_path", ""), "candidate recovery manifest source path must match: %s" % path)
	_expect(recovery.get("sha256", "") == candidate.get("sha256", ""), "candidate recovery manifest sha256 must match: %s" % path)


func _get_project_root() -> String:
	var args := OS.get_cmdline_user_args()
	for index in range(args.size() - 1):
		if args[index] == "--project-root":
			return str(args[index + 1]).simplify_path()
	return ""


func _rooted(path: String) -> String:
	return _project_root.path_join(path)


func _file_exists(path: String) -> bool:
	return FileAccess.file_exists(_rooted(path))


func _is_repo_relative(path: String) -> bool:
	return not path.is_empty() and not path.begins_with("/") and not path.begins_with("\\") and not (path.length() > 1 and path.substr(1, 1) == ":")


func _is_commit_sha(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[0-9a-fA-F]{7,40}$")
	return regex.search(value) != null


func _is_sha256(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[0-9a-fA-F]{64}$")
	return regex.search(value) != null


func _line_count(text: String) -> int:
	return 0 if text.strip_edges().is_empty() else text.strip_edges().split("\n").size()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("project_current_truth_contract: PASS")
		quit(0)
		return
	for failure in _failures:
		push_error("project_current_truth_contract: %s" % failure)
	quit(1)
