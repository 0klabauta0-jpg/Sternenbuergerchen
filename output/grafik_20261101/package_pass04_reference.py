"""Preserve the actually viewed Thedus image as an offline visual reference."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path("C:/Users/bjoer/Downloads/HDMS_Thedus.png")
TARGET = ROOT / "docs/reports/assets/grafik-2026-11-01/references/pass04/HDMS_Thedus.png"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    if TARGET.exists():
        if sha(TARGET) != sha(SOURCE):
            raise ValueError("Refusing to overwrite a different preserved Thedus original")
    else:
        shutil.copyfile(SOURCE, TARGET)
    assert sha(TARGET) == sha(SOURCE)
    with Image.open(TARGET) as image:
        dimensions = list(image.size)
    data = {
        "schema": "sternenbuergerchen.graphics_pass04_visual_reference.v1",
        "task": "docs/tasks/ART_2026_11_01_pass04.md",
        "references": [{
            "id": "ref_thedus", "title": "HDMS-Thedus · Außenposten-Pads",
            "source_path": SOURCE.as_posix(), "package_path": TARGET.relative_to(ROOT).as_posix(),
            "sha256": sha(TARGET), "bytes": TARGET.stat().st_size, "dimensions": dimensions,
            "copy_byte_identical": True, "artwork_modified": False,
            "image_url": "https://media.starcitizen.tools/d/d3/HDMS_Thedus.png",
            "page_url": "https://starcitizen.tools/HDMS-Thedus",
            "attribution": "Community-gehosteter Star-Citizen-Ingame-Screenshot, Star Citizen Wiki; historische visuelle Vorlage, keine offizielle aktuelle Technikquelle.",
            "assignment": "Pad-/Außenpostenform: flache rechteckige Metalldecks mit kleinen Fasen, gebrochenen Landelinien, niedrigen Randlichtern und seitlichen Zugangsrampen.",
            "scope": "visual reference only; no model geometry imported and no game/performance/technical specifications inferred",
            "license_note": "Underlying Star Citizen game image; no Kenney CC0 license attribution inferred.",
        }],
    }
    output = ROOT / "output/grafik_20261101/pass04_reference_manifest.json"
    output.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"manifest": str(output), "sha256": sha(TARGET), "dimensions": dimensions, "byte_identical": True}))


if __name__ == "__main__":
    main()
