extends RefCounted
## Steuerung der Kampagnen-Hinweispfeile. Reine Anzeige: liest nur `facts` und die Oberflaeche,
## schreibt nie Spielwahrheit und speichert nichts.
##
## Hinweisliste (data/campaign_hint_arrows.json):
##   {"version": 1, "hints": [{"id", "text", "target": {"node": "<Knotenname>"},
##     "show_when": ["stage:0", ...], "done_when": [...], "order": 10}]}
## Bedingungswoerter (feste Liste, Unbekanntes ist falsch und warnt einmal):
##   stage:<n>      facts["stage"] == n
##   view:<name>    facts["view"] == name oder facts["views"] enthaelt name
##   fact:<key>     facts[key] ist der Bool true
## Zielnamen: `find_child(name, true, false)` nimmt den ERSTEN Treffer unter der Suchwurzel. Ein Name
## muss dort also eindeutig sein und darf kein `*` oder `?` enthalten (das waeren Muster).

const SETTINGS: GDScript = preload("res://scripts/ui/game_settings_contract.gd")
const DEFAULT_PATH: String = "res://data/campaign_hint_arrows.json"

## Nur fuer Tests: anderer Einstellungspfad / anderer Abstand der Neu-Lesung.
var settings_path: String = SETTINGS.CONFIG_PATH
var poll_interval_msec: int = 2000

var _hints: Array = []
var _loaded: bool = false
var _arrow: Control = null
var _enabled: bool = true
var _mode: String = "compact"
var _last_poll_msec: int = -1000000
var _active_id: String = ""
var _warned: Dictionary = {}


func attach_arrow(arrow: Control) -> void:
	_arrow = arrow


func configure(hints: Array) -> void:
	_hints = []
	for entry: Variant in hints:
		if entry is Dictionary:
			var hint: Dictionary = entry
			if String(hint.get("id", "")).is_empty() or not hint.get("target") is Dictionary:
				push_warning("campaign_hint_arrows: Hinweis ohne id oder target uebersprungen")
				continue
			_hints.append(hint)
	_hints.sort_custom(_order_less)
	_loaded = true
	_hide()


## Laedt die Liste einmal (ohne vorheriges `configure`). Danach billig.
func ensure_loaded() -> void:
	_ensure_loaded()


func has_hints() -> bool:
	_ensure_loaded()
	return not _hints.is_empty()


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if not enabled:
		_hide()


func is_enabled() -> bool:
	return _enabled


## Modus der Kontext-Hilfe ("off", "compact", "expanded"); setzt auch die Neu-Lesung zurueck.
func set_help_mode(mode: String) -> void:
	_mode = SETTINGS.normalize_contextual_help_mode(mode)
	_last_poll_msec = Time.get_ticks_msec()
	if _mode == "off":
		_hide()


func get_help_mode() -> String:
	return _mode


func get_active_hint_id() -> String:
	return _active_id


func refresh(search_root: Node, facts: Dictionary) -> void:
	_ensure_loaded()
	if _hints.is_empty():
		_hide()
		return
	_poll_settings()
	if not _enabled or _mode == "off" or search_root == null or not is_instance_valid(search_root) or _arrow == null or not is_instance_valid(_arrow):
		_hide()
		return
	var chosen: Dictionary = {}
	for hint: Dictionary in _hints:
		if _all_hold(hint.get("show_when", []), facts) and not _any_holds(hint.get("done_when", []), facts):
			chosen = hint
			break
	if chosen.is_empty():
		_hide()
		return
	var target_info: Dictionary = chosen.get("target", {})
	var node_name: String = String(target_info.get("node", ""))
	var found: Node = search_root.find_child(node_name, true, false) if not node_name.is_empty() else null
	var control: Control = found as Control
	if control == null or not control.is_visible_in_tree():
		_hide()
		return
	var rect: Rect2 = control.get_global_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_hide()
		return
	_active_id = String(chosen.get("id", ""))
	_arrow.call("show_at", rect, String(chosen.get("text", "")))


func _hide() -> void:
	_active_id = ""
	if _arrow != null and is_instance_valid(_arrow) and bool(_arrow.call("is_showing")):
		_arrow.call("hide_arrow")


func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_hints = []
	if not FileAccess.file_exists(DEFAULT_PATH):
		push_warning("campaign_hint_arrows: %s fehlt" % DEFAULT_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DEFAULT_PATH))
	if parsed is Dictionary:
		var data: Dictionary = parsed
		var list: Variant = data.get("hints", [])
		if list is Array:
			configure(list)


func _poll_settings() -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_poll_msec < poll_interval_msec:
		return
	_last_poll_msec = now
	var loaded: Dictionary = SETTINGS.load_settings(settings_path)
	_mode = SETTINGS.normalize_contextual_help_mode(String(loaded.get("contextual_help_mode", "compact")))


func _order_less(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("order", 0)) < int(b.get("order", 0))


func _all_hold(words: Variant, facts: Dictionary) -> bool:
	if not words is Array:
		return true
	for word: Variant in words:
		if not _holds(String(word), facts):
			return false
	return true


func _any_holds(words: Variant, facts: Dictionary) -> bool:
	if not words is Array:
		return false
	for word: Variant in words:
		if _holds(String(word), facts):
			return true
	return false


func _holds(word: String, facts: Dictionary) -> bool:
	var split: int = word.find(":")
	var kind: String = word.substr(0, split) if split >= 0 else word
	var arg: String = word.substr(split + 1) if split >= 0 else ""
	match kind:
		"stage":
			return arg.is_valid_int() and facts.has("stage") and int(facts["stage"]) == int(arg)
		"view":
			if String(facts.get("view", "")) == arg:
				return true
			var views: Variant = facts.get("views", [])
			return views is Array and (views as Array).has(arg)
		"fact":
			var value: Variant = facts.get(arg, false)
			return typeof(value) == TYPE_BOOL and bool(value)
	if not _warned.has(word):
		_warned[word] = true
		push_warning("campaign_hint_arrows: unbekanntes Bedingungswort '%s'" % word)
	return false
