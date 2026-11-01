"""Record immutable implementation and exact native comparison files for Pass02."""
import hashlib
import json
import subprocess
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = ROOT / "output/grafik_20261101"
CODE = "4e21697fce43aa2cf89da3f8d527bd48d09b4d58"
CHECKS = PACKAGE / "pass02_check_runs/20261101T135343Z-pid108400/metadata/report.json"


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


check = read(CHECKS)
assert check["summary"] == {"selected": 15, "passed": 15, "failed": 0}
remote = subprocess.check_output(["git", "rev-parse", "origin/task/grafikreferenzen-20261101"], cwd=ROOT, text=True).strip()
subprocess.run(["git", "merge-base", "--is-ancestor", CODE, remote], cwd=ROOT, check=True)
after = read(PACKAGE / "pass02_after_capture.json")
assert after["report_ready"] and after["missing_asset_mapping_count"] == 0
assert len(after["captures"]) == 7
for path, digest in after["runtime_sources_sha256"].items():
    assert sha(ROOT / path.removeprefix("res://")) == digest, path
for model in after["models"]:
    assert sha(ROOT / model["path"].removeprefix("res://")) == model["source_sha256"]
before = read(PACKAGE / "pass02_before_capture.json")
before_cameras = {c["id"]: c for c in before["captures"]}
after_cameras = {c["id"]: c for c in after["captures"]}
pairs = []
for view in ("overview", "workshop", "crew", "hex_grid"):
    original = ROOT / f"docs/reports/assets/grafik-2026-11-01/engine_pass/{view}.png"
    old = ROOT / f"docs/reports/assets/grafik-2026-11-01/engine_pass02/before/{view}.png"
    new = ROOT / f"docs/reports/assets/grafik-2026-11-01/engine_pass02/after/{view}.png"
    assert sha(old) == sha(original)
    with Image.open(old) as a, Image.open(new) as b:
        assert a.size == b.size == (1600, 900)
    assert before_cameras[view]["camera_size"] == after_cameras[view]["camera_size"]
    pairs.append({"view": view, "before": old.relative_to(ROOT).as_posix(), "before_sha256": sha(old), "after": new.relative_to(ROOT).as_posix(), "after_sha256": sha(new), "camera_size": after_cameras[view]["camera_size"]})
result = {
    "schema": "sternenbuergerchen.graphics_pass02_verification.v1",
    "code_commit": CODE, "code_commit_pushed": True,
    "based_on_unintegrated_graphics_branch": "task/grafikreferenzen-20261101",
    "previous_handoff_commit": "93bdf43ff0355df44e22a9b09b04d5e138a3639b",
    "engine_report": CHECKS.relative_to(ROOT).as_posix(), "engine_checks_passed": 15,
    "pass02_assertions_passed": 27, "native_captures": 7,
    "pairs": pairs, "renderer_match": before["renderer"] == after["renderer"],
    "lighting_deliberately_changed": before["light"] != after["light"],
    "additional_after_only_view": "landscape",
    "asset_source_qa": "art/frontier_illustrated_20261101/structures/manifest.json",
    "citizen_source_qa": "art/frontier_illustrated_20261101/citizens/pass02/manifest.json",
    "reference_manifest": "output/grafik_20261101/reference_manifest.json",
    "scope": "Native synthetic Hex base graphics pass; not complete campaign/editor migration, no interior/logistics simulation, no ship model adoption or release acceptance.",
    "remaining_visual_differences": "Cliffs remain more regular and the scene less dense than the concepts. Cutaway rooms, Freihafen hall ensemble and complete terrain composition are not implemented by this pass."
}
browser = PACKAGE / "browser_qa_pass02/browser_qa.json"
if browser.is_file():
    qa = read(browser)
    assert qa.get("checks") and all(row["pass"] for row in qa["checks"])
    assert not qa.get("console_errors") and not qa.get("page_errors") and not qa.get("external_requests")
    assert qa["html_sha256_start"] == qa["html_sha256_end"] == sha(ROOT / "docs/reports/STERNENBUERGERCHEN_GRAFIK_2026-11-01.html")
    result["browser_qa"] = str(browser.relative_to(ROOT)).replace("\\", "/")
    result["browser_qa_html_sha256"] = qa["html_sha256_end"]
    result["browser_checks_passed"] = len(qa["checks"])
write(PACKAGE / "pass02_verification_manifest.json", result)
validation = read(PACKAGE / "report_validation.json")
validation.update({
    "pass02_local_checks": "Pass02: 15/15 strenge Godot-Prüfläufe bestanden; neuer Grafik-/Owner-/Geologie-Verifier 27/27. Source-QA, Posen und frischer GLB-Roundtrip für drei Strukturen und vier Ausrüstungskandidaten bestanden. Sieben native Vulkan-Aufnahmen, vier Vorher/Nachher-Paare bei gleichen Kameras und 1600×900. Vorher-PNGs bytegleich erhalten; Licht bewusst überarbeitet. Browsernachweise werden separat mit dem exakten HTML-Hash geführt.",
    "pass02_git_status": f"Pass02-Code {CODE} auf task/grafikreferenzen-20261101 erfolgreich gepusht. Bewusste Fortsetzung des noch nicht integrierten Grafikstands 93bdf43ff; HTML/Browserbelege bilden ein eigenes Übergabepaket. Keine Main-Integration."
})
write(PACKAGE / "report_validation.json", validation)
print("Pass02: 15/15 engine checks, 7 native images, 4 immutable comparison pairs verified.")
