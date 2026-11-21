"""Run only in a separate background Blender, never in the user's live scene."""
import argparse, collections, hashlib, itertools, json, math, sys
from pathlib import Path
import bpy
import numpy as np
from mathutils import Matrix, Vector
from mathutils.kdtree import KDTree

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'source/tanker_tripo_original.blend'
QA=ROOT/'qa'
EDIT=ROOT/'editable'
EXPORT=ROOT/'exports'
for directory in (QA,EDIT,EXPORT): directory.mkdir(parents=True,exist_ok=True)
sys.path.insert(0,str(Path(__file__).parent))
sys.path.insert(0,r'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts')
import qa_check

def write(path,data): Path(path).write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
def sha(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def meshes(): return [o for o in bpy.context.scene.objects if o.type=='MESH']
def stats(obs):
    pts=[o.matrix_world@v.co for o in obs for v in o.data.vertices]
    lo=[min(p[i] for p in pts) for i in range(3)]; hi=[max(p[i] for p in pts) for i in range(3)]
    for o in obs:o.data.calc_loop_triangles()
    return {'meshes':len(obs),'triangles':sum(len(o.data.loop_triangles) for o in obs),
      'vertices':sum(len(o.data.vertices) for o in obs),'materials':len({m for o in obs for m in o.data.materials if m}),
      'bounds_min':lo,'bounds_max':hi,'dimensions_xyz':[hi[i]-lo[i] for i in range(3)]}
def select(obs):
    for o in bpy.context.scene.objects:o.select_set(False)
    for o in obs:o.select_set(True)
    bpy.context.view_layer.objects.active=obs[0]
def export(path,obs):
    select(obs)
    result=bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
      export_extras=True,export_animations=False,export_cameras=False,export_lights=False,
      export_materials='EXPORT',export_image_format='AUTO',export_yup=True)
    assert result=={'FINISHED'} and path.is_file() and path.stat().st_size>0
def inventory(obs):
    mats=sorted({m for o in obs for m in o.data.materials if m},key=lambda m:m.name)
    images=sorted({n.image for m in mats for n in m.node_tree.nodes if n.type=='TEX_IMAGE' and n.image},key=lambda i:i.name)
    return {'stats':stats(obs),'images':[{'name':im.name,'size':list(im.size),'packed':bool(im.packed_file),
      'has_data':im.has_data,'source_path':im.filepath,'colorspace':im.colorspace_settings.name} for im in images],
      'parts':[{'name':o.name,'triangles':len(o.data.loop_triangles),'uv_layers':[u.name for u in o.data.uv_layers],
      'materials':[m.name if m else None for m in o.data.materials]} for o in obs]}
def geometry_signature(obs):
    # Triangle positions are independent of vertex order, mesh joins, UV seams, and normals.
    triangles=[]
    for o in obs:
        o.data.calc_loop_triangles()
        for t in o.data.loop_triangles:
            verts=[tuple(round(float(v),4) for v in (o.matrix_world@o.data.vertices[i].co)) for i in t.vertices]
            triangles.append(tuple(sorted(verts)))
    return hashlib.sha256(repr(sorted(triangles)).encode()).hexdigest()

def world_triangles(obs):
    result=[]
    for o in obs:
        o.data.calc_loop_triangles()
        result.extend([tuple(o.matrix_world@o.data.vertices[i].co for i in t.vertices)
                       for t in o.data.loop_triangles])
    return result

def compare_geometry(before, after, tolerance=0.00002):
    # Joining changes the local origin and introduces float32 rounding. Match each
    # complete triangle uniquely and measure the actual maximum error in metres.
    assert len(before)==len(after)
    tree=KDTree(len(after))
    for index,tri in enumerate(after):tree.insert(sum(tri,Vector())/3,index)
    tree.balance();used=set();worst=0.0
    for tri in before:
        center=sum(tri,Vector())/3
        candidates=[]
        for _,index,_ in tree.find_range(center,tolerance):
            if index in used:continue
            error=min(max((a-b).length for a,b in zip(tri,order))
                      for order in itertools.permutations(after[index]))
            if error<=tolerance:candidates.append((error,index))
        assert candidates,'A triangle changed beyond the 0.02 mm float tolerance'
        error,index=min(candidates);used.add(index);worst=max(worst,error)
    return {'triangles_matched':len(used),'max_corner_error_m':worst,
            'tolerance_m':tolerance,'all_triangles_matched':len(used)==len(before)}
