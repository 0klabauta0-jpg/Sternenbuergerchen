extends RefCounted
## Munition im Bodengefecht (M4a). Merkt je Person und Waffe das eingelegte Magazin und das Nachladen; die Regeln selbst
## (Schuss, leer, Nachladen) stehen in ammo_rules.gd, die Zahlen in den Waffendaten und in data/combat/ammo_rules.json.
## Ein Schuss = eine Patrone. Ist das Magazin leer, wird das naechste Reservemagazin der Person abgezogen und es wird
## reload_ticks x reload_scale Ticks nachgeladen (ohne Schuss); ohne Reservemagazin bleibt die Einheit ohne Munition.
## Gegner ("unlimited") laden ohne Abzug nach. Der Zustand gehoert dem Einsatz: nichts davon steht im Speicherstand.
## Kein Zufall, nur Tickzaehler: gleiche Tickfolge ergibt gleichen Verbrauch.

const AMMO_RULES = preload("res://scripts/core/ammo_rules.gd")
const WEAPON_DATA = preload("res://scripts/core/weapon_data.gd")

## Lesezugriff auf die Reserve einer Person: (unit_id: String, ammo_class: String) -> int.
var reserve_count: Callable = Callable()
## Abzug eines Reservemagazins: (unit_id: String, ammo_class: String) -> bool.
var take_reserve: Callable = Callable()
## Waffeneintrag: (weapon_id: String) -> Dictionary mit ammo_class, magazine_size, reload_ticks; leer = Waffendaten.
var weapon_lookup: Callable = Callable()

var _reload_scale: int = AMMO_RULES.DEFAULT_RELOAD_SCALE
var _rules: Dictionary = {}
## "unit_id|weapon_id" -> {"state": {rounds, reload_ticks_left}, "last": Tick der letzten Fortschreibung}
var _entries: Dictionary = {}
## "unit_id|weapon_id" -> abgegebene Schuesse im Einsatz (nur Zaehler, kein Einfluss auf die Regeln)
var _shots: Dictionary = {}


func _init() -> void:
	_rules = AMMO_RULES.load_rules()
	_reload_scale = AMMO_RULES.reload_scale(_rules)


func reset() -> void:
	_entries.clear()
	_shots.clear()


func weapon_info(weapon_id: String) -> Dictionary:
	# Keine Angriffswaffe (leere Kennung, z. B. Medictool): kein Munitionsbedarf; die Waffendaten wuerden hier auf die Pistole zurueckfallen.
	var weapon: Dictionary = {}
	if weapon_id != "":
		weapon = Dictionary(weapon_lookup.call(weapon_id)) if weapon_lookup.is_valid() else WEAPON_DATA.get_weapon(weapon_id)
	var ammo_class: String = String(weapon.get("ammo_class", ""))
	# Wirksame Groesse im Gefecht (M4b): Waffendaten x magazine_scale.
	var magazine_size: int = AMMO_RULES.effective_magazine_size(int(weapon.get("magazine_size", 0)), _rules)
	return {
		"ammo_class": ammo_class,
		"magazine_size": magazine_size,
		"reload_ticks": maxi(1, int(weapon.get("reload_ticks", 0))) * _reload_scale,
		"needs_ammo": ammo_class != "" and magazine_size > 0,
	}


func needs_ammo(weapon_id: String) -> bool:
	return bool(weapon_info(weapon_id).needs_ammo)


## Darf die Einheit jetzt schiessen? Schreibt die Zeit fort und beginnt bei Bedarf das Nachladen (zieht dann die Reserve ab).
func can_fire(unit_id: String, weapon_id: String, tick: int, unlimited: bool) -> bool:
	var info: Dictionary = weapon_info(weapon_id)
	if not bool(info.needs_ammo):
		return true
	return AMMO_RULES.can_fire(_update(unit_id, weapon_id, tick, unlimited, info), true)


## Bucht einen abgegebenen Schuss (Normalschuss oder Ueberwachung): eine Patrone weniger; wird das Magazin leer, beginnt das Nachladen.
## Gibt "empty" zurueck, wenn die Einheit mit diesem Schuss ganz ohne Munition dasteht (leer, keine Reserve), sonst "".
## Ein Schuss einer Einheit, die gar nicht schiessen darf (laedt nach, leer), ist ein Fehlerfall: "not_firing" und eine Warnung
## mit Einheit und Waffe; gebucht wird er nicht. Die Aufrufer fragen vorher can_fire.
func note_shot(unit_id: String, weapon_id: String, tick: int, unlimited: bool) -> String:
	var info: Dictionary = weapon_info(weapon_id)
	if not bool(info.needs_ammo):
		return ""
	var state: Dictionary = _update(unit_id, weapon_id, tick, unlimited, info)
	if not AMMO_RULES.can_fire(state, true):
		push_warning("CombatAmmo: Schuss gebucht, obwohl die Einheit nicht schiessen darf (unit=%s weapon=%s tick=%d)" % [unit_id, weapon_id, tick])
		return "not_firing"
	state = AMMO_RULES.after_shot(state)
	var result := ""
	if AMMO_RULES.needs_reload(state):
		state = _begin_reload_if_possible(unit_id, state, unlimited, info)
		if AMMO_RULES.needs_reload(state):
			result = "empty"
	var key: String = _key(unit_id, weapon_id)
	_entries[key]["state"] = state
	_shots[key] = int(_shots.get(key, 0)) + 1
	return result


