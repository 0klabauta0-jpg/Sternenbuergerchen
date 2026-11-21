extends RefCounted
## Steuerung der Kampagnen-Hinweispfeile. Reine Anzeige: liest nur `facts` und die Oberflaeche,
## schreibt nie Spielwahrheit und speichert nichts.
##
## Hinweisliste (data/campaign_hint_arrows.json):
##   {"version": 1, "hints": [{"id", "text", "target": <Ziel oder Liste von Zielen>,
##     "show_when": ["stage:0", ...], "done_when": [...], "order": 10}]}
## Ein Ziel ist {"node": "<Knotenname>"} oder {"node": "<Knotenname>", "within": "<Elternname>"}.
## Bei einer Liste gewinnt das ERSTE Ziel, das gerade sichtbar ist (Wegweiser: zuerst das eigentliche Ziel,
## danach die Schaltflaeche, die dorthin fuehrt). Ein Ziel kann zusaetzlich "text" (eigener Text statt dem
## des Hinweises) und "require" ({"<Eigenschaft>": <Wert>} am gefundenen Steuerelement) tragen; gilt nur,
## wenn alle Eigenschaften passen (z. B. {"selected": 0}: Auswahlfeld, in dem noch nichts gewaehlt ist).
## Bedingungswoerter (feste Liste, Unbekanntes ist falsch und warnt einmal). Reine Anzeige-Fakten:
##   stage:<n>      facts["stage"] == n
##   view:<name>    facts["view"] == name oder facts["views"] enthaelt name
##   fact:<key>     facts[key] ist der Bool true
## Spielstand-Woerter lesen NUR die Schnappschuesse facts["runtime"] (Laufzeit des Einzelspielers) und
## facts["operations"] (Basisansicht) und schreiben nichts:
##   weapon_carried          irgendeine Person traegt eine Waffe (Waffe 1 oder 2)
##   pistol_in_store         im Basislager liegt mindestens eine Pistole
##   job_open:<id>           Auftrag ist annehmbar (offered/failed), also noch nicht angenommen
##   job_taken:<id>          Auftrag ist angenommen oder laeuft (accepted/active)
##   job_closed:<id>         Auftrag ist weder annehmbar noch angenommen (erledigt)
##   stage_above:<n>         Einfuehrungsstufe ist groesser als n
##   fuel_full               Tank des gewaehlten Schiffs ist voll
##   crew_boarded            Trupp und Pilot des gewaehlten Schiffs sind wirklich an Bord
##   boarding_underway       Trupp ist dem Schiff zugeteilt, aber noch nicht vollstaendig an Bord
##   launch_ready            Abflug ist moeglich (kein Sperrgrund)
##   craft_away              das gewaehlte Schiff ist unterwegs/im Einsatz
## Optional oberste Liste "retire_when": [Woerter] (nur stage_above/job_closed): gelten alle, kann nie wieder ein
## Hinweis offen sein; die Karte baut dann keine Fakten mehr (is_retired).
## Zielnamen: `find_child(name, true, false)` nimmt den ERSTEN Treffer unter der Suchwurzel. Ein Name
## muss dort also eindeutig sein und darf kein `*` oder `?` enthalten (das waeren Muster). Ist er es nicht
## (z. B. InventorySlot_weapon_1 gibt es im Ausruestungspanel UND im Charakterblatt), sagt "within" den
## Elternknoten, unter dem gesucht wird (selbst eindeutig, z. B. PersonnelInventory).

const SETTINGS: GDScript = preload("res://scripts/ui/game_settings_contract.gd")
const DEFAULT_PATH: String = "res://data/campaign_hint_arrows.json"

## Nur fuer Tests: anderer Einstellungspfad / anderer Abstand der Neu-Lesung.
var settings_path: String = SETTINGS.CONFIG_PATH
var poll_interval_msec: int = 2000

var _hints: Array = []
var _retire_when: Array = []
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
			if String(hint.get("id", "")).is_empty() or _target_list(hint.get("target")).is_empty():
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
	# Erstes sichtbares Ziel der Liste gewinnt (Wegweiser-Kette); keins sichtbar: kein Pfeil.
	var rect: Rect2 = Rect2()
	var have_rect: bool = false
	var text: String = String(chosen.get("text", ""))
	for target_info: Dictionary in _target_list(chosen.get("target")):
		var control: Control = _find_target(search_root, target_info)
		if control == null or not control.is_visible_in_tree() or not _requirements_met(control, target_info.get("require", {})):
			continue
		var candidate: Rect2 = control.get_global_rect()
		if candidate.size.x <= 0.0 or candidate.size.y <= 0.0:
			continue
		rect = candidate
		have_rect = true
		text = String(target_info.get("text", text))
		break
	if not have_rect:
		_hide()
		return
	_active_id = String(chosen.get("id", ""))
	_arrow.call("show_at", rect, text)


## "require": {"<Eigenschaft>": <Wert>} am gefundenen Steuerelement (z. B. {"selected": 0} fuer ein Auswahlfeld ohne Wahl).
func _requirements_met(control: Control, require: Variant) -> bool:
	if not require is Dictionary:
		return true
	for key: Variant in (require as Dictionary):
		if control.get(String(key)) != (require as Dictionary)[key]:
			return false
	return true


## `target` darf ein Ziel oder eine Liste von Zielen sein; ergibt immer eine Liste gueltiger Ziele.
func _target_list(raw: Variant) -> Array:
	var result: Array = []
	var entries: Array = []
	if raw is Dictionary:
		entries.append(raw)
	elif raw is Array:
		entries = raw
	for entry: Variant in entries:
		if entry is Dictionary and not String((entry as Dictionary).get("node", "")).is_empty():
			result.append(entry)
	return result


