"""Local-only ship derivatives; run in an isolated Blender --background process.

Adapted from the archived prepare_shuttle.py / prepare_geier.py workflow.
Never connects to the user's Blender session. Originals remain read-only.
"""
import argparse
import hashlib
import json
import math
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[1]
SOURCES = Path('C:/Users/bjoer/3D Objects')
CONFIG = {
    'prospector': ('002/MISC/MISC-PROSPECTOR.obj', 20000, (0.66, .68, .64), (.75, .28, .055)),
    'vulture': ('001/DRAKE/DRAKE-VULTURE.obj', 18000, (.64, .48, .16), (.89, .61, .12)),
    'gladius': ('002/AEGIS/AEGIS-GLADIUS.obj', 14000, (.29, .34, .25), (.57, .62, .49)),
    'hornet': ('001/ANVIL/ANVIL-HORNET.obj', 16000, (.52, .55, .51), (.58, .15, .09)),
}
DEFAULT_VOXEL = dict(prospector=.035, vulture=.025, gladius=.018, hornet=.022)
QA_DIR = Path('C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts')
sys.path.insert(0, str(QA_DIR))
import qa_check
import review_shots
sys.path.insert(0, str(Path(__file__).resolve().parent))
import repair_coplanar


def write(path, value):
    path.write_text(json.dumps(value, indent=2), encoding='utf-8')


def stats(ob):
    bpy.context.view_layer.update()
    ob.data.calc_loop_triangles()
    coords = np.empty(len(ob.data.vertices) * 3, dtype=np.float32)
    ob.data.vertices.foreach_get('co', coords)
    coords = coords.reshape(-1, 3)
    return dict(vertices=len(coords), triangles=len(ob.data.loop_triangles),
                bounds_min=coords.min(axis=0).tolist(), bounds_max=coords.max(axis=0).tolist(),
                dimensions=list(ob.dimensions), materials=len(ob.data.materials))


def select(ob):
    bpy.ops.object.select_all(action='DESELECT')
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob


def clean(ob):
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=.0001)
    bmesh.ops.dissolve_degenerate(bm, edges=list(bm.edges), dist=.00001)
    loose = [v for v in bm.verts if not v.link_faces]
    if loose:
        bmesh.ops.delete(bm, geom=loose, context='VERTS')
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(ob.data)
    bm.free()
    ob.data.validate(clean_customdata=True)
    ob.data.update()


