class_name StationReentryFirefightPlayerDecisionReadabilityPass
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_player_decision_readability_pass.v1"
const EXPECTED_SOURCE_TASK_ID: String = "TASK_786"
const DEFAULT_MANIFEST_PATH: String = "tmp/station_reentry_firefight_player_decision_readability_pass.json"
const DECISION_LINE_LIMIT: int = 96
const REASON_LINE_LIMIT: int = 112
const GUARD_LINE_LIMIT: int = 64
const MIN_QUICK_ACTIONS: int = 3


static func build_snapshot(host_client_surface: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var source: Dictionary = _normalize_source(host_client_surface)
	var primary_label: String = _primary_label(source)
	var quick_actions: Array[String] = _quick_actions(source)
	var reason_tokens: Array[String] = _reason_tokens(source)
	var guard_line: String = _guard_line(source)
	var decision_line: String = _build_decision_line(primary_label, quick_actions)
	var reason_line: String = _build_reason_line(reason_tokens)
	var confirm_control: String = String(options.get("confirm_control", "existing command buttons / GO")).strip_edges()
	var source_ready: bool = _source_ready(source)
	var read_only_source: bool = _source_read_only(source)
	var primary_visible: bool = not primary_label.is_empty()
	var quick_actions_visible: bool = quick_actions.size() >= MIN_QUICK_ACTIONS
	var reason_visible: bool = not reason_tokens.is_empty()
	var guard_visible: bool = guard_line.contains("NO AUTO") and guard_line.contains("EXISTING")
	var no_auto_command: bool = bool(source.get("no_auto_command_commit", false))
	var existing_commands_only: bool = bool(source.get("uses_existing_commands_only", false))
	var text_budget_ok: bool = decision_line.length() <= DECISION_LINE_LIMIT \
		and reason_line.length() <= REASON_LINE_LIMIT \
		and guard_line.length() <= GUARD_LINE_LIMIT
	var host_client_context_visible: bool = bool(source.get("peer_context_distinct", false)) and bool(source.get("team_context_present", false))
	var checks: Array = [
		_check("source_ready", source_ready, "TASK_786 Host/Client-Surface ist bereit."),
		_check("read_only_source", read_only_source, "Quelle bleibt read-only und erzeugt keine Gameplay-Wahrheit."),
		_check("primary_action_visible", primary_visible, "Primaerer Griff ist klar sichtbar."),
		_check("quick_actions_visible", quick_actions_visible, "Quick-Actions enthalten genug echte Folgegriffe."),
		_check("reason_visible", reason_visible, "Warum dieser Griff sinnvoll ist, bleibt sichtbar."),
		_check("guard_visible", guard_visible, "No-Auto-Command und Existing-Buttons-Grenze bleiben sichtbar."),
		_check("no_auto_command_commit", no_auto_command, "Decision-Card fuehrt nichts automatisch aus."),
		_check("existing_commands_only", existing_commands_only, "Decision-Card verweist nur auf bestehende Befehle."),
		_check("text_budget_ok", text_budget_ok, "Decision-, Reason- und Guard-Zeilen bleiben kompakt."),
		_check("host_client_context_visible", host_client_context_visible, "Host/Client-Kontext bleibt unterscheidbar."),
	]
	var failed_checks: Array[String] = _failed_check_ids(checks)
	var status: String = _build_status(failed_checks)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_787",
		"source_task_id": EXPECTED_SOURCE_TASK_ID,
		"runtime_authority": "read-only player decision card over synchronized TASK_786 firefight command surface",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"source_schema": String(source.get("schema", "")),
		"source_status": String(source.get("status", "")),
		"source_sync_gate": String(source.get("sync_gate", "")),
		"primary_action_label": primary_label,
		"quick_action_labels": quick_actions,
		"quick_action_count": quick_actions.size(),
		"reason_tokens": reason_tokens,
		"decision_line": decision_line,
		"decision_line_limit": DECISION_LINE_LIMIT,
		"reason_line": reason_line,
		"reason_line_limit": REASON_LINE_LIMIT,
		"guard_line": guard_line,
		"guard_line_limit": GUARD_LINE_LIMIT,
		"confirm_control": confirm_control,
		"decision_card": {
			"title": "NEXT %s" % primary_label if not primary_label.is_empty() else "NEXT ?",
			"primary": primary_label,
			"quick": quick_actions,
			"why": reason_line,
			"guard": guard_line,
			"confirm": confirm_control,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_navigation": false,
			"creates_fire_event": false,
			"creates_damage_event": false,
		},
		"source_ready": source_ready,
		"read_only_source": read_only_source,
		"primary_action_visible": primary_visible,
		"quick_actions_visible": quick_actions_visible,
		"reason_visible": reason_visible,
		"guard_visible": guard_visible,
		"no_auto_command_commit": no_auto_command,
		"existing_commands_only": existing_commands_only,
		"text_budget_ok": text_budget_ok,
		"host_client_context_visible": host_client_context_visible,
		"checks": checks,
		"failed_checks": failed_checks,
		"failed_check_count": failed_checks.size(),
		"status": status,
		"ready_for_visible_player_decision_review": status == "ready_for_visible_player_decision_review",
		"manual_review_required": true,
		"manual_review_done": false,
		"summary": _build_summary(status, decision_line, failed_checks),
		"recommended_next_task": _recommended_next_task(status, failed_checks),
		"manifest_path": String(options.get("manifest_path", DEFAULT_MANIFEST_PATH)),
	}


