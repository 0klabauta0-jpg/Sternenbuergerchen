"""Preserve the four rejected native R01 ship views without changing originals."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "docs/reports/assets/grafik-2026-11-01/engine_pass04"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def preserve(source, target):
    original_hash = digest(source)
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        if digest(target) != original_hash:
            raise ValueError(f"Refusing to overwrite a different archived R01 file: {target}")
    else:
        shutil.copyfile(source, target)
    if digest(source) != original_hash or digest(target) != original_hash:
        raise ValueError(f"R01 file changed during preservation: {source}")
    return original_hash


def main():
    rows = []
    for ship in ("cutlass", "buccaneer"):
        for view in ("front", "rear"):
            source = ART / "after" / f"{ship}_{view}.png"
            target = ART / "rejected_r01" / source.name
            if not source.is_file():
                raise FileNotFoundError(source)
            rows.append({"id": f"rejected_r01_{ship}_{view}", "ship": ship, "view": view,
                         "source_path": source.relative_to(ROOT).as_posix(),
                         "archive_path": target.relative_to(ROOT).as_posix(),
                         "sha256": preserve(source, target), "copy_byte_identical": True,
                         "status": "user_rejected_r01", "current_model_approval": False})
    source_metadata = ROOT / "output/grafik_20261101/pass04_after_capture.json"
    metadata_copy = ROOT / "output/grafik_20261101/pass04_rejected_r01_capture.json"
    metadata_hash = preserve(source_metadata, metadata_copy)
    data = {"schema": "sternenbuergerchen.graphics_rejected_revision.v1", "pass": "04", "revision": "r01",
            "status": "explicitly_rejected_by_user", "views": rows,
            "source_manifest": "art/frontier_illustrated_20261101/ships/pass04/manifest.json",
            "capture_metadata_archive": metadata_copy.relative_to(ROOT).as_posix(),
            "capture_metadata_sha256": metadata_hash,
            "notes": ["The user explicitly rejected both R01 ships; technical/source checks are historical evidence, not visual acceptance.",
                      "Archived raw capture metadata retains its original paths. This manifest relocates the four ship PNGs to rejected_r01.",
                      "R02 report decisions and notes use a new namespace; these rejected views must never activate as the current R02 model."]}
    output = ROOT / "output/grafik_20261101/pass04_rejected_r01_manifest.json"
    output.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"archived_ship_views": len(rows), "all_byte_identical": True,
                      "status": data["status"], "manifest": str(output)}))


if __name__ == "__main__":
    main()
