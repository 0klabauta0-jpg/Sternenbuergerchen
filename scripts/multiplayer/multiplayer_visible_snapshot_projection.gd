extends RefCounted
## Prepared host publish filter. Caller proves visibility; this owns no sight state.
## New full-scope envelope needs an explicit receiver; never apply as legacy V1.
const V1 = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")
const PROJECTION_SCHEMA := "multiplayer.visible_state.v1"
const ENEMY_DISPLAY := ["unit_id","team_id","visible","position","facing_angle","runtime_state","fire_mode","tactical_stance","tactical_stance_revision","vital_state","health","bleedout_ticks","vital_tick","active_weapon_id","movement_posture","weapon_posture","enemy_visual_archetype_id"]
const OWN_LISTS := ["enemy_security","enemy_team_tactics","character_gameplay","feedback_bubbles","fireteam_tactical","commander_intents","fireteam_plan_status","communication_events","tactical_rules","breakout_states"]

func project_state(dto: Dictionary, recipient_team: String, context: Dictionary) -> Dictionary:
	var checked := _context(dto,recipient_team,context)
	if not checked.ok: return checked
	var own: Dictionary=checked.own
	var allowed: Dictionary=checked.allowed
	var filtered: Dictionary=dto.duplicate(true)
	filtered.units=[]
	for unit: Dictionary in dto.units:
		var id: String=unit.unit_id
		if own.has(id): filtered.units.append(_scrub(unit,checked))
		elif allowed.has(id): filtered.units.append(_pick(unit,ENEMY_DISPLAY))
	filtered.vital_updates=_filter_vitals(dto.get("vital_updates",[]),allowed)
	filtered.contacts=[]
	for contact: Dictionary in dto.get("contacts",[]):
		# contact.team_id is the target's team, never the observer's authority.
		if _own_fireteam(contact.get("fireteam_id",""),checked) and allowed.has(contact.get("unit_id","")):
			filtered.contacts.append(_scrub(contact,checked))
	for key in OWN_LISTS:
		filtered[key]=[]
		for entry: Dictionary in dto.get(key,[]):
			if _own_entry(entry,checked): filtered[key].append(_scrub(entry,checked))
	filtered.fire_events=[]
	for event: Dictionary in dto.get("fire_events",[]):
		if allowed.has(event.get("attacker_unit_id","")) or allowed.has(event.get("target_unit_id","")):
			filtered.fire_events.append(_scrub(event,checked))
	filtered.dropship=_dropship(dto.get("dropship",{}),checked)
	filtered.air_asset_status=[]
	for asset: Dictionary in dto.get("air_asset_status",[]):
		if _record_team(asset,"asset_id",checked.assets)==recipient_team:
			var copy: Dictionary=_scrub(asset,checked)
			for key in ["vfx_events","sfx_events"]:
				copy[key]=[]
				for event in asset.get(key,[]):
					if event is Dictionary:
						# V1 status effects use generic position, not target_position.
						# Do not let normalization discard the hidden endpoint proof.
						var hidden_endpoint := false
						for endpoint in ["unit_id","target_unit_id","attacker_unit_id"]:
							if event.get(endpoint,"")!="" and not allowed.has(event[endpoint]): hidden_endpoint=true
						if hidden_endpoint or event.get("asset_id",asset.asset_id)!=asset.asset_id: continue
					if event is String or event is Dictionary: copy[key].append(_scrub(event,checked))
			filtered.air_asset_status.append(copy)
	var interactions: Dictionary=dto.get("mission_interactions",{}).duplicate(true)
	interactions.interaction_states={}
	for id in dto.get("mission_interactions",{}).get("interaction_states",{}):
		var entry: Dictionary=dto.mission_interactions.interaction_states[id]
		if _own_entry(entry,checked): interactions.interaction_states[id]=_scrub(entry,checked)
	filtered.mission_interactions=interactions
	filtered.objective=_scrub(dto.get("objective",{}),checked)
	filtered.mission_result=_scrub(dto.get("mission_result",{}),checked)
	if filtered.mission_result.has("team_states"):
		filtered.mission_result.team_states=[]
		for entry in dto.mission_result.team_states:
			# Actual Driver team_states are per-unit debrief rows, without team_id.
			if entry is Dictionary and own.has(entry.get("unit_id","")):
				filtered.mission_result.team_states.append(_pick(entry,["unit_id","display_name","vital_state","health_points"]))
	var snapshot: Dictionary=V1.new().build_state_snapshot(filtered)
	return {"ok":true,"schema_version":2,"projection_schema":PROJECTION_SCHEMA,"projection_scope":"full_recipient_state","recipient_team":recipient_team,"tick":snapshot.tick,"snapshot":snapshot}

