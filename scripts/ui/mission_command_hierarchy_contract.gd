class_name MissionCommandHierarchyContract
extends RefCounted

const SCHEMA_VERSION: int = 1
const VISUAL_ONLY: bool = true
const UI_SETS_GAMEPLAY_TRUTH: bool = false

const PANEL_COMMAND_MATRIX: String = "#16"
const PANEL_FIRETEAM_DETAILS: String = "#17"
const PANEL_MISSION_CONTROL: String = "#18"

const GROUP_GOAL: String = "goal"
const GROUP_RULE: String = "rule"
const GROUP_PLAN: String = "plan"
const GROUP_AIR_LZ: String = "air_lz"
const GROUP_BREAKOUT: String = "breakout"

const REASON_PHASE_PLANNING_HIDDEN: String = "phase_planning_hidden"
const REASON_SELECT_MULTIPLE_FIRETEAMS: String = "select_multiple_fireteams"
const REASON_NO_FIRETEAM_SELECTED: String = "no_fireteam_selected"
const REASON_INVALID_SELECTED_TILE: String = "invalid_selected_tile"
const REASON_NO_SELECTED_TILE: String = "no_selected_tile"
const REASON_OBSERVER_MODE: String = "observer_mode"
const REASON_PLANNING_LOCKED: String = "planning_locked"
const REASON_DROP_ALREADY_ACTIVE: String = "drop_already_active"
const REASON_DROP_AIR_LANE_BLOCKED: String = "drop_air_lane_blocked"
const REASON_DROPSHIP_UNAVAILABLE: String = "dropship_unavailable"
const REASON_DROP_COOLDOWN: String = "drop_cooldown"
const REASON_NO_LZ: String = "no_lz"
const REASON_NO_DROP_TEAM: String = "no_drop_team"
const REASON_NO_EXECUTABLE_ORDERS: String = "no_executable_orders"
const REASON_NO_PLAN_RESUME: String = "no_plan_resume"
const REASON_NO_DELETABLE_ORDER: String = "no_deletable_order"
const REASON_FUTURE_TASK: String = "future_task"
const REASON_MISSING_BUTTON: String = "missing_button"
const REASON_HIDDEN_IN_CONTEXT: String = "hidden_in_context"
const REASON_CONTEXT_GATED: String = "context_gated"
const REASON_PLAN_CONTEXT_MISSING: String = "plan_context_missing"
const REASON_AIR_CONTEXT_GATED: String = "air_context_gated"

const BUTTON_PATH_MOVE: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/MoveButton"
const BUTTON_PATH_HOLD: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/HoldButton"
const BUTTON_PATH_FLANK: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/FlankButton"
const BUTTON_PATH_TAKE: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TakeButton"
const BUTTON_PATH_TARGET: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TargetButton"
const BUTTON_PATH_CLEAR_TARGET: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/ClearTargetButton"
const BUTTON_PATH_DELETE_ORDER: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/DeleteOrderButton"
const BUTTON_PATH_SORT: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/SortCommandMatrixButton"
const BUTTON_PATH_SET_LZ: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/SetLZButton"
const BUTTON_PATH_CALL_DROPSHIP: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton"
const BUTTON_PATH_GO_PLAN: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/GoCommandMatrixButton"
const BUTTON_PATH_RETURN_TO_PLAN: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/PlanCommandMatrixButton"
const BUTTON_PATH_APPROACH_NW: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NWButton"
const BUTTON_PATH_APPROACH_NE: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NEButton"
const BUTTON_PATH_APPROACH_SW: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/SWButton"
const BUTTON_PATH_APPROACH_SE: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/SEButton"

static var _action_catalog_cache: Array = []


static func get_group_order() -> PackedStringArray:
	return PackedStringArray([GROUP_GOAL, GROUP_RULE, GROUP_PLAN, GROUP_AIR_LZ, GROUP_BREAKOUT])


static func get_group_labels() -> Dictionary:
	return {
		GROUP_GOAL: "Ziel",
		GROUP_RULE: "Regeln",
		GROUP_PLAN: "Plan",
		GROUP_AIR_LZ: "Air/LZ",
		GROUP_BREAKOUT: "Ausbruch",
	}


