class_name DropLightLayoutContract
extends RefCounted

const TARGET_VIEWPORT := Vector2i(1920, 1080)
const BASE_SPACING := 8
const PANEL_RADIUS_MAX := 6
const ACTION_BUTTON_SIZE := Vector2i(48, 48)
const SMALL_ACTION_BUTTON_SIZE := Vector2i(40, 40)
const MISSION_SCOPE_HUD_ONLY := true

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


static func get_layout(screen_id: String) -> Dictionary:
	match screen_id.strip_edges().to_lower():
		SCREEN_FOB:
			return get_fob_layout()
		SCREEN_HOMEBASE:
			return get_homebase_layout()
		SCREEN_MISSION_HUD:
			return get_mission_hud_layout()
		_:
			return {}


static func get_fob_layout() -> Dictionary:
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


static func get_homebase_layout() -> Dictionary:
	return {
		"viewport": Rect2i(Vector2i.ZERO, TARGET_VIEWPORT),
		"topbar": Rect2i(0, 0, 1920, 64),
		"mission_brief": Rect2i(24, 80, 1872, 568),
		"roster": Rect2i(24, 664, 520, 392),
		"fireteams": Rect2i(560, 664, 456, 392),
		"transfer_team": Rect2i(560, 664, 456, 392),
		"flightdeck": Rect2i(1032, 664, 864, 392),
		"character_popup": Rect2i(1088, 144, 808, 840),
	}


static func get_mission_hud_layout() -> Dictionary:
	return {
		"viewport": Rect2i(Vector2i.ZERO, TARGET_VIEWPORT),
		"mission_identity": Rect2i(24, 24, 360, 80),
		"top_nav": Rect2i(768, 24, 384, 56),
		"fireteam_mini": Rect2i(24, 128, 240, 248),
		"event_log": Rect2i(24, 392, 240, 184),
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


static func is_rect_inside_viewport(rect: Rect2i) -> bool:
	return rect.position.x >= 0 \
		and rect.position.y >= 0 \
		and rect.end.x <= TARGET_VIEWPORT.x \
		and rect.end.y <= TARGET_VIEWPORT.y
