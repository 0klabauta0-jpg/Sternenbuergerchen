"""Freeze the editable native ground/paint sources, not a generated concept image."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TARGET = ROOT / "art/frontier_illustrated_20261101/environment/pass06/ground_paint"
SOURCES = [
    "shaders/terrain/frontier_ground.gdshader",
    "shaders/terrain/frontier_contact_paint.gdshader",
    "scripts/terrain/frontier_art_dressing.gd",
    "scripts/tests/frontier_pass06_environment_verifier.gd",
]
REFERENCES = [
    "docs/reports/assets/grafik-2026-11-01/references/current/01_rostgrenze_cutaway.png",
    "docs/reports/assets/grafik-2026-11-01/references/current/02_freihafen_distribution_center.png",
    "docs/reports/assets/grafik-2026-11-01/references/current/03_taktische_rostwelt_gesamtkarte.png",
]


def fact(path):
    p = ROOT / path
    return {"path": path, "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}


TARGET.mkdir(parents=True, exist_ok=True)
for source in SOURCES:
    (TARGET / Path(source).name).write_bytes((ROOT / source).read_bytes())
manifest = {
    "schema": "sternenbuergerchen.art_pass06_ground_paint.v1",
    "status": "Native Godot shader/dressing revision on unintegrated graphics branch; no user art approval.",
    "based_on": "04e934f60",
    "sources": [fact(p) for p in SOURCES],
    "references": [fact(p) for p in REFERENCES],
    "scope": ["soft multiscale pigment/silt fields", "localized cliff wash and broken strata paint", "paving aggregate scuff and selective marking loss", "broken dusty object contact banks"],
    "geometry_route": "Existing continuous flat plane and unchanged road/apron geometry. Real blocked-area relief belongs to the separate geology package.",
    "preserved": "Nine primary GLBs, original characters/animation, shared light, Hex facts, actor starts and cameras.",
    "material_route": "World-coordinate integer hash noise; shared/cached ShaderMaterial for soil, cliffs, paving and marking colors. No per-frame mesh rebuilding.",
    "limits": "Procedural paint; no hand-painted texture bake. Walkable soil remains flat. Fine painted wear is intentionally quieter at strategic distance.",
}
(TARGET / "manifest.json").write_bytes((json.dumps(manifest, indent=2, ensure_ascii=False) + "\n").encode("utf-8"))
(TARGET / "README.md").write_bytes("""# Pass06 Boden und Materialabrieb

Editierbare native Quellen sind bytegleiche Schnappschuesse der im Manifest
genannten Runtime-Dateien. Die neuen Bilder entstehen in Godot, nicht im
Bildgenerator. Vorherbilder sind echte P05-Aufnahmen, keine simulierte alte
Shaderansicht. Finaler technischer Nachweis und native Kamera-/Bildhashes:
output/grafik_20261101/pass06_environment_verification_manifest.json.

Nach einer nativen Probe wurden auffaellige Konturlinien und gestreifte
Pigmentfelder verworfen. Der finale Boden behaelt ruhige breite Flaechen mit
weichen, gebrochenen Ablagerungen. Paving bekommt matte Abriebfelder, 78
Weg-/Vorplatzmarkierungen verlieren selektiv kleine Lackstellen.

Die begehbaren Flaechen, Bodenhoehen und Modelle bleiben unveraendert. Neues
echtes Relief ist gesondert im Geologiepaket dokumentiert. Keine Main- oder
allgemeine Art-/Performance-Abnahme.
""".encode("utf-8"))
print(f"Packaged {len(SOURCES)} editable ground/paint sources and {len(REFERENCES)} hashed targets.")
