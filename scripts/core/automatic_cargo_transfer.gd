extends RefCounted
## Authoritative finite transfer job. Inventory remains with the supply owner;
## every item is committed through its ordinary atomic transfer command.
const SECONDS_PER_ITEM:=0.75
const MAX_STEPS_PER_TICK:=8
var _validate:Callable
var _inventory:Callable
var _transfer:Callable
var _job:Dictionary={}
var _receipts:Dictionary={}
var _elapsed:=0.0

func configure(validate:Callable,inventory:Callable,transfer:Callable)->void:
	_validate=validate;_inventory=inventory;_transfer=transfer

func start(request_id:String,source:String,target:String)->Dictionary:
	if request_id.strip_edges().is_empty() or source.is_empty() or target.is_empty() or source==target:return {"ok":false,"reason":"invalid_cargo_transfer"}
	var signature:=JSON.stringify([source,target])
	if _receipts.has(request_id):
		if _receipts[request_id].signature!=signature:return {"ok":false,"reason":"request_id_conflict"}
		return {"ok":true,"replayed":true,"job":get_snapshot()}
	if not _job.is_empty() and _job.phase in ["active","blocked"]:return {"ok":false,"reason":"cargo_transfer_busy"}
	if not _validate.is_valid() or not _inventory.is_valid() or not _transfer.is_valid():return {"ok":false,"reason":"cargo_owner_unavailable"}
	var valid:Variant=_validate.call(source,target)
	if not valid is Dictionary or not valid.get("ok",false):return valid if valid is Dictionary else {"ok":false,"reason":"cargo_context_unavailable"}
	var inventory:Variant=_inventory.call()
	if not inventory is Dictionary or not inventory.has(source) or not inventory.has(target):return {"ok":false,"reason":"cargo_container_unavailable"}
	var items:Dictionary=Dictionary(inventory[source]).get("items",{})
	var keys:Array=items.keys();keys.sort()
	var queue:Array=[];var total:=0
	for item in keys:
		var count:=int(items[item])
		if count>0:queue.append({"item":String(item),"remaining":count});total+=count
	if total==0:return {"ok":false,"reason":"cargo_source_empty"}
	_job={"request_id":request_id,"source":source,"target":target,"phase":"active","reason":"","queue":queue,"total":total,"completed":0}
	_receipts[request_id]={"signature":signature}
	_elapsed=0.0
	return {"ok":true,"message":"Frachtauftrag gestartet","job":get_snapshot()}

func advance(delta:float)->void:
	if _job.is_empty() or _job.phase!="active" or not is_finite(delta) or delta<=0.0:return
	_elapsed=minf(_elapsed+delta,SECONDS_PER_ITEM*MAX_STEPS_PER_TICK)
	var count:=0
	while _elapsed>=SECONDS_PER_ITEM and count<MAX_STEPS_PER_TICK and _job.phase=="active":
		var valid:Variant=_validate.call(_job.source,_job.target)
		if not valid is Dictionary or not valid.get("ok",false):
			_job.phase="blocked";_job.reason=String(valid.get("reason","cargo_context_unavailable")) if valid is Dictionary else "cargo_context_unavailable";break
		var entry:Dictionary=_job.queue[0]
		var result:Variant=_transfer.call(_job.source,_job.target,entry.item,1,String(_job.request_id)+":"+str(_job.completed))
		if not result is Dictionary or not result.get("ok",false):
			_job.phase="blocked";_job.reason=String(result.get("reason","cargo_transfer_failed")) if result is Dictionary else "cargo_transfer_failed";break
		entry.remaining=int(entry.remaining)-1
		_job.completed=int(_job.completed)+1
		if entry.remaining<=0:_job.queue.pop_front()
		_elapsed-=SECONDS_PER_ITEM;count+=1
		if _job.queue.is_empty():_job.phase="complete"

func cancel()->Dictionary:
	if _job.is_empty() or _job.phase not in ["active","blocked"]:return {"ok":false,"reason":"cargo_transfer_unavailable"}
	_job.phase="cancelled";_job.reason="cancelled";return {"ok":true,"message":"Frachtauftrag abgebrochen; bereits verlagerte Ware bleibt am Ziel","job":get_snapshot()}

func get_snapshot()->Dictionary:
	if _job.is_empty():return {"phase":"idle","checkpoint_safe":true}
	return {"phase":_job.phase,"source":_job.source,"target":_job.target,"reason":_job.reason,"completed":_job.completed,"total":_job.total,"request_id":_job.request_id,"checkpoint_safe":_job.phase not in ["active","blocked"]}

func blocks_craft(craft_id:String)->bool:
	return not craft_id.is_empty() and not _job.is_empty() and _job.phase in ["active","blocked"] and ("craft:"+craft_id in [_job.source,_job.target])
