"""Build a byte-level manifest for this visual-target package (Python stdlib only)."""

import argparse
import hashlib
import json
import struct
import sys
from pathlib import Path


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def image_dimensions(path):
    """Read PNG/JPEG dimensions without decoding or modifying the image."""
    with path.open("rb") as stream:
        header = stream.read(24)
        if header[:8] == b"\x89PNG\r\n\x1a\n" and header[12:16] == b"IHDR":
            width, height = struct.unpack(">II", header[16:24])
            return {"width": width, "height": height, "format": "PNG"}
        if header[:2] != b"\xff\xd8":
            return None
        stream.seek(2)
        sof_markers = {0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7,
                       0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF}
        while True:
            marker_start = stream.read(1)
            if not marker_start:
                break
            if marker_start != b"\xff":
                continue
            marker_byte = stream.read(1)
            while marker_byte == b"\xff":
                marker_byte = stream.read(1)
            if not marker_byte:
                break
            marker = marker_byte[0]
            if marker in (0xD9, 0xDA):
                break
            if marker == 0x01 or 0xD0 <= marker <= 0xD8:
                continue
            length_data = stream.read(2)
            if len(length_data) != 2:
                break
            length = struct.unpack(">H", length_data)[0]
            if length < 2:
                break
            if marker in sof_markers:
                frame = stream.read(5)
                if len(frame) != 5:
                    break
                height, width = struct.unpack(">HH", frame[1:5])
                return {"width": width, "height": height, "format": "JPEG"}
            stream.seek(length - 2, 1)
    return None


def local_path(root, relative):
    path = (root / relative).resolve()
    if not path.is_relative_to(root):
        raise ValueError("Datei liegt außerhalb des Pakets: " + str(relative))
    return path


def file_record(root, relative, require_image=False):
    path = local_path(root, relative)
    if not path.is_file():
        raise FileNotFoundError("Fehlende Datei: " + relative)
    result = {"file": path.relative_to(root).as_posix(),
              "sha256": sha256(path), "bytes": path.stat().st_size}
    if require_image:
        dimensions = image_dimensions(path)
        if not dimensions or min(dimensions["width"], dimensions["height"]) <= 0:
            raise ValueError("Bildabmessungen nicht lesbar: " + relative)
        result.update(dimensions)
    return result


def build(root):
    prompts = read_json(root / "prompts.json")
    sources = read_json(root / "sources.json")
    errors = []
    active = []
    superseded = []
    source_records = []
    known_images = set()
    seen_ids = set()

    for status, items, target in (("active_visual_target", prompts["items"], active),
                                  ("superseded_visual_target", prompts.get("superseded", []), superseded)):
        for item in items:
            name = item["file"]
            if name in known_images:
                errors.append("Doppelter Bilddateieintrag: " + name)
            known_images.add(name)
            if status == "active_visual_target":
                if item["id"] in seen_ids:
                    errors.append("Doppelte aktive Bild-ID: " + str(item["id"]))
                seen_ids.add(item["id"])
            try:
                target.append({**item, **file_record(root, name, True),
                               "package_status": status,
                               "native_game_capture": False,
                               "user_approved": False})
            except (OSError, ValueError) as exc:
                errors.append(str(exc))

    for source in sources["sources"]:
        try:
            record = file_record(root, source["file"], True)
            if record["sha256"] != source["sha256"]:
                errors.append("Referenzkopie weicht vom dokumentierten Original ab: " + source["file"])
            original = Path(source["source_path"])
            is_remote = source["source_path"].startswith(("https://", "http://"))
            original_available = not is_remote and original.is_file()
            original_matches = sha256(original) == source["sha256"] if original_available else None
            if original_matches is False:
                errors.append("Originalquelle wurde seit der Sicherung verändert: " + source["source_path"])
            source_records.append({**source, **record,
                                   "original_available_at_manifest_build": original_available,
                                   "original_matches_recorded_sha256": original_matches})
        except (OSError, ValueError) as exc:
            errors.append(str(exc))

    extras = []
    for path in sorted(root.iterdir()):
        if path.is_file() and path.suffix.lower() in {".png", ".jpg", ".jpeg"} and path.name not in known_images:
            try:
                extras.append({**file_record(root, path.name, True), "package_status": "not_assigned_in_prompts"})
            except (OSError, ValueError) as exc:
                errors.append(str(exc))

    documents = []
    generation_metadata = None
    for name in ("prompts.json", "sources.json", "README.md", "build_manifest.py",
                 "generation_metadata.json", "BILDPRUEFUNG.md", "GALERIE_QA.md",
                 "RAUMKARTEN_RECHERCHE.md", "POLISAR_BLENDER_AUFTRAG.md",
                 "space_revision_prompts.json", "space_revision_generation.json",
                 "space_final_generation.json", "station_revision_prompt.json",
                 "station_annotated_revision_prompt.json", "station_annotated_revision_generation.json"):
        if (root / name).is_file():
            documents.append(file_record(root, name))
            if name == "generation_metadata.json":
                generation_metadata = read_json(root / name)

    if errors:
        raise ValueError("Paket unvollständig oder verändert:\n- " + "\n- ".join(errors))

    return {
        "schema": "sternenbuergerchen.visual_target_package_manifest.v1",
        "date": prompts["date"],
        "tool": prompts["tool"],
        "base_commit": prompts.get("base_commit"),
        "reference_working_head": prompts.get("reference_working_head"),
        "complete": True,
        "scope": "KI-Zielbilder; Boden-Stilrichtung positiv bestätigt, neue Raumkarten zur Bewertung. Keine native Modellabnahme. Native Aufnahmen nur als getrennte Referenzquellen.",
        "reference_mode": sources["new_generation_reference_mode"],
        "validation": "SHA-256, Dateiexistenz und PNG/JPEG-Abmessungen; keine geometrische oder gestalterische Abnahme",
        "counts": {"active": len(active), "superseded": len(superseded),
                   "sources": len(source_records), "additional_images": len(extras)},
        "active_images": active,
        "superseded_images": superseded,
        "sources": source_records,
        "additional_images": extras,
        "documents": documents,
        "generation_metadata": generation_metadata,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent)
    parser.add_argument("--check", action="store_true", help="Prüfen, ohne manifest.json zu schreiben")
    args = parser.parse_args()
    root = args.root.resolve()
    try:
        manifest = build(root)
        if not args.check:
            (root / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    except (OSError, ValueError, KeyError) as exc:
        print(str(exc), file=sys.stderr)
        return 2
    print(json.dumps({"ok": True, "written": not args.check, "counts": manifest["counts"]}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
