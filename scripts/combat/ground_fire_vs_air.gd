extends RefCounted
## LC6: gegnerische Bodentruppen beschiessen ein eigenes Schiff in der Luft (Luftunterstuetzung im Einsatz).
##
## Regeln (Auftraggeber, 22.11.2026):
## - Nur Raketenwerfer (rocket_launcher) und Schienenkanone (rail_gun) wirken gegen Schiffe; alle anderen
##   Waffen haelt der Schild ab, solche Einheiten schiessen gar nicht erst auf Schiffe.
## - Eigener Takt je Einheit (Waffentakt), nicht der eine Schussplatz des Bodengefechts. Hat die Einheit ein
##   Bodenziel in Kontakt, geht der Boden vor.
## - Warnung, dann Treffer: das rechnet der vorhandene Baustein air_asset_threat_resolver.gd mit seinen Zahlen.
##   Dazu kommt das Ausweichen des Piloten (air_defense_engagement.pilot_profile) als Faktor (1 - Ausweichen) auf
##   die Trefferchance. Die Trefferchance ist die "risk" des Bausteins.
## - Zufall aus dem Strom des Luft-Boden-Feuers der SimulationRoot (Callable "roll"), kein eigener Strom.
## - Rumpf (AirAssetStatus.integrity) faellt durch Bodenbeschuss nie unter 1 %. Auf oder unter
##   auto_break_off_hull_fraction (35 %) dreht das Schiff ab: Feuerstopp, kein Angriffsbefehl und kein Bodenfeuer
##   bis zur Reparatur.
## Die Klasse haelt nur Takt- und Meldungsgedaechtnis; die Spielwahrheit (Rumpf) schreibt die SimulationRoot.

const RESOLVER_SCRIPT: GDScript = preload("res://scripts/combat/air_asset_threat_resolver.gd")
const AIR_DEFENSE: GDScript = preload("res://scripts/combat/air_defense_engagement.gd")
const AIR_ASSET_STATUS_SCRIPT: GDScript = preload("res://scripts/mission/air_asset_status.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const COMBAT_FIRE_DECISION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")

const HULL_FLOOR: int = 1
const REFUSAL_REASON: String = "hull_too_damaged"
const REFUSAL_TEXT: String = "Schiff schwer beschädigt: kein Angriff mehr möglich."
const MESSAGE_FIRST_HIT: String = "%s wird vom Boden beschossen."
const MESSAGE_BREAK_OFF: String = "%s schwer beschädigt – dreht ab. Rumpf %d %%."
const WARNING_TEXT: Dictionary = {
	"rocket_launcher": "%s: Raketenwerfer schaltet auf!",
	"rail_gun": "%s: Schienenkanone zielt!",
}

var _resolver = RESOLVER_SCRIPT.new()
var _next_shot_tick: Dictionary = {}
var _locks: Dictionary = {}
var _hit_reported: Dictionary = {}
var _break_off_reported: Dictionary = {}
var _cease_pending: Dictionary = {}
## Ergebnis des letzten advance() (leer, wenn nichts zu tun war); nur zum Lesen, etwa fuer Pruefungen.
var last_result: Dictionary = {}
# Nur waehrend advance() gesetzt (Zugriff fuer die Callables), danach wieder leer.
var _driver: Node = null
var _adapter = null
var _registry: Node = null
var _friendly_units: Array = []


## Nur Raketenwerfer und Schienenkanone wirken gegen Schiffe in der Luft.
static func weapon_threatens_ships(weapon_id: String) -> bool:
	return bool(WEAPON_DATA_SCRIPT.call("is_anti_armor_weapon_id", weapon_id))


static func break_off_fraction() -> float:
	var pilot: Dictionary = Dictionary(AIR_DEFENSE.definition().get("pilot", {}))
	return float(pilot.get("auto_break_off_hull_fraction", 0.35))


## Rumpf auf oder unter der Abdrehgrenze. Ein leerer Stand (nie getroffen) ist nicht abgedreht.
static func is_broken_off(status: Dictionary) -> bool:
	if status.is_empty():
		return false
	var max_integrity: int = int(status.get("max_integrity", 100))
	if max_integrity <= 0:
		return false
	return float(int(status.get("integrity", max_integrity))) / float(max_integrity) <= break_off_fraction() + 0.000001


static func refusal() -> Dictionary:
	return {"ok": false, "reason": REFUSAL_REASON, "message": REFUSAL_TEXT}


