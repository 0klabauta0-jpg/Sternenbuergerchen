"""Verify saved matched-render camera/light metadata (plain Python)."""
import argparse
import json
from pathlib import Path


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--comparison-dir", required=True)
    a = p.parse_args()
    root = Path(a.comparison_dir).resolve()
    manifests = {k: json.loads((root / k / "render_manifest.json").read_text()) for k in ["r02", "new", "roundtrip"]}
    shot_keys = ["location", "rotation_euler", "ortho_scale", "resolution", "azimuth", "elevation"]
    scene_keys = ["target_length", "target", "engine", "samples", "color_management", "lights", "floor", "transparent"]
    result = {
        "schema": "sternenbuergerchen.matched_render_conditions.v1", "checks": [],
        "input_hashes": {k: m["input_sha256"] for k, m in manifests.items()},
        "manifests": {k: str(root / k / "render_manifest.json") for k in manifests},
        "note": "Equal controlled render setup; no claim of bitwise identical stochastic EEVEE samples or native Godot output.",
    }
    for left, right, views in [
        ("r02", "new", ["front", "rear", "side", "top", "game"]),
        ("new", "roundtrip", ["front", "rear", "game"]),
    ]:
        for view in views:
            aa = next((s for s in manifests[left]["shots"] if s["view"] == view and s["mode"] == "material"), None)
            bb = next((s for s in manifests[right]["shots"] if s["view"] == view and s["mode"] == "material"), None)
            cond = {"both_material_shots_present": aa is not None and bb is not None}
            if cond["both_material_shots_present"]:
                cond.update({k: aa[k] == bb[k] for k in shot_keys})
                cond.update({k: manifests[left][k] == manifests[right][k] for k in scene_keys})
            result["checks"].append({"left": left, "right": right, "view": view, "conditions_equal": all(cond.values()), "conditions": cond})
    result["pass"] = all(r["conditions_equal"] for r in result["checks"])
    dest = root / "matched_conditions.json"
    dest.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps({"pass": result["pass"], "comparisons": len(result["checks"]), "out": str(dest)}))
    raise SystemExit(0 if result["pass"] else 1)


if __name__ == "__main__":
    main()
