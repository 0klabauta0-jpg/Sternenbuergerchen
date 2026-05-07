class_name AirAssetRecoveryState
extends RefCounted

const AIR_ASSET_STATUS_SCRIPT: GDScript = preload("res://scripts/mission/air_asset_status.gd")

const META_STATE_AVAILABLE: String = "craft_available"
const META_STATE_DAMAGED_REPAIRING: String = "damaged_repairing"
const META_STATE_DESTROYED_REPLACEMENT_PENDING: String = "destroyed_replacement_pending"

const PILOT_SAFE_HOMEBASE: String = "pilot_safe_homebase"
const PILOT_INJURED_RECOVERING: String = "pilot_injured_recovering"

const DEFAULT_REPAIR_SECONDS: float = 90.0
const DEFAULT_REPLACEMENT_SECONDS: float = 240.0
const DEFAULT_RECOVERY_TRANSFER_SECONDS: float = 30.0


static func from_air_asset_status(air_asset_status: Dictionary, craft_context: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var status = AIR_ASSET_STATUS_SCRIPT.call("from_dict", air_asset_status)
	var craft_id: String = str(craft_context.get("craft_id", air_asset_status.get("asset_id", ""))).strip_edges()
	if craft_id.is_empty():
		craft_id = str(status.asset_id).strip_edges()
	var pilot_unit_id: String = str(craft_context.get("pilot_unit_id", air_asset_status.get("pilot_unit_id", ""))).strip_edges()
	var meta_state: String = META_STATE_AVAILABLE
	var duration_seconds: float = 0.0
	var pilot_state: String = PILOT_SAFE_HOMEBASE
	var consequence_text: String = "Air asset available."
	if bool(AIR_ASSET_STATUS_SCRIPT.call("is_terminal_state", status.state)):
		meta_state = META_STATE_DESTROYED_REPLACEMENT_PENDING
		duration_seconds = maxf(float(options.get("replacement_seconds", DEFAULT_REPLACEMENT_SECONDS)), 1.0)
		pilot_state = PILOT_INJURED_RECOVERING if bool(options.get("pilot_injured", false)) else PILOT_SAFE_HOMEBASE
		consequence_text = "Replacement pending; mission transport unavailable until ETA completes."
	elif bool(AIR_ASSET_STATUS_SCRIPT.call("is_damage_state", status.state)):
		meta_state = META_STATE_DAMAGED_REPAIRING
		duration_seconds = maxf(float(options.get("repair_seconds", DEFAULT_REPAIR_SECONDS)), 1.0)
		pilot_state = PILOT_SAFE_HOMEBASE
		consequence_text = "Repairing; dropship/freighter cannot launch until repair ETA completes."
	return _normalize_state({
		"craft_id": craft_id,
		"asset_id": str(air_asset_status.get("asset_id", craft_id)).strip_edges(),
		"asset_type": str(air_asset_status.get("asset_type", craft_context.get("craft_type", "dropship"))).strip_edges(),
		"display_name": str(craft_context.get("display_name", air_asset_status.get("display_name", craft_id))).strip_edges(),
		"meta_state": meta_state,
		"pilot_state": pilot_state,
		"pilot_unit_id": pilot_unit_id,
		"elapsed_seconds": 0.0,
		"duration_seconds": duration_seconds,
		"eta_seconds": int(ceil(duration_seconds)),
		"recovery_transfer_seconds": float(options.get("recovery_transfer_seconds", DEFAULT_RECOVERY_TRANSFER_SECONDS)),
		"air_asset_status": Dictionary(status.call("to_snapshot")).duplicate(true),
		"consequence_text": consequence_text,
		"softlock_guard": meta_state != META_STATE_AVAILABLE,
		"can_recover": true,
		"runtime_authority": "MetaLayerFlow",
		"ui_sets_gameplay_truth": false,
	})


static func tick_recovery(recovery_state: Dictionary, delta_seconds: float) -> Dictionary:
	var state: Dictionary = _normalize_state(recovery_state)
	if not is_recovery_active(state):
		return state
	var duration_seconds: float = maxf(float(state.get("duration_seconds", 0.0)), 0.0)
	var elapsed_seconds: float = clampf(float(state.get("elapsed_seconds", 0.0)) + maxf(delta_seconds, 0.0), 0.0, duration_seconds)
	state["elapsed_seconds"] = elapsed_seconds
	state["eta_seconds"] = maxi(int(ceil(duration_seconds - elapsed_seconds)), 0)
	state["progress"] = 100.0 if duration_seconds <= 0.001 else clampf((elapsed_seconds / duration_seconds) * 100.0, 0.0, 100.0)
	if elapsed_seconds >= duration_seconds:
		state["meta_state"] = META_STATE_AVAILABLE
		state["eta_seconds"] = 0
		state["progress"] = 100.0
		state["consequence_text"] = "Air asset available after repair/replacement."
		state["softlock_guard"] = false
		var air_status: Dictionary = Dictionary(state.get("air_asset_status", {})).duplicate(true)
		air_status["state"] = str(AIR_ASSET_STATUS_SCRIPT.get("STATE_INTACT"))
		air_status["integrity"] = int(air_status.get("max_integrity", 100))
		air_status["warning_visible"] = false
		air_status["destroyed"] = false
		air_status["crashed"] = false
		air_status["recovering"] = false
		air_status["unavailable"] = false
		state["air_asset_status"] = Dictionary(AIR_ASSET_STATUS_SCRIPT.call("from_dict", air_status).call("to_snapshot")).duplicate(true)
	return state


static func is_recovery_active(recovery_state: Dictionary) -> bool:
	var meta_state: String = str(recovery_state.get("meta_state", META_STATE_AVAILABLE)).strip_edges().to_lower()
	return meta_state == META_STATE_DAMAGED_REPAIRING or meta_state == META_STATE_DESTROYED_REPLACEMENT_PENDING


static func build_transport_patch(recovery_state: Dictionary) -> Dictionary:
	var state: Dictionary = _normalize_state(recovery_state)
	var active: bool = is_recovery_active(state)
	var patch: Dictionary = {
		"air_asset_meta_status": str(state.get("meta_state", META_STATE_AVAILABLE)),
		"air_asset_recovery": state,
		"air_asset_unavailable": active,
		"air_asset_recovery_eta_seconds": int(state.get("eta_seconds", 0)),
		"air_asset_recovery_progress": float(state.get("progress", 100.0)),
		"pilot_recovery_state": str(state.get("pilot_state", PILOT_SAFE_HOMEBASE)),
	}
	if active:
		patch["is_boardable"] = false
	return patch


static func build_debrief_summary(recovery_state: Dictionary) -> String:
	var state: Dictionary = _normalize_state(recovery_state)
	var craft_name: String = str(state.get("display_name", state.get("craft_id", "Air asset"))).strip_edges()
	var eta_seconds: int = int(state.get("eta_seconds", 0))
	match str(state.get("meta_state", META_STATE_AVAILABLE)):
		META_STATE_DAMAGED_REPAIRING:
			return "Air asset: %s damaged | repair ETA %ds | pilot status %s" % [craft_name, eta_seconds, str(state.get("pilot_state", PILOT_SAFE_HOMEBASE))]
		META_STATE_DESTROYED_REPLACEMENT_PENDING:
			return "Air asset: %s lost | replacement ETA %ds | pilot status %s" % [craft_name, eta_seconds, str(state.get("pilot_state", PILOT_SAFE_HOMEBASE))]
		_:
			return "Air asset: %s available" % craft_name


static func _normalize_state(recovery_state: Dictionary) -> Dictionary:
	var state: Dictionary = recovery_state.duplicate(true)
	var meta_state: String = str(state.get("meta_state", META_STATE_AVAILABLE)).strip_edges().to_lower()
	if not [META_STATE_AVAILABLE, META_STATE_DAMAGED_REPAIRING, META_STATE_DESTROYED_REPLACEMENT_PENDING].has(meta_state):
		meta_state = META_STATE_AVAILABLE
	state["meta_state"] = meta_state
	state["craft_id"] = str(state.get("craft_id", state.get("asset_id", ""))).strip_edges()
	state["asset_id"] = str(state.get("asset_id", state.get("craft_id", ""))).strip_edges()
	state["asset_type"] = str(state.get("asset_type", "dropship")).strip_edges().to_lower()
	state["display_name"] = str(state.get("display_name", state.get("craft_id", "Air Asset"))).strip_edges()
	state["pilot_state"] = str(state.get("pilot_state", PILOT_SAFE_HOMEBASE)).strip_edges()
	state["pilot_unit_id"] = str(state.get("pilot_unit_id", "")).strip_edges()
	state["elapsed_seconds"] = maxf(float(state.get("elapsed_seconds", 0.0)), 0.0)
	state["duration_seconds"] = maxf(float(state.get("duration_seconds", 0.0)), 0.0)
	state["eta_seconds"] = maxi(int(state.get("eta_seconds", ceil(float(state.get("duration_seconds", 0.0)) - float(state.get("elapsed_seconds", 0.0))))), 0)
	var duration_seconds: float = float(state.get("duration_seconds", 0.0))
	state["progress"] = 100.0 if duration_seconds <= 0.001 else clampf((float(state.get("elapsed_seconds", 0.0)) / duration_seconds) * 100.0, 0.0, 100.0)
	var active: bool = meta_state == META_STATE_DAMAGED_REPAIRING or meta_state == META_STATE_DESTROYED_REPLACEMENT_PENDING
	state["softlock_guard"] = bool(state.get("softlock_guard", active))
	state["can_recover"] = bool(state.get("can_recover", true))
	state["runtime_authority"] = str(state.get("runtime_authority", "MetaLayerFlow"))
	state["ui_sets_gameplay_truth"] = false
	state["air_asset_status"] = Dictionary(state.get("air_asset_status", {})).duplicate(true)
	return state
