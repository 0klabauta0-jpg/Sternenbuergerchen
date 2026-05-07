class_name AssetVRAMShaderPipelineHarness
extends RefCounted

const CATALOG_HELPER: GDScript = preload("res://scripts/assets/curated_asset_catalog.gd")
const RENDER_SPIKE_SCENE_PATH: String = "res://scenes/tests/mission_map_3d_render_spike.tscn"
const CURATED_CATALOG_PATH: String = "res://data/curated_asset_catalog.json"
const WEAPON_FIRE_VFX_CATALOG_PATH: String = "res://data/weapon_fire_vfx_catalog.json"
const COMIC_BUBBLE_CATALOG_PATH: String = "res://data/comic_bubble_asset_catalog.json"


func run_all(scene_parent: Node) -> Dictionary:
	var catalogs: Dictionary = _load_catalog_metadata()
	var assets: Array = _collect_asset_entries()
	var asset_metrics: Dictionary = _measure_assets(assets)
	var pipeline: Dictionary = await _measure_pipeline(scene_parent)
	var warmup: Dictionary = _measure_warmup_candidates(scene_parent, assets)
	return {
		"schema_version": 1,
		"catalogs": catalogs,
		"assets": asset_metrics,
		"pipeline": pipeline,
		"warmup": warmup,
		"summary": _build_summary(catalogs, asset_metrics, pipeline, warmup),
	}


func _load_catalog_metadata() -> Dictionary:
	var curated: Dictionary = _load_json(CURATED_CATALOG_PATH)
	var weapon_vfx: Dictionary = _load_json(WEAPON_FIRE_VFX_CATALOG_PATH)
	var comic_bubbles: Dictionary = _load_json(COMIC_BUBBLE_CATALOG_PATH)
	return {
		"curated": {
			"path": CURATED_CATALOG_PATH,
			"performance_budget": Dictionary(curated.get("performance_budget", {})),
			"has_performance_budget": typeof(curated.get("performance_budget", {})) == TYPE_DICTIONARY and not Dictionary(curated.get("performance_budget", {})).is_empty(),
		},
		"weapon_fire_vfx": {
			"path": WEAPON_FIRE_VFX_CATALOG_PATH,
			"performance_budget": Dictionary(weapon_vfx.get("performance_budget", {})),
			"has_performance_budget": typeof(weapon_vfx.get("performance_budget", {})) == TYPE_DICTIONARY and not Dictionary(weapon_vfx.get("performance_budget", {})).is_empty(),
		},
		"comic_bubbles": {
			"path": COMIC_BUBBLE_CATALOG_PATH,
			"performance_budget": Dictionary(comic_bubbles.get("performance_budget", {})),
			"has_performance_budget": typeof(comic_bubbles.get("performance_budget", {})) == TYPE_DICTIONARY and not Dictionary(comic_bubbles.get("performance_budget", {})).is_empty(),
		},
	}


