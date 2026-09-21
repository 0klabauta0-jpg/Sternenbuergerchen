extends RefCounted
## A single actionable hint from confirmed mission state; no simulation mutation.
static func target(state: Dictionary) -> Dictionary:
	if str(state.get("region",""))!="base":return {}
	var status:=str(state.get("contract",{}).get("status",""))
	if status=="available":return {"id":"contracts","text":"Neuer Auftrag"}
	if status=="recovered":
		return {"id":"storage","text":"Blackbox abgeben" if int(state.get("inventory",{}).get("blackbox",0))>0 else "Blackbox hier ausladen"}
	return {}
