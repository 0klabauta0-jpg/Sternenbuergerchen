"""Read-only source probe for split-normal preservation in consolidated exports."""
import bpy,sys,json
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import verify_ship as qa
HERE=Path(__file__).resolve().parent;BASE=HERE.parent
SRC=BASE/'buccaneer/buccaneer_master.blend';OUT=HERE/'consolidation_probe';OUT.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(SRC));obs=[o for o in bpy.data.collections['LOW'].all_objects if o.type=='MESH']
source=qa.snapshot(obs);dg=bpy.context.evaluated_depsgraph_get()
verts=[];faces=[];norms=[];uvs=[];mi=[];mats=[];smooth=[];sharps=set()
for ob in obs:
    eo=ob.evaluated_get(dg);me=eo.to_mesh(preserve_all_data_layers=True,depsgraph=dg);me.calc_loop_triangles()
    offset=len(verts);verts.extend(tuple(ob.matrix_world@v.co) for v in me.vertices)
    nm=ob.matrix_world.to_3x3().inverted().transposed()
    for edge in me.edges:
        if edge.use_edge_sharp:sharps.add(tuple(sorted(offset+v for v in edge.vertices)))
    for tri in me.loop_triangles:
        faces.append(tuple(offset+v for v in tri.vertices));mat=me.materials[tri.material_index]
        if mat not in mats:mats.append(mat)
        mi.append(mats.index(mat));smooth.append(me.polygons[tri.polygon_index].use_smooth)
        for li in tri.loops:
            norms.append(tuple((nm@me.corner_normals[li].vector).normalized()));uvs.append(tuple(me.uv_layers.active.data[li].uv))
    eo.to_mesh_clear()
expected=dict(source);rot=qa.np.array([[1,0,0],[0,0,1],[0,-1,0]])
expected['points']=source['points']@rot.T;expected['normals']=source['normals']@rot.T
expected['uvs']=source['uvs'].copy();expected['uvs'][:,1]=1-expected['uvs'][:,1]
results={}
for mode in ['preserve_flags','all_sharp','split_vertices']:
    mesh=bpy.data.meshes.new('PROBE_'+mode)
    if mode=='split_vertices':
        new_verts=[];new_faces=[];remap={}
        for k,tri in enumerate(faces):
            tf=[]
            for corner,vi in enumerate(tri):
                li=k*3+corner;key=(vi,tuple(round(v,7) for v in norms[li]),tuple(uvs[li]))
                if key not in remap:remap[key]=len(new_verts);new_verts.append(verts[vi])
                tf.append(remap[key])
            new_faces.append(tf)
        mesh.from_pydata(new_verts,[],new_faces)
    else:mesh.from_pydata(verts,[],faces)
    mesh.update()
    for mat in mats:mesh.materials.append(mat)
    for poly,idx,sm in zip(mesh.polygons,mi,smooth):poly.material_index=idx;poly.use_smooth=sm if mode=='preserve_flags' else True
    for edge in mesh.edges:
        if mode=='all_sharp' or tuple(sorted(edge.vertices)) in sharps:edge.use_edge_sharp=True
    uv=mesh.uv_layers.new(name='UVMap')
    for datum,value in zip(uv.data,uvs):datum.uv=value
    mesh.normals_split_custom_set(norms)
    ob=bpy.data.objects.new('PROBE_'+mode,mesh);bpy.context.scene.collection.objects.link(ob)
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
    target=OUT/(mode+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,export_apply=False,export_yup=True,export_animations=False)
    direct=qa.read_glb(target,OUT/(mode+'_images'))
    results[mode]={'direct':qa.compare_corners(expected,direct,2e-5,2e-4,2e-5),'vertices':len(mesh.vertices)}
    bpy.data.objects.remove(ob,do_unlink=True)
for mode in results:
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(OUT/(mode+'.glb')))
    imported=qa.snapshot([o for o in bpy.context.scene.objects if o.type=='MESH'])
    results[mode]['roundtrip']=qa.compare_corners(source,imported,2e-5,.002,2e-5)
    print('PROBE',mode,json.dumps({k:{field:value for field,value in results[mode][k].items() if field in ['pass','errors','max_normal_vector_error','max_uv_coordinate_error']} for k in ['direct','roundtrip']}))
(OUT/'results.json').write_text(json.dumps(results,indent=2),encoding='utf8')
