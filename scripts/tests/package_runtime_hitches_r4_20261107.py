"""Create a new byte-exact R4 evidence package after the native profile freeze.

Never starts Godot/Git, overwrites an artifact, deletes data or restores a pin.
Run only by Root, after profiling: python -B scripts/tests/package_runtime_hitches_r4_20261107.py
    (--profile-done | --native-deferred) [--image output/runtime_hitches_r4_20261107/...png]
An interrupted/failed run preserves its new partial artifacts for inspection.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path, PurePosixPath, PureWindowsPath
import re
import shutil
import struct
import zipfile


ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "output/runtime_hitches_r4_20261107"
QA = ROOT / "docs/qa/runtime_hitches_r4_20261107"
R3 = ROOT / "output/reference_polish_r3_20261106/final_code_manifest.json"
LIMIT_BYTES = 95_000_000  # Strict decimal 95 MB per member AND whole ZIP.
BLOCK_BYTES = 1_048_576
R4_INPUTS = (
    "project.godot",
    "scripts/tests/mission_tactical_sandbox_controller.gd",
    "scripts/terrain/terrain_map_3d_view.gd",
    "scripts/terrain/weapon_fire_feedback_layer.gd",
    "scripts/terrain/weapon_fire_feedback_pulse.gd",
    "scripts/tactical/periodic_hud_projection_queue.gd",
    "data/npc_unit_visual_mapping.json",
    "scripts/core/fog_of_war_system.gd",
    "scripts/core/los_system.gd",
)


def safe_relative(value: str) -> Path:
    parsed = PurePosixPath(value)
    if (not value or "\\" in value or parsed.is_absolute()
            or PureWindowsPath(value).drive or any(part in {".", ".."} for part in value.split("/"))):
        raise ValueError("Expected portable relative path: " + value)
    return Path(*parsed.parts)


def confined_file(relative: str) -> Path:
    candidate = ROOT / safe_relative(relative)
    candidate.resolve(strict=True).relative_to(ROOT.resolve())
    if not candidate.is_file():
        raise ValueError("Expected existing file: " + relative)
    return candidate


def signature(path: Path) -> tuple[int, int]:
    info = path.stat()
    return info.st_size, info.st_mtime_ns


def digest_stream(stream) -> tuple[str, int]:
    checksum = hashlib.sha256()
    size = 0
    for block in iter(lambda: stream.read(BLOCK_BYTES), b""):
        checksum.update(block)
        size += len(block)
    return checksum.hexdigest(), size


def pin_file(path: Path) -> dict:
    before = signature(path)
    with path.open("rb") as stream:
        digest, size = digest_stream(stream)
    if signature(path) != before or size != before[0]:
        raise RuntimeError("File changed while hashing: " + str(path))
    return {"size": size, "sha256": digest, "mtime_ns": before[1]}


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def write_json_new(path: Path, value: dict) -> dict:
    path.resolve().relative_to(QA.resolve())
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("x", encoding="utf-8", newline="\n") as stream:
        json.dump(value, stream, ensure_ascii=False, indent=2)
        stream.write("\n")
    return {"path": path.relative_to(QA).as_posix(), **pin_file(path)}


def preservation_report() -> dict:
    groups = {}
    errors = []
    for name, expected_count in (("preserved_untracked", 1415), ("preserved_rosters", 502)):
        baseline = RAW / (name + ".json")
        records = load_json(baseline)
        if not isinstance(records, list) or len(records) != expected_count:
            raise ValueError("Unexpected preservation baseline count: " + name)
        groups[name] = {"count": len(records), "baseline": baseline.relative_to(ROOT).as_posix(),
                        "baseline_sha256": pin_file(baseline)["sha256"]}
        for entry in records:
            original = Path(entry["path"])
            if not original.is_absolute():
                original = ROOT / safe_relative(entry["path"])
            expected = {key: entry[key] for key in ("size", "sha256", "mtime_ns")}
            try:
                actual = pin_file(original)
            except (OSError, RuntimeError) as error:
                errors.append({"group": name, "path": entry["path"], "expected": expected,
                               "reason": str(error)})
                continue
            if actual != expected:
                errors.append({"group": name, "path": entry["path"], "expected": expected,
                               "actual": actual, "reason": "bytes_size_or_mtime_changed"})
    baseline = RAW / "roster_baseline.json"
    roster = load_json(baseline)
    expected = {"size": roster["state"]["length"], "sha256": roster["state"]["sha256"],
                "mtime_ns": roster["state"]["mtime_ns"]}
    groups["actual_player_roster"] = {"count": 1, "path": roster["roster_path"],
                                      "baseline_sha256": pin_file(baseline)["sha256"]}
    try:
        actual = pin_file(Path(roster["roster_path"]))
        if actual != expected:
            errors.append({"group": "actual_player_roster", "expected": expected,
                           "actual": actual, "reason": "bytes_size_or_mtime_changed"})
    except (OSError, RuntimeError) as error:
        errors.append({"group": "actual_player_roster", "expected": expected, "reason": str(error)})
    return {"schema": "sternenbuergerchen.runtime_hitches_r4.preservation.v1", "groups": groups,
            "passed": not errors, "errors": errors,
            "policy": "Compare only SHA256, size and mtime_ns. Never restore or delete."}


def resource_strings(value):
    if isinstance(value, dict):
        for nested in value.values():
            yield from resource_strings(nested)
    elif isinstance(value, list):
        for nested in value:
            yield from resource_strings(nested)
    elif isinstance(value, str) and value.startswith("res://"):
        yield value.removeprefix("res://")


def source_binding(selected_scripts: list[str]) -> dict:
    prior = load_json(R3)["files"]
    if not isinstance(prior, dict) or len(prior) != 2230:
        raise ValueError("Expected the unchanged 2230-path R3 files dictionary")
    paths = set(prior) | set(R4_INPUTS)
    paths.add(Path(__file__).resolve().relative_to(ROOT).as_posix())
    for path in (ROOT / "scripts/tests").glob("*runtime_hitches_r4_20261107*"):
        if path.is_file() and path.suffix.lower() in {".gd", ".py", ".json"}:
            paths.add(path.relative_to(ROOT).as_posix())
    for case in load_json(ROOT / "scripts/tests/runtime_hitches_r4_20261107_regression_manifest.json")["checks"]:
        paths.add(case["script"].removeprefix("res://"))
    for script in selected_scripts:
        relative = script.removeprefix("res://")
        if safe_relative(relative).suffix not in {".gd", ".py"}:
            raise ValueError("Selected script must be .gd/.py: " + script)
        confined_file(relative)
        paths.add(relative)
    pending = list(resource_strings(load_json(ROOT / "data/npc_unit_visual_mapping.json")))
    directories = set()
    dependencies = {}
    visited = set()
    while pending:
        relative = pending.pop()
        safe_relative(relative.rstrip("/"))
        if relative in visited:
            continue
        visited.add(relative)
        path = ROOT / relative
        path.resolve(strict=True).relative_to(ROOT.resolve())
        if path.is_dir():
            directories.add(relative)
            continue  # Catalog directory metadata is not an implicit asset scan.
        confined_file(relative)
        paths.add(relative)
        imported = path.with_name(path.name + ".import")
        if imported.is_file():
            imported_relative = imported.relative_to(ROOT).as_posix()
            paths.add(imported_relative)
            refs = sorted(set(re.findall(r'res://([^"\r\n]+)', imported.read_text(encoding="utf-8"))))
            dependencies[relative] = {"import_metadata": imported_relative, "targets_and_sources": refs}
            pending.extend(refs)
    files = {}
    for relative in sorted(paths):
        current = pin_file(confined_file(relative))
        files[relative] = current
    return {"schema": "sternenbuergerchen.runtime_hitches_r4.source_binding.v1",
            "snapshot_utc": datetime.now(timezone.utc).isoformat(),
            "r3_path_manifest": R3.relative_to(ROOT).as_posix(), "r3_manifest_sha256": pin_file(R3)["sha256"],
            "r3_path_count": len(prior), "count": len(files), "files": files,
            "changed_from_r3": [relative for relative, item in files.items()
                                if relative in prior and item["sha256"] != prior[relative]],
            "added_after_r3": sorted(set(files) - set(prior)),
            "mapping_directory_references": sorted(directories), "mapping_import_dependencies": dependencies,
            "selected_scripts": selected_scripts,
            "policy": "Current source hashes from original R3 path set plus explicit R4/resource inputs; not historical source substitution."}


def selected_images(values: list[str]) -> list[tuple[Path, Path]]:
    images = []
    destinations = set()
    for value in values:
        original = Path(value)
        if not original.is_absolute():
            original = ROOT / safe_relative(value)
        relative = original.resolve(strict=True).relative_to(RAW.resolve())
        if original.suffix.lower() != ".png" or not original.is_file():
            raise ValueError("--image requires an existing R4 PNG: " + value)
        with original.open("rb") as stream:
            header = stream.read(24)
        if header[:8] != b"\x89PNG\r\n\x1a\n" or len(header) != 24:
            raise ValueError("Invalid PNG: " + value)
        destination = QA / "captures" / relative
        normalized = destination.relative_to(QA).as_posix().casefold()
        if normalized in destinations:
            raise ValueError("Duplicate --image destination: " + value)
        destinations.add(normalized)
        images.append((original, destination))
    return images


def write_raw_archive(archive: Path, paths: list[Path]) -> list[dict]:
    entries = []
    with archive.open("xb") as output:
        with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as packed:
            for original in paths:
                relative = original.relative_to(ROOT).as_posix()
                expected = pin_file(original)
                if expected["size"] >= LIMIT_BYTES:
                    raise ValueError("Raw member exceeds strict 95 MB limit: " + relative)
                checksum = hashlib.sha256()
                copied = 0
                with original.open("rb") as source, packed.open(relative, "w") as destination:
                    for block in iter(lambda: source.read(BLOCK_BYTES), b""):
                        checksum.update(block)
                        copied += len(block)
                        if copied >= LIMIT_BYTES:
                            raise ValueError("Raw member grew beyond budget: " + relative)
                        destination.write(block)
                        if output.tell() >= LIMIT_BYTES:
                            raise ValueError("ZIP exceeds strict 95 MB limit")
                if (copied != expected["size"] or checksum.hexdigest() != expected["sha256"]
                        or signature(original) != (expected["size"], expected["mtime_ns"])):
                    raise RuntimeError("Raw source changed during archive write: " + relative)
                entries.append({"original_path": relative, "archive_path": relative, **expected})
    if archive.stat().st_size >= LIMIT_BYTES:
        raise ValueError("Final ZIP exceeds strict 95 MB limit")
    # Read each compressed member through a bounded buffer, including CRC check.
    with zipfile.ZipFile(archive, "r") as packed:
        if packed.namelist() != [entry["archive_path"] for entry in entries]:
            raise RuntimeError("ZIP member list differs from manifest")
        for entry in entries:
            with packed.open(entry["archive_path"], "r") as stream:
                digest, size = digest_stream(stream)
            if digest != entry["sha256"] or size != entry["size"]:
                raise RuntimeError("ZIP streamed readback differs: " + entry["archive_path"])
    return entries


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    phase = parser.add_mutually_exclusive_group(required=True)
    phase.add_argument("--profile-done", action="store_true",
                       help="Root confirms the planned native measurement phase is over.")
    phase.add_argument("--native-deferred", action="store_true",
                       help="The user deferred remaining native runs; package the current checkpoint without claiming Main readiness.")
    parser.add_argument("--image", action="append", default=[], help="Explicit existing PNG inside the R4 output tree; repeatable.")
    parser.add_argument("--script", action="append", default=[], help="Additional selected .gd/.py source input; repeatable.")
    args = parser.parse_args()
    images = selected_images(args.image)
    QA.resolve().relative_to(ROOT.resolve())
    archive = QA / "raw_evidence.zip"
    generated = [archive, QA / "manifest.json", QA / "source_binding.json", QA / "preservation_report.json",
                 QA / "preservation_final_failure.json"]
    for target in generated + [destination for _, destination in images]:
        target.resolve().relative_to(QA.resolve())
        if target.exists() or target.is_symlink():
            raise FileExistsError("Preserve existing artifact; refusing overwrite: " + str(target))
    QA.mkdir(parents=True, exist_ok=True)
    preservation = preservation_report()
    preservation["scope"] = "Before packaging; successful final manifest additionally requires the post-packaging comparison."
    preservation_pin = write_json_new(QA / "preservation_report.json", preservation)
    if not preservation["passed"]:
        print(json.dumps({"status": "PRESERVATION_FAILED_NO_PACKAGE", "errors": len(preservation["errors"]),
                          "report": str(QA / "preservation_report.json")}))
        return 2
    binding = source_binding(args.script)
    binding_pin = write_json_new(QA / "source_binding.json", binding)
    raw_paths = sorted((path for path in RAW.rglob("*") if path.is_file()
                        and path.suffix.lower() in {".json", ".log", ".txt", ".raw"}),
                       key=lambda path: path.relative_to(ROOT).as_posix())
    if not raw_paths:
        raise RuntimeError("No R4 raw evidence inputs")
    for path in raw_paths:
        path.resolve(strict=True).relative_to(RAW.resolve())
    entries = write_raw_archive(archive, raw_paths)
    captures = []
    for original, destination in images:
        expected = pin_file(original)
        if expected["size"] >= LIMIT_BYTES:
            raise ValueError("PNG exceeds strict 95 MB limit: " + str(original))
        destination.parent.mkdir(parents=True, exist_ok=True)
        with original.open("rb") as source, destination.open("xb") as target:
            shutil.copyfileobj(source, target, BLOCK_BYTES)
        actual = pin_file(destination)
        if (actual["sha256"] != expected["sha256"] or actual["size"] != expected["size"]
                or pin_file(original) != expected):
            raise RuntimeError("PNG copy/source drift: " + str(original))
        with destination.open("rb") as stream:
            dimensions = list(struct.unpack(">II", stream.read(24)[16:24]))
        captures.append({"original_path": original.resolve().relative_to(ROOT.resolve()).as_posix(),
                         "path": destination.relative_to(QA).as_posix(), "image_size": dimensions, **actual})
    # Sources are not copied into the raw archive. Detect ordinary write drift
    # across packaging separately from the byte-exact evidence member checks.
    for relative, expected in binding["files"].items():
        if signature(confined_file(relative)) != (expected["size"], expected["mtime_ns"]):
            raise RuntimeError("Bound source metadata changed during package build: " + relative)
    current_raw_paths = sorted((path.relative_to(ROOT).as_posix() for path in RAW.rglob("*") if path.is_file()
                                and path.suffix.lower() in {".json", ".log", ".txt", ".raw"}))
    if current_raw_paths != [entry["original_path"] for entry in entries]:
        raise RuntimeError("Raw evidence input set changed during package build")
    for entry in entries:
        if signature(confined_file(entry["original_path"])) != (entry["size"], entry["mtime_ns"]):
            raise RuntimeError("Raw evidence metadata changed after archive write: " + entry["original_path"])
    preservation_after = preservation_report()
    if not preservation_after["passed"]:
        write_json_new(QA / "preservation_final_failure.json", preservation_after)
        print(json.dumps({"status": "FINAL_PRESERVATION_FAILED_NO_MANIFEST",
                          "errors": len(preservation_after["errors"])}))
        return 2
    manifest = {"schema": "sternenbuergerchen.runtime_hitches_r4.qa.v1",
                "created_utc": datetime.now(timezone.utc).isoformat(), "passed": True,
                "native_phase": "deferred_by_user" if args.native_deferred else "measurement_phase_finished",
                "passed_scope": "Evidence bytes, source binding and preservation only; not performance or Main readiness.",
                "archive": {"path": archive.name, **pin_file(archive), "streamed_readback_verified": True,
                            "strict_limit_bytes": LIMIT_BYTES},
                "files": entries, "captures": captures,
                "source_binding": binding_pin, "preservation": preservation_pin,
                "preservation_after_packaging": preservation_after,
                "policy": "All R4 .json/.log/.txt/.raw original bytes in ZIP; PNG only by explicit --image. No overwrite/delete/restore. Root reports/Main receipts remain separate."}
    write_json_new(QA / "manifest.json", manifest)
    print(json.dumps({"status": "R4_QA_PACKAGE_PASS", "raw_files": len(entries), "captures": len(captures),
                      "bound_sources": binding["count"], "archive_bytes": manifest["archive"]["size"],
                      "manifest": str(QA / "manifest.json")}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
