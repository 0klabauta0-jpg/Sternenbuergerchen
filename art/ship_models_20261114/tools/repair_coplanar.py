"""Separate tiny coplanar surface overlaps without opening or changing topology.

Used on the Vulture's localized rear-top remesh fold. Detection follows the
asset-QA plane/triangle test; this changes geometry, not QA tolerances.
"""
from mathutils import Vector
from mathutils.bvhtree import BVHTree


def _point_in_tri(point, a, b, c, normal):
    return all((v - u).cross(point - u).dot(normal) >= -1e-9
               for u, v in ((a, b), (b, c), (c, a)))


def _find_pairs(ob, eps):
    mesh = ob.data
    mesh.calc_loop_triangles()
    vertices = [v.co.copy() for v in mesh.vertices]
    triangles = [tuple(t.vertices) for t in mesh.loop_triangles]
    sets = [set(t) for t in triangles]
    normals = [(vertices[b] - vertices[a]).cross(vertices[c] - vertices[a]).normalized()
               for a, b, c in triangles]
    bvh = BVHTree.FromPolygons(vertices, triangles, all_triangles=True)
    pairs = set()
    for i, (ia, ib, ic) in enumerate(triangles):
        a, b, c = vertices[ia], vertices[ib], vertices[ic]
        normal = normals[i]
        center = (a + b + c) / 3
        for point in (center, center.lerp(a, .6), center.lerp(b, .6), center.lerp(c, .6)):
            for _, _, j, _ in bvh.find_nearest_range(point, eps):
                if j is None or j == i or sets[i] & sets[j] or normal.dot(normals[j]) < .999:
                    continue
                a2, b2, c2 = [vertices[v] for v in triangles[j]]
                n2 = normals[j]
                projected = point - n2 * n2.dot(point - a2)
                if _point_in_tri(projected, a2, b2, c2, n2):
                    pairs.add(tuple(sorted((i, j))))
    return sorted(pairs)


def fix(ob, eps=.00005, step=.0005, max_iterations=4):
    """Move smaller overlapping patches slightly along their surface normals.

    Shared vertices move together with neighboring faces: no holes or detached
    triangles are created. Returns an auditable adjustment record; the caller
    must rerun complete geometry QA and bounds checks afterward.
    """
    original = [v.co.copy() for v in ob.data.vertices]
    records = []
    for iteration in range(max_iterations):
        pairs = _find_pairs(ob, eps)
        if not pairs:
            break
        mesh = ob.data
        mesh.calc_loop_triangles()
        chosen = {}
        for a, b in pairs:
            ta, tb = mesh.loop_triangles[a], mesh.loop_triangles[b]
            target = a if ta.area <= tb.area else b
            triangle = mesh.loop_triangles[target]
            delta = triangle.normal.copy() * step
            chosen[target] = (tuple(triangle.vertices), delta)
            records.append(dict(iteration=iteration, pair=[a, b], target=target,
                                vertices=list(triangle.vertices), offset=list(delta)))
        deltas = {}
        for vertex_ids, delta in chosen.values():
            for vertex_id in vertex_ids:
                deltas.setdefault(vertex_id, []).append(delta)
        for vertex_id, moves in deltas.items():
            mesh.vertices[vertex_id].co += sum(moves, Vector()) / len(moves)
        mesh.update()
    displacement = [(v.co - before).length for v, before in zip(ob.data.vertices, original)]
    return dict(adjustments=records, remaining_pairs=_find_pairs(ob, eps),
                max_displacement=max(displacement, default=0),
                changed_vertices=sum(d > 1e-9 for d in displacement))
