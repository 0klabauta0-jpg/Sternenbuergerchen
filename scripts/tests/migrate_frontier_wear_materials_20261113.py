"""Move immutable wear bounds from instance uniforms into shared materials.

Only the two derived text scenes are rewritten. Geometry, transforms, remaining
material values and the original binary models are preserved byte for byte.
"""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[2]
PATHS = [ROOT / f"scenes/terrain/frontier_{kind}_exterior.tscn" for kind in ("habitat", "hall")]
AUDIT = ROOT / "docs/qa/review_completion_20261113/frontier_wear_material_migration.json"


def digest(text):
    return hashlib.sha256(text.encode()).hexdigest()


def migrate(path):
    before_bytes = path.read_bytes()
    before = before_bytes.decode("utf-8").replace("\r\n", "\n")
    if "instance_shader_parameters/wear_part_" not in before:
        return None
    sections = re.split(r"(?=^\[)", before, flags=re.M)
    materials = {}
    for i, section in enumerate(sections):
        match = re.match(r'\[sub_resource type="ShaderMaterial" id="([^"]+)"\]', section)
        if match:
            materials[match[1]] = (i, section)
    variants = {}
    first_variants = {}
    extra_materials = []
    nodes = []
    for i, section in enumerate(sections):
        if not section.startswith("[node ") or "instance_shader_parameters/wear_part_" not in section:
            continue
        source_id = re.search(r'material_override = SubResource\("([^"]+)"\)', section)[1]
        lo = re.search(r"^instance_shader_parameters/wear_part_min = (.+)$", section, re.M)[1]
        hi = re.search(r"^instance_shader_parameters/wear_part_max = (.+)$", section, re.M)[1]
        key = (source_id, lo, hi)
        if key not in variants:
            material_index, original_material = materials[source_id]
            if source_id not in first_variants:
                variant_id = source_id
                first_variants[source_id] = key
            else:
                variant_id = f"{source_id}_bounds_{len(variants):02d}"
            variant = original_material.replace(f'id="{source_id}"', f'id="{variant_id}"', 1).rstrip()
            variant += f"\nshader_parameter/wear_part_min = {lo}\nshader_parameter/wear_part_max = {hi}\n\n"
            if variant_id == source_id:
                sections[material_index] = variant
            else:
                extra_materials.append(variant)
            variants[key] = variant_id
        updated = section.replace(f'material_override = SubResource("{source_id}")', f'material_override = SubResource("{variants[key]}")')
        updated = re.sub(r"^instance_shader_parameters/wear_part_(?:min|max) = .+\n", "", updated, flags=re.M)
        # Only the parameter location and material reference may change a node.
        canonical = lambda value: re.sub(r'^material_override = .+\n|^instance_shader_parameters/wear_part_(?:min|max) = .+\n', '', value, flags=re.M)
        assert canonical(section) == canonical(updated)
        sections[i] = updated
        nodes.append({"node": re.search(r'^\[node name="([^"]+)"', section)[1], "source_material": source_id, "material": variants[key], "min": lo, "max": hi})
    insertion = next(i for i, section in enumerate(sections) if section.startswith("[node "))
    sections[insertion:insertion] = extra_materials
    after = "".join(sections)
    geometry = lambda text: "".join(s for s in re.split(r"(?=^\[)", text, flags=re.M) if s.startswith("[sub_resource ") and not s.startswith('[sub_resource type="ShaderMaterial"'))
    assert geometry(before) == geometry(after)
    assert "instance_shader_parameters/wear_part_" not in after
    path.write_text(after, encoding="utf-8", newline="\n")
    return {"path": path.relative_to(ROOT).as_posix(), "before_sha256": hashlib.sha256(before_bytes).hexdigest(), "before_normalized_text_sha256": digest(before), "after_sha256": digest(after), "unchanged_geometry_resources_sha256": digest(geometry(before)), "mesh_parts": len(nodes), "shared_material_variants": len(variants), "nodes": nodes}


def main():
    changed = [row for path in PATHS if (row := migrate(path)) is not None]
    if changed:
        AUDIT.parent.mkdir(parents=True, exist_ok=True)
        AUDIT.write_text(json.dumps({"schema": "frontier_wear_material_migration.v1", "source": "unchanged derived exterior scenes; original binary models untouched", "scenes": changed}, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"changed": len(changed), "parts": sum(row["mesh_parts"] for row in changed), "audit": AUDIT.relative_to(ROOT).as_posix()}))


if __name__ == "__main__":
    main()
