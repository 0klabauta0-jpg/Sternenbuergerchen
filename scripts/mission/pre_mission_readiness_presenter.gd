class_name PreMissionReadinessPresenter
extends RefCounted

const STATE_READY := "ready"
const STATE_WARN := "warn"
const STATE_BLOCKED := "blocked"


func build_snapshot(context: Dictionary) -> Dictionary:
	var briefing: Dictionary = Dictionary(context.get("briefing", {}))
	var loadout: Dictionary = Dictionary(context.get("loadout", {}))
	var aircraft: Dictionary = Dictionary(context.get("aircraft", {}))
	var staging: Dictionary = Dictionary(context.get("staging", {}))
	var can_start: bool = bool(context.get("can_start", false))
	var items: Array = [
		_build_briefing_item(briefing),
		_build_team_item(staging),
		_build_loadout_item(loadout, staging),
		_build_pilot_item(staging),
		_build_cargo_item(aircraft, staging),
		_build_dropship_item(staging),
		_build_boarding_item(staging),
		_build_start_item(can_start, staging),
	]
	var ready_count: int = _count_state(items, STATE_READY)
	var warn_count: int = _count_state(items, STATE_WARN)
	var blocked_count: int = _count_state(items, STATE_BLOCKED)
	return {
		"runtime_authority": "PreMissionReadinessPresenter",
		"ui_sets_gameplay_truth": false,
		"source": "homebase_snapshots",
		"can_start": can_start,
		"overall_state": STATE_READY if blocked_count == 0 else STATE_BLOCKED,
		"ready_count": ready_count,
		"warn_count": warn_count,
		"blocked_count": blocked_count,
		"item_count": items.size(),
		"items": items,
		"summary_text": _build_summary_text(can_start, ready_count, warn_count, blocked_count),
		"compact_text": _build_compact_text(items),
	}


func _build_briefing_item(briefing: Dictionary) -> Dictionary:
	var configured: bool = bool(briefing.get("configured", false))
	var valid: bool = bool(briefing.get("valid", configured))
	var title: String = String(briefing.get("title", "Mission Briefing")).strip_edges()
	if configured and valid:
		return _make_item("briefing", "Briefing", STATE_READY, title)
	if configured:
		return _make_item("briefing", "Briefing", STATE_WARN, "Briefing ist sichtbar, aber noch nicht voll validiert.")
	return _make_item("briefing", "Briefing", STATE_BLOCKED, "Kein Briefing fuer die ausgewaehlte Mission.")


func _build_team_item(staging: Dictionary) -> Dictionary:
	var selected_count: int = Array(staging.get("selected_unit_ids", [])).size()
	var payload_count: int = int(staging.get("payload_operator_count", 0))
	var payload_fireteam_count: int = Array(staging.get("payload_fireteam_ids", [])).size()
	if payload_count > 0:
		return _make_item("team", "Team", STATE_READY, "%d Operatoren in %d Fireteams im Payload." % [payload_count, payload_fireteam_count])
	if selected_count > 0:
		return _make_item("team", "Team", STATE_WARN, "%d Operatoren gestagt, aber noch nicht im Dropship." % selected_count)
	return _make_item("team", "Team", STATE_BLOCKED, "Keine Operatoren fuer die Mission gestagt.")


func _build_loadout_item(loadout: Dictionary, staging: Dictionary) -> Dictionary:
	var apply_count: int = int(loadout.get("apply_count", loadout.get("recommended_loadout_apply_count", 0)))
	var member_loadouts: Dictionary = Dictionary(staging.get("member_loadouts", {}))
	if apply_count > 0:
		return _make_item("loadout", "Loadout", STATE_READY, "Briefing-Empfehlung bestaetigt angewendet.")
	if not member_loadouts.is_empty():
		return _make_item("loadout", "Loadout", STATE_WARN, "Standard-/manuelle Loadouts vorhanden; keine Empfehlung bestaetigt.")
	return _make_item("loadout", "Loadout", STATE_WARN, "Loadouts noch nicht sichtbar im Payload-Snapshot.")


func _build_pilot_item(staging: Dictionary) -> Dictionary:
	var pilot_id: String = String(staging.get("mission_drop_pilot_unit_id", "")).strip_edges()
	if pilot_id.is_empty():
		pilot_id = String(staging.get("mission_drop_pilot_display_name", "")).strip_edges()
	if not pilot_id.is_empty():
		return _make_item("pilot", "Pilot", STATE_READY, "Pilot: %s" % pilot_id)
	var craft_ready: bool = bool(staging.get("homebase_direct_craft_ready", false))
	return _make_item("pilot", "Pilot", STATE_WARN if craft_ready else STATE_BLOCKED, "Kein Pilot im Launch-Payload sichtbar.")


