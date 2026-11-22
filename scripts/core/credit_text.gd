extends RefCounted
## Schulden (Abschnitt K): die eine gemeinsame Formatierung fuer Guthaben und die festen Saetze zu Krediten und Zinsen.
## Reine Texte aus Zahlen; kein Spielstand. Alle Anzeigen, die Credits zeigen, rufen format() statt "%d" selbst zu bauen.

## Guthaben als Text. Ab 0: "<n><einheit>"; im Minus: "-<n><einheit> Schulden". einheit mit fuehrendem Leerzeichen, z. B. " Cr".
static func format(credits: int, unit: String = "") -> String:
	if credits >= 0: return "%d%s" % [credits, unit]
	return "-%d%s Schulden" % [-credits, unit]

## Zusatzzeile im Angebot des Nottankdienstes, wenn die Credits nicht reichen.
static func credit_offer_line(credits_after: int, interest_rate: float, interest_period_seconds: float) -> String:
	return "Auf Kredit: Kontostand danach -%d Cr. Zinsen %s alle %s." % [-credits_after, _percent(interest_rate), _period(interest_period_seconds)]

## Meldung bei jeder Zinsbuchung (amount > 0 = abgezogene Zinsen, credits = Kontostand danach, negativ).
static func interest_message(amount: int, credits: int) -> String:
	return "Zinsen: -%d Cr. Kontostand %d Cr." % [amount, credits]

static func _percent(rate: float) -> String:
	var percent: float = roundf(rate * 1000.0) / 10.0
	if is_equal_approx(percent, floorf(percent)): return "%d %%" % int(percent)
	return "%.1f %%" % percent

static func _period(seconds: float) -> String:
	var minutes: float = seconds / 60.0
	if seconds >= 120.0 and is_equal_approx(minutes, floorf(minutes)):
		return "%d Minuten" % int(minutes)
	return "%d Sekunden" % int(ceil(seconds))
