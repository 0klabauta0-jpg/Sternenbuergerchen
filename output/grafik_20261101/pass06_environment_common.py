"""Read-only asset/capture gates shared by the P06 report and finalizer."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = ROOT / "output/grafik_20261101"
ART = ROOT / "docs/reports/assets/grafik-2026-11-01"
REVISION = "env06"
ARCHIVE_SHA = "ab79aeec33e86fcf2c4cbe1751937dba6e1b6b8f81b84f2e355d2a51981a28aa"
VIEWS = [("lived_outpost", "Arbeitsbereich"), ("ground_detail", "Boden / Kontakte"),
         ("geology_detail", "Felsdetail"), ("closed_outpost", "Außenposten geschlossen"),
         ("closed_habitat", "Basis geschlossen"), ("closed_hall", "Halle geschlossen"),
         ("landscape", "Weites Gelände"), ("overview", "Übersicht / Schnitt"),
         ("workshop", "Werkstatt / Schnitt"), ("crew", "Crew"), ("hex_grid", "Hexraster"),
         ("cutaway", "Basis / Schnitt")]
CAMERA_FIELDS = ("camera_size", "camera_transform", "camera_projection", "viewport_size", "building_shells_visible")


def read(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def local(path: str) -> Path:
    return ROOT / path.removeprefix("res://")


def released(metadata: dict) -> bool:
    return metadata.get("report_ready") is True and metadata.get("report_revision") == REVISION


def load_package(*, require_release: bool = False) -> dict:
    baseline = read(PACKAGE / "pass06_environment_before_manifest.json")
    assert sha(ROOT / baseline["html_archive"]) == ARCHIVE_SHA == baseline["html_archive_sha256"]
    assert sha(ROOT / baseline["capture_metadata"]) == baseline["capture_metadata_sha256"]
    for row in baseline["captures"]:
        assert sha(ROOT / row["before"]) == row["sha256"] == sha(ROOT / row["source"]), row["id"]
    assert len(baseline["captures"]) == 20
    before = read(PACKAGE / "pass06_environment_before_capture.json")
    path = PACKAGE / "pass06_environment_after_capture.json"
    candidate = read(path) if path.is_file() else {}
    ready = released(candidate)
    if require_release and not ready:
        raise ValueError("P06 requires explicit report_ready:true and report_revision:env06")
    after = candidate if ready else {}
    old_cameras = {row["id"]: row for row in before["captures"]}
    new_cameras = {row["id"]: row for row in after.get("captures", [])}
    captures = []
    if ready:
        assert after.get("missing_asset_mapping_count") == 0
        assert after["renderer"] == before["renderer"] and after["light"] == before["light"]
        assert len(new_cameras) == len(after["captures"])
        assert after.get("canonical_star_citizen_dimensions") is False
        sources = after.get("runtime_sources_sha256", {})
        assert sources, "No captured runtime source hashes"
        for source, digest in sources.items():
            assert sha(local(source)) == digest, source
        old_models = {row["id"]: (row["path"], row["source_sha256"]) for row in before["models"]}
        models = {row["id"]: (row["path"], row["source_sha256"]) for row in after["models"]}
        assert models == old_models and len(models) == 9, "Primary GLB source changed"
        for source, digest in models.values():
            assert sha(local(source)) == digest, source
        original_stock = {row["id"]: (row["path"], row["source_sha256"]) for row in before["worklife_sources"]}
        stock = {row["id"]: (row["path"], row["source_sha256"]) for row in after["worklife_sources"]}
        assert stock == original_stock and len(stock) == 3
        for row in after["worklife_sources"]:
            for path_key, hash_key in (("path", "source_sha256"), ("license_path", "license_sha256"), ("atlas_path", "atlas_sha256")):
                assert sha(local(row[path_key])) == row[hash_key], row[path_key]
        for row in after["captures"]:
            image = ART / "engine_pass06_environment/after" / f'{row["id"]}.png'
            assert local(row["path"]) == image and row.get("error") == 0, row["id"]
            with Image.open(image) as opened:
                assert opened.size == (1600, 900), row["id"]
            captures.append({"id": row["id"], "path": image.relative_to(ROOT).as_posix(), "sha256": sha(image)})
    pairs = []
    for view, title in VIEWS:
        old = ART / "engine_pass06_environment/before" / f"{view}.png"
        pair = {"id": view, "title": title, "before": old.relative_to(ROOT).as_posix(),
                "before_sha256": sha(old), "before_camera": old_cameras[view]}
        if ready:
            for field in CAMERA_FIELDS:
                assert field in old_cameras[view] and field in new_cameras[view]
                assert old_cameras[view][field] == new_cameras[view][field], (view, field)
            new = ART / "engine_pass06_environment/after" / f"{view}.png"
            with Image.open(old) as a, Image.open(new) as b:
                assert a.size == b.size == (1600, 900)
            pair.update(after=new.relative_to(ROOT).as_posix(), after_sha256=sha(new),
                        after_camera=new_cameras[view], camera_match=True)
        pairs.append(pair)
    packages = {}
    for name in ("buildings", "geology", "ground_paint"):
        path = ROOT / f"art/frontier_illustrated_20261101/environment/pass06/{name}/manifest.json"
        if path.is_file():
            packages[name] = {"path": path.relative_to(ROOT).as_posix(), "sha256": sha(path), "data": read(path)}
        elif require_release:
            raise FileNotFoundError(path)
    return {"revision": REVISION, "ready": ready, "baseline": baseline, "before_metadata": before,
            "after_metadata": after, "pairs": pairs, "captures": captures, "source_packages": packages}
