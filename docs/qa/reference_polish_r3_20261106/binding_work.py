"""Read-only checks against fresh R3 snapshots; explicit new output receipt only."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = ROOT / "output/reference_polish_r3_20261106"


def sha(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1048576), b""):
            value.update(block)
    return value.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    target = ROOT / args.output
    if target.exists():
        raise RuntimeError("Receipt target must be new")
    errors = []
    groups = {}
    for name in ["preserved_untracked", "preserved_rosters"]:
        records = json.loads((BASE / (name + ".json")).read_text(encoding="utf-8"))
        groups[name] = len(records)
        for entry in records:
            path = ROOT / entry["path"]
            if not path.is_file():
                errors.append({"group": name, "path": entry["path"], "reason": "missing"})
                continue
            stat = path.stat()
            if stat.st_size != entry["size"] or stat.st_mtime_ns != entry["mtime_ns"] or sha(path) != entry["sha256"]:
                errors.append({"group": name, "path": entry["path"], "reason": "bytes_size_or_mtime_changed"})
    manifest_path = BASE / "final_code_manifest.json"
    files = json.loads(manifest_path.read_text(encoding="utf-8"))["files"]
    groups["final_code_inputs"] = len(files)
    for relative, digest in files.items():
        path = ROOT / relative
        if not path.is_file() or sha(path) != digest:
            errors.append({"group": "final_code_inputs", "path": relative, "reason": "missing_or_source_drift"})
    roster = json.loads((BASE / "roster_baseline.json").read_text(encoding="utf-8"))
    path = Path(roster["roster_path"])
    expected = roster["state"]
    groups["actual_player_roster"] = 1
    if not path.is_file() or path.stat().st_size != expected["length"] or path.stat().st_mtime_ns != expected["mtime_ns"] or sha(path) != expected["sha256"]:
        errors.append({"group": "actual_player_roster", "reason": "missing_or_bytes_size_mtime_changed"})
    report = {"schema": "sternenbuergerchen.reference_r3.preservation.v1", "groups": groups,
              "manifest_sha256": sha(manifest_path), "passed": not errors, "errors": errors}
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(json.dumps({"passed": not errors, "groups": groups, "errors": len(errors), "path": str(target)}))
    return int(bool(errors))


if __name__ == "__main__":
    raise SystemExit(main())
