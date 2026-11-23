class_name CombatCadence
extends RefCounted
## Gefechtstakt: reine Rechnung ohne Knoten und ohne Spielzustand.
## Jede Einheit beider Seiten schiesst in ihrem eigenen Takt. Der Zaehler ist der
## Entscheidungsschritt (Tick / DECISION_INTERVAL_TICKS), er laeuft dauernd.
## Stufenloser Takt (INI-5): p = Grundschritte der Waffe x cadence_scale x (initiative_base - initiative_weight x Initiative),
## nie unter 1,0. Faellig im Schritt s, wenn floor(s / p) > floor((s - 1) / p). Gerechnet wird in Tausendsteln mit
## ganzen Zahlen, damit Host und jeder Lauf dasselbe Ergebnis bekommen (keine Fliesskomma-Vergleiche).
## Die Werte stehen in data/combat/combat_cadence.json; fehlt die Datei oder ein Feld, gelten die Vorgaben unten.

## Das Gefecht entscheidet jeden 3. Tick; ein Schritt ist so lang.
const DECISION_INTERVAL_TICKS := 3
const CONFIG_PATH := "res://data/combat/combat_cadence.json"
const DEFAULT_CONFIG := {
	"cadence_scale": 8.0,
	"initiative_base": 1.30,
	"initiative_weight": 0.6,
	"reaction_initiative_ticks": 90,
}
## Ohne gueltige Achse (fehlend, NaN, unendlich, negativ) gilt dieser Wert: weder schneller noch langsamer.
const INITIATIVE_NEUTRAL := 0.5

static var _loaded: bool = false
static var _scale_milli: int = 8000
static var _base_milli: int = 1300
static var _weight_milli: int = 600
static var _reaction_ticks: int = 90


static func _ensure_loaded() -> void:
	if _loaded:
		return
	var values: Dictionary = DEFAULT_CONFIG.duplicate()
	if FileAccess.file_exists(CONFIG_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		if typeof(parsed) == TYPE_DICTIONARY:
			for key in DEFAULT_CONFIG.keys():
				var value: Variant = Dictionary(parsed).get(key, null)
				if (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value)):
					values[key] = value
	_apply(values)


static func _apply(values: Dictionary) -> void:
	# Unbrauchbare Werte (Massstab <= 0, negatives Gewicht oder Basis, Basis <= Gewicht, negative Reaktion) ergeben die
	# Vorgaben statt Dauerfeuer: sonst waere der Takt ueberall 1 Schritt.
	var scale_milli: int = int(round(float(values.get("cadence_scale", 8.0)) * 1000.0))
	var base_milli: int = int(round(float(values.get("initiative_base", 1.3)) * 1000.0))
	var weight_milli: int = int(round(float(values.get("initiative_weight", 0.6)) * 1000.0))
	var reaction: int = int(round(float(values.get("reaction_initiative_ticks", 90))))
	if scale_milli <= 0:
		scale_milli = int(round(float(DEFAULT_CONFIG["cadence_scale"]) * 1000.0))
	if base_milli <= 0 or weight_milli < 0 or base_milli <= weight_milli:
		base_milli = int(round(float(DEFAULT_CONFIG["initiative_base"]) * 1000.0))
		weight_milli = int(round(float(DEFAULT_CONFIG["initiative_weight"]) * 1000.0))
	if reaction < 0:
		reaction = int(DEFAULT_CONFIG["reaction_initiative_ticks"])
	_scale_milli = scale_milli
	_base_milli = base_milli
	_weight_milli = weight_milli
	_reaction_ticks = reaction
	_loaded = true


## Nur fuer Tests: andere Werte setzen (fehlende Felder behalten die Vorgabe). reset_config() liest die Datei neu.
static func override_config_for_test(values: Dictionary) -> void:
	var merged: Dictionary = DEFAULT_CONFIG.duplicate()
	for key in values.keys():
		merged[key] = values[key]
	_apply(merged)


static func reset_config() -> void:
	_loaded = false


## Initiative in Tausendsteln (0..1000). Fehlend oder ungueltig = neutral, ueber 1 wird auf 1 begrenzt.
static func initiative_milli(initiative: float) -> int:
	var score: float = initiative
	if is_nan(score) or is_inf(score) or score < 0.0:
		score = INITIATIVE_NEUTRAL
	return int(round(clampf(score, 0.0, 1.0) * 1000.0))


## Takt in Tausendsteln von Schritten (24000 = 24 Schritte). Mindestens 1000. Waffen mit 0 Ticks bleiben bei 1 Schritt.
static func period_milli(ticks_between_attacks: int, initiative: float) -> int:
	_ensure_loaded()
	var base_steps: int = int(ceil(float(maxi(ticks_between_attacks, 0)) / float(DECISION_INTERVAL_TICKS)))
	if base_steps <= 0:
		return 1000
	var factor_micro: int = maxi(_base_milli * 1000 - _weight_milli * initiative_milli(initiative), 0)
	# base_steps x scale x factor, in Tausendsteln: scale_milli x factor_micro / 1e6.
	return maxi((base_steps * _scale_milli * factor_micro + 500000) / 1000000, 1000)


## Aufgerundete Periode in ganzen Schritten (fuer Sperren in Ticks).
static func period_steps(ticks_between_attacks: int, initiative: float) -> int:
	return (period_milli(ticks_between_attacks, initiative) + 999) / 1000


## Zuschlag auf die Erkennung in Ticks: round((0,5 - Initiative) x reaction_initiative_ticks), langsame Leute
## brauchen laenger (+), schnelle kuerzer (-). Ganzzahlig, halbe Werte weg von null.
static func reaction_ticks(initiative: float) -> int:
	_ensure_loaded()
	var numerator: int = (500 - initiative_milli(initiative)) * _reaction_ticks
	var denominator: int = 1000
	if numerator >= 0:
		return (numerator + denominator / 2) / denominator
	return -((-numerator + denominator / 2) / denominator)


static func _floor_div(numerator: int, denominator: int) -> int:
	var quotient: int = numerator / denominator
	if numerator % denominator != 0 and numerator < 0:
		quotient -= 1
	return quotient


static func is_due(step: int, period_milli_value: int) -> bool:
	var p: int = maxi(period_milli_value, 1000)
	return _floor_div(step * 1000, p) > _floor_div((step - 1) * 1000, p)


## Schritte bis zur naechsten Faelligkeit: 0 = jetzt faellig.
static func steps_until_due(step: int, period_milli_value: int) -> int:
	var p: int = maxi(period_milli_value, 1000)
	# Naechster faelliger Schritt t: kleinstes t mit floor(t x 1000 / p) > floor((step - 1) x 1000 / p),
	# also t >= ceil(q x p / 1000) fuer q = floor((step - 1) x 1000 / p) + 1.
	var next_count: int = _floor_div((step - 1) * 1000, p) + 1
	var due_step: int = (next_count * p + 999) / 1000
	return maxi(due_step - step, 0)
