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


static func get_mission_hud_layout(viewport_size: Vector2i = TARGET_VIEWPORT) -> Dictionary:
	var large: bool = viewport_size.y >= 1260
	var medium: bool = viewport_size.y >= 900
	var action: int = 72 if large else (64 if medium else 52)
	var gap: int = 8 if medium else 6
	var inset: int = 12 if large else 8
	var edge: int = 24 if large else 16
	var card_width: int = 376 if large else (312 if medium else 280)
	var portrait_height: int = 96 if large else (88 if medium else 80)
	var band_height: int = 2 * action + 3 * inset
	var band_top: int = viewport_size.y - band_height
	var team_height: int = portrait_height + 48
	var team_top: int = band_top - team_height - 12
	var mini_top: int = 96 if medium else 88
	var mini_height: int = mini(680 if large else 480, maxi(120, team_top - mini_top - 12))
	var command_width: int = 5 * action + 4 * gap + 2 * inset
	var transport_width: int = 376 if large else (312 if medium else 280)
	var objective_width: int = 504 if large else (440 if medium else 392)
	var target_width: int = 344 if large else (320 if medium else 272)
	var event_log_height: int = 152 if large else (120 if medium else 104)
	return {
		"viewport": Rect2i(Vector2i.ZERO, viewport_size),
		"mission_identity": Rect2i(viewport_size.x - transport_width - objective_width - 2 * edge - 12, edge, objective_width, 72 if large else (64 if medium else 56)),
		"top_nav": Rect2i(edge, edge, 528 if large else (440 if medium else 384), 72 if large else (64 if medium else 56)),
		"fireteam_mini": Rect2i(edge, team_top - mini_height - 12, card_width + 16, mini_height),
		"event_log": Rect2i(viewport_size.x - transport_width - edge, band_top - event_log_height - (12 if large else 16), transport_width, event_log_height),
		"bottom_dock": Rect2i(0, band_top, viewport_size.x, band_height),
		"command_matrix": Rect2i(0, band_top, command_width, band_height),
		"target_order": Rect2i(command_width + gap, band_top, target_width, band_height),
		"team_parameters": Rect2i(command_width + gap + target_width + gap, band_top, 528, band_height),
		"selected_fireteam": Rect2i(edge, team_top, card_width, team_height),
		"selected_members": Rect2i(edge, team_top, card_width, portrait_height),
		"mission_control": Rect2i(viewport_size.x - transport_width - edge, edge, transport_width, 200 if large else (176 if medium else 160)),
		"action_edge": action, "action_gap": gap, "action_inset": inset,
		"card_width": card_width, "portrait_height": portrait_height,
		"body_font_size": 18 if large else (16 if medium else 14),
		"heading_font_size": 26 if large else (23 if medium else 20),
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
