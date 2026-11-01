"""Read evaluated before/after geometry without modifying either source."""
import bpy, json, hashlib, struct
from pathlib import Path
HERE=Path(__file__).resolve().parent
PREVIOUS=HERE.parent.parent/'refinement_02/buccaneer/buccaneer_master.blend'
CURRENT=HERE/'buccaneer_master.blend'

def measure(path):
    bpy.ops.wm.open_mainfile(filepath=str(path))
    dg=bpy.context.evaluated_depsgraph_get();parts={};allpoints=[];glassfractions=[]
    for ob in bpy.data.collections['LOW'].all_objects:
        if ob.type!='MESH':continue
        eo=ob.evaluated_get(dg);me=eo.to_mesh();me.calc_loop_triangles()
        pts=[tuple(ob.matrix_world@v.co) for v in me.vertices];allpoints+=pts
        h=hashlib.sha256()
        for p in pts:h.update(struct.pack('<3f',*p))
        for t in me.loop_triangles:h.update(struct.pack('<3I',*t.vertices))
        lo=[min(p[i] for p in pts) for i in range(3)];hi=[max(p[i] for p in pts) for i in range(3)]
        parts[ob.name]={'min':lo,'max':hi,'size':[hi[i]-lo[i] for i in range(3)],'geometry_sha256':h.hexdigest()}
        if 'canopy' in ob.name:
            fac=1.13492093986703;yoffset=lo[1]+5.55*fac
            sections=[(-5.55,1.02,1.54),(-5.25,1.02,1.83),(-3.62,1.08,2.83),(-2.10,1.20,2.93),(-1.72,1.28,2.80)]
            for tri in me.loop_triangles:
                if 'Glass' not in me.materials[tri.material_index].name or abs(tri.normal.x)<.25:continue
                for vi in tri.vertices:
                    _,py,pz=pts[vi];y=(py-yoffset)/fac;z=pz/fac
                    for a,b in zip(sections,sections[1:]):
                        if a[0]<=y<=b[0]:
                            u=(y-a[0])/(b[0]-a[0]);bottom=a[1]*(1-u)+b[1]*u;top=a[2]*(1-u)+b[2]*u
                            glassfractions.append((z-bottom)/(top-bottom));break
        eo.to_mesh_clear()
    return {'source':str(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'parts':parts,
            'side_glass_min_relative_height':min(glassfractions),
            'overall_size':[max(p[i] for p in allpoints)-min(p[i] for p in allpoints) for i in range(3)]}

old=measure(PREVIOUS);new=measure(CURRENT)
groups={
    'pressure_shell':('VH_Buccaneer_Continuous_pressure_shell_R','VH_Buccaneer_Continuous_pressure_shell_R'),
    'canopy':('VH_Buccaneer_Broad_two_pane_wedge_canopy','VH_Buccaneer_Armored_tub_and_upper_canopy'),
    'wing':('VH_Buccaneer_Swept_thick_airfoil_R','VH_Buccaneer_Swept_thick_airfoil_R')}
summary={}
for label,(a,b) in groups.items():
    av=old['parts'][a]['size'];bv=new['parts'][b]['size']
    summary[label]={'previous_size_xyz':av,'current_size_xyz':bv,'percent_change_xyz':[(y/x-1)*100 for x,y in zip(av,bv)]}
common=set(old['parts'])&set(new['parts'])
cannon=[n for n in common if any(k in n.lower() for k in ['cannon','gun','barrel'])]
unchanged_cannon=all(old['parts'][n]['geometry_sha256']==new['parts'][n]['geometry_sha256'] for n in cannon)
changed_common=[n for n in common if old['parts'][n]['geometry_sha256']!=new['parts'][n]['geometry_sha256']]
assert cannon and unchanged_cannon
assert not changed_common,changed_common
assert abs(old['overall_size'][0]-new['overall_size'][0])<1e-5
data={'interpretation':'Perspective-derived stylized dimensions, not calibrated/canonical spacecraft dimensions.',
      'previous':old,'current':new,'summary':summary,
      'unchanged_cannon_parts':cannon,'unchanged_cannon_geometry':unchanged_cannon,
      'outer_span_preserved':True,'unchanged_common_parts':len(common),'unexpected_changed_common_parts':changed_common,
      'side_glass_min_relative_height':{'previous':old['side_glass_min_relative_height'],'current':new['side_glass_min_relative_height']},
      'scope':'Only canopy mesh replaced; all87 other source parts including complete reduced engines, wings, cannon and gear remain identical.',
      'authored_sill_fraction':{'previous':.17,'current':.50},'pass':True}
(HERE/'evaluated_proportions.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf8')
print(json.dumps({'summary':summary,'unchanged_common_parts':len(common),'side_glass_min_relative_height':data['side_glass_min_relative_height']}))