## Ausweichen des Piloten (0.15 bis 0.60), derselbe Pilotenwert wie beim Anflug.
static func evasion_for(pilot_skill: float) -> float:
	return float(AIR_DEFENSE.pilot_profile(pilot_skill).get("evasion", 0.0))


static func hit_chance(risk: float, pilot_skill: float) -> float:
	return clampf(risk * (1.0 - evasion_for(pilot_skill)), 0.0, 1.0)


func mark_cease_done(craft_id: String) -> void:
	_cease_pending.erase(craft_id)


## ctx: tick:int, targets:Array (je {craft_id, display_name, status:Dictionary, pilot_skill:float, position:Vector2}),
## shooters:Array, id_of(unit)->String, weapon_of(unit)->String, is_fit(unit)->bool, has_ground_contact(unit)->bool,
## sees(unit, target)->{visible:bool, range_tiles:float}, roll()->float.
## Rueckgabe: events (Schuesse, Warnungen), messages ({craft_id,text}), updates ({craft_id: {snapshot, effect}}),
## cease (Schiffe, fuer die ein Feuerstopp aussteht).
func step(ctx: Dictionary) -> Dictionary:
	var out: Dictionary = {"events": [], "messages": [], "updates": {}, "cease": []}
	var tick: int = int(ctx.get("tick", 0))
	var targets: Array = Array(ctx.get("targets", []))
	_forget_departed(targets)
	if targets.is_empty():
		return out
	var shooters: Array = Array(ctx.get("shooters", []))
	var id_of: Callable = ctx.get("id_of", Callable())
	var weapon_of: Callable = ctx.get("weapon_of", Callable())
	var is_fit: Callable = ctx.get("is_fit", Callable())
	var has_ground_contact: Callable = ctx.get("has_ground_contact", Callable())
	var sees: Callable = ctx.get("sees", Callable())
	var roll: Callable = ctx.get("roll", Callable())
	if not (id_of.is_valid() and weapon_of.is_valid() and is_fit.is_valid() and has_ground_contact.is_valid() and sees.is_valid() and roll.is_valid()):
		return out
	for target_variant in targets:
		var target: Dictionary = Dictionary(target_variant)
		var craft_id: String = String(target.get("craft_id", ""))
		if craft_id.is_empty():
			continue
		var display_name: String = String(target.get("display_name", craft_id))
		var status: Dictionary = _seed_status(target, craft_id, display_name)
		if bool(AIR_ASSET_STATUS_SCRIPT.call("is_terminal_state", String(status.get("state", "")))):
			continue
		var changed: bool = false
		var last_effect: Dictionary = {}
		for unit in shooters:
			var unit_id: String = String(id_of.call(unit))
			if unit_id.is_empty():
				continue
			var weapon_id: String = String(WEAPON_DATA_SCRIPT.call("sanitize_weapon_id", String(weapon_of.call(unit)), "none"))
			var key: String = "%s|%s" % [craft_id, unit_id]
			if not weapon_threatens_ships(weapon_id) or not bool(is_fit.call(unit)) or bool(has_ground_contact.call(unit)):
				_locks.erase(key)
				continue
			var sight: Dictionary = Dictionary(sees.call(unit, target))
			var range_tiles: float = float(sight.get("range_tiles", INF))
			if not bool(sight.get("visible", false)) or range_tiles > float(WEAPON_DATA_SCRIPT.call("get_effective_tile_range", weapon_id)):
				_locks.erase(key)
				continue
			if tick < int(_next_shot_tick.get(unit_id, 0)):
				continue
			_next_shot_tick[unit_id] = tick + maxi(int(WEAPON_DATA_SCRIPT.call("get_ticks_between_attacks", weapon_id)), 1)
			var threat_context: Dictionary = {
				"weapon_id": weapon_id, "attacker_unit_id": unit_id, "attacker_label": unit_id, "asset_id": craft_id,
				"range_tiles": range_tiles, "asset_position": target.get("position", Vector2.ZERO),
				"sequence": str(tick), "has_line_of_sight": true, "visible_in_fow": true, "altitude_layer": "low",
				"allow_destroy": false,
			}
			if not _locks.has(key):
				# Aufschaltung: erst Warnung (der Baustein richtet keinen Schaden an), dann Treffer im naechsten Takt.
				_locks[key] = true
				threat_context["warning_seen"] = false
				var warning: Dictionary = Dictionary(_resolver.call("evaluate_threat", status, threat_context))
				if not bool(warning.get("eligible", false)):
					_locks.erase(key)
					continue
				if not bool(AIR_ASSET_STATUS_SCRIPT.call("is_damage_state", String(status.get("state", "")))):
					status = Dictionary(warning.get("next_status", status)).duplicate(true)
					last_effect = Dictionary(warning.get("simulation_effect", {})).duplicate(true)
					changed = true
				out.events.append({"type": "warning", "craft_id": craft_id, "attacker_id": unit_id, "weapon_id": weapon_id, "tick": tick})
				out.messages.append({"craft_id": craft_id, "text": String(WARNING_TEXT.get(weapon_id, "%s: Bodenfeuer schaltet auf!")) % display_name})
				continue
			threat_context["warning_seen"] = true
			var probe: Dictionary = Dictionary(_resolver.call("evaluate_threat", status, threat_context))
			if not bool(probe.get("eligible", false)) or not bool(probe.get("hit_allowed", false)):
				continue
			var risk: float = float(probe.get("risk", 0.0))
			var chance: float = hit_chance(risk, float(target.get("pilot_skill", 0.5)))
			var drawn: float = float(roll.call())
			var hit: bool = drawn < chance
			var event: Dictionary = {"type": "shot", "craft_id": craft_id, "attacker_id": unit_id, "weapon_id": weapon_id, "tick": tick,
				"risk": risk, "evasion": evasion_for(float(target.get("pilot_skill", 0.5))), "chance": chance, "roll": drawn, "hit": hit, "damage": 0}
			if hit:
				var before: int = int(status.get("integrity", 100))
				threat_context["damage"] = mini(int(probe.get("damage", 0)), maxi(before - HULL_FLOOR, 0))
				var applied: Dictionary = Dictionary(_resolver.call("evaluate_threat", status, threat_context))
				if bool(applied.get("eligible", false)):
					status = Dictionary(applied.get("next_status", status)).duplicate(true)
					last_effect = Dictionary(applied.get("simulation_effect", {})).duplicate(true)
					changed = true
					event["damage"] = before - int(status.get("integrity", before))
				event["integrity_after"] = int(status.get("integrity", before))
				if not _hit_reported.has(craft_id):
					_hit_reported[craft_id] = true
					out.messages.append({"craft_id": craft_id, "text": MESSAGE_FIRST_HIT % display_name})
				if is_broken_off(status) and not _break_off_reported.has(craft_id):
					_break_off_reported[craft_id] = true
					_cease_pending[craft_id] = true
					out.messages.append({"craft_id": craft_id, "text": MESSAGE_BREAK_OFF % [display_name, int(status.get("integrity", 0))]})
			out.events.append(event)
		if changed:
			out.updates[craft_id] = {"snapshot": status, "effect": last_effect}
	for craft_id in _cease_pending.keys():
		out.cease.append(craft_id)
	return out