func project_reliable_vitals(vitals: Array, dto: Dictionary, recipient_team: String, context: Dictionary) -> Dictionary:
	var checked := _context(dto,recipient_team,context)
	if not checked.ok: return checked
	if not _plain(vitals): return _reject("invalid_vital_values")
	for entry in vitals:
		if not entry is Dictionary: return _reject("invalid_vital_values")
	var normalized: Dictionary=V1.new().build_state_snapshot({"vital_updates":_filter_vitals(vitals,checked.allowed)})
	return {"ok":true,"schema_version":2,"projection_schema":PROJECTION_SCHEMA,"projection_scope":"recipient_vital_delta","recipient_team":recipient_team,"tick":dto.tick,"vital_updates":normalized.vital_updates}

func _context(dto: Dictionary, team: String, context: Dictionary) -> Dictionary:
	if typeof(dto.get("schema_version"))!=TYPE_INT or dto.schema_version!=1 or dto.get("snapshot_type")!="state" or dto.get("transfer_mode")!="unreliable" or typeof(dto.get("tick"))!=TYPE_INT or dto.tick<0: return _reject("unsupported_source_snapshot")
	if not _canonical(team) or not _plain(dto) or not _plain(context) or not dto.get("units") is Array: return _reject("invalid_visibility_context")
	if context.get("reference_provenance")!="host_raw": return _reject("host_raw_references_required")
	for key in ["own_unit_ids","visible_unit_ids","fireteam_team_ids"]:
		if not context.has(key): return _reject("missing_visibility_context")
	var ft: Variant=context.fireteam_team_ids
	if not _team_map(ft,true): return _reject("invalid_fireteam_teams")
	var crafts: Variant=context.get("craft_team_ids",{})
	var assets: Variant=context.get("asset_team_ids",{})
	if not _team_map(crafts) or not _team_map(assets): return _reject("invalid_asset_teams")
	var known: Dictionary={}
	var expected_own: Dictionary={}
	var team_known: bool=team in ft.values()
	for unit in dto.units:
		if not unit is Dictionary or not _id(unit.get("unit_id")) or not _canonical(unit.get("team_id")) or known.has(unit.unit_id): return _reject("invalid_unit_identity")
		known[unit.unit_id]=unit.team_id
		if unit.team_id==team: expected_own[unit.unit_id]=true;team_known=true
		var fireteam: Variant=unit.get("fireteam_id","")
		if fireteam!="" and (not _canonical(fireteam) or ft.get(fireteam)!=unit.team_id): return _reject("unit_fireteam_conflict")
	if not team_known: return _reject("unknown_recipient_team")
	var own: Dictionary={}
	var visible: Dictionary={}
	for pair in [[context.own_unit_ids,own],[context.visible_unit_ids,visible]]:
		if typeof(pair[0]) not in [TYPE_ARRAY,TYPE_PACKED_STRING_ARRAY]: return _reject("invalid_visibility_ids")
		for id in pair[0]:
			if not _id(id) or not known.has(id) or pair[1].has(id): return _reject("invalid_visibility_ids")
			pair[1][id]=true
	if own!=expected_own: return _reject("own_unit_context_conflict")
	var allowed: Dictionary=own.duplicate()
	allowed.merge(visible,true)
	for unit in dto.units:
		if not own.has(unit.unit_id) and allowed.has(unit.unit_id) and unit.get("visible",true)!=true: return _reject("visible_unit_context_conflict")
	for key in ["vital_updates","contacts","fire_events","air_asset_status"]+OWN_LISTS:
		if dto.has(key):
			if not dto[key] is Array: return _reject("invalid_snapshot_list")
			for entry in dto[key]:
				if not entry is Dictionary: return _reject("invalid_snapshot_entry")
	for key in ["dropship","objective","mission_result","mission_interactions"]:
		if dto.has(key) and not dto[key] is Dictionary: return _reject("invalid_snapshot_entry")
	if not dto.get("mission_interactions",{}).get("interaction_states",{}) is Dictionary: return _reject("invalid_interaction_states")
	for entry in dto.get("mission_interactions",{}).get("interaction_states",{}).values():
		if not entry is Dictionary: return _reject("invalid_interaction_states")
	if dto.get("mission_result",{}).has("team_states") and not dto.mission_result.team_states is Array: return _reject("invalid_team_states")
	var dropship: Dictionary=dto.get("dropship",{})
	if dropship.has("mission_drop_cards"):
		if not dropship.mission_drop_cards is Array: return _reject("invalid_drop_cards")
		for card in dropship.mission_drop_cards:
			if not card is Dictionary: return _reject("invalid_drop_cards")
	return {"ok":true,"team":team,"own":own,"allowed":allowed,"ft":ft,"crafts":crafts,"assets":assets}