def prepare():
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE),load_ui=False,use_scripts=False)
    bpy.context.preferences.filepaths.save_version=0
    original=inventory(meshes()); write(QA/'source_inventory.json',original)
    assert all(i['packed'] and i['has_data'] and min(i['size'])>0 for i in original['images'])
    obs=meshes(); before=stats(obs)
    scale=102.0/before['dimensions_xyz'][0]
    center=Vector(((before['bounds_min'][0]+before['bounds_max'][0])/2,
      (before['bounds_min'][1]+before['bounds_max'][1])/2,before['bounds_min'][2]))
    transform=Matrix.Rotation(math.pi/2,4,'Z')@Matrix.Scale(scale,4)@Matrix.Translation(-center)
    # Positive rotation: original nose -X -> Blender -Y -> glTF/Godot +Z.
    for o in obs:
        world=o.matrix_world.copy(); o.parent=None; o.matrix_world=transform@world
    select(obs)
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    for o in list(bpy.context.scene.objects):
        if o.type!='MESH':bpy.data.objects.remove(o,do_unlink=True)
    root=bpy.data.objects.new('Tanker_Rescue',None); bpy.context.scene.collection.objects.link(root)
    root['reference_length_m']=102.0; root['forward_axis_blender']='-Y'; root['forward_axis_godot']='+Z'
    root['source_sha256']=sha(SOURCE); root['asset_status']='separate_model_candidate'
    for o in obs:
        world=o.matrix_world.copy(); o.parent=root; o.matrix_world=world
        o['source_part']=o.name
    scene=bpy.context.scene
    scene.unit_settings.system='METRIC'; scene.unit_settings.scale_length=1.0; scene.unit_settings.length_unit='METERS'
    scene['reference_length_m']=102.0; scene['game_units_per_metre']=3.52/37.5
    bpy.context.view_layer.update()
    after=stats(obs); assert abs(after['dimensions_xyz'][1]-102)<1e-4
    assert after['triangles']==before['triangles'] and after['meshes']==82
    # Packed images are authoritative; discard stale temporary-file paths in the candidate only.
    for image in bpy.data.images:
        if image.packed_file:image.filepath='//textures/'+image.name+'.jpg'
    report=qa_check.run(objects=[o.name for o in obs],profile='game')
    write(QA/'geometry_segmented.json',report)
    select(obs)
    bpy.ops.wm.save_as_mainfile(filepath=str(EDIT/'tanker_102m_segmented.blend'),compress=True)
    export(EXPORT/'tanker_102m_segmented.glb',obs+[root])
    write(ROOT/'metrics.json',{'source_sha256':sha(SOURCE),'source':before,'metres':after,
      'uniform_scale_from_source':scale,'reference_length_m':102.0,'game_units_per_metre':3.52/37.5,
      'game_dimensions_xyz':[v*(3.52/37.5) for v in after['dimensions_xyz']],
      'geometry_signature':geometry_signature(obs),'qa_errors':report['errors'],'qa_warnings':report['warnings']})
    print('TANKER_PREPARED '+json.dumps({'metres':after,'errors':report['errors'],'warnings':report['warnings']}))
def finish():
    bpy.ops.wm.open_mainfile(filepath=str(EDIT/'tanker_102m_clean_segmented.blend'),load_ui=False,use_scripts=False)
    bpy.context.preferences.filepaths.save_version=0
    obs=meshes(); expected=geometry_signature(obs)
    clean_stats=stats(obs)
    root=obs[0].parent
    export(EXPORT/'tanker_102m_clean_segmented.glb',obs+[root])
    from atlas_materials import atlas_materials
    atlas=atlas_materials(obs,EXPORT/'tanker_basecolor_atlas.png')
    write(QA/'atlas.json',atlas)
    assert geometry_signature(obs)==expected
    report=qa_check.run(objects=[o.name for o in obs],profile='game')
    write(QA/'geometry_atlas_segmented.json',report)
    assert report['pass'],report['errors']
    bpy.ops.wm.save_as_mainfile(filepath=str(EDIT/'tanker_102m_atlas_segmented.blend'),compress=True)
    # Static runtime mesh: merge draw calls, but preserve separate parts in both editable files.
    before_join=world_triangles(obs)
    select(obs); bpy.ops.object.join(); joined=bpy.context.object; joined.name='Tanker_Rescue_Static'
    join_comparison=compare_geometry(before_join,world_triangles([joined]))
    write(QA/'join_geometry.json',join_comparison)
    materials=[m for m in joined.data.materials if m]
    assert len(set(materials))==1
    material=materials[0]; joined.data.materials.clear(); joined.data.materials.append(material)
    for p in joined.data.polygons:p.material_index=0
    root=joined.parent
    export(EXPORT/'tanker_102m.glb',[joined,root])
    metre_stats=stats([joined])
    # A second explicit game-scale export avoids accidental 102-unit monsters in the current renderer.
    joined.data.transform(Matrix.Scale(3.52/37.5,4)); joined.location*=3.52/37.5
    root['asset_unit']='prepared_game_world'; root['reference_length_m']=102.0
    bpy.context.view_layer.update()
    export(EXPORT/'tanker_game.glb',[joined,root])
    game_stats=stats([joined])
    write(QA/'runtime_stats.json',{'metres':metre_stats,'game':game_stats,'atlas':atlas,
      'clean_segmented':clean_stats,'geometry_matches_segmented_with_float_tolerance':True,
      'join_geometry_comparison':join_comparison,
      'qa_errors':report['errors'],'qa_warnings':report['warnings']})
    print('TANKER_FINISHED '+json.dumps({'metres':metre_stats,'game':game_stats,'atlas_size':atlas.get('atlas_size')}))

args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
parser=argparse.ArgumentParser();parser.add_argument('--stage',choices=['prepare','finish'],required=True)
options=parser.parse_args(args)
prepare() if options.stage=='prepare' else finish()
