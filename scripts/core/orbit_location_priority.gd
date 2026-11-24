extends RefCounted
## Handel 2a-2, Nachbesserung 2: EINE Stelle fuer "welcher Ort gilt in einem Orbit, wenn mehrere Orte darin liegen".
## Ohne passende Vorwahl zuerst ein Ort, der NICHT in ADDITIVE_LOCATION_IDS steht (die vorhandene Kampagne rechnet wie vor den neuen
## Orten), danach alphabetisch; erst dann die additiven Orte, ebenfalls alphabetisch. Reine Hilfsfunktion, keine Abhaengigkeiten.
## SimulationRoot._location_at_orbit (Sprungkosten) und SingleplayerRuntimeAdapter._location_for_orbit (Reichweite, Nottanker) rufen sie.
## Die Liste der additiven Orte hat hier ihren Ursprung; der Kampagnenstand (ADDITIVE_LOCATION_IDS) zeigt auf sie.

const ADDITIVE_LOCATION_IDS: Array = ["relay_ridge", "asteroid_belt", "muellers_farm", "shady_lab", "templanon"]

## location_orbits: {Ort -> Orbit}. Liefert "" bei leerem oder unbekanntem Orbit.
static func location_at_orbit(location_orbits: Dictionary, orbit_id: String, preferred: String = "") -> String:
	if orbit_id.is_empty(): return ""
	if not preferred.is_empty() and String(location_orbits.get(preferred, "")) == orbit_id: return preferred
	var ids: Array = []
	var additive: Array = []
	for id in location_orbits:
		if String(location_orbits[id]) != orbit_id: continue
		if ADDITIVE_LOCATION_IDS.has(String(id)): additive.append(String(id))
		else: ids.append(String(id))
	ids.sort()
	additive.sort()
	ids.append_array(additive)
	return "" if ids.is_empty() else String(ids[0])
