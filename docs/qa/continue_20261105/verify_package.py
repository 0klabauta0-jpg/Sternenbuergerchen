"""Read-only byte verification; no Godot, Git, extraction, or source writes."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import zipfile


def digest(stream) -> str:
    value = hashlib.sha256()
    for block in iter(lambda: stream.read(1048576), b""):
        value.update(block)
    return value.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--zip", action="store_true", help="Also verify archive members and whole ZIP.")
    parser.add_argument("--originals", action="store_true", help="Also verify original workspace paths.")
    args = parser.parse_args()
    base = Path(__file__).resolve().parent
    manifest = json.loads((base / "manifest.json").read_text(encoding="utf-8"))
    failures = []
    packed = zipfile.ZipFile(base / "continue_20261105.zip") if args.zip else None
    for entry in manifest["files"] + manifest["archive_only"]:
        candidate = base / entry["path"]
        if entry in manifest["files"] or candidate.is_file():
            if not candidate.is_file():
                failures.append("MISSING " + entry["path"])
            else:
                with candidate.open("rb") as stream:
                    if candidate.stat().st_size != entry["bytes"] or digest(stream) != entry["sha256"]:
                        failures.append("MISMATCH " + entry["path"])
        elif packed is None:
            failures.append("ARCHIVE_ONLY_NOT_EXTRACTED use --zip: " + entry["path"])
        if packed is not None:
            member = "continue_20261105/" + entry["path"]
            with packed.open(member) as stream:
                if packed.getinfo(member).file_size != entry["bytes"] or digest(stream) != entry["sha256"]:
                    failures.append("ZIP_MISMATCH " + member)
        if args.originals:
            original = base.parents[2] / entry["original_path"]
            if not original.is_file():
                failures.append("ORIGINAL_MISSING " + entry["original_path"])
            else:
                with original.open("rb") as stream:
                    if original.stat().st_size != entry["bytes"] or digest(stream) != entry["sha256"]:
                        failures.append("ORIGINAL_MISMATCH " + entry["original_path"])
    for line in (base / "SHA256SUMS.txt").read_text(encoding="utf-8").splitlines():
        expected, relative = line.split("  ", 1)
        candidate = base / relative
        with candidate.open("rb") as stream:
            if digest(stream) != expected:
                failures.append("PAYLOAD_MISMATCH " + relative)
    if packed is not None:
        packed.close()
        receipt = json.loads((base / "zip_receipt.json").read_text(encoding="utf-8"))
        candidate = base / receipt["path"]
        with candidate.open("rb") as stream:
            if candidate.stat().st_size != receipt["bytes"] or digest(stream) != receipt["sha256"]:
                failures.append("WHOLE_ZIP_MISMATCH")
    for failure in failures:
        print(failure)
    print(f"CONTINUE_QA {'FAIL' if failures else 'PASS'} "
          f"copies={len(manifest['files'])} raw_archive_members={len(manifest['archive_only'])} "
          f"zip={args.zip} originals={args.originals}")
    return int(bool(failures))


if __name__ == "__main__":
    raise SystemExit(main())
