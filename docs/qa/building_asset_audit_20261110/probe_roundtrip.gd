extends SceneTree
## Audit only: source maps are never written. Scratch goes to a unique user directory.
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const NAV = preload("res://scripts/meta/base_interior_navigation.gd")
const REPORT = "res://docs/qa/building_asset_audit_20261110/roundtrip.json"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var rows: Array = []
	var valid := true
	var scratch := "user://building_asset_audit_20261110_%d/" % OS.get_process_id()
	for name in ["campaign_intro_base", "homebase_frontier_exploration", "trade_outpost", "satellite_crash_site", "Ground_Mission01_32x32"]:
		var source := "res://maps/%s.json" % name
		var before_hash := FileAccess.get_sha256(source)
		var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(source))
		var data = MAP.load_from_file(source)
		var target: String = scratch + name + ".json"
		var error: Error = data.save_to_file(target)
		var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(target)) if error == OK else {}
		var lost: Array = []
		for key in original:
			if not saved.has(key): lost.append(key)
		var same_source := before_hash == FileAccess.get_sha256(source)
		var row := {"source": source, "source_sha256": before_hash, "source_unchanged": same_source, "scratch": target, "save_error": error, "tiles_before": Array(original.get("tiles", [])).size(), "tiles_after": Array(saved.get("tiles", [])).size(), "lost_top_level_keys": lost, "place_presentation_preserved": original.get("place_presentation", {}) == saved.get("place_presentation", {})}
		rows.append(row)
		valid = valid and same_source and error == OK
		print(JSON.stringify(row))
	var active_layout: Dictionary = NAV.layout("res://maps/campaign_intro_base.json")
	var asset_paths: Array = []
	for asset in Array(active_layout.get("assets", [])):
		asset_paths.append({"id": asset.get("id"), "path": asset.get("path"), "exists": FileAccess.file_exists(String(asset.get("path", "")))})
	var output := {"scope": "Actual TerrainMapData save used by editor; scratch only; no rendering or original map writes", "engine": Engine.get_version_info().get("string"), "roundtrips": rows, "base_nav_layout_assets": asset_paths, "probe_executed_successfully": valid}
	var file := FileAccess.open(REPORT, FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "\t") + "\n")
	file.close()
	quit(0 if valid else 1)
