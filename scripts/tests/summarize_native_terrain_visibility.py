"""Validate archived paired CPU evidence; never run or invent engine samples."""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import statistics
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = "a982a0b5d2265678bc796a5da77fe7a0e13e397c"


def stats(values):
    ordered = sorted(values)
    if not ordered:
        raise ValueError("Empty measurement series")
    return {"count": len(ordered), "mean_ms": statistics.fmean(ordered) / 1000,
            "median_ms": statistics.median(ordered) / 1000,
            "p95_ms": ordered[math.ceil(len(ordered) * .95) - 1] / 1000,
            "max_ms": ordered[-1] / 1000, "small_sample": len(ordered) < 20}


def comparison(before, after):
    left, right = stats(before), stats(after)
    return {"reference": left, "candidate": right,
            "median_change_percent": 100 * (right["median_ms"] / left["median_ms"] - 1)
            if left["median_ms"] else None}


def body(source, function):
    match = re.search(r"^func " + re.escape(function) + r"\(.*?(?=^func |\Z)", source, re.M | re.S)
    if not match:
        raise ValueError("Missing function: " + function)
    return match.group().strip()


def verify_reference():
    original = subprocess.check_output(["git", "show", BASE + ":scripts/terrain/native_navigation.gd"], cwd=ROOT).decode("utf-8").replace("\r\n", "\n")
    frozen = (ROOT / "scripts/tests/native_terrain_preparation_reference.gd").read_text(encoding="utf-8-sig")
    stripped = "\n".join(line for line in body(frozen, "_load_terrain").splitlines()
                         if not re.match(r"\s*(?:var phase_started:|phase_started =|phases\[)", line))
    expected = body(original, "_load_terrain")
    if stripped.strip() != expected:
        raise ValueError("Frozen terrain reference differs from Main beyond phase timers")
    return {"main": BASE, "frozen_body_matches_main_without_timers": True,
            "normalized_body_sha256": hashlib.sha256(expected.encode()).hexdigest(),
            "scope": "Only _load_terrain is frozen; surrounding adapter is shared."}


def read_run(path):
    path = path.resolve()
    result = json.loads((path / "result.json").read_text(encoding="utf-8-sig"))
    if result.get("passed") is not True or result.get("failures") or not result.get("rows"):
        raise ValueError("Failed or empty result: " + str(path))
    manifest = json.loads((path / "source_manifest.json").read_text(encoding="utf-8-sig"))
    if not manifest["engine"].startswith("4.6.2."):
        raise ValueError("Unexpected engine: " + manifest["engine"])
    for stage in ["import", "run"]:
        process = json.loads((path / (stage + "_process.json")).read_text())
        log = (path / (stage + ".log")).read_text(encoding="utf-8")
        if process["exit_code"] != 0 or re.search(r"SCRIPT ERROR|Parse Error|Compile Error|ERROR:|ObjectDB instances leaked|resources still in use at exit", log):
            raise ValueError("Rejected process: " + str(path / stage))
    mismatches = []
    for relative, expected in manifest["source_sha256"].items():
        file = ROOT / relative
        if not file.is_file():
            mismatches.append(relative)
            continue
        data = file.read_bytes()
        if hashlib.sha256(data).hexdigest() != expected and hashlib.sha256(data.replace(b"\r\n", b"\n")).hexdigest() != manifest.get("source_lf_sha256", {}).get(relative):
            mismatches.append(relative)
    if mismatches:
        raise ValueError("Final evidence source drift: " + str(mismatches))
    return result, {"path": path.relative_to(ROOT).as_posix(),
                    "result_sha256": hashlib.sha256((path / "result.json").read_bytes()).hexdigest(),
                    "engine": manifest["engine"], "sources_match": True,
                    "dll_sha256": manifest["source_sha256"].get("native/navigation/bin/native_navigation.windows.template_release.x86_64.dll")}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--terrain", action="append", type=Path, required=True)
    parser.add_argument("--visibility", action="append", type=Path, required=True)
    parser.add_argument("--near", action="append", type=Path, default=[])
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    terrain_rows, visibility_rows, provenance = [], [], []
    for path in args.terrain:
        result, source = read_run(path)
        terrain_rows += result["rows"]
        provenance.append(source)
    for path in args.visibility:
        result, source = read_run(path)
        visibility_rows += result["rows"]
        provenance.append(source)
    terrain = {}
    for fixture, phase in sorted({(r["fixture"], r["phase"]) for r in terrain_rows}):
        rows = [r for r in terrain_rows if (r["fixture"], r["phase"]) == (fixture, phase)]
        if not all(r["valid"] and r["exact_packed_parity"] for r in rows):
            raise ValueError("Terrain parity failure")
        if phase != "reused" and not all(r["candidate_debug"].get("terrain_builder") == "native" for r in rows):
            raise ValueError("Terrain benchmark did not use native builder")
        terrain[fixture + "/" + phase] = comparison([r["reference_usec"] for r in rows], [r["candidate_usec"] for r in rows])
    visibility = {}
    for label, keys in [("combat", ["combat", "usec"]), ("fow_full", ["fow", "full", "usec"]),
                        ("fow_dirty", ["fow", "dirty", "usec"]), ("hex_lines_diagnostic", ["line", "usec"])]:
        series = {"gdscript": [], "native": []}
        for row in visibility_rows:
            value = row
            for key in keys:
                value = value[key]
            series[row["backend"]].append(value)
            if row["backend"] == "native" and (row["combat"]["audit"].get("native_calls", 0) < 1 or row["fow"]["audit"].get("native_calls", 0) < 1):
                raise ValueError("Visibility benchmark silently fell back")
        if len(series["gdscript"]) != len(series["native"]):
            raise ValueError("Unpaired visibility series")
        visibility[label] = comparison(series["gdscript"], series["native"])
    near_rows = []
    for path in args.near:
        result, source = read_run(path)
        near_rows += result["rows"]
        provenance.append(source)
    if near_rows:
        series = {"gdscript": [], "native": []}
        signatures = set()
        for row in near_rows:
            series[row["backend"]].append(row["usec"])
            signatures.add(row["signature"])
            if row["cache"]["actual_los_check_count"] != 64 or row["cache"]["cache_hit_count"] != 192:
                raise ValueError("Near visibility cache workload drift")
            if row["backend"] == "native" and row["audit"]["native_calls"] != 64:
                raise ValueError("Near visibility silently fell back")
        if len(signatures) != 1 or len(series["gdscript"]) != len(series["native"]):
            raise ValueError("Near visibility parity or pairing failure")
        visibility["near_cached_queries"] = comparison(series["gdscript"], series["native"])
    report = {"reference": verify_reference(), "terrain": terrain, "visibility": visibility,
              "provenance": provenance, "passed": True,
              "limitations": ["Headless subsystem CPU; no GPU/FPS or whole-game claim.",
                              "Terrain cold is adapter-cold inside running process; three reference phase timers included.",
                              "Final paired series preserve current combat cache and FoW owner jobs."]}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"passed": True, "terrain": terrain, "visibility": visibility}, ensure_ascii=False))


if __name__ == "__main__":
    main()
