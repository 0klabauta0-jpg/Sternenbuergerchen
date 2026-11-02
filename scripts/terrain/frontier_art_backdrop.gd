extends Node3D
## Deterministic geological masses outside the playable base; visual only.

func build(profile, center: Vector2) -> void:
	var groups := [
		[Vector2(-8.0,-9.0),Vector3(6.2,3.5,4.4)],
		[Vector2(-1.0,-12.0),Vector3(6.7,4.7,4.0)],
		[Vector2(7.0,-10.0),Vector3(5.7,3.8,4.6)],
		[Vector2(14.0,-9.0),Vector3(5.0,3.1,5.3)],
		[Vector2(19.0,-3.0),Vector3(4.0,2.2,4.3)],
	]
	var levels := [0.0,0.16,0.34,0.48,0.72,1.0]
	var radii := [1.0,1.04,0.91,0.96,0.73,0.68]
	for index in range(groups.size()):
		var offset: Vector2 = groups[index][0]
		var dimensions: Vector3 = groups[index][1]
		var rock := Node3D.new()
		rock.name = "MesaCluster_%d" % index
		rock.position = Vector3(center.x+offset.x,-0.11,center.y+offset.y-3.0)
		rock.rotation.y = float(index)*0.37
		add_child(rock)
		for layer in range(levels.size()-1):
			var mesh := CylinderMesh.new()
			mesh.radial_segments = 9
			mesh.rings = 1
			mesh.bottom_radius = radii[layer]
			mesh.top_radius = radii[layer+1]
			mesh.height = (levels[layer+1]-levels[layer])*dimensions.y
			var part := MeshInstance3D.new()
			part.name = "Stratum_%d" % layer
			part.mesh = mesh
			part.scale = Vector3(dimensions.x,1.0,dimensions.z)
			part.position.y = (levels[layer]+levels[layer+1])*0.5*dimensions.y
			part.material_override = profile.material_for(Color("b67853").lightened(0.035*float(layer)),true)
			rock.add_child(part)