def render_comparison(ob, out, bounds):
    """Identical orthographic cameras for source and candidate, no auto refitting."""
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_WORKBENCH'
    scene.render.resolution_x = scene.render.resolution_y = 560
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.display.shading.light = 'STUDIO'
    scene.display.shading.color_type = 'SINGLE'
    scene.display.shading.single_color = (.62, .66, .69)
    scene.display.shading.show_shadows = True
    scene.display.shading.show_cavity = True
    scene.display.shading.cavity_type = 'BOTH'
    scene.display.shading.background_type = 'WORLD'
    scene.world.color = (.035, .045, .055)
    lo, hi = Vector(bounds['bounds_min']), Vector(bounds['bounds_max'])
    center = (lo + hi) / 2
    radius = (hi-lo).length / 2
    cam_data = bpy.data.cameras.new('ReviewCamera')
    cam = bpy.data.objects.new('ReviewCamera', cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = radius * 2.12
    cam_data.clip_end = 200
    images = []
    for name, direction in [('front',(0,-1,.12)),('side',(1,0,.12)),('top',(0,-.001,1)),('three_quarter',(1,-1,.65))]:
        cam.location = center + Vector(direction).normalized() * radius * 3
        cam.rotation_euler = (center-cam.location).to_track_quat('-Z','Y').to_euler()
        path = out.parent / (out.stem + '_' + name + '.png')
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        im = bpy.data.images.load(str(path), check_existing=False)
        pixels = np.empty(560 * 560 * 4, dtype=np.float32)
        im.pixels.foreach_get(pixels)
        images.append(pixels.reshape(560,560,4))
        bpy.data.images.remove(im)
    sheet = np.ones((1120,1120,4), dtype=np.float32)
    for i, pixels in enumerate(images):
        row, col = 1-i//2, i%2
        sheet[row*560:(row+1)*560,col*560:(col+1)*560]=pixels
    im = bpy.data.images.new('ComparisonSheet',1120,1120,alpha=True)
    im.pixels.foreach_set(sheet.ravel())
    im.filepath_raw = str(out)
    im.file_format='PNG'
    im.save()
    bpy.data.images.remove(im)
    scene.camera=None
    bpy.data.objects.remove(cam,do_unlink=True)
    bpy.data.cameras.remove(cam_data)


def material(name, rgb, metallic=.15):
    mat=bpy.data.materials.new(name)
    mat.diffuse_color=(*rgb,1)
    mat.use_nodes=True
    bsdf=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    bsdf.inputs['Base Color'].default_value=(*rgb,1)
    bsdf.inputs['Roughness'].default_value=.68
    bsdf.inputs['Metallic'].default_value=metallic
    return mat


def build(key, stage, voxel):
    source_suffix, budget, hull, accent = CONFIG[key]
    source = SOURCES / ('drive-download-20250521T120706Z-1-' + source_suffix)
    out = ROOT / key
    out.mkdir(parents=True,exist_ok=True)
    (out/'qa').mkdir(exist_ok=True)
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    bpy.ops.wm.obj_import(filepath=str(source))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    assert len(meshes)==1, 'Unexpected source structure; inspect before merging'
    ob=meshes[0]
    ob.name=key.title()
    select(ob)
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    raw=stats(ob)
    sha=hashlib.sha256(source.read_bytes()).hexdigest()
    lo,hi=Vector(raw['bounds_min']),Vector(raw['bounds_max'])
    center=(lo+hi)/2
    scale=8/(hi.y-lo.y)
    transform=Matrix.Rotation(math.pi,4,'Z') @ Matrix.Scale(scale,4) @ Matrix.Translation(-Vector((center.x,center.y,lo.z)))
    ob.data.transform(transform)
    ob.data.update()
    normalized=stats(ob)
    manifest=dict(ship=key, source=str(source), source_sha256=sha, raw=raw,
                  normalized_source=normalized, source_scale_factor=scale,
                  authoring_length_m=8, forward_blender='-Y', forward_gltf='+Z',
                  material_note='Source contains no materials; authored four-color preview palette, not original textures.',
                  provenance='User-supplied RSI model conversion; local derivative, redistribution license not established.',
                  blender=bpy.app.version_string)
    write(out/'source_manifest.json',manifest)
    if stage=='inspect':
        render_comparison(ob,out/'qa/source.png',normalized)
        print('INSPECTED',key,json.dumps(raw),flush=True)
        return
    clean(ob)
    if voxel:
        ob.data.remesh_voxel_size=voxel
        bpy.ops.object.voxel_remesh()
        smooth=ob.modifiers.new('Remove subpixel source greebles','SMOOTH')
        smooth.factor=.65
        smooth.iterations=3
        bpy.ops.object.modifier_apply(modifier=smooth.name)
    # Planar dissolve creates folded n-gons on dense remeshed ship shells.
    # Collapse directly preserves the manifold voxel surface.
    if not voxel:
        planar=ob.modifiers.new('Coplanar simplification','DECIMATE')
        planar.decimate_type='DISSOLVE'
        planar.angle_limit=math.radians(5)
        bpy.ops.object.modifier_apply(modifier=planar.name)
    before_collapse=stats(ob)['triangles']
    dec=ob.modifiers.new('Measured triangle budget','DECIMATE')
    dec.ratio=min(1,budget/before_collapse)
    dec.use_collapse_triangulate=True
    dec.use_symmetry=False
    bpy.ops.object.modifier_apply(modifier=dec.name)
    # Triangulate explicitly so QA and glTF evaluate identical topology.
    tri=ob.modifiers.new('Export triangulation','TRIANGULATE')
    bpy.ops.object.modifier_apply(modifier=tri.name)
    # Do not weld/dissolve again: this opens otherwise valid thin triangles.
    # Fresh datablock drops stale imported split normals/corner attributes.
    old=ob.data
    vertices=[tuple(v.co) for v in old.vertices]
    faces=[]
    seen=set()
    for face in old.polygons:
        ids=tuple(face.vertices)
        token=tuple(sorted(ids))
        if face.area>1e-10 and len(set(ids))>=3 and token not in seen:
            seen.add(token)
            faces.append(ids)
    fresh=bpy.data.meshes.new(key.title()+'_Reduced')
    fresh.from_pydata(vertices,[],faces)
    fresh.update()
    ob.data=fresh
    bpy.data.meshes.remove(old)
    bm=bmesh.new()
    bm.from_mesh(fresh)
    unseen=set(bm.verts)
    removed_dust=0
    while unseen:
        first=unseen.pop()
        component={first}
        stack=[first]
        while stack:
            v=stack.pop()
            for edge in v.link_edges:
                other=edge.other_vert(v)
                if other in unseen:
                    unseen.remove(other)
                    component.add(other)
                    stack.append(other)
        cfaces={f for v in component for f in v.link_faces}
        extent=max(max(v.co[k] for v in component)-min(v.co[k] for v in component) for k in range(3))
        if not cfaces or len(component)<12 or (len(cfaces)<24 and extent<.18):
            removed_dust+=len(cfaces)
            bmesh.ops.delete(bm,geom=list(component),context='VERTS')
        else:
            bmesh.ops.recalc_face_normals(bm,faces=list(cfaces))
            closed=all(len(e.link_faces)==2 for v in component for e in v.link_edges)
            volume=sum(f.verts[0].co.dot(f.verts[1].co.cross(f.verts[2].co))/6 for f in cfaces)
            if closed and volume<0:
                bmesh.ops.reverse_faces(bm,faces=list(cfaces))
    bm.to_mesh(fresh)
    bm.free()
    fresh.update()
    print('DUST_REMOVED',key,removed_dust,flush=True)
    coplanar_repair=repair_coplanar.fix(ob) if key=='vulture' else None
    if coplanar_repair:
        write(out/'qa/coplanar_repair.json',coplanar_repair)
    bottom=min(v.co.z for v in ob.data.vertices)
    for v in ob.data.vertices:
        v.co.z-=bottom
    ob.data.materials.clear()
    for name,rgb in [('Hull',hull),('Structure',(.075,.095,.11)),('Accent',accent),('Glass',(.028,.085,.11))]:
        ob.data.materials.append(material(key+'_'+name,rgb))
    dims=stats(ob)['dimensions']
    for face in ob.data.polygons:
        x,y,z=face.center
        slot=0
        if z<dims[2]*.23 or (y>2.5 and abs(x)>dims[0]*.18): slot=1
        if abs(x)>dims[0]*.32 and -.7<y<.1 and z>dims[2]*.4: slot=2
        # Deliberately sparse color blocking; no claim to reproduce source paint.
        if key=='gladius' and -2.7<y<-.6 and abs(x)<dims[0]*.085 and z>dims[2]*.66: slot=3
        face.material_index=slot
        face.use_smooth=False
    # Source UVs are not useful after remeshing. Simple smart UVs keep this editable.
    select(ob)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.015)
    bpy.ops.object.mode_set(mode='OBJECT')
    ob['source_sha256']=sha
    ob['source_file']=source.name
    ob['forward_gltf']='+Z'
    ob['authoring_length_m']=8.0
    final=stats(ob)
    write(out/'metrics.json',dict(source=raw,processed=final,voxel_size=voxel,before_collapse=before_collapse))
    qa=qa_check.run(objects=[ob.name],profile='game',eps=.00005,tol=.015)
    write(out/'qa/geometry.json',qa)
    print('QA',key,'errors',qa['errors'],'warnings',qa['warnings'][:8],flush=True)
    assert qa['pass'], 'Asset geometry QA must pass before delivery export'
    bpy.ops.wm.save_as_mainfile(filepath=str(out/(key+'.blend')))
    select(ob)
    bpy.ops.export_scene.gltf(filepath=str(out/(key+'.glb')),export_format='GLB',use_selection=True,
                              export_apply=True,export_extras=True,export_yup=True)
    render_comparison(ob,out/'qa/candidate.png',normalized)
    review_shots.run(objects=[ob.name],out=str(out/'qa/material.png'),mode='material',res=560)
    review_shots.run(objects=[ob.name],out=str(out/'qa/wire.png'),mode='wire',res=400)
    review_shots.run(objects=[ob.name],out=str(out/'qa/parts.png'),mode='random',res=400)
    # Roundtrip the actual file, then reopen the editable deliverable.
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(out/(key+'.glb')))
    imported=[o for o in bpy.context.scene.objects if o.type=='MESH']
    assert len(imported)==1
    select(imported[0])
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    roundtrip=stats(imported[0])
    assert roundtrip['triangles']==final['triangles']
    assert max(abs(a-b) for a,b in zip(roundtrip['dimensions'],final['dimensions']))<.001
    bpy.ops.wm.open_mainfile(filepath=str(out/(key+'.blend')))
    assert stats(bpy.data.objects[key.title()])['triangles']==final['triangles']
    assert hashlib.sha256(source.read_bytes()).hexdigest()==sha
    write(out/'metrics.json',dict(source=raw,processed=final,voxel_size=voxel,before_collapse=before_collapse,
                                  roundtrip=roundtrip,blend_reopened=True,source_unchanged=True,
                                  removed_dust_faces=removed_dust,coplanar_repair=coplanar_repair,
                                  reduction_percent=100*(1-final['triangles']/raw['triangles'])))
    print('COMPLETE',key,final['triangles'],flush=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('ship',choices=CONFIG)
    parser.add_argument('--stage',choices=['inspect','build'],default='build')
    parser.add_argument('--voxel',type=float,default=None)
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
    build(args.ship,args.stage,DEFAULT_VOXEL[args.ship] if args.voxel is None else args.voxel)