static func _normalize_source(source: Dictionary) -> Dictionary:
	var host_view: Dictionary = Dictionary(source.get("host_view", {}))
	var fallback_view: Dictionary = Dictionary(source.get("client_view", {}))
	if host_view.is_empty():
		host_view = fallback_view
	return {
		"schema": String(source.get("schema", "")),
		"task_id": String(source.get("task_id", "")),
		"status": String(source.get("status", "")),
		"sync_gate": String(source.get("sync_gate", "")),
		"ready_for_visible_host_client_polished_surface_review": bool(source.get("ready_for_visible_host_client_polished_surface_review", false)),
		"primary_action_label": String(host_view.get("primary_action_label", source.get("primary_action_label", ""))).strip_edges(),
		"quick_action_labels": _normalize_string_array(Array(host_view.get("quick_action_labels", source.get("quick_action_labels", [])))),
		"interaction_line": String(host_view.get("interaction_line", source.get("interaction_line", ""))).strip_edges(),
		"summary_line": String(source.get("host_summary_line", host_view.get("summary_line", source.get("summary_line", "")))).strip_edges(),
		"guard_line": String(host_view.get("guard_line", source.get("guard_line", ""))).strip_edges(),
		"no_auto_command_commit": bool(host_view.get("no_auto_command_commit", source.get("same_no_auto_command_commit", false))),
		"uses_existing_commands_only": bool(host_view.get("uses_existing_commands_only", source.get("same_existing_commands_only", false))),
		"peer_context_distinct": bool(source.get("peer_context_distinct", false)),
		"team_context_present": bool(source.get("team_context_present", false)),
		"read_only": bool(source.get("read_only", false)),
		"ui_sets_gameplay_truth": bool(source.get("ui_sets_gameplay_truth", true)),
		"creates_navigation": bool(source.get("creates_navigation", true)),
		"creates_command": bool(source.get("creates_command", true)),
		"creates_fire_event": bool(source.get("creates_fire_event", true)),
		"creates_damage_event": bool(source.get("creates_damage_event", true)),
	}


static func _source_ready(source: Dictionary) -> bool:
	return String(source.get("task_id", "")) == EXPECTED_SOURCE_TASK_ID \
		and String(source.get("status", "")) == "ready_for_host_client_polished_surface_review" \
		and String(source.get("sync_gate", "")) == "pass" \
		and bool(source.get("ready_for_visible_host_client_polished_surface_review", false))


static func _source_read_only(source: Dictionary) -> bool:
	return bool(source.get("read_only", false)) \
		and not bool(source.get("ui_sets_gameplay_truth", true)) \
		and not bool(source.get("creates_navigation", true)) \
		and not bool(source.get("creates_command", true)) \
		and not bool(source.get("creates_fire_event", true)) \
		and not bool(source.get("creates_damage_event", true))


