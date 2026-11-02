"""Read-only evaluated n-gon best-fit plane audit for Blender."""
import argparse
import hashlib
import json
import sys
from pathlib import Path
import bpy
import numpy as np


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--source", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--collection", default="LOW")
    p.add_argument("--tolerance", type=float, default=1e-5)
    args = p.parse_args(sys.argv[sys.argv.index("--")+1:])
    src, out = Path(args.source).resolve(), Path(args.out).resolve()
    bpy.ops.wm.open_mainfile(filepath=str(src))
    collection = bpy.data.collections.get(args.collection)
    if collection is None:
        raise RuntimeError(f"Missing collection: {args.collection}")
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    records = []
    counts = {}
    for ob in sorted(collection.all_objects, key=lambda o: o.name):
        if ob.type != "MESH":
            continue
        ev = ob.evaluated_get(depsgraph)
        me = ev.to_mesh()
        try:
            for poly in me.polygons:
                if len(poly.vertices) <= 4:
                    continue
                coords = np.array([tuple(ev.matrix_world @ me.vertices[i].co) for i in poly.vertices], dtype=np.float64)
                center = coords.mean(axis=0)
                _, singular, basis = np.linalg.svd(coords-center, full_matrices=False)
                normal = basis[-1]
                distances = (coords-center) @ normal
                maximum = float(np.abs(distances).max())
                counts[ob.name] = counts.get(ob.name, 0)+1
                records.append({
                    "object": ob.name, "evaluated_face_index": poly.index,
                    "vertex_count": len(poly.vertices), "vertex_indices": list(poly.vertices),
                    "world_vertices": coords.tolist(), "centroid": center.tolist(),
                    "best_fit_normal": normal.tolist(), "singular_values": singular.tolist(),
                    "signed_distances_m": distances.tolist(), "max_distance_m": maximum,
                    "rms_distance_m": float(np.sqrt((distances**2).mean())),
                    "within_tolerance": bool(np.isfinite(coords).all() and maximum <= args.tolerance),
                })
        finally:
            ev.to_mesh_clear()
    data = {
        "source": str(src), "source_sha256": hashlib.sha256(src.read_bytes()).hexdigest(),
        "blender": bpy.app.version_string, "collection": args.collection,
        "method": "Evaluated mesh world coordinates, centered SVD least-squares best-fit plane; maximum absolute vertex-to-plane distance.",
        "tolerance_m": args.tolerance, "ngon_count": len(records), "per_object_counts": counts,
        "maximum_distance_m": max((r["max_distance_m"] for r in records), default=0.0),
        "warped_face_count": sum(not r["within_tolerance"] for r in records),
        "pass": all(r["within_tolerance"] for r in records), "faces": records,
        "limits": "Planarity only; this does not prove polygon simplicity, manifold topology, visible material correctness or reference fidelity. No source mesh was changed or saved.",
    }
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(data, indent=2), encoding="utf-8")
    print("NGON_PLANARITY " + json.dumps({k:v for k,v in data.items() if k != "faces"}))


if __name__ == "__main__":
    main()
