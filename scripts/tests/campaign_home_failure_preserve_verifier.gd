extends SceneTree
const HOME = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const ACTIVE = preload("res://scripts/meta/campaign_active_checkpoint_store.gd")
func _initialize() -> void:
	if OS.get_environment("POLISA_TEST_PROFILE").is_empty(): printerr("isolated profile required"); quit(1); return
	var loaded: Dictionary = HOME.load_checkpoint()
	var before := FileAccess.get_file_as_bytes(ACTIVE.DEFAULT_PATH)
	if not loaded.get("ok",false) or before.is_empty(): printerr("actual captured profile required"); quit(1); return
	var blocker := FileAccess.open("user://campaigns/active_write_blocker",FileAccess.WRITE)
	if blocker==null: printerr("fixture unavailable"); quit(1); return
	blocker.store_string("file, not directory"); blocker.close()
	var failed: Dictionary = HOME.save_checkpoint(loaded.payload,"user://campaigns/active_write_blocker/blocked.json")
	if failed.get("ok",false) or FileAccess.get_file_as_bytes(ACTIVE.DEFAULT_PATH)!=before: printerr("home write failure changed active save"); quit(1); return
	print("CAMPAIGN_HOME_FAILURE_PRESERVES_ACTIVE_PASS")
	quit(0)
