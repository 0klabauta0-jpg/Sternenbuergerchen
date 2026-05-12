class_name DropLightLayoutContract
extends RefCounted

const TARGET_VIEWPORT := Vector2i(1920, 1080)
const COMPACT_VIEWPORT := Vector2i(1280, 720)
const BASE_SPACING := 8
const PANEL_RADIUS_MAX := 6
const ACTION_BUTTON_SIZE := Vector2i(48, 48)
const SMALL_ACTION_BUTTON_SIZE := Vector2i(40, 40)
const COMPACT_ACTION_BUTTON_SIZE := Vector2i(40, 40)
const COMPACT_SMALL_ACTION_BUTTON_SIZE := Vector2i(32, 32)
const MISSION_SCOPE_HUD_ONLY := true

const PROFILE_FULL_HD := "full_hd"
const PROFILE_COMPACT_720 := "compact_720"

const SCREEN_FOB := "fob"
const SCREEN_HOMEBASE := "homebase"
const SCREEN_MISSION_HUD := "mission_hud"


static func get_component_names() -> PackedStringArray:
	return PackedStringArray([
		"Panel / Fixed",
		"NPC Card / Compact",
		"NPC Stack Card",
		"Ship Slot Card",
		"Status Badge",
		"Command Button",
		"Pad Field / 3x5",
	])


static func get_allowed_runtime_asset_paths() -> PackedStringArray:
	return PackedStringArray([
		"res://Assets/kenney_space-kit/Isometric/platform_large_NW.png",
		"res://Assets/kenney_space-kit/Isometric/craft_speederA_NE.png",
		"res://Assets/kenney_space-kit/Isometric/craft_speederB_NE.png",
		"res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png",
		"res://Assets/kenney_space-kit/Isometric/craft_speederD_NE.png",
		"res://Assets/kenney_space-kit/Isometric/craft_cargoA_NE.png",
		"res://Assets/used/npc/blaster_kit/previews/blaster-a.png",
		"res://Assets/used/npc/blaster_kit/previews/blaster-b.png",
	])


static func get_default_profile_id() -> String:
	return PROFILE_FULL_HD


static func get_profile_for_viewport(viewport_size: Vector2i) -> String:
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return PROFILE_FULL_HD
	if viewport_size.x <= 1366 or viewport_size.y <= 800:
		return PROFILE_COMPACT_720
	return PROFILE_FULL_HD


static func normalize_profile_id(profile_id: String) -> String:
	match profile_id.strip_edges().to_lower():
		PROFILE_COMPACT_720:
			return PROFILE_COMPACT_720
		_:
			return PROFILE_FULL_HD


static func get_profile_viewport(profile_id: String = PROFILE_FULL_HD) -> Vector2i:
	if normalize_profile_id(profile_id) == PROFILE_COMPACT_720:
		return COMPACT_VIEWPORT
	return TARGET_VIEWPORT


static func get_base_spacing(_profile_id: String = PROFILE_FULL_HD) -> int:
	return BASE_SPACING


static func get_action_button_size(profile_id: String = PROFILE_FULL_HD) -> Vector2i:
	if normalize_profile_id(profile_id) == PROFILE_COMPACT_720:
		return COMPACT_ACTION_BUTTON_SIZE
	return ACTION_BUTTON_SIZE


static func get_small_action_button_size(profile_id: String = PROFILE_FULL_HD) -> Vector2i:
	if normalize_profile_id(profile_id) == PROFILE_COMPACT_720:
		return COMPACT_SMALL_ACTION_BUTTON_SIZE
	return SMALL_ACTION_BUTTON_SIZE


static func get_layout(screen_id: String, profile_id: String = PROFILE_FULL_HD) -> Dictionary:
	match screen_id.strip_edges().to_lower():
		SCREEN_FOB:
			return get_fob_layout(profile_id)
		SCREEN_HOMEBASE:
			return get_homebase_layout(profile_id)
		SCREEN_MISSION_HUD:
			return get_mission_hud_layout(profile_id)
		_:
			return {}


