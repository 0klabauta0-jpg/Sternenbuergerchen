class_name CombatCadence
extends RefCounted
## Gefechtstakt: reine Rechnung ohne Knoten und ohne Zustand.
## Jede Einheit beider Seiten schiesst in ihrem eigenen Takt. Der Zaehler ist der
## Entscheidungsschritt (Tick / DECISION_INTERVAL_TICKS), er laeuft dauernd.
## Eine Einheit mit Periode N ist dran, wenn step % N == 0 (kleineres N = oefter).
## Periode = Grundtakt der Waffe (in Schritten) + Verschiebung aus der Initiative.

## Das Gefecht entscheidet jeden 3. Tick; ein Schritt ist so lang.
const DECISION_INTERVAL_TICKS := 3
## Initiative (0..1) ab diesem Wert schiesst die Person einen Schritt frueher (Periode -1).
const INITIATIVE_FAST_FROM := 0.67
## Initiative (0..1) bis zu diesem Wert schiesst die Person einen Schritt spaeter (Periode +1).
const INITIATIVE_SLOW_UNTIL := 0.33
const INITIATIVE_STEP_SHIFT := 1
## Ohne gueltige Achse (fehlend, NaN, ausserhalb 0..1) gilt dieser Wert: keine Verschiebung.
const INITIATIVE_NEUTRAL := 0.5


static func period_steps(ticks_between_attacks: int, initiative: float) -> int:
	var base_steps: int = int(ceil(float(maxi(ticks_between_attacks, 0)) / float(DECISION_INTERVAL_TICKS)))
	var score: float = initiative
	if is_nan(score) or is_inf(score) or score < 0.0 or score > 1.0:
		score = INITIATIVE_NEUTRAL
	var shift: int = 0
	if score >= INITIATIVE_FAST_FROM:
		shift = -INITIATIVE_STEP_SHIFT
	elif score <= INITIATIVE_SLOW_UNTIL:
		shift = INITIATIVE_STEP_SHIFT
	return maxi(base_steps + shift, 1)


static func is_due(step: int, period: int) -> bool:
	return step % maxi(period, 1) == 0


## Schritte bis zur naechsten Faelligkeit: 0 = jetzt faellig.
static func steps_until_due(step: int, period: int) -> int:
	var p: int = maxi(period, 1)
	return (p - step % p) % p
