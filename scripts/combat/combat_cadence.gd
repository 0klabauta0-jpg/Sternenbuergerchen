class_name CombatCadence
extends RefCounted
## Gefechtstakt: reine Rechnung ohne Knoten und ohne Zustand.
## Jede Einheit beider Seiten schiesst in ihrem eigenen Takt. Der Zaehler ist der
## Entscheidungsschritt (Tick / DECISION_INTERVAL_TICKS), er laeuft dauernd.
## Stufenloser Takt (INI-5): p = Grundschritte der Waffe x (1,30 - 0,6 x Initiative), nie unter 1,0.
## Faellig im Schritt s, wenn floor(s / p) > floor((s - 1) / p). Gerechnet wird in Tausendsteln mit ganzen Zahlen,
## damit Host und jeder Lauf dasselbe Ergebnis bekommen (keine Fliesskomma-Vergleiche).

## Das Gefecht entscheidet jeden 3. Tick; ein Schritt ist so lang.
const DECISION_INTERVAL_TICKS := 3
## p = base x (PERIOD_FACTOR_BASE_MILLI - PERIOD_FACTOR_SLOPE_MILLI x Initiative) / 1000.
const PERIOD_FACTOR_BASE_MILLI := 1300
const PERIOD_FACTOR_SLOPE_MILLI := 600
## Ohne gueltige Achse (fehlend, NaN, unendlich, negativ) gilt dieser Wert: weder schneller noch langsamer.
const INITIATIVE_NEUTRAL := 0.5
## Reaktionszeit vor dem ersten Schuss: round((0,5 - Initiative) x 20) Ticks.
const REACTION_TICKS_PER_INITIATIVE := 20


## Initiative in Tausendsteln (0..1000). Fehlend oder ungueltig = neutral, ueber 1 wird auf 1 begrenzt.
static func initiative_milli(initiative: float) -> int:
	var score: float = initiative
	if is_nan(score) or is_inf(score) or score < 0.0:
		score = INITIATIVE_NEUTRAL
	return int(round(clampf(score, 0.0, 1.0) * 1000.0))


## Takt in Tausendsteln von Schritten (3180 = 3,18 Schritte). Mindestens 1000.
static func period_milli(ticks_between_attacks: int, initiative: float) -> int:
	var base_steps: int = int(ceil(float(maxi(ticks_between_attacks, 0)) / float(DECISION_INTERVAL_TICKS)))
	var factor_milli_milli: int = PERIOD_FACTOR_BASE_MILLI * 1000 - PERIOD_FACTOR_SLOPE_MILLI * initiative_milli(initiative)
	return maxi((base_steps * factor_milli_milli + 500) / 1000, 1000)


## Aufgerundete Periode in ganzen Schritten (fuer Sperren in Ticks).
static func period_steps(ticks_between_attacks: int, initiative: float) -> int:
	return (period_milli(ticks_between_attacks, initiative) + 999) / 1000


## Zuschlag auf die Erkennung in Ticks: langsame Leute brauchen laenger (+), schnelle kuerzer (-).
## Ganzzahlig gerundet, halbe Werte weg von null.
static func reaction_ticks(initiative: float) -> int:
	var numerator: int = (500 - initiative_milli(initiative)) * REACTION_TICKS_PER_INITIATIVE
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
	var waited: int = 0
	while not is_due(step + waited, p):
		waited += 1
	return waited
