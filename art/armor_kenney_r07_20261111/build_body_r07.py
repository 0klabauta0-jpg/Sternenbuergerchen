"""Own Kenney body derivative, authorized R07 scope change. Original untouched."""
import bpy,bmesh,json,sys,hashlib,math
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[2];ART=Path(__file__).resolve().parent;OUT=ROOT/'output/native_glut_maps/armor_r07_parts'
OUT.mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
source=ROOT/'Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb'
bpy.ops.import_scene.gltf(filepath=str(source))
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
body=next(o for o in bpy.data.objects if o.type=='MESH' and o.name.startswith('character'))
hips=rig.matrix_world@rig.data.bones['Hips'].head_local
head=rig.matrix_world@rig.data.bones['Head'].head_local
left=rig.matrix_world@rig.data.bones['LeftArm'].head_local;right=rig.matrix_world@rig.data.bones['RightArm'].head_local
up=(head-hips).normalized();axis=(left-right).normalized();axis=(axis-up*axis.dot(up)).normalized();front=axis.cross(up).normalized()
basis=Matrix((axis,up,front)).transposed();height=(left-hips).dot(up);width=(left-right).length
profile={'revision':'kenney_body_r07','source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
 'rows':[[-.45,1.,1.],[-.10,.98,.97],[.12,.94,.94],[.32,.82,.87],[.48,.87,.90],[.66,1.19,.98],[.85,1.42,1.04],[1.00,1.42,1.02],[1.12,1.18,1.00],[1.28,1.,1.]],
 'lateral_full':.47,'lateral_end':.97,'depth_center_width':.10,
 'head_scale':[.95,.92,.95],'head_pivot_height':(head-hips).dot(up)/height,'head_blend':[1.178,1.2215],
 'deltoid_scale':[1.20,1.10],'deltoid_lateral':[.40,.64,1.05,1.28],
 'description':'R07 broader real clavicle/deltoid contour and modest head reduction; hands/feet/rest skeleton unchanged.'}
def smooth(a,b,value):
 t=max(0.,min(1.,(value-a)/(b-a)));return t*t*(3-2*t)
def deform(p):
 h=p.y/height;rows=profile['rows'];sx=sd=1.
 for a,b in zip(rows,rows[1:]):
  if a[0]<=h<=b[0]:
   t=(h-a[0])/(b[0]-a[0]);sx=a[1]+(b[1]-a[1])*t;sd=a[2]+(b[2]-a[2])*t;break
 edge=abs(p.x)/width;t=max(0.,min(1.,(edge-profile['lateral_full'])/(profile['lateral_end']-profile['lateral_full'])))
 mask=1-t*t*(3-2*t);sx=1+(sx-1)*mask;sd=1+(sd-1)*mask
 center=width*profile['depth_center_width']
 q=Vector((p.x*sx,p.y,center+(p.z-center)*sd))
 a,b,c,d=profile['deltoid_lateral'];mask=smooth(a,b,edge)*(1-smooth(c,d,edge))*(1-smooth(1.20,1.28,h))*smooth(.70,.82,h)
 q.y=height+(q.y-height)*(1+(profile['deltoid_scale'][0]-1)*mask)
 q.z*=1+(profile['deltoid_scale'][1]-1)*mask
 hm=smooth(*profile['head_blend'],h);pivot=Vector((0,height*profile['head_pivot_height'],0))
 for i,scale in enumerate(profile['head_scale']):q[i]=pivot[i]+(q[i]-pivot[i])*(1+(scale-1)*hm)
 return q
before=[];after=[];changed=0;mx=0
source_corner_normals=[n.vector.copy() for n in body.data.corner_normals]
local_to_canonical=basis.transposed()@body.matrix_world.to_3x3()
normal_to_canonical=local_to_canonical.inverted().transposed()
normal_transforms=[]
for v in body.data.vertices:
 p=basis.transposed()@(body.matrix_world@v.co-hips);q=deform(p)
 before.append(tuple(p));after.append(tuple(q));delta=(q-p).length
 if delta>1e-7:changed+=1;mx=max(mx,delta)
 v.co=body.matrix_world.inverted()@(hips+basis@q)
 epsilon=width*.0001
 columns=[]
 for axis_index in range(3):
  offset=Vector((0,0,0));offset[axis_index]=epsilon
  columns.append((deform(p+offset)-deform(p-offset))/(2*epsilon))
 jacobian=Matrix(columns).transposed()
 normal_transforms.append(local_to_canonical.transposed()@jacobian.inverted().transposed()@normal_to_canonical)
body.data.update()
lo=Vector(tuple(min(p[i] for p in before) for i in range(3)));hi=Vector(tuple(max(p[i] for p in before) for i in range(3)))
profile['canonical_bounds_center']=[v/width for v in (lo+hi)*.5]
profile['canonical_bounds_size']=[v/width for v in hi-lo]
# Preserve original open-island winding and all UV loops. Recalculating the
# orientation of open components with bmesh can flip valid source faces.
body.data.normals_split_custom_set([(normal_transforms[loop.vertex_index]@source_corner_normals[loop.index]).normalized() for loop in body.data.loops])
body['source_role']='R07 derived real body: chest/shoulder/waist silhouette'
body['source_sha256']=profile['source_sha256'];body['unchanged_rig']=True
sys.path.insert(0,str(Path.home()/'.codex/skills/blender-asset-qa/scripts'));import qa_check
qa=qa_check.run(objects=[body.name],profile='game')
(ART/'body_qa.json').write_text(json.dumps(qa,indent=2),encoding='utf8')
for path in [ART/'body_shape_profile.json',OUT/'body_shape_profile.json']:path.write_text(json.dumps(profile,indent=2),encoding='utf8')
# Canonical positions support exact runtime-to-Blender correspondence checks.
(ART/'body_vertices.json').write_text(json.dumps({'width':width,'height':height,'before':before,'after':after}),encoding='utf8')
bpy.ops.wm.save_as_mainfile(filepath=str(ART/'body_r07_editable.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'body_r07_derived.glb'),export_format='GLB',export_animations=True,export_extras=True)
summary={'blender':bpy.app.version_string,'vertices':len(body.data.vertices),'changed_vertices':changed,'maximum_displacement':mx,'width':width,'height':height,'profile':profile,'body_qa_pass':qa['pass'],'body_glb_sha256':hashlib.sha256((OUT/'body_r07_derived.glb').read_bytes()).hexdigest()}
(ART/'body_manifest.json').write_text(json.dumps(summary,indent=2),encoding='utf8')
print('R07_BODY',json.dumps(summary))