## Anschluss an den Gefechts-Driver (ein Aufruf je Entscheidungs-Tick, nur mit Schiffen in der Luft).
## Der Driver reicht sich selbst herein; gelesen wird nur, was er auch fuer das Bodengefecht liest.
func advance(driver: Node, root: Node, controller: Node, tick: int) -> Dictionary:
	last_result = {}
	if root == null or not root.has_method("get_air_support_threat_targets"):
		return {}
	var targets: Array = Array(root.call("get_air_support_threat_targets"))
	if targets.is_empty() and _locks.is_empty() and _hit_reported.is_empty() and _break_off_reported.is_empty() and _cease_pending.is_empty():
		return {}
	var adapter = driver.call("get_hex_sight_adapter")
	var registry: Node = root.call("get_hex_ground_terrain_registry") if root.has_method("get_hex_ground_terrain_registry") else null
	if not targets.is_empty() and (adapter == null or not adapter.is_active() or registry == null):
		return {}
	for index in range(targets.size()):
		var target: Dictionary = Dictionary(targets[index])
		target["display_name"] = _display_name(controller, String(target.get("craft_id", "")))
		targets[index] = target
	_driver = driver
	_adapter = adapter
	_registry = registry
	_friendly_units = driver.call("_get_friendly_combat_units") if not targets.is_empty() else []
	var ctx: Dictionary = {
		"tick": tick,
		"targets": targets,
		"shooters": driver.call("_get_enemy_combat_units") if not targets.is_empty() else [],
		"id_of": Callable(self, "_unit_id_of"),
		"weapon_of": Callable(self, "_weapon_of"),
		"is_fit": Callable(self, "_is_fit"),
		"has_ground_contact": Callable(self, "_has_ground_contact"),
		"sees": Callable(self, "_sees"),
		"roll": Callable(root, "draw_air_ground_roll"),
	}
	var result: Dictionary = step(ctx)
	_driver = null
	_adapter = null
	_registry = null
	_friendly_units = []
	var texts_by_craft: Dictionary = {}
	for message in result.messages:
		var list: Array = texts_by_craft.get(message.craft_id, [])
		list.append(message.text)
		texts_by_craft[message.craft_id] = list
	var craft_ids: Dictionary = {}
	for craft_id in result.updates.keys():
		craft_ids[craft_id] = true
	for craft_id in texts_by_craft.keys():
		craft_ids[craft_id] = true
	for craft_id in craft_ids.keys():
		var update: Dictionary = Dictionary(result.updates.get(craft_id, {}))
		var effect: Dictionary = Dictionary(update.get("effect", {}))
		if not effect.is_empty():
			root.call("enqueue_effect", effect)
		if controller != null and controller.has_method("report_ground_fire_vs_air"):
			controller.call("report_ground_fire_vs_air", craft_id, Dictionary(update.get("snapshot", {})), Array(texts_by_craft.get(craft_id, [])))
	for craft_id in result.cease:
		var ceased: Dictionary = Dictionary(root.call("request_air_support_cease_fire", craft_id, "ground-fire-break-off:%s:%d" % [craft_id, tick]))
		if bool(ceased.get("ok", false)) or String(ceased.get("reason", "")) != "simulation_busy":
			mark_cease_done(craft_id)
	last_result = result
	return result


