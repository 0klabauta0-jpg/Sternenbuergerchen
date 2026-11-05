"""Read-only checks for generated PNG receipts and text AtlasTexture resources."""
from __future__ import annotations

import hashlib
import json
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
    assert catalog == prepared, "Active catalog differs from reviewed prepared catalog"
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
    assert len([face for face in manifest["faces"] if not face["assigned"]]) == 2
    product_text = json.dumps(catalog)
    assert "C:/Users" not in product_text and "C:\\\\Users" not in product_text
    print("PORTRAIT_SOURCE_VERIFY_PASS: 11 original PNGs, 44 exact quadrants, 42 unchanged IDs/tags, 2 reserves, receipts/hashes/project paths checked.")


if __name__ == "__main__":
    main()
