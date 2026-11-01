"""Pin native Pass05 environment artifacts; browser verification is a separate final phase."""
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
after = read(PACKAGE / "pass05_environment_after_capture.json")
before = read(PACKAGE / "pass05_environment_before_capture.json")
assert after["report_ready"] and after["report_revision"] == "env05" and after["missing_asset_mapping_count"] == 0
assert len(after["captures"]) == 20 and after["canonical_star_citizen_dimensions"] is False
assert all("/ships_pass04_r02/" in model["path"] for model in after["models"] if model["id"] in ("cutlass_01","buccaneer_01"))
for path, digest in after["runtime_sources_sha256"].items():
    assert sha(ROOT / path.removeprefix("res://")) == digest, path
    committed = subprocess.check_output(["git", "show", code + ":" + path.removeprefix("res://")], cwd=ROOT)
    assert hashlib.sha256(committed).hexdigest() == digest, (path, "committed source mismatch")
for model in after["models"]:
    assert sha(ROOT / model["path"].removeprefix("res://")) == model["source_sha256"]
before_models = {row["id"]: row["source_sha256"] for row in before["models"]}
assert before_models == {row["id"]: row["source_sha256"] for row in after["models"]}
for source in after["worklife_sources"]:
    for path_key, hash_key in (("path", "source_sha256"), ("license_path", "license_sha256"), ("atlas_path", "atlas_sha256")):
        assert sha(ROOT / source[path_key].removeprefix("res://")) == source[hash_key]
before_cameras = {row["id"]: row for row in before["captures"]}
after_cameras = {row["id"]: row for row in after["captures"]}
pairs = []
for view in ("overview", "workshop", "crew", "hex_grid", "landscape", "cutaway", "closed_outpost", "closed_habitat", "closed_hall"):
    original = ROOT / f"docs/reports/assets/grafik-2026-11-01/engine_pass04/after/{view}.png"
    old = ROOT / f"docs/reports/assets/grafik-2026-11-01/engine_pass05_environment/before/{view}.png"
    new = ROOT / f"docs/reports/assets/grafik-2026-11-01/engine_pass05_environment/after/{view}.png"
    assert sha(old) == sha(original)
    with Image.open(old) as a, Image.open(new) as b:
        assert a.size == b.size == (1600, 900)
    for field in ("camera_size", "camera_transform", "camera_projection", "viewport_size"):
        assert before_cameras[view][field] == after_cameras[view][field], (view, field)
    pairs.append({"view": view, "before": old.relative_to(ROOT).as_posix(), "before_sha256": sha(old), "after": new.relative_to(ROOT).as_posix(), "after_sha256": sha(new), "camera_size": after_cameras[view]["camera_size"]})
assert before["renderer"] == after["renderer"]
assert before["light"] == after["light"]
archive = ROOT / "docs/reports/STERNENBUERGERCHEN_GRAFIK_PASS04_2026-11-01.html"
assert sha(archive) == "7ae0d52d3b258b2ae17b617d743a734de8ede0bd871b6843166ae559a7cbc5e6"
result = {
    "schema": "sternenbuergerchen.graphics_pass05_environment_verification.v1",
    "code_commit": code, "code_commit_pushed": True,
    "based_on_unintegrated_graphics_branch": "task/grafikreferenzen-20261101",
    "previous_handoff_commit": "fbcac03d1", "engine_report": args.engine_report,
    "engine_checks_passed": checks["summary"]["passed"],
    "native_captures": len(after["captures"]), "pairs": pairs,
    "geology_manifest": "art/frontier_illustrated_20261101/environment/pass05/geology/manifest.json",
    "worklife_sources": after["worklife_sources"], "use_groups": after["use_groups"],
    "primary_glb_hashes_unchanged": True,
    "renderer_match": True, "lighting_match": True, "camera_transforms_match": True,
    "archived_pass04_html_sha256": sha(archive),
    "structure_manifest": "art/frontier_illustrated_20261101/environment/pass05/buildings/manifest.json",
    "scope": "Native synthetic Hex environment: differentiated closed building masses, fractured geology, material/soil contacts and functional use groups with four repositioned original citizens. Original GLB sources unchanged; no new ship, interior, AI or campaign simulation.",
    "remaining_visual_differences": "Building silhouettes and use groups now vary, but terrain remains flat, broad cliff crowns and quieter back faces are simpler, and overall building scale/composition/material weathering remain less rich than2D. No user art approval or general release acceptance.",
    "report_revision": "env05",
    "ship_user_status": "R01 rejected; R02 still criticized as far from 2D targets. Separate Astra Ultra Blender revision commissioned.",
    "ship_followup_chat": "01a197d8-ebd0-7100-8d12-21ff6bc52c0d",
    "ship_manifests": ["art/frontier_illustrated_20261101/ships/pass04_r02/" + ship + "/manifest.json" for ship in ("cutlass", "buccaneer")],
    "rejected_r01": "output/grafik_20261101/pass04_rejected_r01_manifest.json",
    "closed_shell_source": "scripts/terrain/frontier_closed_buildings.gd"
}
if args.include_browser:
    qa = read(PACKAGE / "browser_qa_pass05_environment/browser_qa.json")
    assert qa.get("checks") and all(row["pass"] for row in qa["checks"])
    assert not qa.get("console_errors") and not qa.get("page_errors") and not qa.get("external_requests")
    assert qa["html_sha256_start"] == qa["html_sha256_end"] == sha(ROOT / "docs/reports/STERNENBUERGERCHEN_GRAFIK_2026-11-01.html")
    result.update(browser_report="output/grafik_20261101/browser_qa_pass05_environment/browser_qa.json", browser_checks_passed=len(qa["checks"]), browser_html_sha256=qa["html_sha256_end"])
write(PACKAGE / "pass05_environment_verification_manifest.json", result)
validation = read(PACKAGE / "report_validation.json")
validation.update({
    "pass05_environment_local_checks": f"Pass05 Umgebung: {checks['summary']['passed']}/{checks['summary']['selected']} strenge Godot-Laeufe. 20 native Vulkan-PNGs, neun feste Vorher/Nachher-Kameras mit identischem Globallicht und1600x900; drei neue Detailkameras nurNachher. Eigene Gebaeudegeometrie21/21, Felsvertrag12/12, neue Platzierungs-/Kontaktfakten19/19. GLB-Quellen bleiben hashgleich; Material-/Aufstellungsroute bewusst ueberarbeitet. Technische Pruefung ist keine Nutzer-Artfreigabe.",
    "pass05_environment_git_status": f"Umgebungscode {code} auf weiterhin unintegriertem task/grafikreferenzen-20261101 gepusht; Grundlage fbcac03d1. HTML/Browsernachweise als separates Uebergabepaket. Keine Main-Integration; Astra-Schiffsarbeit bleibt getrennt."
})
write(PACKAGE / "report_validation.json", validation)
print(f"Pass05 environment: {checks['summary']['passed']} engine checks and nine unchanged-condition native pairs verified.")