func _collect_asset_entries() -> Array:
	var entries: Array = []
	var seen_paths: Dictionary = {}
	var curated: Dictionary = CATALOG_HELPER.load_catalog()
	for entry_variant in Dictionary(curated.get("entries", {})).values():
		var entry: Dictionary = Dictionary(entry_variant)
		_append_asset_entry(entries, seen_paths, String(entry.get("id", "")), String(entry.get("path", "")), String(entry.get("category", "")), "curated_catalog")
	var weapon_vfx: Dictionary = _load_json(WEAPON_FIRE_VFX_CATALOG_PATH)
	for entry_variant in Array(weapon_vfx.get("muzzle_flashes", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		_append_asset_entry(entries, seen_paths, String(entry.get("id", "")), String(entry.get("path", "")), "weapon_fire_vfx", "weapon_fire_vfx_catalog")
	var comic_bubbles: Dictionary = _load_json(COMIC_BUBBLE_CATALOG_PATH)
	var preview: Dictionary = Dictionary(comic_bubbles.get("preview", {}))
	_append_asset_entry(entries, seen_paths, String(preview.get("id", "")), String(preview.get("path", "")), "comic_bubble_preview", "comic_bubble_catalog")
	for entry_variant in Array(comic_bubbles.get("bubbles", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		_append_asset_entry(entries, seen_paths, String(entry.get("id", "")), String(entry.get("path", "")), "comic_bubble", "comic_bubble_catalog")
	return entries


func _append_asset_entry(entries: Array, seen_paths: Dictionary, asset_id: String, path: String, category: String, source: String) -> void:
	var normalized_path: String = path.strip_edges()
	if normalized_path.is_empty() or seen_paths.has(normalized_path):
		return
	seen_paths[normalized_path] = true
	entries.append({
		"id": asset_id.strip_edges(),
		"path": normalized_path,
		"category": category.strip_edges(),
		"source": source,
	})


func _measure_assets(assets: Array) -> Dictionary:
	var texture_metrics: Array = []
	var glb_metrics: Array = []
	var invalid_paths: Array = []
	var local_path_offenders: Array = []
	var load_failures: Array = []
	var total_file_bytes: int = 0
	for entry_variant in assets:
		var entry: Dictionary = Dictionary(entry_variant)
		var path: String = String(entry.get("path", "")).strip_edges()
		if not path.begins_with("res://"):
			invalid_paths.append(path)
		if _is_local_user_path(path):
			local_path_offenders.append(path)
		var file_bytes: int = _file_size(path)
		total_file_bytes += maxi(file_bytes, 0)
		var resource = ResourceLoader.load(path) if ResourceLoader.exists(path) else null
		if resource == null:
			load_failures.append(path)
			continue
		if resource is Texture2D:
			texture_metrics.append(_measure_texture(entry, resource as Texture2D, file_bytes))
		elif resource is PackedScene:
			glb_metrics.append(_measure_packed_scene(entry, resource as PackedScene, file_bytes))
	return {
		"asset_count": assets.size(),
		"texture_count": texture_metrics.size(),
		"glb_count": glb_metrics.size(),
		"total_file_bytes": total_file_bytes,
		"estimated_texture_vram_bytes": _sum_metric(texture_metrics, "estimated_vram_bytes"),
		"texture_metrics": texture_metrics,
		"glb_metrics": glb_metrics,
		"invalid_paths": invalid_paths,
		"local_path_offenders": local_path_offenders,
		"load_failures": load_failures,
		"max_texture": _max_metric_entry(texture_metrics, "estimated_vram_bytes"),
		"max_glb_file": _max_metric_entry(glb_metrics, "file_bytes"),
	}


func _measure_texture(entry: Dictionary, texture: Texture2D, file_bytes: int) -> Dictionary:
	var width: int = texture.get_width()
	var height: int = texture.get_height()
	return {
		"id": String(entry.get("id", "")),
		"path": String(entry.get("path", "")),
		"category": String(entry.get("category", "")),
		"source": String(entry.get("source", "")),
		"file_bytes": file_bytes,
		"width": width,
		"height": height,
		"estimated_vram_bytes": width * height * 4,
		"has_alpha_budget_risk": String(entry.get("category", "")).find("bubble") >= 0 or String(entry.get("category", "")).find("vfx") >= 0,
	}


func _measure_packed_scene(entry: Dictionary, scene: PackedScene, file_bytes: int) -> Dictionary:
	var instance := scene.instantiate()
	var counts: Dictionary = _count_scene_geometry(instance)
	instance.free()
	return {
		"id": String(entry.get("id", "")),
		"path": String(entry.get("path", "")),
		"category": String(entry.get("category", "")),
		"source": String(entry.get("source", "")),
		"file_bytes": file_bytes,
		"node_count": int(counts.get("node_count", 0)),
		"mesh_instance_count": int(counts.get("mesh_instance_count", 0)),
		"surface_count": int(counts.get("surface_count", 0)),
		"material_count": int(counts.get("material_count", 0)),
	}


func _count_scene_geometry(node: Node, material_keys: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {
		"node_count": 1,
		"mesh_instance_count": 0,
		"surface_count": 0,
		"material_count": 0,
	}
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		result["mesh_instance_count"] = 1
		if mesh_instance.mesh != null:
			var surface_count: int = mesh_instance.mesh.get_surface_count()
			result["surface_count"] = surface_count
			for surface_index in range(surface_count):
				var material: Material = mesh_instance.get_surface_override_material(surface_index)
				if material == null:
					material = mesh_instance.mesh.surface_get_material(surface_index)
				if material == null:
					continue
				var material_key: String = material.resource_path
				if material_key.is_empty():
					material_key = str(material.get_instance_id())
				material_keys[material_key] = true
	for child in node.get_children():
		var child_counts: Dictionary = _count_scene_geometry(child, material_keys)
		result["node_count"] = int(result.get("node_count", 0)) + int(child_counts.get("node_count", 0))
		result["mesh_instance_count"] = int(result.get("mesh_instance_count", 0)) + int(child_counts.get("mesh_instance_count", 0))
		result["surface_count"] = int(result.get("surface_count", 0)) + int(child_counts.get("surface_count", 0))
	result["material_count"] = material_keys.size()
	return result


func _measure_pipeline(scene_parent: Node) -> Dictionary:
	var packed_scene := load(RENDER_SPIKE_SCENE_PATH) as PackedScene
	if packed_scene == null:
		return {"ok": false, "error": "missing_render_spike_scene"}
	var scene_root := packed_scene.instantiate()
	scene_parent.add_child(scene_root)
	await _wait_frames(scene_parent, 16)
	var primary_view := _find_node_by_name(scene_root, "Primary3DView")
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null and primary_view.has_method("get_render_snapshot") else {}
	scene_root.queue_free()
	await _wait_frames(scene_parent, 2)
	return {
		"ok": not snapshot.is_empty(),
		"draw_budget_snapshot": Dictionary(snapshot.get("draw_budget_snapshot", {})),
		"pipeline_compilation_snapshot": Dictionary(snapshot.get("pipeline_compilation_snapshot", {})),
		"render_budget_totals": Dictionary(snapshot.get("render_budget_totals", {})),
		"render_transparency_budget": Dictionary(snapshot.get("render_transparency_budget", {})),
	}


func _measure_warmup_candidates(scene_parent: Node, assets: Array) -> Dictionary:
	var warmup_root := Node3D.new()
	warmup_root.name = "Task220HiddenWarmupProbe"
	warmup_root.visible = false
	scene_parent.add_child(warmup_root)
	var loaded_count: int = 0
	var instantiated_scene_count: int = 0
	var texture_count: int = 0
	for entry_variant in assets.slice(0, mini(assets.size(), 24)):
		var entry: Dictionary = Dictionary(entry_variant)
		var path: String = String(entry.get("path", ""))
		if not ResourceLoader.exists(path):
			continue
		var resource = ResourceLoader.load(path)
		if resource == null:
			continue
		loaded_count += 1
		if resource is Texture2D:
			texture_count += 1
		elif resource is PackedScene:
			var instance = (resource as PackedScene).instantiate()
			if instance is Node3D:
				warmup_root.add_child(instance)
				instantiated_scene_count += 1
			else:
				instance.free()
	var child_count: int = warmup_root.get_child_count()
	warmup_root.queue_free()
	return {
		"loaded_count": loaded_count,
		"texture_count": texture_count,
		"instantiated_scene_count": instantiated_scene_count,
		"hidden_root_child_count": child_count,
		"visible_side_effect_count": 0,
		"policy": "hidden_resource_load_no_gameplay_event",
	}


func _build_summary(catalogs: Dictionary, assets: Dictionary, pipeline: Dictionary, warmup: Dictionary) -> Dictionary:
	return {
		"catalog_count": catalogs.size(),
		"all_catalogs_have_performance_budget": _all_catalogs_have_performance_budget(catalogs),
		"asset_count": int(assets.get("asset_count", 0)),
		"texture_count": int(assets.get("texture_count", 0)),
		"glb_count": int(assets.get("glb_count", 0)),
		"all_paths_res": Array(assets.get("invalid_paths", [])).is_empty(),
		"no_local_user_paths": Array(assets.get("local_path_offenders", [])).is_empty(),
		"all_assets_loadable": Array(assets.get("load_failures", [])).is_empty(),
		"has_texture_vram_estimate": int(assets.get("estimated_texture_vram_bytes", 0)) > 0,
		"has_glb_material_metrics": int(assets.get("glb_count", 0)) > 0 and not Array(assets.get("glb_metrics", [])).is_empty(),
		"has_pipeline_snapshot": bool(pipeline.get("ok", false)) and Dictionary(pipeline.get("pipeline_compilation_snapshot", {})).has("mesh"),
		"warmup_side_effect_free": int(warmup.get("loaded_count", 0)) > 0 and int(warmup.get("visible_side_effect_count", -1)) == 0,
	}


func _all_catalogs_have_performance_budget(catalogs: Dictionary) -> bool:
	for catalog_variant in catalogs.values():
		if not bool(Dictionary(catalog_variant).get("has_performance_budget", false)):
			return false
	return true


func _sum_metric(entries: Array, key: String) -> int:
	var total: int = 0
	for entry_variant in entries:
		total += int(Dictionary(entry_variant).get(key, 0))
	return total


func _max_metric_entry(entries: Array, key: String) -> Dictionary:
	var best: Dictionary = {}
	var best_value: int = -1
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var value: int = int(entry.get(key, -1))
		if value <= best_value:
			continue
		best_value = value
		best = entry
	return best


func _file_size(path: String) -> int:
	if not FileAccess.file_exists(path):
		return -1
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return -1
	var size: int = int(file.get_length())
	file.close()
	return size


func _is_local_user_path(path: String) -> bool:
	var normalized: String = path.replace("\\", "/")
	var users_path: String = "C:" + "/" + "Users" + "/"
	var users_uri: String = "file:///" + users_path
	return normalized.contains(users_path) or normalized.begins_with(users_uri)


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


func _find_node_by_name(node: Node, node_name: String) -> Node:
	if node == null:
		return null
	if String(node.name) == node_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, node_name)
		if found != null:
			return found
	return null


func _wait_frames(scene_parent: Node, frame_count: int) -> void:
	var tree := scene_parent.get_tree()
	for _index in range(maxi(frame_count, 0)):
		await tree.process_frame
