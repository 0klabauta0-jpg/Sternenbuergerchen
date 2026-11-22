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

const BUTTON_PATH_MOVE: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/MoveButton"
const BUTTON_PATH_HOLD: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/HoldButton"
const BUTTON_PATH_FLANK: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/FlankButton"
const BUTTON_PATH_TAKE: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TakeButton"
const BUTTON_PATH_BREACH_DOOR: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/DoorBreachButton"
const BUTTON_PATH_TARGET: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TargetButton"
const BUTTON_PATH_CLEAR_TARGET: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/ClearTargetButton"
const BUTTON_PATH_DELETE_ORDER: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/DeleteOrderButton"
const BUTTON_PATH_WAYPOINT_ERASE: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/WaypointEraseButton"
const BUTTON_PATH_SORT: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/SortCommandMatrixButton"
const BUTTON_PATH_FIRE_RULE_HOLD: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/FireRuleHoldButton"
const BUTTON_PATH_FIRE_RULE_RETURN: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/FireRuleReturnButton"
const BUTTON_PATH_FIRE_RULE_FREE: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/FireRuleFreeButton"
const BUTTON_PATH_FIRE_RULE_SUPPRESS: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/FireRuleSuppressButton"
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
		_action("move", "Bewegen", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.move", BUTTON_PATH_MOVE, {"requires_selection": true, "requires_tile_selection": true, "requires_local_command": true, "implemented": true, "context": "single_or_multi"}),
		_action("take", "Nehmen", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.take", BUTTON_PATH_TAKE, {"requires_selection": true, "requires_tile_selection": true, "requires_local_command": true, "implemented": true, "context": "single_or_multi"}),
		_action("breach_door", "Sturm", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.breach_door", BUTTON_PATH_BREACH_DOOR, {"requires_selection": true, "requires_local_command": true, "requires_usable_door_interaction": true, "implemented": true, "context": "door_interaction", "tooltip_hint": "Plant einen Tuersturm; Ausfuehrung bleibt getrennt ueber GO."}),
		_action("defend", "Halten", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.defend", BUTTON_PATH_HOLD, {"requires_selection": true, "requires_tile_selection": true, "requires_local_command": true, "implemented": true, "context": "single_or_multi"}),
		_action("engage", "Ziel", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.attack_area", BUTTON_PATH_TARGET, {"requires_planning": true, "implemented": true, "context": "area"}),
		_action("secure", "Secure", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.defend_area", "", {"requires_selection": true, "requires_planning": true, "status_only": true, "context": "area"}),
		_action("recon", "Recon", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.area_order", "", {"requires_selection": true, "future_task": "future mission objective slice", "context": "area"}),
		_action("withdraw", "Withdraw", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.area_order", "", {"requires_selection": true, "future_task": "TASK_276 breakout behavior", "context": "breakout"}),
		_action("flank", "Flanke", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.flank", BUTTON_PATH_FLANK, {"requires_selection": true, "requires_tile_selection": true, "requires_local_command": true, "implemented": true, "context": "single_or_multi"}),
		_action("clear_target", "Leeren", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.clear_target", BUTTON_PATH_CLEAR_TARGET, {"requires_planning": true, "implemented": true, "context": "area"}),
		_action("delete_order", "Loeschen", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.clear_target", BUTTON_PATH_DELETE_ORDER, {"requires_planning": true, "implemented": true, "context": "waypoint_or_area"}),
		_action("waypoint_erase", "WP-", GROUP_GOAL, PANEL_COMMAND_MATRIX, "mission.command.clear_target", BUTTON_PATH_WAYPOINT_ERASE, {"requires_planning": true, "implemented": true, "context": "waypoint_or_area", "tooltip_hint": "Deletes the selected waypoint or area order from the command matrix."}),

		_action("tactical_stance", "Stance", GROUP_RULE, PANEL_FIRETEAM_DETAILS, "mission.command.stance", "", {"requires_selection": true, "implemented": true, "context": "single_or_multi", "status_source": "TacticalStanceController", "tooltip_hint": "Direct C/N/A stance toggle on each fireteam card."}),
		_action("tempo", "Tempo", GROUP_RULE, PANEL_FIRETEAM_DETAILS, "mission.rule.tempo", "", {"requires_selection": true, "status_only": true, "context": "single_or_multi", "status_source": "FTL profile and current command", "tooltip_hint": "Status value from FTL initiative, plan quality, and active order."}),
		_action("fire_rule", "Feuerregel", GROUP_RULE, PANEL_FIRETEAM_DETAILS, "mission.rule.fire_rule", "", {"requires_selection": true, "implemented": true, "context": "single_or_multi", "status_source": "Mission fire-rule snapshot", "control_type": "segmented_buttons", "button_count": 4, "tooltip_hint": "Die Feuerdisziplin wird ueber FH, AF, FF und UN gesetzt."}),
		_action("fire_rule_hold", "FH", GROUP_RULE, PANEL_COMMAND_MATRIX, "mission.rule.fire_rule_hold", BUTTON_PATH_FIRE_RULE_HOLD, {"requires_selection": true, "requires_local_command": true, "implemented": true, "context": "single_or_multi", "control_type": "fire_rule_button", "tooltip_hint": "Feuer halten: kein freiwilliges Feuer."}),
		_action("fire_rule_return", "AF", GROUP_RULE, PANEL_COMMAND_MATRIX, "mission.rule.fire_rule_return", BUTTON_PATH_FIRE_RULE_RETURN, {"requires_selection": true, "requires_local_command": true, "implemented": true, "context": "single_or_multi", "control_type": "fire_rule_button", "tooltip_hint": "Antwortfeuer: nur nach gegnerischem Beschuss feuern."}),
		_action("fire_rule_free", "FF", GROUP_RULE, PANEL_COMMAND_MATRIX, "mission.rule.fire_rule_free", BUTTON_PATH_FIRE_RULE_FREE, {"requires_selection": true, "requires_local_command": true, "implemented": true, "context": "single_or_multi", "control_type": "fire_rule_button", "tooltip_hint": "Feuer frei: sichtbare Gegner selbststaendig bekaempfen."}),
		_action("fire_rule_suppress", "UN", GROUP_RULE, PANEL_COMMAND_MATRIX, "mission.rule.fire_rule_suppress", BUTTON_PATH_FIRE_RULE_SUPPRESS, {"requires_selection": true, "requires_local_command": true, "implemented": true, "context": "single_or_multi", "control_type": "fire_rule_button", "tooltip_hint": "Unterdruecken: Feuer fuer Unterdrueckungsbefehle bereithalten."}),
		_action("contact_response", "Contact", GROUP_RULE, PANEL_FIRETEAM_DETAILS, "mission.rule.contact_response", "", {"requires_selection": true, "status_only": true, "context": "single_or_multi", "status_source": "FTL profile and current contacts", "tooltip_hint": "Status value from recognition, comms, and known contact state."}),
		_action("cover_priority", "Cover", GROUP_RULE, PANEL_FIRETEAM_DETAILS, "mission.rule.cover_priority", "", {"requires_selection": true, "status_only": true, "context": "single_or_multi", "status_source": "FTL profile and tactical stance", "tooltip_hint": "Status value from toughness, stance, terrain, and command type."}),
		_action("security_mode", "Security", GROUP_RULE, PANEL_FIRETEAM_DETAILS, "mission.rule.security_mode", "", {"requires_selection": true, "status_only": true, "context": "single_or_multi", "status_source": "FTL profile and area order", "tooltip_hint": "Status value from current order, overwatch, and contact risk."}),

		_action("role_suggestion", "Roles", GROUP_PLAN, PANEL_MISSION_CONTROL, "mission.command.go_plan", "", {"requires_multi_selection": true, "status_only": true, "context": "multi_fireteam"}),
		_action("swap_roles", "Swap", GROUP_PLAN, PANEL_MISSION_CONTROL, "mission.command.go_plan", "", {"requires_multi_selection": true, "future_task": "multi-plan edit UI", "context": "multi_fireteam"}),
		_action("preview_plan", "Preview", GROUP_PLAN, PANEL_MISSION_CONTROL, "mission.command.go_plan", "", {"requires_multi_selection": true, "status_only": true, "context": "multi_fireteam"}),
		_action("sort_fireteam", "Ordnen", GROUP_PLAN, PANEL_COMMAND_MATRIX, "mission.command.go_plan", BUTTON_PATH_SORT, {"requires_selection": true, "requires_local_command": true, "implemented": true, "context": "single_or_multi", "tooltip_hint": "Den ausgewaehlten Fireteam-Plan vor GO ordnen."}),
		_action("go_plan", "GO", GROUP_PLAN, PANEL_COMMAND_MATRIX, "mission.command.go_plan", BUTTON_PATH_GO_PLAN, {"requires_selection": true, "requires_local_command": true, "implemented": true, "context": "single_or_multi", "tooltip_hint": "Execute the selected planned order."}),
		_action("return_to_plan", "Plan", GROUP_PLAN, PANEL_COMMAND_MATRIX, "mission.command.go_plan", "", {"requires_selection": true, "requires_local_command": true, "implemented": false, "hidden": true, "context": "single_or_multi", "tooltip_hint": "Internal recovery path; visible continuation is handled by GO."}),

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
			"action_count": 0,
			"active_action_count": 0,
			"implemented_action_count": 0,
			"actions": [],
		}

	for action_variant in get_action_catalog():
		var action: Dictionary = Dictionary(action_variant).duplicate(true)
		var action_id: String = str(action.get("action_id", ""))
		var button_snapshot: Dictionary = Dictionary(button_snapshots.get(action_id, {})) if button_snapshots.has(action_id) else {}
		var disabled_reason: String = resolve_disabled_reason(action, context, button_snapshot, button_snapshots.has(action_id))
		action["active"] = disabled_reason.is_empty()
		action["disabled"] = not disabled_reason.is_empty()
		action["disabled_reason"] = disabled_reason
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
			group["disabled_reason"] = _resolve_group_disabled_reason(group_id, context)
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
		"waypoint_erase_button_slot": "16.20",
		"return_to_plan_button_hidden": true,
		"legacy_window_17_go_removed": true,
		"status_preview_panel_role": PANEL_FIRETEAM_DETAILS,
		"lz_pick_panel_role": PANEL_COMMAND_MATRIX,
		"lz_pick_group": "target_selection_left",
		"approach_style_options": PackedStringArray(["vorsichtig", "normal", "aggressiv"]),
		"approach_path_options": PackedStringArray(["steil", "normal", "tief"]),
		"go_enabled": disabled_reasons.is_empty(),
		"disabled_reasons": disabled_reasons,
		"ui_sets_gameplay_truth": UI_SETS_GAMEPLAY_TRUTH,
	}


static func resolve_disabled_reason(action: Dictionary, context: Dictionary, button_snapshot: Dictionary = {}, has_button_snapshot: bool = false) -> String:
	if bool(action.get("requires_phase_planning", false)) and not bool(context.get("phase_planning_enabled", false)):
		return "phase planning hidden in fixed HUD"
	if bool(action.get("requires_multi_selection", false)) and int(context.get("selected_fireteam_count", 0)) < 2:
		return "select multiple fireteams"
	if bool(action.get("requires_selection", false)) and int(context.get("selected_fireteam_count", 0)) <= 0:
		return "select one or more fireteams"
	if bool(action.get("requires_tile_selection", false)) and bool(context.get("requires_tile_selection", true)) and not bool(context.get("has_selected_tile", false)):
		return "select a map tile"
	if bool(action.get("requires_local_command", false)) and not bool(context.get("can_issue_local_commands", true)):
		return "host controls mission commands"
	if bool(action.get("requires_usable_door_interaction", false)) and not bool(context.get("has_usable_door_interaction", false)):
		return "no usable door"
	if bool(action.get("requires_planning", false)) and not bool(context.get("can_edit_planning", true)):
		return "planning locked in this mode"
	if bool(action.get("requires_drop_available", false)) and not bool(context.get("drop_available", true)):
		return "dropship unavailable"
	if str(action.get("action_id", "")) == "call_dropship" and float(context.get("drop_cooldown_remaining", 0.0)) > 0.0:
		return "dropship cooldown"
	if not str(action.get("future_task", "")).is_empty():
		return "reserved for %s" % str(action.get("future_task", "later task"))
	if has_button_snapshot:
		if not bool(button_snapshot.get("exists", false)):
			return "not implemented in this slice"
		if not bool(button_snapshot.get("visible", true)):
			return "hidden in current context"
		if bool(button_snapshot.get("disabled", false)):
			return "context gated"
	return ""


static func build_button_metadata(action: Dictionary, context: Dictionary, button_snapshot: Dictionary = {}) -> Dictionary:
	var disabled_reason: String = resolve_disabled_reason(action, context, button_snapshot, not button_snapshot.is_empty())
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
		"requires_usable_door_interaction": bool(options.get("requires_usable_door_interaction", false)),
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