## Schuesse, die die Einheit mit dieser Waffe in diesem Einsatz abgegeben hat.
func shots_fired(unit_id: String, weapon_id: String) -> int:
	return int(_shots.get(_key(unit_id, weapon_id), 0))


## Nur lesen (Anzeige, Tests): {"state": none|ready|reloading|empty, rounds, magazine_size, reserve (-1 = unbegrenzt), reload_ticks_left}.
func status(unit_id: String, weapon_id: String, tick: int, unlimited: bool) -> Dictionary:
	var info: Dictionary = weapon_info(weapon_id)
	if not bool(info.needs_ammo):
		return {"state": "none", "rounds": 0, "magazine_size": 0, "reserve": -1, "reload_ticks_left": 0}
	var magazine_size: int = int(info.magazine_size)
	var entry: Dictionary = Dictionary(_entries.get(_key(unit_id, weapon_id), {}))
	var state: Dictionary = Dictionary(entry.get("state", AMMO_RULES.new_weapon_state(magazine_size))).duplicate(true)
	if not entry.is_empty():
		state = AMMO_RULES.advance_reload(state, maxi(0, tick - int(entry.get("last", tick))), magazine_size)
	var reserve: int = -1 if unlimited else _reserve(unit_id, String(info.ammo_class))
	var kind := "ready"
	if int(state.get("reload_ticks_left", 0)) > 0:
		kind = "reloading"
	elif int(state.get("rounds", 0)) <= 0:
		# Leer ohne laufendes Nachladen: mit Reserve beginnt es beim naechsten Schritt, sonst ist die Einheit ohne Munition.
		kind = "reloading" if (unlimited or reserve > 0) else "empty"
	return {"state": kind, "rounds": int(state.get("rounds", 0)), "magazine_size": magazine_size, "reserve": reserve, "reload_ticks_left": int(state.get("reload_ticks_left", 0))}


## Kurzer Anzeigetext: "Mun. 9/12 +2", "lädt nach", "Keine Munition"; leer, wenn die Waffe keine Munition braucht.
func status_text(unit_id: String, weapon_id: String, tick: int, unlimited: bool) -> String:
	var st: Dictionary = status(unit_id, weapon_id, tick, unlimited)
	match String(st.state):
		"ready":
			var text: String = "Mun. %d/%d" % [int(st.rounds), int(st.magazine_size)]
			return text if int(st.reserve) < 0 else "%s +%d" % [text, int(st.reserve)]
		"reloading":
			return "lädt nach"
		"empty":
			return "Keine Munition"
	return ""


func _key(unit_id: String, weapon_id: String) -> String:
	return unit_id + "|" + weapon_id


func _reserve(unit_id: String, ammo_class: String) -> int:
	return maxi(0, int(reserve_count.call(unit_id, ammo_class))) if reserve_count.is_valid() else 0


func _begin_reload_if_possible(unit_id: String, state: Dictionary, unlimited: bool, info: Dictionary) -> Dictionary:
	if unlimited or (take_reserve.is_valid() and bool(take_reserve.call(unit_id, String(info.ammo_class)))):
		return AMMO_RULES.begin_reload(state, int(info.reload_ticks))
	return state


## Zeit fortschreiben (laufendes Nachladen zaehlt herunter, am Ende ist das Magazin voll); ein leeres Magazin ohne laufendes
## Nachladen versucht, ein Reservemagazin zu ziehen. Legt den Eintrag an: zu Einsatzbeginn ist das Magazin voll.
func _update(unit_id: String, weapon_id: String, tick: int, unlimited: bool, info: Dictionary) -> Dictionary:
	var key: String = _key(unit_id, weapon_id)
	var magazine_size: int = int(info.magazine_size)
	var entry: Dictionary = Dictionary(_entries.get(key, {}))
	var state: Dictionary = Dictionary(entry.get("state", AMMO_RULES.new_weapon_state(magazine_size)))
	if not entry.is_empty():
		state = AMMO_RULES.advance_reload(state, maxi(0, tick - int(entry.get("last", tick))), magazine_size)
	if AMMO_RULES.needs_reload(state):
		state = _begin_reload_if_possible(unit_id, state, unlimited, info)
	_entries[key] = {"state": state, "last": tick}
	return state