func _filter_vitals(entries: Array, allowed: Dictionary) -> Array:
	var result: Array=[]
	for entry: Dictionary in entries:
		if allowed.has(entry.get("unit_id","")): result.append(_pick(entry,["unit_id","vital_state","health","bleedout_ticks","vital_tick"]))
	return result

func _own_fireteam(id: Variant, checked: Dictionary) -> bool:
	return id is String and not id.is_empty() and checked.ft.get(id)==checked.team

func _own_entry(entry: Dictionary, checked: Dictionary) -> bool:
	var proven := false
	if entry.get("team_id","")!="":
		if entry.team_id!=checked.team: return false
		proven=true
	if entry.get("fireteam_id","")!="":
		if not _own_fireteam(entry.fireteam_id,checked): return false
		proven=true
	if entry.get("unit_id","")!="":
		if not checked.own.has(entry.unit_id): return false
		proven=true
	if not proven and typeof(entry.get("unit_ids")) in [TYPE_ARRAY,TYPE_PACKED_STRING_ARRAY] and not entry.unit_ids.is_empty():
		proven=true
		for id in entry.unit_ids:
			if not checked.own.has(id): return false
	return proven

func _record_team(entry: Dictionary, id_key: String, owners: Dictionary) -> String:
	var explicit: String=String(entry.get("team_id",""))
	var mapped: String=String(owners.get(entry.get(id_key,""),""))
	return "" if not explicit.is_empty() and not mapped.is_empty() and explicit!=mapped else (explicit if not explicit.is_empty() else mapped)

func _dropship(source: Dictionary, checked: Dictionary) -> Dictionary:
	var result: Dictionary=_scrub(source,checked) if _record_team(source,"craft_id",checked.crafts)==checked.team else {}
	result.mission_drop_cards=[]
	for card: Dictionary in source.get("mission_drop_cards",[]):
		var team: String=_record_team(card,"craft_id",checked.crafts)
		if team.is_empty() and not checked.crafts.has(card.get("craft_id","")) and String(card.get("team_id","")).is_empty():
			var crew: Array=Array(card.get("embarked_unit_ids",[]))
			if not String(card.get("pilot_unit_id","")).is_empty(): crew.append(card.pilot_unit_id)
			if not crew.is_empty() and crew.all(func(id):return checked.own.has(id)): team=checked.team
		if team==checked.team: result.mission_drop_cards.append(_scrub(card,checked))
	return result

