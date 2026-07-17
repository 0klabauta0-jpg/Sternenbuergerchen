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

var _failures: Array[String] = []


func _init() -> void:
	_check_required_files()
	_check_current_documents()
	_check_manifest()
	_check_compatibility_contracts()
	_finish()


func _check_required_files() -> void:
	for path in CURRENT_DOCUMENTS:
		_expect(FileAccess.file_exists(path), "missing current document: %s" % path)
	_expect(FileAccess.file_exists("docs/reports/README.md"), "missing report snapshot index")
	_expect(FileAccess.file_exists("data/project_evidence_manifest.json"), "missing evidence manifest")


func _check_current_documents() -> void:
	for path in CURRENT_DOCUMENTS:
		if not FileAccess.file_exists(path):
			continue
		var text := _read_text(path)
		_expect(_line_count(text) <= int(CURRENT_DOCUMENTS[path]), "%s exceeds its %d-line budget" % [path, CURRENT_DOCUMENTS[path]])

	if FileAccess.file_exists("docs/CURRENT_GAME_STATE.md"):
		var current_state := _read_text("docs/CURRENT_GAME_STATE.md")
		_expect(current_state.contains("TASK_1179"), "current state must classify TASK_1179")
		_expect(current_state.contains("historische 18/18"), "current state must preserve the historical TASK_1179 result")
		_expect(current_state.contains("kein frischer"), "current state must keep the TASK_1179 freshness caveat")
		_expect(current_state.contains("TASK_1180"), "current state must classify TASK_1180")
		_expect(current_state.contains("nicht integriert"), "current state must keep TASK_1180 unintegrated")

	_expect(_count_marker_in_docs("<!-- canonical-current-state: true -->") == 1, "exactly one document must declare canonical current state")
	_expect(_count_marker_in_docs("<!-- milestone: now -->") == 1, "exactly one milestone must be marked now")


func _check_manifest() -> void:
	var manifest_path := "data/project_evidence_manifest.json"
	if not FileAccess.file_exists(manifest_path):
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


func _check_compatibility_contracts() -> void:
	for path in ["docs/IMPLEMENTATION_STATUS.md", "docs/TASK_ROADMAP.md"]:
		_expect(_read_text(path).contains("Kompatibilitaetsledger"), "%s must retain a compatibility-ledger banner" % path)
	_expect(_read_text("docs/reports/README.md").contains("TASK_1181"), "report index must classify TASK_1181")
	_expect(_read_text("docs/reports/README.md").contains("supersedes"), "report index must expose supersedes metadata")
	_expect(_read_text("AGENTS.md").contains("Current Truth"), "AGENTS.md must define current-truth precedence")
	_expect(_read_text("docs/ARCHITECTURE.md").contains("Monolith"), "architecture must forbid documentation monoliths")
	_expect(_read_text("docs/CODEX_RULES.md").contains("Current Truth"), "rules must define current-truth precedence")


func _count_marker_in_docs(marker: String) -> int:
	return _count_marker_in_directory("docs", marker)


func _count_marker_in_directory(path: String, marker: String) -> int:
	var directory := DirAccess.open(path)
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
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()


func _line_count(text: String) -> int:
	return 0 if text.strip_edges().is_empty() else text.strip_edges().split("\n").size()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("project_current_truth_contract: PASS")
		quit(0)
	for failure in _failures:
		push_error("project_current_truth_contract: %s" % failure)
	quit(1)
