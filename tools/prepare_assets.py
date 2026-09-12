"""Copy the exact CC0 subset, including external glTF textures, unchanged.

Run from any directory with Python 3. Source assets are never written.
"""
import json
import shutil
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(r"C:\Users\bjoer\Pictures\Kenney Game Assets All-in-1 3.4.0\3D assets")
PACKS = {
    "Space Station Kit": ("space-station", "GLB format", ["floor", "wall", "bed-single", "door-single", "computer", "computer-wide"]),
    "Survival Kit": ("survival", "GLB format", ["workbench"]),
    "Space Kit": ("space", "GLTF format", ["craft_cargoA"]),
    "Blaster Kit": ("blaster", "GLB format", ["crate-wide", "crate-small"]),
}

for pack, (slug, format_dir, models) in PACKS.items():
    source = SOURCE / pack / "Models" / format_dir
    target = ROOT / "assets" / "curated" / slug
    target.mkdir(parents=True, exist_ok=True)
    license_dir = ROOT / "assets" / "licenses"
    license_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SOURCE / pack / "License.txt", license_dir / (pack.replace(" ", "-") + ".txt"))
    for model in models:
        original = source / (model + ".glb")
        shutil.copy2(original, target / original.name)
        data = original.read_bytes()
        length = struct.unpack_from("<I", data, 12)[0]
        gltf = json.loads(data[20:20 + length])
        for image in gltf.get("images", []):
            uri = image.get("uri", "")
            if not uri or uri.startswith("data:"):
                continue
            if ".." in Path(uri).parts or Path(uri).is_absolute():
                raise ValueError("Unexpected external texture path: " + uri)
            destination = target / uri
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source / uri, destination)
        print(slug + "/" + original.name)
