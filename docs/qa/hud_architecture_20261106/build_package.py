"""Build only after Root explicitly says PROFILE_DONE; no engine or Git calls."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import struct
import zipfile


BASE = Path(__file__).resolve().parent
PROJECT = BASE.parents[2]
ZIP_NAME = "hud_architecture_20261106.zip"
MUTABLE = {"main_receipt.json", "main_preservation.json", "main_sources_index.json", "zip_receipt.json"}
ROOT_DOCUMENTS = {"README.md", "REPORT.md", "analysis.json", "analysis_work.py"}


def sha(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1048576), b""):
            value.update(block)
    return value.hexdigest()


def safe_relative(value: str) -> Path:
    path = Path(value)
    if path.is_absolute() or path.drive or ".." in path.parts or "\\" in value:
        raise ValueError(f"Expected portable relative path: {value}")
    return path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile-done", action="store_true", required=True,
                        help="Use only after explicit Root PROFILE_DONE, never after elapsed time alone.")
    parser.add_argument("--documents-final", action="store_true",
                        help="Root confirms its report/analysis are ready to snapshot read-only.")
    parser.add_argument("--stage-only", action="store_true", help="Copy/hash raw inputs only; never creates a ZIP.")
    parser.add_argument("--replace-generated-zip", action="store_true")
    args = parser.parse_args()
    if not args.stage_only and not args.documents_final:
        raise SystemExit("ZIP requires Root's document freeze and --documents-final; use --stage-only before that.")
    plan = json.loads((BASE / "package_plan.json").read_text(encoding="utf-8"))
    if not plan.get("approved_final_run"):
        raise SystemExit("Final native run has not been approved in the package plan.")
    archive = BASE / ZIP_NAME
    if archive.exists() and not args.replace_generated_zip:
        raise SystemExit("Generated ZIP exists; replacement must be explicit.")
    files, paths = [], set()
    for item in plan["entries"]:
        relative = safe_relative(item["path"])
        if relative.parts[0] not in {"raw", "sources", "binding", "references", "output"}:
            raise ValueError("Raw copies may not overwrite Root documents or package helpers.")
        if item["path"] in paths:
            raise ValueError("Duplicate archive path: " + item["path"])
        paths.add(item["path"])
        original_relative = safe_relative(item["original_path"])
        if relative.name.casefold() in MUTABLE or original_relative.name.casefold() in MUTABLE or "main_smoke" in relative.parts or "main_smoke" in original_relative.parts:
            raise ValueError("Mutable receipts may not enter the frozen raw payload.")
        original = PROJECT / original_relative
        if str(item.get("role", "")).startswith("baseline_source") and original_relative.parts[0] != "output":
            raise ValueError("A current product source cannot be labeled as a historical baseline.")
        if not original.is_file():
            raise FileNotFoundError(original)
        checksum = sha(original)
        entry = {**item, "bytes": original.stat().st_size, "sha256": checksum}
        if original.suffix.lower() == ".png":
            with original.open("rb") as stream:
                header = stream.read(24)
            if header[:8] != b"\x89PNG\r\n\x1a\n":
                raise ValueError("Invalid PNG header")
            entry["image_size"] = list(struct.unpack(">II", header[16:24]))
        if item["storage"] == "copy":
            target = BASE / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            if target.exists() and sha(target) != checksum:
                raise ValueError("Existing raw copy differs; preserve it and use another name: " + str(relative))
            if not target.exists():
                shutil.copy2(original, target)
            if sha(target) != checksum or sha(original) != checksum:
                raise ValueError("Copy/source drift: " + str(relative))
        elif item["storage"] != "archive":
            raise ValueError("Unknown storage policy")
        files.append(entry)
    documents = []
    if args.documents_final:
        for name in sorted(ROOT_DOCUMENTS):
            path = BASE / name
            if not path.is_file():
                raise FileNotFoundError("Required frozen Root document is missing: " + name)
            documents.append({"path": name, "bytes": path.stat().st_size, "sha256": sha(path)})
    manifest = {"schema": "sternenbuergerchen.hud_architecture_20261106.qa.v1",
                "base": plan.get("base"), "approved_final_run": plan["approved_final_run"],
                "copy_policy": "Exact original bytes, no image editing. Large raw JSONs/sources may be archive-only.",
                "source_binding_policy": "Run reports and Root binding describe actual inputs; output hashes are separate. No current source is substituted for a baseline.",
                "files": files, "documents": documents,
                "main_receipt_policy": "Separate mutable Root receipt, excluded from frozen payload hashes; no ZIP rebuild after Main."}
    (BASE / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
                                         encoding="utf-8", newline="\n")
    if args.stage_only:
        print(json.dumps({"status": "STAGED_RAW_ONLY_DOCUMENTS_PENDING", "files": len(files),
                          "copied_bytes": sum(item["bytes"] for item in files if item["storage"] == "copy")}))
        return 0
    immutable = [BASE / "manifest.json", BASE / "build_package.py", BASE / "verify_package.py", BASE / "package_plan.json"]
    immutable += [BASE / item["path"] for item in documents]
    document_pins = {item["path"]: item for item in documents}
    pinned_bytes = {}
    for path in immutable:
        relative = path.relative_to(BASE).as_posix()
        data = path.read_bytes()
        pin = document_pins.get(relative)
        if pin and (len(data) != pin["bytes"] or hashlib.sha256(data).hexdigest() != pin["sha256"]):
            raise ValueError("Root document changed before archive: " + relative)
        pinned_bytes[relative] = data
    index = "\n".join(hashlib.sha256(data).hexdigest() + "  " + relative
                      for relative, data in pinned_bytes.items()) + "\n"
    (BASE / "SHA256SUMS.txt").write_text(index, encoding="utf-8", newline="\n")
    pinned_bytes["SHA256SUMS.txt"] = index.encode("utf-8")
    temp = BASE / (ZIP_NAME + ".building")
    with zipfile.ZipFile(temp, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as packed:
        for entry in files:
            original = PROJECT / entry["original_path"]
            if sha(original) != entry["sha256"]:
                raise ValueError("Source changed before compression")
            packed.write(original, BASE.name + "/" + entry["path"])
            if sha(original) != entry["sha256"]:
                raise ValueError("Source changed during compression")
        for relative, data in pinned_bytes.items():
            if (BASE / relative).read_bytes() != data:
                raise ValueError("Immutable input changed before archive write: " + relative)
            packed.writestr(BASE.name + "/" + relative, data)
            if (BASE / relative).read_bytes() != data:
                raise ValueError("Immutable input changed during archive write: " + relative)
    os.replace(temp, archive)
    with zipfile.ZipFile(archive) as packed:
        members = len(packed.infolist())
        unpacked = sum(item.file_size for item in packed.infolist())
    total = sum(path.stat().st_size for path in BASE.rglob("*") if path.is_file())
    receipt = {"schema": "sternenbuergerchen.hud_qa_zip_receipt.v1", "path": ZIP_NAME,
               "bytes": archive.stat().st_size, "sha256": sha(archive), "members": members,
               "uncompressed_bytes": unpacked, "package_bytes_before_receipt": total,
               "budget_bytes": int(plan.get("budget_bytes", 25 * 1048576)),
               "main_receipt": "Separate mutable receipt owned by Root."}
    (BASE / "zip_receipt.json").write_text(json.dumps(receipt, ensure_ascii=False, indent=2) + "\n",
                                            encoding="utf-8", newline="\n")
    print(json.dumps(receipt))
    return 0 if total <= receipt["budget_bytes"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
