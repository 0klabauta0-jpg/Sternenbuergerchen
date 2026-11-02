"""Pin native Pass03 artifacts; browser verification is a separate final phase."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = ROOT / "output/grafik_20261101"
parser = argparse.ArgumentParser()
parser.add_argument("--code-commit", required=True)
parser.add_argument("--engine-report", required=True)
parser.add_argument("--include-browser", action="store_true")
args = parser.parse_args()


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


code = subprocess.check_output(["git", "rev-parse", args.code_commit], cwd=ROOT, text=True).strip()
subprocess.run(["git", "merge-base", "--is-ancestor", code, "origin/task/grafikreferenzen-20261101"], cwd=ROOT, check=True)
checks_path = ROOT / args.engine_report
checks = read(checks_path)
assert checks["summary"]["selected"] > 0 and checks["summary"]["failed"] == 0
assert all(row["passed"] for row in checks["checks"])
after = read(PACKAGE / "pass03_after_capture.json")
before = read(PACKAGE / "pass03_before_capture.json")
assert after["report_ready"] and after["missing_asset_mapping_count"] == 0
for path, digest in after["runtime_sources_sha256"].items():
    assert sha(ROOT / path.removeprefix("res://")) == digest, path
for model in after["models"]:
    assert sha(ROOT / model["path"].removeprefix("res://")) == model["source_sha256"]
before_cameras = {row["id"]: row for row in before["captures"]}
after_cameras = {row["id"]: row for row in after["captures"]}
pairs = []
for view in ("overview", "workshop", "crew", "hex_grid", "landscape"):
    original = ROOT / f"docs/reports/assets/grafik-2026-11-01/engine_pass02/after/{view}.png"
    old = ROOT / f"docs/reports/assets/grafik-2026-11-01/engine_pass03/before/{view}.png"
    new = ROOT / f"docs/reports/assets/grafik-2026-11-01/engine_pass03/after/{view}.png"
    assert sha(old) == sha(original)
    with Image.open(old) as a, Image.open(new) as b:
        assert a.size == b.size == (1600, 900)
    for field in ("camera_size", "camera_transform", "camera_projection", "viewport_size"):
        assert before_cameras[view][field] == after_cameras[view][field], (view, field)
    pairs.append({"view": view, "before": old.relative_to(ROOT).as_posix(), "before_sha256": sha(old), "after": new.relative_to(ROOT).as_posix(), "after_sha256": sha(new), "camera_size": after_cameras[view]["camera_size"]})
assert before["renderer"] == after["renderer"]
assert before["light"] == after["light"]
archive = ROOT / "docs/reports/STERNENBUERGERCHEN_GRAFIK_PASS02_2026-11-01.html"
assert sha(archive) == "97a79d60ae65a3178f037ad226c082c46ce5e773b59e9484a225293ee83879c9"
result = {
    "schema": "sternenbuergerchen.graphics_pass03_verification.v1",
    "code_commit": code, "code_commit_pushed": True,
    "based_on_unintegrated_graphics_branch": "task/grafikreferenzen-20261101",
    "previous_handoff_commit": "7a37f5d9a", "engine_report": args.engine_report,
    "engine_checks_passed": checks["summary"]["passed"],
    "native_captures": len(after["captures"]), "pairs": pairs,
    "renderer_match": True, "lighting_match": True, "camera_transforms_match": True,
    "archived_pass02_html_sha256": sha(archive),
    "structure_manifest": "art/frontier_illustrated_20261101/structures/pass03/manifest.json",
    "scope": "Native synthetic Hex base graphics pass; static cutaway and Freihafen ensemble, no interior/logistics/vehicle simulation or campaign/editor migration.",
    "remaining_visual_differences": "A simplified candidate ensemble. Broader composition, richer terrain transitions and more varied use groups remain; no ship model adoption or general art/release acceptance."
}
if args.include_browser:
    qa = read(PACKAGE / "browser_qa_pass03/browser_qa.json")
    assert qa.get("checks") and all(row["pass"] for row in qa["checks"])
    assert not qa.get("console_errors") and not qa.get("page_errors") and not qa.get("external_requests")
    assert qa["html_sha256_start"] == qa["html_sha256_end"] == sha(ROOT / "docs/reports/STERNENBUERGERCHEN_GRAFIK_2026-11-01.html")
    result.update(browser_report="output/grafik_20261101/browser_qa_pass03/browser_qa.json", browser_checks_passed=len(qa["checks"]), browser_html_sha256=qa["html_sha256_end"])
write(PACKAGE / "pass03_verification_manifest.json", result)
validation = read(PACKAGE / "report_validation.json")
validation.update({
    "pass03_local_checks": f"Pass03: {checks['summary']['passed']}/{checks['summary']['selected']} strenge Godot-Prüfläufe bestanden. Source-/frische GLB-Roundtrip-QA für Cutaway und Halle; echte Kenney-Bauteile mit Herkunft und Anpassungen im Modellmanifest. Fünf native Vorher/Nachher-Paare bei identischer Kamera, Beleuchtung, Vulkan-Renderer und 1600×900. Pass02-PNGs und alter HTML-Report bytegleich erhalten. Browsernachweise separat am exakten HTML-Hash.",
    "pass03_git_status": f"Pass03-Code {code} auf task/grafikreferenzen-20261101 erfolgreich gepusht. Bewusste Fortsetzung des noch nicht integrierten Grafikstands 7a37f5d9a; HTML/Browserbelege bilden ein eigenes Übergabepaket. Keine Main-Integration."
})
write(PACKAGE / "report_validation.json", validation)
print(f"Pass03: {checks['summary']['passed']} engine checks and five unchanged-condition native pairs verified.")
