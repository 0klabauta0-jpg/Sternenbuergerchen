extends RefCounted
## Cached immutable quotes for one campaign market batch. The Supply owner
## records money and accepted identities; callers must revalidate local access.
const GENERATOR = preload("res://scripts/meta/polisa_recruit_offers.gd")
var _batch_id := ""
var _recruiter_id := ""
var _offers: Array = []
var _recruiter: Dictionary = {}
var _occupied: Dictionary = {}

func open(batch_id: String, recruiter: Dictionary, occupied: Dictionary) -> Dictionary:
	var id := String(recruiter.get("unit_id", ""))
	if batch_id.is_empty() or id.is_empty(): return {"ok":false,"reason":"invalid_market_context"}
	if _batch_id != batch_id or _recruiter_id != id:
		var offers: Array = GENERATOR.build_offers(batch_id + ":" + id, recruiter, occupied)
		if offers.size() != 4: return {"ok":false,"reason":"market_unavailable"}
		_batch_id = batch_id
		_recruiter_id = id
		_offers = offers.duplicate(true)
		_recruiter = recruiter.duplicate(true)
		_occupied = occupied.duplicate(true)
	return {"ok":true,"offers":_offers.duplicate(true)}

func snapshot() -> Dictionary:
	return {"batch_id":_batch_id,"recruiter_id":_recruiter_id,"offers":_offers.duplicate(true)}

func export_state() -> Dictionary:
	if _batch_id.is_empty(): return {}
	return {"version":1,"batch_id":_batch_id,"recruiter":_recruiter.duplicate(true),"occupied":_occupied.duplicate(true),"offers":_offers.duplicate(true)}

func restore_state(data: Dictionary) -> Dictionary:
	if data.is_empty():
		_batch_id = ""; _recruiter_id = ""; _offers = []; _recruiter = {}; _occupied = {}
		return {"ok":true}
	if data.get("version") != 1 or typeof(data.get("batch_id")) != TYPE_STRING or String(data.batch_id).is_empty() or String(data.batch_id).length() > 128 or typeof(data.get("recruiter")) != TYPE_DICTIONARY or typeof(data.get("occupied")) != TYPE_DICTIONARY or Dictionary(data.occupied).size() > 128 or typeof(data.get("offers")) != TYPE_ARRAY: return {"ok":false,"reason":"invalid_market"}
	var candidate = get_script().new()
	var opened: Dictionary = candidate.open(String(data.batch_id), data.recruiter, data.occupied)
	var normalized: Variant = JSON.parse_string(JSON.stringify(opened.get("offers", [])))
	var normalized_saved: Variant = JSON.parse_string(JSON.stringify(data.offers))
	if not opened.get("ok", false) or JSON.stringify(normalized, "", true) != JSON.stringify(normalized_saved, "", true): return {"ok":false,"reason":"market_offer_mismatch"}
	_batch_id = candidate._batch_id
	_recruiter_id = candidate._recruiter_id
	_offers = candidate._offers.duplicate(true)
	_recruiter = candidate._recruiter.duplicate(true)
	_occupied = candidate._occupied.duplicate(true)
	return {"ok":true}

func quote(offer_id: String) -> Dictionary:
	for offer: Dictionary in _offers:
		if String(offer.get("id", "")) == offer_id:
			return {"ok":true,"offer_id":offer_id,"unit_id":String(offer.profile.get("unit_id", "")),"price":int(offer.price),"profile":offer.profile.duplicate(true)}
	return {"ok":false,"reason":"stale_offer","message":"Angebot nicht mehr verfügbar"}