func _build_cargo_item(aircraft: Dictionary, staging: Dictionary) -> Dictionary:
	var payload_craft_id: String = String(staging.get("payload_craft_id", staging.get("transport_craft_id", ""))).strip_edges()
	var visible_aircraft: Array = Array(aircraft.get("visible_aircraft_definitions", []))
	var craft_def: Dictionary = _find_craft(visible_aircraft, payload_craft_id)
	if craft_def.is_empty() or not bool(craft_def.get("supports_cargo", false)):
		return _make_item("cargo", "Cargo", STATE_READY, "Fuer dieses Dropship nicht erforderlich.")
	var loaded_cargo_id: String = String(staging.get("loaded_cargo_id", "")).strip_edges()
	if not loaded_cargo_id.is_empty():
		return _make_item("cargo", "Cargo", STATE_READY, "Cargo geladen: %s" % loaded_cargo_id)
	return _make_item("cargo", "Cargo", STATE_WARN, "Cargo-faehiges Schiff ohne sichtbare Pflichtladung.")


func _build_dropship_item(staging: Dictionary) -> Dictionary:
	var craft_id: String = String(staging.get("payload_craft_id", staging.get("transport_craft_id", ""))).strip_edges()
	var craft_ready: bool = bool(staging.get("homebase_direct_craft_ready", false))
	var block_text: String = String(staging.get("homebase_direct_craft_block_text", "")).strip_edges()
	if craft_ready and not craft_id.is_empty():
		return _make_item("dropship", "Dropship", STATE_READY, "%s bereit." % craft_id)
	if not block_text.is_empty():
		return _make_item("dropship", "Dropship", STATE_BLOCKED, block_text)
	return _make_item("dropship", "Dropship", STATE_BLOCKED, "Kein startbereites Dropship.")


func _build_boarding_item(staging: Dictionary) -> Dictionary:
	var payload_count: int = int(staging.get("payload_operator_count", 0))
	var boarded_count: int = int(staging.get("boarded_operator_count", staging.get("homebase_direct_boarded_operator_count", 0)))
	if payload_count > 0 and boarded_count >= payload_count:
		return _make_item("boarding", "Boarding", STATE_READY, "%d/%d Operatoren geboardet." % [boarded_count, payload_count])
	if payload_count > 0:
		return _make_item("boarding", "Boarding", STATE_BLOCKED, "%d/%d Operatoren geboardet." % [boarded_count, payload_count])
	return _make_item("boarding", "Boarding", STATE_BLOCKED, "Kein Payload im Dropship.")


func _build_start_item(can_start: bool, staging: Dictionary) -> Dictionary:
	if can_start:
		return _make_item("start", "Start", STATE_READY, "Startbutton darf Mission ausloesen.")
	var status_text: String = String(staging.get("payload_status_text", staging.get("homebase_direct_payload_status_text", ""))).strip_edges()
	if status_text.is_empty():
		status_text = "Startbutton bleibt blockiert."
	return _make_item("start", "Start", STATE_BLOCKED, status_text)


func _make_item(id: String, label: String, state: String, detail: String) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"state": state,
		"ready": state == STATE_READY,
		"blocking": state == STATE_BLOCKED,
		"detail": detail.strip_edges(),
	}


func _count_state(items: Array, state: String) -> int:
	var count: int = 0
	for item_variant in items:
		var item: Dictionary = Dictionary(item_variant)
		if String(item.get("state", "")).strip_edges() == state:
			count += 1
	return count


func _build_summary_text(can_start: bool, ready_count: int, warn_count: int, blocked_count: int) -> String:
	if can_start and blocked_count == 0:
		return "Startbereit: %d Checks gruen, %d Hinweise." % [ready_count, warn_count]
	return "Nicht startbereit: %d Blocker, %d Hinweise, %d gruen." % [blocked_count, warn_count, ready_count]


func _build_compact_text(items: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for item_variant in items:
		var item: Dictionary = Dictionary(item_variant)
		var state: String = String(item.get("state", "")).strip_edges()
		var marker: String = "OK" if state == STATE_READY else "!" if state == STATE_WARN else "X"
		parts.append("%s %s" % [marker, String(item.get("label", "")).strip_edges()])
	return " | ".join(parts)


func _find_craft(visible_aircraft: Array, craft_id: String) -> Dictionary:
	var normalized_craft_id: String = craft_id.strip_edges()
	for craft_variant in visible_aircraft:
		if typeof(craft_variant) != TYPE_DICTIONARY:
			continue
		var craft: Dictionary = Dictionary(craft_variant)
		if String(craft.get("craft_id", "")).strip_edges() == normalized_craft_id:
			return craft
	return {}
