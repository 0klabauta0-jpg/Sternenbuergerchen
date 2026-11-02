"""P07 capture gates: paired art fixture and separate real-map controls."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = ROOT / "output/grafik_20261101"
ART = ROOT / "docs/reports/assets/grafik-2026-11-01"
REVISION = "env07"
ARCHIVE_SHA = "75064afec11b66510846cd4679008fb3247ace2c71ac2a3d558aa1cb42662602"
VIEWS = [("lived_outpost", "Arbeitsbereich"), ("ground_detail", "Boden / Anschlüsse"),
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
    baseline = read(PACKAGE / "pass07_paths_before_manifest.json")
    assert sha(ROOT / baseline["html_archive"]) == ARCHIVE_SHA == baseline["html_archive_sha256"]
    assert sha(ROOT / baseline["capture_metadata"]) == baseline["capture_metadata_sha256"]
    assert len(baseline["captures"]) == 20
    for row in baseline["captures"]:
        assert sha(ROOT / row["before"]) == row["sha256"] == sha(ROOT / row["source"]), row["id"]
    before = read(PACKAGE / "pass07_paths_before_capture.json")
    path = PACKAGE / "pass07_paths_after_capture.json"
    candidate = read(path) if path.is_file() else {}
    ready = released(candidate)
    if require_release and not ready:
        raise ValueError("P07 requires explicit report_ready:true and report_revision:env07")
    after = candidate if ready else {}
    old_cameras = {row["id"]: row for row in before["captures"]}
    new_cameras = {row["id"]: row for row in after.get("captures", [])}
    captures, controls, combined_sources = [], [], {}
    runtime_evidence, legacy_evidence = {}, {}
    if ready:
        assert after.get("missing_asset_mapping_count") == 0
        assert after["renderer"] == before["renderer"] and after["light"] == before["light"]
        assert len(new_cameras) == len(after["captures"])
        assert after.get("canonical_star_citizen_dimensions") is False
        sources = after.get("runtime_sources_sha256", {})
        assert sources, "No captured runtime source hashes"
        for source, digest in sources.items():
            assert sha(local(source)) == digest, source
        combined_sources.update(sources)
        native_path = PACKAGE / "pass07_runtime/native_check.json"
        native = read(native_path)
        assert native["failed"] == 0 and native["passed"] == len(native["checks"]) > 0
        assert all(check["passed"] is True for check in native["checks"])
        runtime_evidence = {"path": native_path.relative_to(ROOT).as_posix(), "sha256": sha(native_path), "data": native}
        legacy_path = PACKAGE / "pass07_runtime/legacy_baseline_comparison.json"
        legacy = read(legacy_path)
        assert legacy["assertion_sets_identical"] is True and legacy["production_tests_modified"] is False
        assert legacy["overall_legacy_gates_pass"] is False
        assert {row["task"] for row in legacy["tests"]} == {158, 159}
        for row in legacy["tests"]:
            expected = (29, 13) if row["task"] == 158 else (86, 6)
            assert not row["new_failure_labels"]
            assert sorted(row["baseline"]["labels"]) == sorted(row["candidate"]["labels"])
            for side in ("baseline", "candidate"):
                assert (row[side]["passed"], row[side]["failed"]) == expected
                assert sha(local(row[side]["log"])) == row[side]["log_sha256"]
        legacy_evidence = {"path": legacy_path.relative_to(ROOT).as_posix(), "sha256": sha(legacy_path), "data": legacy}
        regular_sources = dict(native["source_sha256"])
        for prefix in ("map", "scenario"):
            regular_sources[native[prefix + "_path"]] = native[prefix + "_sha256"]
        for source, digest in regular_sources.items():
            assert sha(local(source)) == digest, source
            assert source not in combined_sources or combined_sources[source] == digest, source
            combined_sources[source] = digest
        old_models = {row["id"]: (row["path"], row["source_sha256"]) for row in before["models"]}
        models = {row["id"]: (row["path"], row["source_sha256"]) for row in after["models"]}
        assert models == old_models and len(models) == 9, "Primary preview GLB source changed"
        for source, digest in models.values():
            assert sha(local(source)) == digest, source
        stock = {row["id"]: (row["path"], row["source_sha256"]) for row in after["worklife_sources"]}
        old_stock = {row["id"]: (row["path"], row["source_sha256"]) for row in before["worklife_sources"]}
        assert stock == old_stock and len(stock) == 3
        for row in after["worklife_sources"]:
            for path_key, hash_key in (("path", "source_sha256"), ("license_path", "license_sha256"), ("atlas_path", "atlas_sha256")):
                assert sha(local(row[path_key])) == row[hash_key], row[path_key]
        for row in after["captures"]:
            image = ART / "engine_pass07_paths/after" / f'{row["id"]}.png'
            assert local(row["path"]) == image and row.get("error") == 0, row["id"]
            with Image.open(image) as opened:
                assert opened.size == (1600, 900), row["id"]
            captures.append({"id": row["id"], "path": image.relative_to(ROOT).as_posix(), "sha256": sha(image), "evidence_kind": "art_fixture"})
        # Real MapEditor / Mission views are evidence of their own maps and state.
        # They must never silently inherit fixture facts or an invented before.
        if "runtime_controls" in after:
            assert after["runtime_controls"] == native["runtime_controls"], "Do not diverge copied Runtime evidence"
        for row in native["runtime_controls"]:
            assert row["id"] not in new_cameras and not any(x["id"] == row["id"] for x in controls)
            image = local(row["path"])
            allowed_roots = (PACKAGE / "pass07_runtime", ART / "engine_pass07_paths/after")
            assert any(image.resolve().is_relative_to(folder.resolve()) for folder in allowed_roots), image
            assert image.suffix.lower() == ".png" and row.get("error") == 0, row["id"]
            for field in ("map_path", "map_sha256", "grid_topology", "theme_id", "entry_scene", "fact_source"):
                assert row.get(field), (row["id"], field)
            assert sha(local(row["map_path"])) == row["map_sha256"], row["map_path"]
            assert combined_sources.get(row["map_path"]) == row["map_sha256"], "Map must also be bound to committed runtime sources"
            assert row["sha256"] == sha(image), row["id"]
            with Image.open(image) as opened:
                dimensions = list(opened.size)
            controls.append({**row, "path": image.relative_to(ROOT).as_posix(), "sha256": sha(image),
                             "dimensions": dimensions, "evidence_kind": "regular_map_control", "has_before": False})
    pairs = []
    for view, title in VIEWS:
        old = ART / "engine_pass07_paths/before" / f"{view}.png"
        pair = {"id": view, "title": title, "before": old.relative_to(ROOT).as_posix(),
                "before_sha256": sha(old), "before_camera": old_cameras[view]}
        if ready:
            for field in CAMERA_FIELDS:
                assert field in old_cameras[view] and field in new_cameras[view]
                assert old_cameras[view][field] == new_cameras[view][field], (view, field)
            new = ART / "engine_pass07_paths/after" / f"{view}.png"
            with Image.open(old) as a, Image.open(new) as b:
                assert a.size == b.size == (1600, 900)
            pair.update(after=new.relative_to(ROOT).as_posix(), after_sha256=sha(new), after_camera=new_cameras[view], camera_match=True)
        pairs.append(pair)
    # P07 changes paths / map integration, not these retained P06 art sources.
    packages = {}
    for name in ("buildings", "geology", "ground_paint"):
        path = ROOT / f"art/frontier_illustrated_20261101/environment/pass06/{name}/manifest.json"
        assert path.is_file(), path
        packages[name] = {"path": path.relative_to(ROOT).as_posix(), "sha256": sha(path), "data": read(path), "role": "retained_pass06_source"}
    paths_manifest = ROOT / "art/frontier_illustrated_20261101/environment/pass07/paths/manifest.json"
    if paths_manifest.is_file():
        packages["paths"] = {"path": paths_manifest.relative_to(ROOT).as_posix(), "sha256": sha(paths_manifest),
                             "data": read(paths_manifest), "role": "current_pass07_source"}
    elif require_release:
        raise FileNotFoundError(paths_manifest)
    runtime_manifest = ROOT / "art/frontier_illustrated_20261101/environment/pass07/runtime/manifest.json"
    if runtime_manifest.is_file():
        packages["runtime"] = {"path": runtime_manifest.relative_to(ROOT).as_posix(), "sha256": sha(runtime_manifest),
                               "data": read(runtime_manifest), "role": "current_pass07_source"}
    elif require_release:
        raise FileNotFoundError(runtime_manifest)
    return {"revision": REVISION, "ready": ready, "baseline": baseline, "before_metadata": before,
            "after_metadata": after, "pairs": pairs, "captures": captures, "runtime_controls": controls,
            "runtime_evidence": runtime_evidence, "legacy_evidence": legacy_evidence,
            "runtime_sources_sha256": combined_sources, "source_packages": packages}