static func get_group_panel_roles() -> Dictionary:
	return {
		GROUP_GOAL: PANEL_COMMAND_MATRIX,
		GROUP_RULE: PANEL_FIRETEAM_DETAILS,
		GROUP_PLAN: PANEL_MISSION_CONTROL,
		GROUP_AIR_LZ: PANEL_MISSION_CONTROL,
		GROUP_BREAKOUT: PANEL_MISSION_CONTROL,
	}


static func get_group_help_ids() -> Dictionary:
	return {
		GROUP_GOAL: "mission.command.group.goal",
		GROUP_RULE: "mission.command.group.rule",
		GROUP_PLAN: "mission.command.group.plan",
		GROUP_AIR_LZ: "mission.command.group.air_lz",
		GROUP_BREAKOUT: "mission.command.group.breakout",
	}


static func get_action_catalog() -> Array:
	if _action_catalog_cache.is_empty():
		_action_catalog_cache = [
		_action("move", "Move", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.move", BUTTON_PATH_MOVE, {"requires_selection": true, "requires_tile_selection": true, "requires_local_command": true, "implemented": true, "context": "single_or_multi"}),
		_action("take", "Take", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.take", BUTTON_PATH_TAKE, {"requires_selection": true, "requires_tile_selection": true, "requires_local_command": true, "implemented": true, "context": "single_or_multi"}),
		_action("defend", "Defend", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.defend", BUTTON_PATH_HOLD, {"requires_selection": true, "requires_tile_selection": true, "requires_local_command": true, "implemented": true, "context": "single_or_multi"}),
		_action("engage", "Engage", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.attack_area", BUTTON_PATH_TARGET, {"requires_planning": true, "implemented": true, "context": "area"}),
		_action("secure", "Secure", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.defend_area", "", {"requires_selection": true, "requires_planning": true, "status_only": true, "context": "area"}),
		_action("recon", "Recon", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.area_order", "", {"requires_selection": true, "future_task": "future mission objective slice", "context": "area"}),
		_action("withdraw", "Withdraw", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.area_order", "", {"requires_selection": true, "future_task": "TASK_276 breakout behavior", "context": "breakout"}),
		_action("flank", "Flank", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.flank", BUTTON_PATH_FLANK, {"requires_selection": true, "requires_tile_selection": true, "requires_local_command": true, "implemented": true, "context": "single_or_multi"}),
		_action("clear_target", "Clear Target", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.clear_target", BUTTON_PATH_CLEAR_TARGET, {"requires_planning": true, "implemented": true, "context": "area"}),
		_action("delete_order", "Delete", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.clear_target", BUTTON_PATH_DELETE_ORDER, {"requires_planning": true, "implemented": true, "context": "waypoint_or_area"}),

		_action("tactical_stance", "Stance", GROUP_RULE, PANEL_FIRETEAM_DETAILS, "mission.command.stance", "", {"requires_selection": true, "implemented": true, "context": "single_or_multi", "status_source": "TacticalStanceController", "tooltip_hint": "Direct C/N/A stance toggle on each fireteam card."}),
		_action("tempo", "Tempo", GROUP_RULE, PANEL_FIRETEAM_DETAILS, "mission.rule.tempo", "", {"requires_selection": true, "status_only": true, "context": "single_or_multi", "status_source": "FTL profile and current command", "tooltip_hint": "Status value from FTL initiative, plan quality, and active order."}),
		_action("fire_rule", "Fire Rule", GROUP_RULE, PANEL_FIRETEAM_DETAILS, "mission.rule.fire_rule", "", {"requires_selection": true, "status_only": true, "context": "single_or_multi", "status_source": "FTL profile and current command", "tooltip_hint": "Status value from FTL discipline, command type, and contact posture."}),
		_action("contact_response", "Contact", GROUP_RULE, PANEL_FIRETEAM_DETAILS, "mission.rule.contact_response", "", {"requires_selection": true, "status_only": true, "context": "single_or_multi", "status_source": "FTL profile and current contacts", "tooltip_hint": "Status value from recognition, comms, and known contact state."}),
		_action("cover_priority", "Cover", GROUP_RULE, PANEL_FIRETEAM_DETAILS, "mission.rule.cover_priority", "", {"requires_selection": true, "status_only": true, "context": "single_or_multi", "status_source": "FTL profile and tactical stance", "tooltip_hint": "Status value from toughness, stance, terrain, and command type."}),
		_action("security_mode", "Security", GROUP_RULE, PANEL_FIRETEAM_DETAILS, "mission.rule.security_mode", "", {"requires_selection": true, "status_only": true, "context": "single_or_multi", "status_source": "FTL profile and area order", "tooltip_hint": "Status value from current order, overwatch, and contact risk."}),

		_action("role_suggestion", "Roles", GROUP_PLAN, PANEL_MISSION_CONTROL, "mission.command.go_plan", "", {"requires_multi_selection": true, "status_only": true, "context": "multi_fireteam"}),
		_action("swap_roles", "Swap", GROUP_PLAN, PANEL_MISSION_CONTROL, "mission.command.go_plan", "", {"requires_multi_selection": true, "future_task": "multi-plan edit UI", "context": "multi_fireteam"}),
		_action("preview_plan", "Preview", GROUP_PLAN, PANEL_MISSION_CONTROL, "mission.command.go_plan", "", {"requires_multi_selection": true, "status_only": true, "context": "multi_fireteam"}),
		_action("sort_fireteam", "Sort", GROUP_PLAN, PANEL_COMMAND_MATRIX, "mission.command.go_plan", BUTTON_PATH_SORT, {"requires_selection": true, "requires_local_command": true, "implemented": true, "context": "single_or_multi", "tooltip_hint": "Reorder the selected fireteam plan before issuing GO."}),
		_action("go_plan", "GO", GROUP_PLAN, PANEL_COMMAND_MATRIX, "mission.command.go_plan", BUTTON_PATH_GO_PLAN, {"requires_selection": true, "requires_local_command": true, "implemented": true, "context": "single_or_multi", "tooltip_hint": "Execute the selected planned order."}),
		_action("return_to_plan", "Plan", GROUP_PLAN, PANEL_COMMAND_MATRIX, "mission.command.go_plan", BUTTON_PATH_RETURN_TO_PLAN, {"requires_selection": true, "requires_local_command": true, "implemented": true, "context": "single_or_multi", "tooltip_hint": "Return selected fireteams to the planned route."}),

		_action("set_lz", "LZ", GROUP_AIR_LZ, PANEL_MISSION_CONTROL, "mission.command.set_lz", BUTTON_PATH_SET_LZ, {"requires_planning": true, "implemented": true, "context": "mission"}),
		_action("call_dropship", "Drop", GROUP_AIR_LZ, PANEL_MISSION_CONTROL, "mission.command.call_dropship", BUTTON_PATH_CALL_DROPSHIP, {"requires_planning": true, "requires_drop_available": true, "implemented": true, "context": "mission"}),
		_action("dropship_hold", "Hold Air", GROUP_AIR_LZ, PANEL_MISSION_CONTROL, "mission.command.call_dropship", "", {"future_task": "TASK_277 air asset threat controls", "context": "mission"}),
		_action("dropship_cancel", "Cancel Drop", GROUP_AIR_LZ, PANEL_MISSION_CONTROL, "mission.command.call_dropship", "", {"future_task": "TASK_277 air asset threat controls", "context": "mission"}),
		_action("lz_secure", "LZ Secure", GROUP_AIR_LZ, PANEL_MISSION_CONTROL, "mission.command.set_lz", "", {"requires_selection": true, "status_only": true, "context": "mission"}),
		_action("evac_recover", "Evac", GROUP_AIR_LZ, PANEL_MISSION_CONTROL, "mission.command.call_dropship", "", {"future_task": "TASK_278 air asset recovery loop", "context": "mission"}),
		_action("approach_nw", "NW", GROUP_AIR_LZ, PANEL_MISSION_CONTROL, "mission.command.approach", BUTTON_PATH_APPROACH_NW, {"requires_planning": true, "implemented": true, "context": "mission"}),
		_action("approach_ne", "NE", GROUP_AIR_LZ, PANEL_MISSION_CONTROL, "mission.command.approach", BUTTON_PATH_APPROACH_NE, {"requires_planning": true, "implemented": true, "context": "mission"}),
		_action("approach_sw", "SW", GROUP_AIR_LZ, PANEL_MISSION_CONTROL, "mission.command.approach", BUTTON_PATH_APPROACH_SW, {"requires_planning": true, "implemented": true, "context": "mission"}),
		_action("approach_se", "SE", GROUP_AIR_LZ, PANEL_MISSION_CONTROL, "mission.command.approach", BUTTON_PATH_APPROACH_SE, {"requires_planning": true, "implemented": true, "context": "mission"}),

		_action("confirm", "Confirm", GROUP_BREAKOUT, PANEL_MISSION_CONTROL, "mission.command.group.breakout", "", {"future_task": "TASK_276 tactical breakout behavior", "context": "breakout"}),
		_action("override", "Override", GROUP_BREAKOUT, PANEL_MISSION_CONTROL, "mission.command.group.breakout", "", {"future_task": "TASK_276 tactical breakout behavior", "context": "breakout"}),
		_action("abort", "Abort", GROUP_BREAKOUT, PANEL_MISSION_CONTROL, "mission.command.group.breakout", "", {"future_task": "TASK_276 tactical breakout behavior", "context": "breakout"}),
		_action("regroup", "Regroup", GROUP_BREAKOUT, PANEL_MISSION_CONTROL, "mission.command.group.breakout", "", {"future_task": "TASK_276 tactical breakout behavior", "context": "breakout"}),
	]
	return _duplicate_action_catalog(_action_catalog_cache)


static func build_hierarchy_snapshot(context: Dictionary, button_snapshots: Dictionary = {}) -> Dictionary:
	var labels: Dictionary = get_group_labels()
	var panels: Dictionary = get_group_panel_roles()
	var help_ids: Dictionary = get_group_help_ids()
	var groups_by_id: Dictionary = {}
	var actions_by_id: Dictionary = {}
	for group_id in get_group_order():
		groups_by_id[group_id] = {
			"group_id": group_id,
			"label": str(labels.get(group_id, group_id)),
			"panel_role": str(panels.get(group_id, "")),
			"help_id": str(help_ids.get(group_id, "")),
			"active": false,
			"disabled_reason": "",
			"disabled_reason_code": "",
			"disabled_reason_text": "",
			"disabled_reason_short": "",
			"action_count": 0,
			"active_action_count": 0,
			"implemented_action_count": 0,
			"actions": [],
		}

	for action_variant in get_action_catalog():
		var action: Dictionary = Dictionary(action_variant).duplicate(true)
		var action_id: String = str(action.get("action_id", ""))
		var button_snapshot: Dictionary = Dictionary(button_snapshots.get(action_id, {})) if button_snapshots.has(action_id) else {}
		var disabled_reason_code: String = resolve_disabled_reason_code(action, context, button_snapshot, button_snapshots.has(action_id))
		var disabled_reason: String = get_disabled_reason_legacy_text(disabled_reason_code, action)
		action["active"] = disabled_reason.is_empty()
		action["disabled"] = not disabled_reason.is_empty()
		action["disabled_reason"] = disabled_reason
		action["disabled_reason_code"] = disabled_reason_code
		action["disabled_reason_text"] = get_disabled_reason_text(disabled_reason_code, action)
		action["disabled_reason_short"] = get_disabled_reason_short_text(disabled_reason_code, action)
		action["button"] = button_snapshot
		action["visual_only"] = VISUAL_ONLY
		action["ui_sets_gameplay_truth"] = UI_SETS_GAMEPLAY_TRUTH
		actions_by_id[action_id] = action

		var group_id: String = str(action.get("group_id", ""))
		if not groups_by_id.has(group_id):
			continue
		var group: Dictionary = Dictionary(groups_by_id[group_id])
		group["action_count"] = int(group.get("action_count", 0)) + 1
		if bool(action.get("implemented", false)):
			group["implemented_action_count"] = int(group.get("implemented_action_count", 0)) + 1
		if bool(action.get("active", false)):
			group["active"] = true
			group["active_action_count"] = int(group.get("active_action_count", 0)) + 1
		var group_actions: Array = Array(group.get("actions", []))
		group_actions.append(action)
		group["actions"] = group_actions
		groups_by_id[group_id] = group

	var groups: Array = []
	for group_id in get_group_order():
		var group: Dictionary = Dictionary(groups_by_id[group_id])
		if not bool(group.get("active", false)):
			var group_reason_code: String = _resolve_group_disabled_reason_code(group_id, context)
			group["disabled_reason"] = _resolve_group_disabled_reason(group_id, context)
			group["disabled_reason_code"] = group_reason_code
			group["disabled_reason_text"] = get_disabled_reason_text(group_reason_code, {})
			group["disabled_reason_short"] = get_disabled_reason_short_text(group_reason_code, {})
		groups.append(group)

	return {
		"schema_version": SCHEMA_VERSION,
		"visual_only": VISUAL_ONLY,
		"ui_sets_gameplay_truth": UI_SETS_GAMEPLAY_TRUTH,
		"selected_fireteam_count": int(context.get("selected_fireteam_count", 0)),
		"single_fireteam_context": bool(context.get("single_fireteam_context", false)),
		"multi_fireteam_context": bool(context.get("multi_fireteam_context", false)),
		"has_selected_tile": bool(context.get("has_selected_tile", false)),
		"preview_mode": bool(context.get("preview_mode", false)),
		"panels": {
			PANEL_COMMAND_MATRIX: GROUP_GOAL,
			PANEL_FIRETEAM_DETAILS: GROUP_RULE,
			PANEL_MISSION_CONTROL: [GROUP_PLAN, GROUP_AIR_LZ, GROUP_BREAKOUT],
		},
		"groups": groups,
		"groups_by_id": groups_by_id,
		"actions_by_id": actions_by_id,
	}


static func build_dropship_command_matrix_layout_snapshot(context: Dictionary = {}) -> Dictionary:
	var disabled_reasons: PackedStringArray = PackedStringArray()
	if not bool(context.get("has_lz", context.get("has_lz_position", false))):
		disabled_reasons.append("no_lz")
	if not bool(context.get("has_pilot", false)):
		disabled_reasons.append("no_pilot")
	if not bool(context.get("has_boarded_team", false)):
		disabled_reasons.append("no_team_boarded")
	if not bool(context.get("has_dropship", true)):
		disabled_reasons.append("no_dropship")
	return {
		"go_action_id": "call_dropship",
		"go_button_panel_role": PANEL_COMMAND_MATRIX,
		"go_button_source_action": "call_dropship",
		"go_button_slot": "16.15",
		"plan_button_slot": "16.20",
		"legacy_window_17_go_removed": true,
		"status_preview_panel_role": PANEL_FIRETEAM_DETAILS,
		"lz_pick_panel_role": PANEL_COMMAND_MATRIX,
		"lz_pick_group": "target_selection_left",
		"approach_style_options": PackedStringArray(["vorsichtig", "normal", "aggressiv"]),
		"go_enabled": disabled_reasons.is_empty(),
		"disabled_reasons": disabled_reasons,
		"ui_sets_gameplay_truth": UI_SETS_GAMEPLAY_TRUTH,
	}


static func resolve_disabled_reason(action: Dictionary, context: Dictionary, button_snapshot: Dictionary = {}, has_button_snapshot: bool = false) -> String:
	return get_disabled_reason_legacy_text(resolve_disabled_reason_code(action, context, button_snapshot, has_button_snapshot), action)


static func resolve_disabled_reason_code(action: Dictionary, context: Dictionary, button_snapshot: Dictionary = {}, has_button_snapshot: bool = false) -> String:
	var action_id: String = str(action.get("action_id", ""))
	if bool(action.get("requires_phase_planning", false)) and not bool(context.get("phase_planning_enabled", false)):
		return REASON_PHASE_PLANNING_HIDDEN
	if bool(action.get("requires_multi_selection", false)) and int(context.get("selected_fireteam_count", 0)) < 2:
		return REASON_SELECT_MULTIPLE_FIRETEAMS
	if bool(action.get("requires_selection", false)) and int(context.get("selected_fireteam_count", 0)) <= 0:
		return REASON_NO_FIRETEAM_SELECTED
	if bool(action.get("requires_tile_selection", false)) and bool(context.get("requires_tile_selection", true)):
		if bool(context.get("has_selected_tile", false)) and not bool(context.get("selected_tile_valid", true)):
			return REASON_INVALID_SELECTED_TILE
		if not bool(context.get("has_selected_tile", false)):
			return REASON_NO_SELECTED_TILE
	if bool(action.get("requires_local_command", false)) and not bool(context.get("can_issue_local_commands", true)):
		return REASON_OBSERVER_MODE
	if bool(action.get("requires_planning", false)) and not bool(context.get("can_edit_planning", true)):
		return REASON_PLANNING_LOCKED
	if action_id == "call_dropship" and bool(context.get("drop_already_active", false)):
		return REASON_DROP_ALREADY_ACTIVE
	if action_id == "call_dropship" and bool(context.get("drop_air_lane_blocked", false)):
		return REASON_DROP_AIR_LANE_BLOCKED
	if bool(action.get("requires_drop_available", false)) and not bool(context.get("drop_available", true)):
		return REASON_DROPSHIP_UNAVAILABLE
	if action_id == "call_dropship" and float(context.get("drop_cooldown_remaining", 0.0)) > 0.0:
		return REASON_DROP_COOLDOWN
	if action_id == "call_dropship" and not bool(context.get("has_lz", context.get("has_lz_position", false))):
		return REASON_NO_LZ
	if action_id == "call_dropship" and not bool(context.get("drop_has_team", true)):
		return REASON_NO_DROP_TEAM
	if action_id == "go_plan" and not bool(context.get("has_selected_fireteam_orders_to_execute", true)):
		return REASON_NO_EXECUTABLE_ORDERS
	if action_id == "return_to_plan" and not bool(context.get("can_return_selected_fireteams_to_plan", true)):
		return REASON_NO_PLAN_RESUME
	if action_id == "delete_order" and not bool(context.get("has_deletable_order_focus", true)):
		return REASON_NO_DELETABLE_ORDER
	if not str(action.get("future_task", "")).is_empty():
		return REASON_FUTURE_TASK
	if has_button_snapshot:
		if not bool(button_snapshot.get("exists", false)):
			return REASON_MISSING_BUTTON
		if not bool(button_snapshot.get("visible", true)):
			return REASON_HIDDEN_IN_CONTEXT
		if bool(button_snapshot.get("disabled", false)):
			return REASON_CONTEXT_GATED
	return ""


static func get_disabled_reason_legacy_text(reason_code: String, action: Dictionary = {}) -> String:
	match reason_code:
		REASON_PHASE_PLANNING_HIDDEN:
			return "phase planning hidden in fixed HUD"
		REASON_SELECT_MULTIPLE_FIRETEAMS:
			return "select multiple fireteams"
		REASON_NO_FIRETEAM_SELECTED:
			return "select one or more fireteams"
		REASON_INVALID_SELECTED_TILE:
			return "select a valid map tile"
		REASON_NO_SELECTED_TILE:
			return "select a map tile"
		REASON_OBSERVER_MODE:
			return "host controls mission commands"
		REASON_PLANNING_LOCKED:
			return "planning locked in this mode"
		REASON_DROP_ALREADY_ACTIVE:
			return "dropship already active"
		REASON_DROP_AIR_LANE_BLOCKED:
			return "air lane blocked"
		REASON_DROPSHIP_UNAVAILABLE:
			return "dropship unavailable"
		REASON_DROP_COOLDOWN:
			return "dropship cooldown"
		REASON_NO_LZ:
			return "set LZ before drop call"
		REASON_NO_DROP_TEAM:
			return "no drop team available"
		REASON_NO_EXECUTABLE_ORDERS:
			return "plan an order before GO"
		REASON_NO_PLAN_RESUME:
			return "no plan route to resume"
		REASON_NO_DELETABLE_ORDER:
			return "select an order marker"
		REASON_FUTURE_TASK:
			return "reserved for %s" % str(action.get("future_task", "later task"))
		REASON_MISSING_BUTTON:
			return "not implemented in this slice"
		REASON_HIDDEN_IN_CONTEXT:
			return "hidden in current context"
		REASON_CONTEXT_GATED:
			return "context gated"
		REASON_PLAN_CONTEXT_MISSING:
			return "select multiple fireteams or build a plan"
		REASON_AIR_CONTEXT_GATED:
			return "planning or air context gated"
		_:
			return ""


static func get_disabled_reason_text(reason_code: String, _action: Dictionary = {}) -> String:
	match reason_code:
		REASON_PHASE_PLANNING_HIDDEN:
			return "Phase planning is hidden."
		REASON_SELECT_MULTIPLE_FIRETEAMS:
			return "Select at least two fireteams."
		REASON_NO_FIRETEAM_SELECTED:
			return "Select a fireteam."
		REASON_INVALID_SELECTED_TILE:
			return "Pick a valid map tile."
		REASON_NO_SELECTED_TILE:
			return "Pick a map tile."
		REASON_OBSERVER_MODE:
			return "Host controls mission commands."
		REASON_PLANNING_LOCKED:
			return "Planning is locked."
		REASON_DROP_ALREADY_ACTIVE:
			return "Dropship already active."
		REASON_DROP_AIR_LANE_BLOCKED:
			return "Air lane busy."
		REASON_DROPSHIP_UNAVAILABLE:
			return "Dropship unavailable."
		REASON_DROP_COOLDOWN:
			return "Dropship cooling down."
		REASON_NO_LZ:
			return "Set LZ first."
		REASON_NO_DROP_TEAM:
			return "Board a fireteam first."
		REASON_NO_EXECUTABLE_ORDERS:
			return "Plan an order first."
		REASON_NO_PLAN_RESUME:
			return "No route to resume."
		REASON_NO_DELETABLE_ORDER:
			return "Select an order marker."
		REASON_FUTURE_TASK:
			return "Reserved for a later task."
		REASON_MISSING_BUTTON:
			return "Not in this HUD slice."
		REASON_HIDDEN_IN_CONTEXT:
			return "Hidden in this context."
		REASON_CONTEXT_GATED:
			return "Blocked by current context."
		REASON_PLAN_CONTEXT_MISSING:
			return "Select multiple fireteams or build a plan."
		REASON_AIR_CONTEXT_GATED:
			return "Planning or air context blocked."
		_:
			return ""


static func get_disabled_reason_short_text(reason_code: String, _action: Dictionary = {}) -> String:
	match reason_code:
		REASON_PHASE_PLANNING_HIDDEN:
			return "Phase hidden"
		REASON_SELECT_MULTIPLE_FIRETEAMS:
			return "Select 2+ teams"
		REASON_NO_FIRETEAM_SELECTED:
			return "Select fireteam"
		REASON_INVALID_SELECTED_TILE:
			return "Invalid tile"
		REASON_NO_SELECTED_TILE:
			return "Pick tile"
		REASON_OBSERVER_MODE:
			return "Host only"
		REASON_PLANNING_LOCKED:
			return "Planning locked"
		REASON_DROP_ALREADY_ACTIVE:
			return "Drop active"
		REASON_DROP_AIR_LANE_BLOCKED:
			return "Air lane busy"
		REASON_DROPSHIP_UNAVAILABLE:
			return "No dropship"
		REASON_DROP_COOLDOWN:
			return "Cooldown"
		REASON_NO_LZ:
			return "Set LZ"
		REASON_NO_DROP_TEAM:
			return "Board team"
		REASON_NO_EXECUTABLE_ORDERS:
			return "Plan order"
		REASON_NO_PLAN_RESUME:
			return "No route"
		REASON_NO_DELETABLE_ORDER:
			return "Pick order"
		REASON_FUTURE_TASK:
			return "Later task"
		REASON_MISSING_BUTTON:
			return "Not present"
		REASON_HIDDEN_IN_CONTEXT:
			return "Hidden"
		REASON_CONTEXT_GATED:
			return "Blocked"
		REASON_PLAN_CONTEXT_MISSING:
			return "Plan missing"
		REASON_AIR_CONTEXT_GATED:
			return "Air blocked"
		_:
			return ""


static func build_button_metadata(action: Dictionary, context: Dictionary, button_snapshot: Dictionary = {}) -> Dictionary:
	var disabled_reason_code: String = resolve_disabled_reason_code(action, context, button_snapshot, not button_snapshot.is_empty())
	var disabled_reason: String = get_disabled_reason_legacy_text(disabled_reason_code, action)
	return {
		"command_hierarchy_action_id": str(action.get("action_id", "")),
		"command_hierarchy_group_id": str(action.get("group_id", "")),
		"command_hierarchy_panel_role": str(action.get("panel_role", "")),
		"command_hierarchy_help_id": str(action.get("help_id", "")),
		"command_hierarchy_context": str(action.get("context", "")),
		"command_hierarchy_tooltip_hint": str(action.get("tooltip_hint", "")),
		"command_hierarchy_status_source": str(action.get("status_source", "")),
		"command_hierarchy_requires_tile_selection": bool(action.get("requires_tile_selection", false)),
		"command_hierarchy_disabled_reason": disabled_reason,
		"command_hierarchy_disabled_reason_code": disabled_reason_code,
		"command_hierarchy_disabled_reason_text": get_disabled_reason_text(disabled_reason_code, action),
		"command_hierarchy_disabled_reason_short": get_disabled_reason_short_text(disabled_reason_code, action),
		"visual_only": VISUAL_ONLY,
		"ui_sets_gameplay_truth": UI_SETS_GAMEPLAY_TRUTH,
	}


static func _action(action_id: String, label: String, group_id: String, panel_role: String, help_id: String, button_path: String, options: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {
		"action_id": action_id,
		"label": label,
		"group_id": group_id,
		"panel_role": panel_role,
		"help_id": help_id,
		"button_path": button_path,
		"context": str(options.get("context", "mission")),
		"implemented": bool(options.get("implemented", false)),
		"status_only": bool(options.get("status_only", false)),
		"requires_selection": bool(options.get("requires_selection", false)),
		"requires_tile_selection": bool(options.get("requires_tile_selection", false)),
		"requires_multi_selection": bool(options.get("requires_multi_selection", false)),
		"requires_local_command": bool(options.get("requires_local_command", false)),
		"requires_planning": bool(options.get("requires_planning", false)),
		"requires_phase_planning": bool(options.get("requires_phase_planning", false)),
		"requires_drop_available": bool(options.get("requires_drop_available", false)),
		"future_task": str(options.get("future_task", "")),
		"tooltip_hint": str(options.get("tooltip_hint", "")),
		"status_source": str(options.get("status_source", "")),
	}
	return result


static func _duplicate_action_catalog(catalog: Array) -> Array:
	var result: Array = []
	for action_variant in catalog:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		result.append(Dictionary(action_variant).duplicate(true))
	return result


static func _resolve_group_disabled_reason(group_id: String, context: Dictionary) -> String:
	match group_id:
		GROUP_GOAL:
			return "select one or more fireteams"
		GROUP_RULE:
			return "select one or more fireteams"
		GROUP_PLAN:
			return "select multiple fireteams or build a plan"
		GROUP_AIR_LZ:
			return "planning or air context gated"
		GROUP_BREAKOUT:
			return "reserved for TASK_276 tactical breakout behavior"
		_:
			return "context gated"


static func _resolve_group_disabled_reason_code(group_id: String, _context: Dictionary) -> String:
	match group_id:
		GROUP_GOAL:
			return REASON_NO_FIRETEAM_SELECTED
		GROUP_RULE:
			return REASON_NO_FIRETEAM_SELECTED
		GROUP_PLAN:
			return REASON_PLAN_CONTEXT_MISSING
		GROUP_AIR_LZ:
			return REASON_AIR_CONTEXT_GATED
		GROUP_BREAKOUT:
			return REASON_FUTURE_TASK
		_:
			return REASON_CONTEXT_GATED