func _unit_id_of(unit) -> String:
	return String(unit.call("get_unit_id"))


func _weapon_of(unit) -> String:
	return String(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("get_unit_active_weapon_id", unit))


func _is_fit(unit) -> bool:
	return bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("can_enemy_attack", unit))


## Boden geht vor: hat die Einheit ein angreifbares Bodenziel, schiesst sie nicht auf das Schiff.
func _has_ground_contact(unit) -> bool:
	for friendly in _friendly_units:
		if bool(_driver.call("_is_target_attackable", unit, friendly)):
			return true
	return false


## Sichtlinie zur Zelle unter dem Schiff mit den vorhandenen Sichtregeln; der Sichtbogen der Blickrichtung
## gilt gegen Luftziele nicht (360 Grad). Reichweite prueft step() in Feldern (Waffenreichweite).
func _sees(unit, target: Dictionary) -> Dictionary:
	var source: Dictionary = _adapter.build_observer_state(unit, -1.0, 360.0)
	if source.is_empty():
		return {"visible": false, "range_tiles": INF}
	var cell: Vector2i = target.get("cell", Vector2i.ZERO)
	var destination: Dictionary = {"grid": cell, "facing_dir": 0, "stand_height_steps2": roundi(2.0 * float(_registry.call("get_stand_height_at", cell)))}
	var seen: Dictionary = _adapter.query_snapshot(source, destination, _registry, _adapter.get_visibility_cache())
	return {"visible": bool(seen.get("visible", false)), "range_tiles": float(HEX.distance(source.hex_state.grid, cell))}


func _display_name(controller: Node, craft_id: String) -> String:
	if controller != null and controller.has_method("_find_mission_dropship_card_entry"):
		var card: Dictionary = Dictionary(controller.call("_find_mission_dropship_card_entry", craft_id))
		for key in ["display_name", "name", "title"]:
			var text: String = String(card.get(key, "")).strip_edges()
			if not text.is_empty():
				return text
	return craft_id


func _seed_status(target: Dictionary, craft_id: String, display_name: String) -> Dictionary:
	var status: Dictionary = Dictionary(target.get("status", {})).duplicate(true)
	if status.is_empty():
		status = {"asset_type": "dropship", "state": "intact", "integrity": 100, "max_integrity": 100}
	status["asset_id"] = craft_id
	if String(status.get("display_name", "")).is_empty():
		status["display_name"] = display_name
	return status


## Wer nicht mehr in der Luft ist (gelandet, abgestuerzt, Einsatz zu Ende), nimmt sein Gedaechtnis mit.
func _forget_departed(targets: Array) -> void:
	var present: Dictionary = {}
	for target_variant in targets:
		present[String(Dictionary(target_variant).get("craft_id", ""))] = true
	for memory in [_hit_reported, _break_off_reported, _cease_pending]:
		for craft_id in memory.keys():
			if not present.has(craft_id):
				memory.erase(craft_id)
	for key in _locks.keys():
		if not present.has(String(key).get_slice("|", 0)):
			_locks.erase(key)
