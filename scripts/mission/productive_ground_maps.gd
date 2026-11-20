extends RefCounted
## Public game choices. Test-only maps remain loadable for tests,
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
## Maps that are intentionally NOT offered to the player (old graphics style,
## practice and test maps). They stay on disk and loadable (tests, editor,
## multiplayer runtime validation); the player's choice is SELECTABLE below.
const TEST_ONLY: PackedStringArray = [
	"res://maps/station_outpost_64x64.json",
	"res://maps/station_outpost_192x192.json",
	"res://maps/fireteam_command_drill_24x24.json",
	"res://maps/frontier_workyard_24x20.json",
	"res://maps/wall_test_4x4.json",
	"res://maps/test_mission.json",
	"res://maps/test_mission_32x32_slots8.json",
	"res://maps/distress_orbit.json",
	"res://maps/fortified_outpost.json",
]
## Explicit allow-list of what the player may pick (lobby, open-location lists), in display order.
const SELECTABLE: PackedStringArray = [
	"res://maps/Ground_Mission01_32x32.json",
	"res://maps/Ground_Mission02_128x128.json",
	"res://maps/satellite_crash_site.json",
	"res://maps/trade_outpost.json",
	"res://maps/windbruch_outpost.json",
	"res://maps/polisa_station.json",
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

static func playable_paths() -> PackedStringArray:
	var paths := PLAYABLE.duplicate()
	for filename: String in DirAccess.get_files_at("res://maps"):
		var path := "res://maps/" + filename
		if not filename.ends_with(".json") or paths.has(path) or BASES.has(path): continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary and data.get("tiles") is Array and not data.tiles.is_empty() and data.get("grid_size") is Dictionary: paths.append(path)
	return paths

## What the player may pick in lobby / open-location lists: the explicit SELECTABLE allow-list
## (existing files only). Fixtures auto-discovered by playable_paths() never leak in.
static func selectable_paths() -> PackedStringArray:
	var paths := PackedStringArray()
	for path: String in SELECTABLE:
		if FileAccess.file_exists(path): paths.append(path)
	return paths
