extends SceneTree
## Actual product resource paths, not an FPS or GPU-memory benchmark.
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const CATALOG = preload("res://scripts/mission/productive_ground_maps.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
var passed := 0
var failed := 0

func _init() -> void:
	if not GUARD.require_isolated_user_data(): return
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func _run() -> void:
	var paths: PackedStringArray = CATALOG.all_paths()
	_check(paths.size() == 18 and paths.has("res://maps/windbruch_outpost.json"), "all current authored productive ground/base starts including Windbruch are represented")
	# Integration runs may select one actual changed map; default still covers all.
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--map="):
			var selected: String = argument.trim_prefix("--map=")
			_check(paths.has(selected), "selected map belongs to the productive catalog")
			paths = PackedStringArray([selected]) if paths.has(selected) else PackedStringArray()
			break
	for path in paths:
		await _verify(path)
	print("REVIEW_MAP_PREPARATION passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _verify(path: String) -> void:
	var started := Time.get_ticks_msec()
	var map = MAP.load_from_file(path)
	_check(map != null, path + " actual terrain data loads")
	if map == null: return
	var tile_count: int = map.get_tiles().size()
	var view = VIEW.new()
	root.add_child(view)
	view.hide()
	view.set_authoring_markers_visible(false)
	await process_frame
	if map.get_regional_height_step() > 0.0:
		# Do not pass a budget override. This is the same hidden resource
		# producer called by the real surface approach owner.
		view.configure_terrain_resource_prefill(map)
		var deadline := Time.get_ticks_msec() + 120000
		var state: Dictionary = view.get_terrain_resource_preparation_snapshot()
		while state.status == "preparing_resources" and Time.get_ticks_msec() < deadline:
			await process_frame
			state = view.get_terrain_resource_preparation_snapshot()
		print("MAP_PREPARATION ", JSON.stringify({"map":path,"mode":"whole_map_resource_prefill","tiles":tile_count,"elapsed_ms":Time.get_ticks_msec()-started,"state":state}))
		_check(state.ready and state.prepared_chunks == state.expected_chunks and state.expected_chunks > 0, path + " every expected chunk is actually prepared")
		_check(state.max_payload_bytes == 256 * 1024 * 1024 and state.retained_payload_bytes > 0 and state.retained_payload_bytes <= state.max_payload_bytes, path + " actual measured payload respects unchanged 256 MiB product bound")
		_check(state.retained_scene_nodes == 0, path + " hidden whole-map preparation retains no chunk scene nodes")
		var cache: RefCounted = view.get_prepared_terrain_resource_cache()
		_check(cache != null, path + " only complete resource preparation yields a handoff")
		view.set_process(false)
		if cache != null:
			# Retire the producer exactly as Flow does; the actual receiving
			# view must reconstruct visible chunks from the complete cache.
			view.queue_free()
			await process_frame
			view = VIEW.new()
			root.add_child(view)
			view.hide()
			view.set_authoring_markers_visible(false)
			await process_frame
			view.set_prepared_terrain_resource_cache(cache)
			view.configure_from_map(map)
			view.set_process(false)
			var received: Dictionary = view.get_terrain_resource_preparation_snapshot()
			_check(received.ready and received.resource_restore_count > 0 and received.geometry_build_count == 0, path + " actual receiving view restores cached geometry without rebuilding it")
			_check(view.get_render_snapshot().rendered_tile_count > 0, path + " received cache produces real initial map geometry")
		else:
			view.cancel_terrain_resource_prefill()
	else:
		# The other authored maps use their normal direct/authoring renderer;
		# forcing them through the regional prefill API would be a false test.
		view.configure_from_map(map)
		view.set_process(false)
		var rendered: Dictionary = view.get_render_snapshot()
		_check(rendered.total_tile_count == tile_count and rendered.rendered_tile_count > 0, path + " normal product renderer consumes the actual map and creates initial geometry")
		print("MAP_PREPARATION ", JSON.stringify({"map":path,"mode":"normal_direct_renderer","tiles":tile_count,"rendered_tiles":rendered.rendered_tile_count,"elapsed_ms":Time.get_ticks_msec()-started}))
	view.queue_free()
	await process_frame
	await process_frame