static func get_fob_layout(profile_id: String = PROFILE_FULL_HD) -> Dictionary:
	if normalize_profile_id(profile_id) == PROFILE_COMPACT_720:
		return {
			"viewport": Rect2i(Vector2i.ZERO, COMPACT_VIEWPORT),
			"topbar": Rect2i(0, 0, 1280, 56),
			"unassigned_pool": Rect2i(16, 64, 168, 456),
			"fireteams": Rect2i(192, 64, 216, 456),
			"loadout": Rect2i(416, 64, 240, 456),
			"flightdeck": Rect2i(664, 64, 600, 456),
			"boarding_status": Rect2i(16, 536, 288, 168),
			"actions": Rect2i(320, 536, 328, 168),
			"flightdeck_stage": Rect2i(680, 96, 568, 320),
			"ship_slots": Rect2i(680, 424, 568, 144),
		}
	return {
		"viewport": Rect2i(Vector2i.ZERO, TARGET_VIEWPORT),
		"topbar": Rect2i(0, 0, 1920, 72),
		"unassigned_pool": Rect2i(24, 80, 240, 736),
		"fireteams": Rect2i(280, 80, 304, 736),
		"loadout": Rect2i(600, 80, 352, 736),
		"flightdeck": Rect2i(968, 80, 928, 736),
		"boarding_status": Rect2i(24, 832, 448, 224),
		"actions": Rect2i(488, 832, 464, 224),
		"flightdeck_stage": Rect2i(992, 128, 880, 560),
		"ship_slots": Rect2i(992, 704, 880, 240),
	}


static func get_homebase_layout(profile_id: String = PROFILE_FULL_HD) -> Dictionary:
	if normalize_profile_id(profile_id) == PROFILE_COMPACT_720:
		return {
			"viewport": Rect2i(Vector2i.ZERO, COMPACT_VIEWPORT),
			"topbar": Rect2i(0, 0, 1280, 56),
			"mission_brief": Rect2i(16, 64, 1248, 112),
			"roster": Rect2i(16, 184, 336, 520),
			"transfer_team": Rect2i(360, 184, 288, 520),
			"flightdeck": Rect2i(656, 184, 336, 520),
			"character_sheet": Rect2i(1000, 184, 264, 520),
		}
	return {
		"viewport": Rect2i(Vector2i.ZERO, TARGET_VIEWPORT),
		"topbar": Rect2i(0, 0, 1920, 64),
		"mission_brief": Rect2i(24, 80, 1872, 112),
		"roster": Rect2i(24, 200, 520, 856),
		"transfer_team": Rect2i(560, 200, 424, 856),
		"flightdeck": Rect2i(1000, 200, 520, 856),
		"character_sheet": Rect2i(1536, 200, 360, 856),
	}


static func get_mission_hud_layout(profile_id: String = PROFILE_FULL_HD) -> Dictionary:
	if normalize_profile_id(profile_id) == PROFILE_COMPACT_720:
		return {
			"viewport": Rect2i(Vector2i.ZERO, COMPACT_VIEWPORT),
			"mission_identity": Rect2i(16, 16, 248, 72),
			"top_nav": Rect2i(456, 16, 376, 56),
			"fireteam_mini": Rect2i(16, 88, 208, 272),
			"bottom_dock": Rect2i(0, 520, 1280, 200),
			"command_matrix": Rect2i(16, 528, 264, 176),
			"selected_fireteam": Rect2i(288, 528, 696, 176),
			"mission_control": Rect2i(992, 528, 272, 176),
		}
	return {
		"viewport": Rect2i(Vector2i.ZERO, TARGET_VIEWPORT),
		"mission_identity": Rect2i(24, 24, 360, 80),
		"top_nav": Rect2i(720, 24, 480, 56),
		"fireteam_mini": Rect2i(24, 128, 280, 360),
		"bottom_dock": Rect2i(0, 800, 1920, 280),
		"command_matrix": Rect2i(24, 808, 304, 248),
		"selected_fireteam": Rect2i(344, 808, 1192, 248),
		"mission_control": Rect2i(1552, 808, 344, 248),
	}


static func get_mission_forbidden_runtime_targets() -> PackedStringArray:
	return PackedStringArray([
		"TerrainMap3DView",
		"SimulationRoot",
		"MissionCombatLoopDriver",
		"Pathfinder",
		"TerrainMapData",
	])


static func is_rect_on_base_grid(rect: Rect2i) -> bool:
	return rect.position.x % BASE_SPACING == 0 \
		and rect.position.y % BASE_SPACING == 0 \
		and rect.size.x % BASE_SPACING == 0 \
		and rect.size.y % BASE_SPACING == 0


static func is_rect_inside_viewport(rect: Rect2i, profile_id: String = PROFILE_FULL_HD) -> bool:
	var viewport_size: Vector2i = get_profile_viewport(profile_id)
	return rect.position.x >= 0 \
		and rect.position.y >= 0 \
		and rect.end.x <= viewport_size.x \
		and rect.end.y <= viewport_size.y
