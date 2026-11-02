"""Read-only evaluated source comparison and hidden proxy containment check."""
from pathlib import Path
import bpy, json, sys, argparse, hashlib
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ART=Path(__file__).resolve().parents[1]

def bound(names):
    deps=bpy.context.evaluated_depsgraph_get();pts=[]
    for name in names:
        ob=bpy.data.objects['VH_Cutlass_'+name];ev=ob.evaluated_get(deps);me=ev.to_mesh()
        pts.extend([ev.matrix_world@v.co for v in me.vertices]);ev.to_mesh_clear()
    lo=[min(p[k] for p in pts) for k in range(3)];hi=[max(p[k] for p in pts) for k in range(3)]
    return {'min':lo,'max':hi,'size':[hi[k]-lo[k] for k in range(3)]}

def snapshot(path):
    bpy.ops.wm.open_mainfile(filepath=str(path));out={}
    rear_prefixes=('Nacelle_keel','Swept_ivory_cowl','Cowl_','Nacelle_front_mark','Engine_core','Engine_collar','Ochre_nozzle_band','Nozzle_','Thrust_recess','Engine_rib')
    names=[o.name.removeprefix('VH_Cutlass_') for o in bpy.data.collections['LOW'].all_objects if o.type=='MESH']
    groups={'front_wings':['Front_fork_L','Front_fork_R'],'endplate_span':['Front_endplate_L','Front_endplate_R'],'cabin':['Cabin_ivory_monocoque'],'turret_housing':['Turret_housing'],'turret_ring':['Turret_pedestal'],'rear_nacelles':[n for n in names if n.startswith(rear_prefixes)],'rear_nozzle_L':['Nozzle_lip_L'],'fore_nozzle_L':['Forepod_Nozzle_lip_L'],'rear_pod_L':[n for n in names if n.startswith(rear_prefixes) and '_L' in n],'fore_pod_L':[n for n in names if n.startswith('Forepod_') and '_L' in n],'whole_forward_group':[n for n in names if n.startswith(('Front_','Endplate_','Fork_','Forepod_'))]}
    groups['fore_pod_L']=[n for n in groups['fore_pod_L'] if not n.startswith('Forepod_mount_')]
    for label,group in groups.items():
        if group and all('VH_Cutlass_'+n in bpy.data.objects for n in group):out[label]=bound(group)
    preserved=[];deps=bpy.context.evaluated_depsgraph_get()
    for name in sorted(n for n in names if n.startswith(('Cabin_','Bridge_','Nose_','Turret_'))):
        ob=bpy.data.objects['VH_Cutlass_'+name];ev=ob.evaluated_get(deps);me=ev.to_mesh()
        preserved.append({'name':name,'vertices':[list(ev.matrix_world@v.co) for v in me.vertices],'polygons':[list(p.vertices) for p in me.polygons],'materials':[m.name for m in me.materials]});ev.to_mesh_clear()
    out['preserved_cabin_turret_geometry_sha256']=hashlib.sha256(json.dumps(preserved,separators=(',',':')).encode()).hexdigest()
    return out

def main(iteration):
    old=ART.parents[1]/'refinement_02/cutlass/source/final/cutlass_01.blend'
    new=ART/'source'/('iteration%02d'%iteration)/'cutlass_01.blend'
    data={'basis':'Explicit user-designed four-engine layout, deliberately departing from original references. Evaluated component bounds in Blender metres. Comparison baseline is frozen refinement02.','before':snapshot(old),'after':snapshot(new)}
    data['ratio_after_before']={label:[data['after'][label]['size'][i]/b['size'][i] for i in range(3)] for label,b in data['before'].items() if isinstance(b,dict) and label in data['after']}
    for stage in ('before','after'):
        d=data[stage]
        d['ratios']={'endplate_span_to_ship_length':d['endplate_span']['size'][0]/16,'forewing_span_to_rear_nacelle_span':d['front_wings']['size'][0]/d['rear_nacelles']['size'][0],'cabin_width_to_ship_length':d['cabin']['size'][0]/16,'turret_width_to_cabin_width':d['turret_housing']['size'][0]/d['cabin']['size'][0]}
    a=data['after'];data['user_layout_checks']={'fore_nozzle_diameter_to_rear':a['fore_nozzle_L']['size'][0]/a['rear_nozzle_L']['size'][0],'forepod_width_to_rearpod':a['fore_pod_L']['size'][0]/a['rear_pod_L']['size'][0],'rear_radial_diameter_ratio_to_previous':a['rear_nozzle_L']['size'][0]/data['before']['rear_nozzle_L']['size'][0],'rear_outer_x':a['rear_nacelles']['max'][0],'forward_group_outer_x':a['whole_forward_group']['max'][0],'rear_outboard_clearance_each_side_m':a['rear_nacelles']['max'][0]-a['whole_forward_group']['max'][0],'rear_remains_outermost':a['rear_nacelles']['max'][0]>a['whole_forward_group']['max'][0],'preserved_cabin_turret_exact_geometry':a['preserved_cabin_turret_geometry_sha256']==data['before']['preserved_cabin_turret_geometry_sha256'],'axis_centers_x_m':{'rear':[-4.67*1.0410566430652601,4.67*1.0410566430652601],'front':[-4.45*1.0410566430652601,4.45*1.0410566430652601]}}
    # Conservative 8-corner test against the evaluated convex cabin exterior. Not an interior/seat rig.
    deps=bpy.context.evaluated_depsgraph_get();ob=bpy.data.objects['VH_Cutlass_Turret_housing'];ev=ob.evaluated_get(deps);me=ev.to_mesh()
    tree=BVHTree.FromPolygons([ev.matrix_world@v.co for v in me.vertices],[tuple(p.vertices) for p in me.polygons])
    result=[]
    for name in ('Turret_clearance','Seated_operator_envelope'):
        ref=bpy.data.objects['REF_'+name];samples=[]
        for x in (-.5,.5):
            for y in (-.5,.5):
                for z in (-.5,.5):
                    # Hidden REF collections may keep an unevaluated identity matrix_world.
                    # These parentless, unrotated wire proxies explicitly store location+scale.
                    p=ref.location+Vector((x*ref.scale.x,y*ref.scale.y,z*ref.scale.z));near,n,index,dist=tree.find_nearest(p)
                    samples.append({'point':list(p),'signed_surface_offset':(p-near).dot(n),'distance':dist})
        result.append({'name':name,'dimensions_m':list(ref.scale),'all_corners_inside':all(s['signed_surface_offset']<=1e-5 for s in samples),'minimum_corner_surface_clearance_m':min(s['distance'] for s in samples),'corners':samples})
    ev.to_mesh_clear();data['proxy_containment']=result
    data['proxy_limit']='Wire envelopes only. No modeled interior, seats, rig, moving turret clearance, access route, or ergonomic certification.'
    out=ART/'review'/('iteration%02d'%iteration)/'evaluated_proportions.json';out.write_text(json.dumps(data,indent=2),encoding='utf8')
    print(json.dumps({'out':str(out),'ratios':data['ratio_after_before'],'user_layout_checks':data['user_layout_checks'],'proxy':[{k:v for k,v in row.items() if k!='corners'} for row in result]}))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--iteration',type=int,default=1);a=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []);main(a.iteration)
