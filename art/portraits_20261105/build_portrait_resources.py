"""Create text-only atlas resources and provenance; never edit raster images.

Run from any directory. Writes a prepared catalog here, never the active catalog.
Pillow is used only to read existing PNG dimensions/mode.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
ART = Path(__file__).resolve().parent
ASSET = ROOT / "Assets/curated/portraits/frontier_20261105"
QUADRANTS = ("upper_left", "upper_right", "lower_left", "lower_right")
REVIEWS = {
    "a": "Style reference opened. Four complete warm adult faces, crisp eyes, restrained teal/cream suits. Temple implant and distinct hair/beard silhouettes read clearly.",
    "b": "Project PNG opened. Bald moustached man, silver-bob woman, freckled copper-haired man and platinum-haired woman are clearly distinct. Four complete heads; palette matches A.",
    "c": "Project PNG opened. Close-shaved medical woman with temple implant, receding bearded man, braided dark-haired woman and short-haired square-jawed man differ clearly. Four complete heads; palette matches A.",
    "d": "Project PNG opened. Auburn braid/freckles, short twists, grey cropped hair and dark bun/moustache provide clear silhouettes. Four complete heads; coherent painted faces and suits.",
    "e": "Project PNG opened. Black fringe/bob, elderly white curls/moustache, short blonde crop and dark waves distinguish the quartet. Four complete heads; lower-left portrait reads more androgynous than prompt intent.",
    "f": "Project PNG opened. White forelock in curls, bald long face/goatee, twin dark braids and ginger full beard differ visibly. Four complete heads; identical costume palette and backdrop.",
    "g": "Project PNG opened. Silver braids, short dark spiky crop, pale pixie cut/freckles and grey-sided moustached man are distinct. Hair tips approach the top edge more closely than the intended seven percent padding; no head is cut.",
    "h": "Project PNG opened. Grey shoulder hair, youthful sandy curls, tall coiled hair and older silver ponytail/beard give clear distinctions. Complete heads; some hair tips have less than the intended seven percent top padding.",
    "i": "Project PNG opened. Shaved head, blunt black fringe, older copper-grey bob and short mohawk/beard are distinct. Four complete heads and coherent soft lighting.",
    "j": "Project PNG opened. Short tight light curls, silver-streaked upright hair/moustache, dark bob and ginger moustache clearly differ. Complete heads; coherent illustrative treatment.",
    "k": "Project PNG opened at original detail. Long dark-grey side hair and young loose curls are assigned to IDs 041/042. High brown bun and older clean-shaven silver-haired man remain reserves. Four complete heads; upper-left and lower-left share warm angular features but differ visibly in age, eye shape, hair and jaw.",
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def res(path: Path) -> str:
    return "res://" + path.relative_to(ROOT).as_posix()


def write_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    baseline = json.loads((ART / "catalog_before_refresh.json").read_text(encoding="utf-8"))
    catalog = json.loads(json.dumps(baseline))
    catalog["source_root"] = res(ASSET) + "/"
    catalog["art_revision"] = "frontier_20261105"
    catalog["provenance_manifest"] = res(ART / "manifest.json")
    catalog["legacy_source_inventory"] = baseline["source_inventory"]
    catalog["ui_contract"]["load_policy"] = "res_atlas_texture_exact_quadrant_scaled_by_texture_rect"
    sheets, faces = [], []
    (ASSET / "portraits").mkdir(parents=True, exist_ok=True)
    dimensions: dict[str, int] = {}
    for sheet_index, label in enumerate("abcdefghijk"):
        path = ASSET / f"sheets/crew_{label}.png"
        prompt_path = ART / f"atlas_{label}_prompt.json"
        prompt = json.loads(prompt_path.read_text(encoding="utf-8"))
        original = Path(prompt["generated_original"])
        assert sha(path) == sha(original), f"Project PNG differs from generated original: {label}"
        with Image.open(path) as image:
            width, height = image.size
            mode = image.mode
        assert width == height and width % 2 == 0
        key = f"{width}x{height}"
        dimensions[key] = dimensions.get(key, 0) + 1
        half = width // 2
        prompt["status"] = "project_png_opened_visual_review_complete_native_import_pending"
        prompt["sha256"] = sha(path)
        prompt["reference_sha256"] = sha(ASSET / "sheets/crew_a.png") if label != "a" else ""
        prompt["visual_review"] = REVIEWS[label]
        write_json(prompt_path, prompt)
        sheets.append({
            "sheet": label, "path": res(path), "sha256": sha(path),
            "bytes": path.stat().st_size, "width": width, "height": height, "mode": mode,
            "prompt_path": res(prompt_path), "prompt_sha256": sha(prompt_path),
            "tool": "built-in image_gen", "generated_original": str(original),
            "original_sha256": sha(original),
            "style_reference": res(ASSET / "sheets/crew_a.png") if label != "a" else "",
            "image_status": "generated_2d_portrait_asset_prepared_for_native_import",
            "opened_project_file": True, "visual_review": REVIEWS[label],
            "visual_decision": "accept_for_native_ui_review", "native_validation": "pending_root_serial_import_and_fullscreen_checks",
        })
        for quadrant_index, quadrant in enumerate(QUADRANTS):
            number = sheet_index * 4 + quadrant_index + 1
            assigned = number <= len(catalog["entries"])
            identity = f"char_portrait_{number:03d}" if assigned else f"reserve_{number:03d}"
            resource = ASSET / f"portraits/{identity}.tres"
            x, y = (quadrant_index % 2) * half, (quadrant_index // 2) * half
            resource.write_text(
                '[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n'
                f'[ext_resource type="Texture2D" path="{res(path)}" id="1"]\n\n'
                '[resource]\n'
                f'resource_name = "{identity}"\n'
                'atlas = ExtResource("1")\n'
                f'region = Rect2({x}, {y}, {half}, {half})\n'
                'filter_clip = true\n', encoding="utf-8")
            face = {"asset_id": identity, "portrait_id": identity if assigned else "",
                    "assigned": assigned, "path": res(resource), "sha256": sha(resource),
                    "sheet_path": res(path), "sheet": label, "quadrant": quadrant,
                    "region": [x, y, half, half]}
            faces.append(face)
            if assigned:
                entry = catalog["entries"][number - 1]
                assert entry["id"] == identity
                entry["legacy_paths"] = [entry["path"]]
                entry.update(path=res(resource), file_name=resource.name, width=half, height=half,
                             bytes=resource.stat().st_size, sheet_path=res(path),
                             sheet_sha256=sha(path), region=[x, y, half, half],
                             diagnostics=["shared_source_atlas_exact_quadrant_use_scaled_texture_rect"])
    catalog["source_inventory"] = {
        "scanned_png_count": len(sheets), "dimension_distribution": dimensions,
        "large_png_count": sum(sheet["bytes"] > 4_000_000 for sheet in sheets),
        "max_bytes": max(sheet["bytes"] for sheet in sheets),
        "atlas_region_count": len(faces), "assigned_identity_count": len(catalog["entries"]),
        "reserve_region_count": sum(not face["assigned"] for face in faces),
    }
    references = []
    for name in ("menu_fob_loadout.png", "menu_heimatbasis.png", "menu_debrief.png", "mockup_a5_mission_zweireihig.png"):
        path = ROOT / "docs/reports/assets/ui-2026-11-01" / name
        if path.is_file():
            references.append({"path": res(path), "sha256": sha(path), "role": "confirmed_2d_ui_target_context"})
    manifest = {
        "schema_version": 1, "package_id": "portrait_frontier_20261105",
        "task": "res://docs/tasks/PLAYTEST_2026_11_05_portrait_refresh.md",
        "tool": "built-in image_gen", "raster_processing": "none_original_pngs_copied_byte_identically",
        "quadrant_order": list(QUADRANTS), "sheet_count": len(sheets), "face_count": len(faces),
        "assigned_identity_count": len(catalog["entries"]), "reserve_count": 2,
        "baseline_catalog": res(ART / "catalog_before_refresh.json"),
        "baseline_catalog_sha256": sha(ART / "catalog_before_refresh.json"),
        "prepared_catalog": res(ART / "catalog_prepared.json"),
        "style_reference": res(ASSET / "sheets/crew_a.png"),
        "style_reference_sha256": sha(ASSET / "sheets/crew_a.png"),
        "references": references, "sheets": sheets, "faces": faces,
        "visual_review": "All eleven actual project PNGs opened; four complete distinct adult portraits per atlas, cohesive palette and technique, no visible repeated identity. Similar painterly conventions remain; the identity distinction is a visual judgment, not biometric proof.",
        "limitations": ["Some hair tips have less than requested seven percent top padding, but no heads are cut.",
                        "Native import, TextureRect crop/filter and readability at real UI sizes pending Root verification.",
                        "Aesthetic user acceptance remains open; generated assets are not native screenshots."],
        "native_validation": "pending_root", "user_aesthetic_acceptance": "open",
    }
    write_json(ART / "catalog_prepared.json", catalog)
    manifest["prepared_catalog_sha256"] = sha(ART / "catalog_prepared.json")
    write_json(ART / "manifest.json", manifest)
    print(f"Prepared {len(sheets)} sheets, {len(faces)} AtlasTextures, {len(catalog['entries'])} stable IDs and 2 reserves.")


if __name__ == "__main__":
    main()
