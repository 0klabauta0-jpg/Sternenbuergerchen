extends SceneTree
const OUT = "C:/Users/bjoer/.codex/worktrees/grafikreferenzen-20261101/SternenBuergerchen/output/grafik_20261101/model_studies"
const RND = "C:/Users/bjoer/.codex/worktrees/grafikreferenzen-20261101/SternenBuergerchen/docs/reports/assets/grafik-2026-11-01/ship_studies"
func _initialize():
    call_deferred("run")
func meshes_under(n: Node, found: Array):
    if n is MeshInstance3D: found.append(n)
    for child in n.get_children(): meshes_under(child, found)
func run():
    var report = {"engine":Engine.get_version_info(), "isolated_project":true,"production_integration":false,"ships":{}}
    var viewport = SubViewport.new()
    viewport.size=Vector2i(1280,900)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    get_root().add_child(viewport)
    var stage=Node3D.new()
    viewport.add_child(stage)
    var env_node=WorldEnvironment.new()
    var env=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("8db8d0")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("d2dce2")
    env.ambient_light_energy=.65
    env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
    env_node.environment=env
    stage.add_child(env_node)
    var sun=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-42,-28,0)
    sun.light_energy=1.6
    stage.add_child(sun)
    var camera=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    stage.add_child(camera)
    camera.make_current()
    for ship in ["cutlass","buccaneer"]:
        var instance=load("res://"+ship+".glb").instantiate()
        stage.add_child(instance)
        var meshes=[]
        meshes_under(instance,meshes)
        var box=AABB()
        var first=true
        var tris=0
        var surfaces=0
        var mats=[]
        for mi in meshes:
            var aabb=mi.global_transform * mi.get_aabb()
            box=aabb if first else box.merge(aabb)
            first=false
            for surface in range(mi.mesh.get_surface_count()):
                surfaces+=1
                var arr=mi.mesh.surface_get_arrays(surface)
                tris+=arr[Mesh.ARRAY_INDEX].size()/3 if arr[Mesh.ARRAY_INDEX] != null else arr[Mesh.ARRAY_VERTEX].size()/3
                var mat=mi.get_active_material(surface)
                mats.append(mat.resource_name if mat else "MISSING")
        var length=37.5 if ship=="cutlass" else 15.25
        camera.size=length*1.16
        camera.far=length*20
        var captures=[]
        for view in ["front","rear"]:
            var vec=Vector3(1.15,1.15,-1.7) if view=="front" else Vector3(-1.25,1.25,1.7)
            camera.position=vec.normalized()*length*2.2
            camera.look_at(Vector3.ZERO,Vector3.UP)
            for i in range(5): await process_frame
            await RenderingServer.frame_post_draw
            var image=viewport.get_texture().get_image()
            var output=RND+"/"+ship+"_godot_"+view+".png"
            var err=image.save_png(output)
            captures.append({"view":view,"path":output,"error":err,"size":[image.get_width(),image.get_height()]})
        report.ships[ship]={"mesh_instances":meshes.size(),"surfaces":surfaces,"triangles":tris,"materials":mats,"dimensions_m":[box.size.x,box.size.y,box.size.z],"pivot_center":[box.get_center().x,box.get_center().y,box.get_center().z],"front_axis":"negative Z (Blender positive Y)","captures":captures}
        instance.queue_free()
        await process_frame
    FileAccess.open(OUT+"/godot_import_capture.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    print("SHIP_SMOKE_RESULT "+JSON.stringify(report))
    quit(0)
