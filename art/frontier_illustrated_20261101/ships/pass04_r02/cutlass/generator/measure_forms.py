"""Read-only measurement of saved R01 and R02 forms; writes only this task's QA JSON."""
from pathlib import Path
import bpy,json
ART=Path(__file__).resolve().parents[1];ROOT=ART.parents[4]
def metric(ob):
    ps=[ob.matrix_world@v.co for v in ob.data.vertices];dim=[max(p[i] for p in ps)-min(p[i] for p in ps) for i in range(3)]
    return {'object':ob.name,'dimensions_blender_m':dim,'length_width_ratio':dim[1]/dim[0]}
def main():
    rows={}
    for key,path,names in [('r01',ROOT/'art/frontier_illustrated_20261101/ships/pass04/source/cutlass_01.blend',['Cutlass_CargoHull','Cutlass_Canopy','Cutlass_ForeWing_L']),('r02_iteration02',ART/'source/iteration02/cutlass_01.blend',['Cargo_stepped_hull','Cockpit_rounded_angular_shell','Fork_structural_shoulder_L'])]:
        bpy.ops.wm.open_mainfile(filepath=str(path));bpy.context.view_layer.update();rows[key]={role:metric(bpy.data.objects[name]) for role,name in zip(['cargo','cockpit','forward_shoulder'],names)}
    (ART/'qa/iteration02/form_comparison.json').write_text(json.dumps(rows,indent=2),encoding='utf-8');print(json.dumps(rows))
if __name__=='__main__':main()
