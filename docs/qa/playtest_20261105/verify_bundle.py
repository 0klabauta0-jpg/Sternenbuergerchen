"""Read-only lean QA integrity check; does not run Godot or change evidence."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check-originals", action="store_true",
                        help="Also hash all original files, including externally indexed raw data.")
    parser.add_argument("--check-archive", action="store_true",
                        help="Also verify the preserved full 218-file local archive.")
    args = parser.parse_args()
    bundle = Path(__file__).resolve().parent
    project = bundle.parents[2]
    manifest = json.loads((bundle / "manifest.json").read_text(encoding="utf-8"))
    failures: list[str] = []
    cached: dict[Path, str] = {}

    def digest(path: Path) -> str:
        if path not in cached:
            value = hashlib.sha256()
            with path.open("rb") as stream:
                for block in iter(lambda: stream.read(1048576), b""):
                    value.update(block)
            cached[path] = value.hexdigest()
        return cached[path]

    def check(path: Path, expected: dict, label: str) -> None:
        if not path.is_file():
            failures.append(f"MISSING {label}")
        elif path.stat().st_size != expected["bytes"] or digest(path) != expected["sha256"]:
            failures.append(f"MISMATCH {label}")

    total = 0
    for entry in manifest["files"]:
        path = bundle / entry["bundle_path"]
        check(path, entry, entry["bundle_path"])
        if path.is_file():
            total += path.stat().st_size
        if args.check_originals:
            check(project / entry["original_path"], entry, entry["original_path"])
    external = manifest["external_files"]
    for entry in external:
        if args.check_originals or entry["availability"] == "existing_repository_asset":
            check(project / entry["original_path"], entry, entry["original_path"])
    if total != manifest["total_bytes"] or len(manifest["files"]) != manifest["file_count"]:
        failures.append("MANIFEST_TOTAL_MISMATCH")
    if args.check_archive:
        archive = project / manifest["full_archive"]["path"]
        prior_manifest = archive / "manifest.json"
        if not prior_manifest.is_file() or digest(prior_manifest) != manifest["full_archive"]["prior_manifest_sha256"]:
            failures.append("FULL_ARCHIVE_MANIFEST_MISMATCH")
        else:
            prior = json.loads(prior_manifest.read_text(encoding="utf-8"))
            for entry in prior["files"]:
                check(archive / entry["bundle_path"], entry, f"ARCHIVE/{entry['bundle_path']}")
    for failure in failures:
        print(failure)
    print(f"PLAYTEST_QA_BUNDLE {'FAIL' if failures else 'PASS'} "
          f"files={len(manifest['files'])} bytes={total} external={len(external)} "
          f"originals={args.check_originals} archive={args.check_archive}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
