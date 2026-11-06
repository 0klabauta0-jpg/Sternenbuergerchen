"""Read-only verification of copies, original paths, ZIP bytes and portable paths."""
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
    parser.add_argument("--zip", action="store_true")
    parser.add_argument("--originals", action="store_true")
    args = parser.parse_args()
    base = Path(__file__).resolve().parent
    manifest = json.loads((base / "manifest.json").read_text(encoding="utf-8"))
    errors = []
    packed = zipfile.ZipFile(base / "hud_architecture_20261106.zip") if args.zip else None
    for item in manifest["documents"]:
        path = base / item["path"]
        if not path.is_file():
            errors.append("DOCUMENT_MISSING " + item["path"])
            continue
        with path.open("rb") as stream:
            if path.stat().st_size != item["bytes"] or digest(stream) != item["sha256"]:
                errors.append("DOCUMENT_MISMATCH " + item["path"])
        if packed is not None:
            with packed.open(base.name + "/" + item["path"]) as stream:
                if digest(stream) != item["sha256"]:
                    errors.append("ZIP_DOCUMENT_MISMATCH " + item["path"])
    for item in manifest["files"]:
        local = base / item["path"]
        if item["storage"] == "copy" or local.is_file():
            if not local.is_file():
                errors.append("MISSING " + item["path"])
            else:
                with local.open("rb") as stream:
                    if local.stat().st_size != item["bytes"] or digest(stream) != item["sha256"]:
                        errors.append("COPY_MISMATCH " + item["path"])
        elif packed is None:
            errors.append("ARCHIVE_ONLY use --zip or extracted package: " + item["path"])
        if packed is not None:
            member = base.name + "/" + item["path"]
            with packed.open(member) as stream:
                if packed.getinfo(member).file_size != item["bytes"] or digest(stream) != item["sha256"]:
                    errors.append("ZIP_MEMBER_MISMATCH " + member)
        if args.originals:
            original = base.parents[2] / item["original_path"]
            if not original.is_file():
                errors.append("ORIGINAL_MISSING " + item["original_path"])
            else:
                with original.open("rb") as stream:
                    if original.stat().st_size != item["bytes"] or digest(stream) != item["sha256"]:
                        errors.append("ORIGINAL_MISMATCH " + item["original_path"])
    for line in (base / "SHA256SUMS.txt").read_text(encoding="utf-8").splitlines():
        expected, relative = line.split("  ", 1)
        with (base / relative).open("rb") as stream:
            if digest(stream) != expected:
                errors.append("PAYLOAD_MISMATCH " + relative)
        if packed is not None:
            with packed.open(base.name + "/" + relative) as stream:
                if digest(stream) != expected:
                    errors.append("ZIP_PAYLOAD_MISMATCH " + relative)
    if packed is not None:
        if packed.read(base.name + "/SHA256SUMS.txt") != (base / "SHA256SUMS.txt").read_bytes():
            errors.append("ZIP_HASH_INDEX_MISMATCH")
        for name in packed.namelist():
            if name.startswith(("/", "\\")) or "\\" in name or ".." in Path(name).parts:
                errors.append("NONPORTABLE_MEMBER " + name)
        packed.close()
        receipt = json.loads((base / "zip_receipt.json").read_text(encoding="utf-8"))
        path = base / receipt["path"]
        with path.open("rb") as stream:
            if path.stat().st_size != receipt["bytes"] or digest(stream) != receipt["sha256"]:
                errors.append("WHOLE_ZIP_MISMATCH")
    for error in errors:
        print(error)
    print(f"HUD_QA {'FAIL' if errors else 'PASS'} files={len(manifest['files'])} zip={args.zip} originals={args.originals}")
    return int(bool(errors))


if __name__ == "__main__":
    raise SystemExit(main())
