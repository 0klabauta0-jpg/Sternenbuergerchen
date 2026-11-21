"""Inspect manifold winding constraints for the three flagged meshes."""
import json
from collections import Counter, deque
from pathlib import Path

import bmesh
import bpy

ROOT = Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(ROOT / "editable/tanker_102m_segmented.blend"),
                        load_ui=False, use_scripts=False)
report = {}
for part in (1, 43, 74):
    ob = bpy.data.objects[f"tripo_part_{part}"]
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.faces.ensure_lookup_table()
    constraints = {f: [] for f in bm.faces}
    issues = []
    for edge in bm.edges:
        loops = list(edge.link_loops)
        if len(loops) == 2:
            a, b = loops
            same = a.vert == b.vert
            constraints[a.face].append((b.face, same))
            constraints[b.face].append((a.face, same))
            if same:
                issues.append(dict(faces=[a.face.index, b.face.index], length=edge.calc_length(),
                                   points=[list(ob.matrix_world @ v.co) for v in edge.verts]))
    assignments = {}
    groups = []
    for root in bm.faces:
        if root in assignments:
            continue
        assignments[root] = False
        group = [root]
        conflicts = set()
        queue = deque([root])
        while queue:
            current = queue.popleft()
            for other, same in constraints[current]:
                expected = assignments[current] ^ same
                if other in assignments:
                    if assignments[other] != expected:
                        conflicts.add(tuple(sorted((current.index, other.index))))
                    continue
                assignments[other] = expected
                group.append(other)
                queue.append(other)
        minority = [f for f in group if assignments[f]]
        if len(minority) > len(group) / 2:
            minority = [f for f in group if not assignments[f]]
        groups.append(dict(count=len(group), valences=dict(Counter(len(e.link_faces) for e in {e for f in group for e in f.edges})),
                           minority=[f.index for f in minority], conflicts=sorted(conflicts),
                           volume=sum((1 if f not in minority else -1) *
                                      f.verts[0].co.dot(f.verts[1].co.cross(f.verts[2].co)) / 6
                                      for f in group)))
    report[ob.name] = dict(valences=dict(Counter(len(e.link_faces) for e in bm.edges)), issues=issues, groups=groups)
    bm.free()
(ROOT / "qa/geometry_diagnosis.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
for name, data in report.items():
    print(name, data["valences"], data["issues"], data["groups"])
