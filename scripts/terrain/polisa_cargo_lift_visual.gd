extends Node3D
## Temporary 3D presentation of an already committed cargo delivery.
## No collision, inventory, transport or scheduling authority lives here.
var _carrier: Node3D
var _tween: Tween

func _ready() -> void:
	var frame := _material(Color("354951"))
	var deck := _material(Color("a4b2ad"))
	var cargo := _material(Color("d4ac4f"))
	var light := _material(Color("70c7c5"))
	_box(self, Vector3(1.8, 0.10, 1.45), Vector3(1.15, 0.04, 0.0), frame)
	for z in [-0.62, 0.62]:
		_box(self, Vector3(1.6, 0.05, 0.06), Vector3(1.15, 0.11, z), light)
	_carrier = Node3D.new()
	_carrier.position = Vector3(1.15, -0.75, 0.0)
	add_child(_carrier)
	_box(_carrier, Vector3(1.28, 0.12, 1.08), Vector3.ZERO, deck)
	_box(_carrier, Vector3(0.82, 0.62, 0.70), Vector3(0.0, 0.37, 0.0), cargo)
	_box(_carrier, Vector3(0.86, 0.08, 0.74), Vector3(0.0, 0.69, 0.0), frame)

func play_delivery() -> void:
	if _tween != null and _tween.is_valid(): _tween.kill()
	_carrier.position = Vector3(1.15, -0.75, 0.0)
	_carrier.visible = true
	_tween = create_tween()
	_tween.tween_property(_carrier, "position:y", 1.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_interval(0.25)
	_tween.tween_property(_carrier, "position:x", 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(func(): _carrier.visible = false)
	_tween.tween_interval(0.4)
	_tween.tween_callback(queue_free)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.75
	return material

func _box(parent: Node3D, dimensions: Vector3, at: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.position = at
	parent.add_child(part)
