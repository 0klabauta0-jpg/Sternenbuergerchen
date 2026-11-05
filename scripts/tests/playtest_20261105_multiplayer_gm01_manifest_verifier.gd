extends SceneTree
const MANIFEST = preload("res://scripts/multiplayer/multiplayer_map_manifest.gd")
const MAP := "res://maps/Ground_Mission01_32x32.json"
var passed := 0
var failed := 0
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var entry: Dictionary = MANIFEST.build_manifest_for_map(MAP)
	check(bool(entry.get("valid", false)), "Real current default GM01 produces a valid multiplayer manifest")
	check(int(entry.map_size_bytes) == FileAccess.get_file_as_bytes(MAP).size(), "Manifest retains the exact real map size")
	check(String(entry.map_hash) == FileAccess.get_sha256(MAP), "Manifest retains the exact real map SHA-256")
	var known: Dictionary = MANIFEST.check_local_map(entry, [MAP])
	check(String(known.state) == "known" and not bool(known.requires_consent), "Matching installed GM01 is recognized without a download")
	var oversized := entry.duplicate(true)
	oversized.map_size_bytes = MANIFEST.MAX_MAP_BYTES + 1
	check(not bool(MANIFEST.verify_manifest(oversized).valid), "Above the bounded maximum remains rejected")
	var mismatch := entry.duplicate(true)
	mismatch.map_hash = "a".repeat(64)
	var mismatch_state: Dictionary = MANIFEST.check_local_map(mismatch, [MAP])
	check(String(mismatch_state.state) == "hash_mismatch" and bool(mismatch_state.requires_consent), "Changed same-ID map still requires explicit consent")
	check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("user://downloaded_maps")), "Manifest checks never write a downloaded map")
	print("GM01_MULTIPLAYER_MANIFEST: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)