## Known ID references are sanitized before V1 normalization can discard their
## association with a coordinate. Free own target areas remain independent.
func _scrub(value: Variant, checked: Dictionary) -> Variant:
	if value is Dictionary:
		if value.get("unit_id","")!="" and not checked.allowed.has(value.unit_id): return {}
		var result: Dictionary={}
		var erased: Dictionary={}
		for key: String in value:
			var item: Variant=value[key]
			if key=="member_assignments" and item is Array:
				var members: Array=[]
				for member in item:
					if member is Dictionary and checked.own.has(member.get("unit_id","")): members.append(_scrub(member,checked))
				result[key]=members
			elif key.ends_with("_by_unit_id") and item is Dictionary:
				var mapped: Dictionary={}
				for id in item:
					if checked.own.has(id): mapped[id]=_scrub(item[id],checked)
				result[key]=mapped
			elif key.ends_with("unit_ids") and typeof(item) in [TYPE_ARRAY,TYPE_PACKED_STRING_ARRAY]:
				var ids: Array=[]
				for id in item:
					if (checked.allowed if key=="watched_unit_ids" else checked.own).has(id): ids.append(id)
				result[key]=ids
				if ids.size()!=item.size(): erased[key]=true
			elif key.ends_with("unit_id") and item is String:
				if item.is_empty() or checked.allowed.has(item): result[key]=item
				else: erased[key]=true
			elif key.ends_with("fireteam_ids") and typeof(item) in [TYPE_ARRAY,TYPE_PACKED_STRING_ARRAY]:
				var ids: Array=[]
				for id in item:
					if _own_fireteam(id,checked): ids.append(id)
				result[key]=ids
			elif key.ends_with("fireteam_id") and item is String:
				if item.is_empty() or _own_fireteam(item,checked): result[key]=item
			elif key in ["event_id","bubble_id","last_event_id"] and item is String:
				result[key]="projection:"+item.sha256_text() if not item.is_empty() else ""
			else: result[key]=_scrub(item,checked)
		if erased.has("target_unit_id"):
			for key in ["target_position","target_team_id","target_fireteam_id","combat_outcome","result"]: result.erase(key)
		if erased.has("attacker_unit_id"):
			for key in ["attacker_position","attacker_team_id","attacker_fireteam_id","muzzle_position","muzzle_id","weapon_id","weapon_range_world","weapon_tile_range","source"]: result.erase(key)
		if erased.has("pilot_unit_id"):
			for key in ["pilot_display_name","pilot_text"]: result.erase(key)
		if erased.has("locked_by_unit_id"):
			for key in ["threat_weapon_id","last_reason"]: result.erase(key)
		if erased.has("watched_unit_ids"): result.erase("focus_position")
		return result
	if value is Array:
		var result: Array=[]
		for item in value:
			var safe: Variant=_scrub(item,checked)
			if not (safe is Dictionary and safe.is_empty()): result.append(safe)
		return result
	return value.duplicate() if value is PackedStringArray or value is PackedVector2Array else value

func _pick(entry: Dictionary, keys: Array) -> Dictionary:
	var result: Dictionary={}
	for key in keys:
		if entry.has(key): result[key]=entry[key]
	return result

func _id(value: Variant) -> bool:
	return value is String and not value.is_empty() and value==value.strip_edges() and value.length()<=256

func _canonical(value: Variant) -> bool:
	return _id(value) and value==value.to_lower()

func _team_map(value: Variant, canonical_keys: bool=false) -> bool:
	if not value is Dictionary: return false
	for key in value:
		if not (_canonical(key) if canonical_keys else _id(key)) or not _canonical(value[key]): return false
	return true

func _plain(value: Variant, depth: int=0) -> bool:
	if depth>16: return false
	match typeof(value):
		TYPE_NIL,TYPE_BOOL,TYPE_INT,TYPE_STRING: return true
		TYPE_FLOAT: return is_finite(value)
		TYPE_VECTOR2: return value.is_finite()
		TYPE_VECTOR2I: return true
		TYPE_ARRAY,TYPE_PACKED_STRING_ARRAY,TYPE_PACKED_VECTOR2_ARRAY:
			for item in value:
				if not _plain(item,depth+1): return false
			return true
		TYPE_DICTIONARY:
			for key in value:
				if typeof(key) not in [TYPE_STRING,TYPE_STRING_NAME] or not _plain(value[key],depth+1): return false
			return true
	return false

func _reject(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}
