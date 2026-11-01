"""Pack original PNGs into new editable sources only; frozen GLBs untouched."""
from pathlib import Path
import bpy,hashlib,json
HERE=Path(__file__).resolve().parents[1];ROOT=HERE.parents[3]
rows=[]
for role in ['operator','pilot','mechanic','medic']:
    path=HERE/'source'/(role+'_equipment.blend')
    glb=ROOT/'Assets/curated/frontier_illustrated_20261101/citizens_pass02'/(role+'.glb')
    frozen=hashlib.sha256(glb.read_bytes()).hexdigest()
    bpy.ops.wm.open_mainfile(filepath=str(path));images=[]
    for m in bpy.data.objects['characterMedium'].data.materials:
        for node in m.node_tree.nodes:
            if node.type=='TEX_IMAGE' and node.image:
                if not node.image.packed_file:node.image.pack()
                images.append(node.image.name)
    bpy.ops.wm.save_as_mainfile(filepath=str(path))
    assert hashlib.sha256(glb.read_bytes()).hexdigest()==frozen
    rows.append({'role':role,'packed_original_images':images,'glb_unchanged_sha256':frozen})
(HERE/'qa/packed_sources.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