static func _primary_label(source: Dictionary) -> String:
	return String(source.get("primary_action_label", "")).strip_edges().to_upper()


static func _quick_actions(source: Dictionary) -> Array[String]:
	var actions: Array[String] = []
	var primary: String = _primary_label(source)
	for label in Array(source.get("quick_action_labels", [])):
		var normalized: String = String(label).strip_edges().to_upper()
		if normalized.is_empty():
			continue
		actions.append(normalized)
	if actions.is_empty() and not primary.is_empty():
		actions.append(primary)
	return actions


static func _reason_tokens(source: Dictionary) -> Array[String]:
	var tokens: Array[String] = []
	for raw_part in String(source.get("interaction_line", "")).split("|", false):
		var token: String = String(raw_part).strip_edges()
		if token.is_empty():
			continue
		tokens.append(token)
		if tokens.size() >= 4:
			break
	return tokens


static func _guard_line(source: Dictionary) -> String:
	var guard: String = String(source.get("guard_line", "")).strip_edges()
	if guard.is_empty():
		var tokens: Array[String] = []
		if bool(source.get("no_auto_command_commit", false)):
			tokens.append("NO AUTO CMD")
		if bool(source.get("uses_existing_commands_only", false)):
			tokens.append("EXISTING BUTTONS")
		guard = " | ".join(tokens)
	return guard


static func _build_decision_line(primary_label: String, quick_actions: Array[String]) -> String:
	var secondary: Array[String] = []
	for action in quick_actions:
		if action == primary_label:
			continue
		secondary.append(action)
		if secondary.size() >= 4:
			break
	var line: String = "NEXT %s" % primary_label if not primary_label.is_empty() else "NEXT ?"
	if not secondary.is_empty():
		line += " | ALT %s" % " / ".join(secondary)
	return line.left(DECISION_LINE_LIMIT)


static func _build_reason_line(reason_tokens: Array[String]) -> String:
	if reason_tokens.is_empty():
		return "WHY ?"
	return ("WHY " + " | ".join(reason_tokens)).left(REASON_LINE_LIMIT)


static func _normalize_string_array(source: Array) -> Array[String]:
	var normalized: Array[String] = []
	for value in source:
		var text: String = String(value).strip_edges()
		if text.is_empty():
			continue
		normalized.append(text)
	return normalized


static func _build_status(failed_checks: Array[String]) -> String:
	if failed_checks.has("source_ready") or failed_checks.has("read_only_source"):
		return "blocked_until_host_client_surface_ready"
	if failed_checks.is_empty():
		return "ready_for_visible_player_decision_review"
	return "needs_player_decision_readability_polish"


static func _recommended_next_task(status: String, failed_checks: Array[String]) -> String:
	if status == "blocked_until_host_client_surface_ready":
		return "TASK_786 - Station Reentry Firefight Host Client Polished Surface Check"
	if status == "needs_player_decision_readability_polish":
		if failed_checks.has("guard_visible") or failed_checks.has("no_auto_command_commit") or failed_checks.has("existing_commands_only"):
			return "TASK_783 - Station Reentry Firefight Command Surface Polish"
		return "TASK_787 - polish Player Decision Readability"
	return "TASK_788 - Station Reentry Firefight Decision Evidence Packet"


static func _build_summary(status: String, decision_line: String, failed_checks: Array[String]) -> String:
	if status == "blocked_until_host_client_surface_ready":
		return "TASK_787 blockiert: TASK_786 Host/Client-Surface ist noch nicht bereit."
	if status == "needs_player_decision_readability_polish":
		return "Spielerentscheidung braucht Lesbarkeits-Polish: %s." % ", ".join(PackedStringArray(failed_checks))
	return "Naechster Spielergriff ist lesbar: %s." % decision_line


static func _check(id: String, passed: bool, details: String) -> Dictionary:
	return {
		"id": id,
		"passed": passed,
		"details": details,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _failed_check_ids(checks: Array) -> Array[String]:
	var failed: Array[String] = []
	for check_variant in checks:
		if typeof(check_variant) != TYPE_DICTIONARY:
			continue
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			failed.append(String(check.get("id", "")))
	return failed
