extends RefCounted
## Abschnitt P (22.11.2026): Pleite. Reine Regel ohne Knoten und ohne Seiteneffekt.
## Pleite ist man, wenn man das Minus nicht mehr abarbeiten kann: kein eigenes Schiff kann mehr starten oder weiterfliegen, kein
## Nottanker ist unterwegs UND der Nottankdienst wuerde nicht liefern (Kreditrahmen waere ueberschritten, oder am Tankservice ist er
## nicht zustaendig). Solange irgendein Schiff etwas Bezahlbares tun kann, gibt es noch Auftraege und Verkaeufe; dann ist man nicht
## pleite, auch tief im Minus. Der Kontostand ist keine eigene Bedingung: alles, was von ihm abhaengt, steckt in den Eingaben je Schiff.
## `_reachable_credits` ist der erreichbare Kontostand (Guthaben plus Erloes aus allem Verkaufbaren am Ort); der Adapter hat damit schon
## refuel_affordable, next_legs und tanker_available bestimmt (tanker_available = die echte Bestellpruefung des Nottankdienstes
## sagt ok). Ein Rahmen <= 0 heisst: die Daten kennen keine Schulden, dann gibt es keine Pleite.
##
## Ein Schiff kann weiter, wenn eines davon gilt (Felder wie get_fuel_status des Adapters):
##  - tanker_order_open: ein Nottanker ist bestellt und unterwegs,
##  - phase "quantum" oder "approach" ohne Folgeetappe: das Schiff ist unterwegs,
##  - eine Folgeetappe in next_legs ist bezahlbar (affordable) - am Boden zaehlt der Abflug als Folgeetappe,
##  - refuel_affordable: Tanken ist hier bezahlbar,
##  - tanker_available: der Nottankdienst wuerde bestellbar liefern.
## Grund (reason): "bankrupt", "no_debt_limit" (Daten ohne Kreditrahmen), "no_craft" (keine Schiffe),
## "tanker_order_open", "tanker_available", "craft_can_fly".

static func is_bankrupt(_reachable_credits: int, debt_limit: int, craft_fuel_states: Array) -> Dictionary:
	if debt_limit <= 0:
		return {"bankrupt": false, "reason": "no_debt_limit"}
	var counted := 0
	for entry: Variant in craft_fuel_states:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		counted += 1
		var state: Dictionary = entry
		if bool(state.get("tanker_order_open", false)):
			return {"bankrupt": false, "reason": "tanker_order_open", "craft_id": String(state.get("craft_id", ""))}
		if _can_continue(state):
			return {"bankrupt": false, "reason": "craft_can_fly", "craft_id": String(state.get("craft_id", ""))}
		if bool(state.get("tanker_available", false)):
			return {"bankrupt": false, "reason": "tanker_available", "craft_id": String(state.get("craft_id", ""))}
	if counted == 0:
		return {"bankrupt": false, "reason": "no_craft"}
	return {"bankrupt": true, "reason": "bankrupt"}


static func _can_continue(state: Dictionary) -> bool:
	var phase := String(state.get("phase", ""))
	var legs: Array = state.get("next_legs", []) if typeof(state.get("next_legs", [])) == TYPE_ARRAY else []
	if phase == "quantum" or (phase == "approach" and legs.is_empty()):
		return true
	for leg: Variant in legs:
		if typeof(leg) == TYPE_DICTIONARY and bool(Dictionary(leg).get("affordable", false)):
			return true
	return bool(state.get("refuel_affordable", false))
