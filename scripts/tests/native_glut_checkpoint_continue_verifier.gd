extends SceneTree
## Resume an existing checkpoint copied to a caller-owned APPDATA directory.
const START = preload("res://scripts/meta/game_start_contract.gd")
const FLOW = preload("res://scenes/meta/meta_layer_test.tscn")
const STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var appdata := OS.get_environment("APPDATA").replace("\\", "/")
	var profile := ProjectSettings.globalize_path("user://").replace("\\", "/")
	if args.size() != 1 or not appdata.contains("/output/native_glut_maps/profiles/") or not profile.begins_with(appdata + "/"):
		push_error("Use an isolated native_glut_maps APPDATA profile")
		quit(2)
		return
	var original_hash := FileAccess.get_sha256(args[0])
	var data := FileAccess.get_file_as_bytes(args[0])
	if data.is_empty():
		quit(2)
		return
	var target: String = STORE.DEFAULT_PATH
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target.get_base_dir()))
	var file := FileAccess.open(target, FileAccess.WRITE)
	file.store_buffer(data)
	file.close()
	var saved: Dictionary = STORE.load_checkpoint()
	if not saved.get("ok", false):
		print("OLD_GLUT_CHECKPOINT rejected: ", saved.get("reason", "unknown"))
		quit(1)
		return
	START.request_start(self, "campaign", "continue")
	var flow: Node = FLOW.instantiate()
	root.add_child(flow)
	await process_frame
	var runtime: Dictionary = flow.get_singleplayer_snapshot()
	var grounded: bool = flow.is_campaign_start() and runtime.space_travel.phase == "grounded" and runtime.space_travel.system_version == 2
	var progress_ok := true
	for key in Dictionary(saved.payload.campaign.get("progress", {})):
		progress_ok = progress_ok and runtime.campaign.progress.get(key) == saved.payload.campaign.progress[key]
	var adapter: Node = flow.get("_singleplayer_runtime")
	var supply_owner = adapter.get("_supply")
	var restored: Dictionary = supply_owner.export_state()
	var resources_ok := true
	for id in Dictionary(saved.payload.supply.get("location_resources", {})):
		var actual: Dictionary = restored.location_resources.get(id, {})
		for site in Dictionary(saved.payload.supply.location_resources[id]):
			var prior: Dictionary = saved.payload.supply.location_resources[id][site]
			var now: Dictionary = actual.get(site, {})
			resources_ok = resources_ok and int(now.get("remaining", -1)) == int(prior.get("remaining", -2))
			resources_ok = resources_ok and now.get("discovered") == prior.get("discovered")
	var source_unchanged := FileAccess.get_sha256(args[0]) == original_hash
	var valid := grounded and progress_ok and resources_ok and source_unchanged
	print("OLD_GLUT_CHECKPOINT continue=", valid, " grounded=", grounded, " progress=", progress_ok,
		" resources=", resources_ok, " source_unchanged=", source_unchanged)
	flow.queue_free()
	await process_frame
	quit(0 if valid else 1)
