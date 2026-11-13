extends SceneTree
## Read-only accounting of actual unique retained cache resources; not a start gate.
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
var passed := 0
var failed := 0
var _owners: Dictionary = {}

func _init() -> void:
	if GUARD.require_isolated_user_data(): call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func _run() -> void:
	var map = MAP.load_from_file("res://maps/satellite_crash_site.json")
	var view = VIEW.new()
	root.add_child(view)
	view.hide()
	view.set_authoring_markers_visible(false)
	await process_frame
	view.configure_terrain_resource_prefill(map)
	var deadline := Time.get_ticks_msec() + 120000
	var state: Dictionary = view.get_terrain_resource_preparation_snapshot()
	while state.status == "preparing_resources" and Time.get_ticks_msec() < deadline:
		await process_frame
		state = view.get_terrain_resource_preparation_snapshot()
	view.set_process(false)
	var cache: RefCounted = view.get("_terrain_resource_cache")
	var before: Dictionary = cache.get_debug_snapshot()
	for chunk: Dictionary in cache.get("_chunks").values(): _visit(chunk.descriptor)
	var resources: Dictionary = cache.get("_resources")
	var by_name: Dictionary = {}
	var total := 0
	for id in resources:
		var names: Array = _owners.get(id, {}).keys()
		names.sort()
		var category := "+".join(PackedStringArray(names))
		var bytes: int = cache.call("_resource_payload_bytes", resources[id])
		total += bytes
		if not by_name.has(category): by_name[category] = {"name":category,"bytes":0,"resources":0}
		by_name[category].bytes += bytes
		by_name[category].resources += 1
	var ordered: Array = by_name.values()
	ordered.sort_custom(func(a:Dictionary,b:Dictionary): return a.bytes > b.bytes)
	print("RESOURCE_PAYLOAD_BREAKDOWN ", JSON.stringify({"preparation":state,"cache":before,"unique_bytes_sum":total,"unique_resources_seen":_owners.size(),"category_count":ordered.size(),"largest_categories":ordered.slice(0,25)}))
	_check(state.ready or state.reason == "resource_payload_budget_exceeded", "actual production preparation reaches a measured terminal state")
	_check(total == before.geometry_payload_bytes, "category bytes exactly reconcile with unchanged owner accounting")
	_check(_owners.size() == resources.size(), "each retained resource is classified once by identity, including shared resources")
	_check(cache.get_debug_snapshot() == before, "diagnostic reads preserve the complete cache owner state")
	view.queue_free()
	await process_frame
	print("RESOURCE_PAYLOAD_DIAGNOSTIC passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _visit(record: Dictionary) -> void:
	var name := String(record.name)
	if record.get("mesh") is Mesh: _mark(record.mesh, name)
	if record.get("multimesh") is MultiMesh:
		_mark(record.multimesh, name + ":instance_buffer")
		if record.multimesh.mesh != null: _mark(record.multimesh.mesh, name + ":base_mesh")
	for child: Dictionary in record.children: _visit(child)

func _mark(resource: Resource, name: String) -> void:
	var id := resource.get_instance_id()
	if not _owners.has(id): _owners[id] = {}
	_owners[id][name] = true
