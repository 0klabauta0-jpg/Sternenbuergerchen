"""Render actual topology with thin, non-mitered wires (no spike artifacts)."""
import sys
from pathlib import Path
import bpy

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts')
import review_shots


def run(ship):
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/ship/(ship+'.blend')))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    targets=[]
    gray=bpy.data.materials.new('QA_Gray')
    gray.diffuse_color=(.65,.68,.72,1)
    black=bpy.data.materials.new('QA_WireBlack')
    black.diffuse_color=(.008,.012,.018,1)
    for ob in meshes:
        wire=ob.copy()
        wire.data=ob.data.copy()
        bpy.context.scene.collection.objects.link(wire)
        wire.name=ob.name+'_QA_Wire'
        wire.data.materials.clear()
        wire.data.materials.append(black)
        ob.data.materials.clear()
        ob.data.materials.append(gray)
        for face in ob.data.polygons:face.material_index=0
        for face in wire.data.polygons:face.material_index=0
        modifier=wire.modifiers.new('Thin topology only','WIREFRAME')
        modifier.thickness=.0018
        modifier.use_even_offset=False
        modifier.use_relative_offset=False
        modifier.offset=1
        targets.extend([ob.name,wire.name])
    out=ROOT/ship/('candidate_wire.png' if ship=='caterpillar' else 'qa/wire.png')
    review_shots.run(objects=targets,out=str(out),mode='material',res=500)
    # Intentionally never save this diagnostic overlay into the deliverable.
    print('WIRE_REVIEW',ship,flush=True)


for ship in sys.argv[sys.argv.index('--')+1:]:
    run(ship)
