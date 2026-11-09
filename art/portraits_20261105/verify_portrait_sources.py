"""Read-only checks for generated PNG receipts and text AtlasTexture resources."""
from __future__ import annotations

import hashlib
import json
import copy
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = Path(__file__).resolve().parent


def read(path: Path) -> object:
    return json.loads(path.read_text(encoding="utf-8"))


def local(path: str) -> Path:
    assert path.startswith("res://"), path
    return ROOT / path[6:]


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    manifest = read(ART / "manifest.json")
    baseline = read(ART / "catalog_before_refresh.json")
    catalog = read(ROOT / "data/portrait_identity_catalog.json")
    prepared = read(ART / "catalog_prepared.json")
    # Identity metadata may extend the immutable reviewed art catalog. Every
    # original asset/ID/tag/region field must still match the archived receipt.
    reviewed_fields = copy.deepcopy(catalog)
    for entry in reviewed_fields["entries"]:
        entry.pop("presentation_group", None)
        entry.pop("presentation_source", None)
    assert reviewed_fields == prepared, "Reviewed portrait asset fields changed"
    assert len(manifest["sheets"]) == 11 and len(manifest["faces"]) == 44
    assert len(catalog["entries"]) == len(baseline["entries"]) == 42
    assert sha(ART / "catalog_before_refresh.json") == manifest["baseline_catalog_sha256"]
    assert sha(ART / "catalog_prepared.json") == manifest["prepared_catalog_sha256"]
    sheets = {}
    for record in manifest["sheets"]:
        path = local(record["path"])
        assert record["opened_project_file"] is True
        assert sha(path) == record["sha256"] == record["original_sha256"]
        assert sha(local(record["prompt_path"])) == record["prompt_sha256"]
        with Image.open(path) as image:
            assert image.size == (1254, 1254) and image.mode == "RGB"
        sheets[record["path"]] = record
    assert len({s["sha256"] for s in sheets.values()}) == 11
    region_keys = set()
    faces = {face["portrait_id"]: face for face in manifest["faces"] if face["assigned"]}
    assert len(faces) == 42
    for face in manifest["faces"]:
        path = local(face["path"])
        assert sha(path) == face["sha256"]
        text = path.read_text(encoding="utf-8")
        region = tuple(face["region"])
        assert region[0] in (0, 627) and region[1] in (0, 627) and region[2:] == (627, 627)
        assert face["sheet_path"] in sheets
        assert (face["sheet_path"], region) not in region_keys
        region_keys.add((face["sheet_path"], region))
        assert f'path="{face["sheet_path"]}"' in text
        assert "region = Rect2(%d, %d, %d, %d)" % region in text
        assert "filter_clip = true" in text
        assert "C:/Users" not in text and "C:\\Users" not in text
    assert len(region_keys) == 44
    for old, new in zip(baseline["entries"], catalog["entries"], strict=True):
        assert old["id"] == new["id"] and old["tags"] == new["tags"]
        assert old["candidate"] == new["candidate"]
        assert new["legacy_paths"] == [old["path"]]
        assert local(old["path"]).is_file()
        assert new["path"] == faces[new["id"]]["path"]
        assert new["region"] == faces[new["id"]]["region"]
        face = faces[new["id"]]
        sheet = sheets[face["sheet_path"]]
        source = new["presentation_source"]
        assert source["prompt_path"] == sheet["prompt_path"]
        assert source["prompt_sha256"] == sheet["prompt_sha256"]
        assert source["quadrant"] == face["quadrant"]
        assert source["policy"] == "authored_synthetic_character_intent"
        prompt = read(local(sheet["prompt_path"]))
        quadrant_index = manifest["quadrant_order"].index(face["quadrant"])
        if "subjects" in prompt:
            authored_word = prompt["subjects"][quadrant_index].split(" ", 1)[0]
        else:
            subjects = re.findall(r"(?:Upper left|Upper right|Lower left|Lower right):\s*(?:mature )?(man|woman)\b", prompt["prompt"])
            assert len(subjects) == 4
            authored_word = subjects[quadrant_index]
        assert authored_word in ("man", "woman")
        expected_group = "male" if authored_word == "man" else "female"
        if new["id"] == "char_portrait_019":
            assert "androgynous" in sheet["visual_review"]
            assert "review_note" in source
            expected_group = "unspecified"
        assert new["presentation_group"] == expected_group
    assert len([face for face in manifest["faces"] if not face["assigned"]]) == 2
    product_text = json.dumps(catalog)
    assert "C:/Users" not in product_text and "C:\\\\Users" not in product_text
    print("PORTRAIT_SOURCE_VERIFY_PASS: 11 original PNGs, 44 exact quadrants, 42 unchanged IDs/tags and authored presentation groups, 2 reserves, receipts/hashes/project paths checked.")


if __name__ == "__main__":
    main()
