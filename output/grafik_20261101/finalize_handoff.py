"""Record immutable code, native captures and bounded verification for the handoff."""
import hashlib
import json
import subprocess
from pathlib import Path
from next_art_steps import STEPS

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = ROOT / "output/grafik_20261101"
CODE_COMMIT = "3e58cc1887883be9db221eb42fea19aa362aa890"
CHECKS = PACKAGE / "check_runs/20261101T130304Z-pid107088/metadata/report.json"


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write(name, value):
    (PACKAGE / name).write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


checks = read(CHECKS)
assert len(checks["checks"]) == 14 and all(c["passed"] for c in checks["checks"])
movement = read(PACKAGE / "hex_movement_verification.json")
assert movement["passed"] == 25 and movement["failed"] == 0
capture = read(PACKAGE / "frontier_engine_capture.json")
assert len(capture["captures"]) == 6
capture_files = []
for item in capture["captures"]:
    path = ROOT / item["path"].removeprefix("res://")
    assert path.is_file()
    capture_files.append({"id": item["id"], "path": path.relative_to(ROOT).as_posix(), "sha256": digest(path)})
remote_commit = subprocess.check_output(
    ["git", "rev-parse", "origin/task/grafikreferenzen-20261101"], cwd=ROOT, text=True
).strip()
subprocess.run(["git", "merge-base", "--is-ancestor", CODE_COMMIT, remote_commit], cwd=ROOT, check=True)
browser = read(PACKAGE / "browser_qa/browser_qa.json")
mobile = read(PACKAGE / "browser_qa/mobile_notes_followup.json")
roadmap = read(PACKAGE / "browser_qa/roadmap_section.json")
assert all(item["pass"] for item in browser["checks"]) and mobile["pass"]
assert all(item["pass"] for item in roadmap["checks"])
assert browser["html_sha256_start"] == browser["html_sha256_end"] == digest(ROOT / "docs/reports/STERNENBUERGERCHEN_GRAFIK_2026-11-01.html")
write("next_art_steps.json", {"status": "proposed_next_pass_not_implemented", "citizen_base": "provisional Kenney astronauts; future armor and appearance changes requested", "steps": STEPS})
write("final_verification_manifest.json", {
    "schema": "sternenbuergerchen.graphics_handoff.v1",
    "code_commit": CODE_COMMIT,
    "code_commit_pushed": True,
    "branch": "task/grafikreferenzen-20261101",
    "strict_engine_report": CHECKS.relative_to(ROOT).as_posix(),
    "strict_engine_report_sha256": digest(CHECKS),
    "checks_passed": 14,
    "checks_failed": 0,
    "movement_assertions_passed": 25,
    "movement_trials": 12,
    "native_capture_files": capture_files,
    "browser_report": "output/grafik_20261101/browser_qa/browser_qa.json",
    "browser_html_sha256": browser["html_sha256_start"],
    "browser_checks_passed": len(browser["checks"]),
    "mobile_notes_checks_passed": len(mobile["checks"]),
    "next_art_section_checks_passed": len(roadmap["checks"]),
    "next_art_section_report": "output/grafik_20261101/browser_qa/roadmap_section.json",
    "browser_status_note": "Full functional QA passed at the exact current HTML SHA-256, unchanged throughout that run.",
    "import_note": "Headless editor import exit 0; existing MCP-plugin ObjectDB shutdown warning. Native preview and all 14 strict checks contain no runtime/script errors or leak reports.",
    "scope": "First synthetic native hex base, shared versioned hex foundation, three structures, four original Kenney astronauts. Existing campaign/editor content and six-edge wall authoring are not fully migrated. Ships remain 2D targets; old raw 3D material studies failed geometry QA and are not runtime assets."
})
write("report_validation.json", {
    "local_checks": "14/14 strenge Godot-Prüfläufe bestanden: Hex-Grundlage 41/41, Bewegung 25/25, Render/Picking 33/33, Sicht 76/76 sowie Grafikprofil, Integration und bestehende Authority-/Multiplayer-/Legacy-Prüfungen. Zwölf Bewegungsversuche in sechs Richtungen, jeweils mit/ohne Avoidance, dauern gleichmäßig 108 Ticks. Originale Kenney-Exporte und drei Strukturen mit Asset-QA; sechs echte Vulkan-Ansichten. Browser: 58/58 Funktionsprüfungen plus 3/3 mobile Notizprüfungen bestanden; exakte HTML-Hashes und Abschlusslauf stehen in browser_qa.",
    "git_status": "Implementierung auf task/grafikreferenzen-20261101, Code-Commit 3e58cc1887883be9db221eb42fea19aa362aa890, erfolgreich nach origin gepusht. HTML/Belege werden anschließend als eigenes Übergabepaket gesichert. Keine Integration nach main."
})
print(f"Recorded {len(checks['checks'])} strict checks and {len(capture_files)} native captures for {CODE_COMMIT[:9]}.")