func _find_target(search_root: Node, target_info: Dictionary) -> Control:
	var scope: Node = search_root
	var within: String = String(target_info.get("within", ""))
	if not within.is_empty():
		scope = search_root.find_child(within, true, false)
	if scope == null:
		return null
	return scope.find_child(String(target_info.get("node", "")), true, false) as Control


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
		set_retire_when(data.get("retire_when", []))


## Woerter (alle muessen gelten), nach denen kein Hinweis je wieder offen sein kann ("retire_when" der Datei).
func set_retire_when(words: Variant) -> void:
	_retire_when = []
	if words is Array:
		for word: Variant in words:
			_retire_when.append(String(word))


## Gilt nur mit leichten Fakten (stage, runtime). Eine leere Liste heisst: nie fertig.
func is_retired(facts: Dictionary) -> bool:
	_ensure_loaded()
	if _retire_when.is_empty():
		return false
	for word: String in _retire_when:
		if not _holds(word, facts):
			return false
	return true


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
		"weapon_carried":
			return _w_weapon_carried(facts)
		"pistol_in_store":
			return _w_pistol_in_store(facts)
		"job_open":
			return _job_status(facts, arg) in ["offered", "failed"]
		"job_taken":
			return _job_status(facts, arg) in ["accepted", "active"]
		"job_closed":
			return _job_status(facts, arg) not in ["offered", "failed", "accepted", "active"]
		"stage_above":
			return arg.is_valid_int() and facts.has("stage") and int(facts["stage"]) > int(arg)
		"fuel_full":
			return _w_fuel_full(facts)
		"crew_boarded":
			return _w_crew_boarded(facts)
		"boarding_underway":
			return _w_boarding_underway(facts)
		"launch_ready":
			return _w_launch_ready(facts)
		"craft_away":
			return bool(_selected_craft(facts).get("busy", false))
	if not _warned.has(word):
		_warned[word] = true
		push_warning("campaign_hint_arrows: unbekanntes Bedingungswort '%s'" % word)
	return false


# --- Spielstand-Woerter: nur Lesen in den uebergebenen Schnappschuessen ---

## Ein Feld, das ein Dictionary sein soll, sonst ein leeres (kein Skriptfehler bei falschem Typ).
func _dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


func _runtime(facts: Dictionary) -> Dictionary:
	return _dict(facts.get("runtime"))


func _operations(facts: Dictionary) -> Dictionary:
	return _dict(facts.get("operations"))


func _selected_craft(facts: Dictionary) -> Dictionary:
	return _dict(_operations(facts).get("selected_craft"))


func _w_weapon_carried(facts: Dictionary) -> bool:
	var roster: Variant = _operations(facts).get("roster", [])
	if not roster is Array:
		return false
	for unit: Variant in roster:
		if not unit is Dictionary:
			continue
		var loadout: Variant = (unit as Dictionary).get("loadout", {})
		if not loadout is Dictionary:
			continue
		for key: String in ["weapon_1", "weapon_2"]:
			if String((loadout as Dictionary).get(key, "none")) not in ["", "none"]:
				return true
	return false


func _w_pistol_in_store(facts: Dictionary) -> bool:
	var inventory: Dictionary = _dict(_dict(_runtime(facts).get("supply")).get("inventory"))
	var items: Dictionary = _dict(_dict(inventory.get("base:homebase")).get("items"))
	return int(items.get("pistol", 0)) > 0


func _job_status(facts: Dictionary, job_id: String) -> String:
	var jobs: Dictionary = _dict(_dict(_runtime(facts).get("campaign")).get("jobs"))
	return String(_dict(jobs.get(job_id)).get("status", ""))


func _w_fuel_full(facts: Dictionary) -> bool:
	var craft_id: String = String(_selected_craft(facts).get("id", ""))
	var supply: Dictionary = _dict(_runtime(facts).get("supply"))
	var fuel: Variant = _dict(supply.get("fuel_by_craft_id")).get(craft_id, null)
	if craft_id.is_empty() or fuel == null:
		return false
	return float(fuel) >= float(supply.get("fuel_capacity", 0.0)) - 0.001


func _w_crew_boarded(facts: Dictionary) -> bool:
	var craft: Dictionary = _selected_craft(facts)
	var passengers: int = int(craft.get("passenger_count", 0))
	return bool(craft.get("has_payload", false)) and bool(craft.get("pilot_aboard", false)) and passengers > 0 and int(craft.get("aboard_count", 0)) >= passengers


func _w_boarding_underway(facts: Dictionary) -> bool:
	return bool(_selected_craft(facts).get("has_payload", false)) and not _w_crew_boarded(facts)


## Wie das Flugdeck selbst: can_start der Basisansicht und, auf der Orbitroute, die Abflugpruefung der Laufzeit.
func _w_launch_ready(facts: Dictionary) -> bool:
	var craft: Dictionary = _selected_craft(facts)
	if not bool(craft.get("can_start", false)):
		return false
	var runtime: Dictionary = _runtime(facts)
	if bool(_dict(runtime.get("space_travel")).get("enabled", false)):
		var readiness: Dictionary = _dict(_dict(runtime.get("space_launch_readiness_by_craft_id")).get(String(craft.get("id", ""))))
		return bool(readiness.get("ok", false))
	return true
