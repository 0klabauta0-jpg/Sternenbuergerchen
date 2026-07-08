extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_fire_exchange_engagement_readability_polish.v1"
const TASK_ID: String = "TASK_853"
const SOURCE_TASK_ID: String = "TASK_852"
const SOURCE_FOCUS_TASK_ID: String = "TASK_850"
const SOURCE_VISIBILITY_TASK_ID: String = "TASK_847"
const SOURCE_EXCHANGE_TASK_ID: String = "TASK_844"
const STYLE_ID: String = "task_853_release_fire_exchange_engagement_readability_v1"
const NEXT_TASK: String = "TASK_854 - Release Fire Exchange Focused Recapture After Readability Polish"
const MIN_CAPTURE_SAFE_DURATION_MSEC: int = 42000


static func build_snapshot(focused_visual_snapshot: Dictionary, options: Dictionary = {}) -> Dictionary:
	var source_focus: Dictionary = _resolve_focus_snapshot(focused_visual_snapshot)
	var visibility_source: Dictionary = _resolve_visibility_snapshot(focused_visual_snapshot, source_focus)
	var compact_line: String = String(visibility_source.get("compact_line", "")).strip_edges()
	var selected_line: String = String(visibility_source.get("selected_fireteam_line", "")).strip_edges()
	var mission_line: String = String(visibility_source.get("mission_control_line", "")).strip_edges()
	var decision_line: String = String(visibility_source.get("decision_line", "")).strip_edges()
	var event_log_short_text: String = String(visibility_source.get("event_log_short_text", "")).strip_edges()
	var visibility_persistence: Dictionary = Dictionary(visibility_source.get("visibility_persistence", {})).duplicate(true)
	var duration_msec: int = int(visibility_source.get("duration_msec", visibility_persistence.get("duration_msec", 0)))
	var fire_event_id: String = String(visibility_source.get("fire_event_id", visibility_persistence.get("fire_event_id", ""))).strip_edges()
	var primary_lines: Array = []
	primary_lines.append(decision_line)
	primary_lines.append(compact_line)
	primary_lines.append(selected_line)
	primary_lines.append(mission_line)
	primary_lines.append(event_log_short_text)
	var primary_lines_text: String = _join_primary_lines(primary_lines)
	var primary_upper: String = primary_lines_text.to_upper()
	var event_log_display: Dictionary = Dictionary(visibility_source.get("event_log_display", {}))
	var event_log_entries: Array = Array(event_log_display.get("entries", []))
	var line_starts_with_fire: bool = not compact_line.is_empty() and compact_line.to_upper().begins_with("FIRE")
	var selected_has_fire_line: bool = selected_line.contains(compact_line)
	var mission_has_fire_line: bool = mission_line == compact_line or mission_line.contains(compact_line)
	var event_log_has_fire: bool = event_log_short_text.contains("CONTACT FIRE") or _entries_contain_contact_fire(event_log_entries)
	var surfaces_share_fire: bool = line_starts_with_fire and selected_has_fire_line and mission_has_fire_line and event_log_has_fire
	var issues: Array = []
	var source_gate: String = String(source_focus.get("gate", focused_visual_snapshot.get("status", "")))
	var source_gate_ok: bool = source_gate == "pass" or source_gate.is_empty()
	if source_focus.is_empty() or not source_gate_ok:
		issues.append(_issue("source_focus_not_green", "TASK_850-Focus-Snapshot ist nicht gruen."))
	if visibility_source.is_empty():
		issues.append(_issue("visibility_source_missing", "TASK_847-Visibility-Snapshot fehlt."))
	if duration_msec < MIN_CAPTURE_SAFE_DURATION_MSEC:
		issues.append(_issue("persistence_window_too_short", "Fire-Exchange-Persistenz reicht nicht fuer den bekannten Real-Window-Capture."))
	if fire_event_id.is_empty():
		issues.append(_issue("fire_event_reference_missing", "Readability-Snapshot referenziert kein FireEvent."))
	if not surfaces_share_fire:
		issues.append(_issue("hud_surfaces_not_synced", "#17, #18 und #19 teilen die FIRE/CONTACT-FIRE-Lesung nicht."))
	if primary_upper.contains("NO FIRE"):
		issues.append(_issue("primary_lines_contain_debug_no_fire", "Primaere Release-Zeilen enthalten weiter Debug-NO-FIRE."))
	var status: String = "pass" if issues.is_empty() else "review"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_focus_task_id": SOURCE_FOCUS_TASK_ID,
		"source_visibility_task_id": SOURCE_VISIBILITY_TASK_ID,
		"source_exchange_task_id": SOURCE_EXCHANGE_TASK_ID,
		"style_id": STYLE_ID,
		"status": status,
		"active": status == "pass",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
		"persistence_duration_msec": duration_msec,
		"minimum_capture_safe_duration_msec": MIN_CAPTURE_SAFE_DURATION_MSEC,
		"fire_event_id": fire_event_id,
		"decision_line": decision_line,
		"compact_line": compact_line,
		"selected_fireteam_line": selected_line,
		"mission_control_line": mission_line,
		"event_log_short_text": event_log_short_text,
		"primary_lines_text": primary_lines_text,
		"primary_lines_contain_no_fire": primary_upper.contains("NO FIRE"),
		"surfaces_share_contact_fire": surfaces_share_fire,
		"issues": issues,
		"issue_count": issues.size(),
		"source_focus_gate": source_gate,
		"source_visibility_gate": String(visibility_source.get("gate", "")),
		"source": focused_visual_snapshot.duplicate(true),
		"options": options.duplicate(true),
		"recommended_next_task": NEXT_TASK,
	}


static func _resolve_focus_snapshot(snapshot: Dictionary) -> Dictionary:
	if String(snapshot.get("schema", "")) == "sternenbuergerchen.release_fire_exchange_focused_visual_polish.v1":
		if snapshot.has("tactical_focus"):
			return Dictionary(snapshot.get("tactical_focus", {})).duplicate(true)
		return snapshot.duplicate(true)
	return Dictionary(snapshot.get("tactical_focus", {})).duplicate(true)


static func _resolve_visibility_snapshot(snapshot: Dictionary, focus_snapshot: Dictionary) -> Dictionary:
	if String(snapshot.get("schema", "")) == "sternenbuergerchen.release_fire_exchange_visibility_persistence.v1":
		return snapshot.duplicate(true)
	var focus_source: Dictionary = Dictionary(focus_snapshot.get("source", {})).duplicate(true)
	if String(focus_source.get("schema", "")) == "sternenbuergerchen.release_fire_exchange_visibility_persistence.v1":
		return focus_source
	var source: Dictionary = Dictionary(snapshot.get("source", {})).duplicate(true)
	if String(source.get("schema", "")) == "sternenbuergerchen.release_fire_exchange_visibility_persistence.v1":
		return source
	return {}


static func _join_primary_lines(lines: Array) -> String:
	var result: PackedStringArray = PackedStringArray()
	var seen: Dictionary = {}
	for line_variant in lines:
		var line: String = String(line_variant).strip_edges()
		if line.is_empty() or seen.has(line):
			continue
		seen[line] = true
		result.append(line)
	return "\n".join(result)


static func _entries_contain_contact_fire(entries: Array) -> bool:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("short_text", "")).contains("CONTACT FIRE") or String(entry.get("map_label", "")).contains("CONTACT FIRE"):
			return true
	return false


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
