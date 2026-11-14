extends RefCounted
## Public game choices. Historical fixtures remain available to tests/imports,
## but are not advertised as complete playable missions by the multiplayer UI.
const PLAYABLE: PackedStringArray = [
	"res://maps/Ground_Mission01_32x32.json",
	"res://maps/Ground_Mission02_128x128.json",
	"res://maps/fireteam_command_drill_24x24.json",
	"res://maps/frontier_workyard_24x20.json",
	"res://maps/station_outpost_64x64.json",
	"res://maps/station_outpost_192x192.json",
	"res://maps/wall_test_4x4.json",
	"res://maps/satellite_crash_site.json",
	"res://maps/trade_outpost.json",
	"res://maps/fortified_outpost.json",
	"res://maps/windbruch_outpost.json",
	"res://maps/polisa_station.json",
	"res://maps/distress_orbit.json",
	"res://maps/test_mission.json",
	"res://maps/test_mission_32x32_slots8.json",
]
const BASES: PackedStringArray = [
	"res://maps/campaign_intro_base.json",
	"res://maps/homebase_frontier_exploration.json",
	"res://maps/base_interior_navigation.json",
]

static func all_paths() -> PackedStringArray:
	var paths := PLAYABLE.duplicate()
	paths.append_array(BASES)
	return paths

const HISTORICAL_FIXTURES: PackedStringArray = [
	"editor_terrain_visual_recovery_reference.json", "enemy_tactics_smoke_32x32.json",
	"facing_sightline_debug_12x12.json", "hill_mechanics_16x16_testmap.json",
	"task_156_contract_map.json", "task_157_editor_mvp_map.json",
	"test_lz_air_asset_threat_fixture.json",
	"Test_mission_32x32.json", # Commented one-tile template, not valid map JSON.
]

static func is_historical_fixture(path: String) -> bool:
	return path.begins_with("res://maps/legacy/") or (path.get_base_dir() == "res://maps" and HISTORICAL_FIXTURES.has(path.get_file()))

static func playable_paths() -> PackedStringArray:
	var paths := PLAYABLE.duplicate()
	for filename: String in DirAccess.get_files_at("res://maps"):
		var path := "res://maps/" + filename
		if not filename.ends_with(".json") or paths.has(path) or BASES.has(path) or is_historical_fixture(path): continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary and data.get("tiles") is Array and not data.tiles.is_empty() and data.get("grid_size") is Dictionary: paths.append(path)
	return paths
