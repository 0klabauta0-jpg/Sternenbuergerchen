"""Pin P06 evidence after Root's freeze. Git calls are read-only; no commit/push."""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess

from pass06_environment_common import ROOT, PACKAGE, ARCHIVE_SHA, load_package, local, read, sha


def write(path, value):
    path.write_bytes((json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--code-commit", required=True)
    parser.add_argument("--engine-report", required=True)
    parser.add_argument("--remote-ref", default="origin/task/grafikreferenzen-20261101")
    parser.add_argument("--include-browser", action="store_true")
    args = parser.parse_args()
    pack = load_package(require_release=True)
    code = subprocess.check_output(["git", "rev-parse", args.code_commit], cwd=ROOT, text=True).strip()
    subprocess.run(["git", "merge-base", "--is-ancestor", code, args.remote_ref], cwd=ROOT, check=True)
    checks = read(ROOT / args.engine_report)
    assert checks["summary"]["selected"] > 0 and checks["summary"]["failed"] == 0
    assert checks["checks"] and all(row["passed"] for row in checks["checks"])
    after = pack["after_metadata"]
    for path, digest in after["runtime_sources_sha256"].items():
        committed = subprocess.check_output(["git", "show", code + ":" + path.removeprefix("res://")], cwd=ROOT)
        assert hashlib.sha256(committed).hexdigest() == digest == sha(local(path)), path
    result = {
        "schema": "sternenbuergerchen.graphics_pass06_environment_verification.v1",
        "report_revision": "env06", "code_commit": code, "code_commit_pushed": True,
        "based_on_unintegrated_graphics_branch": "task/grafikreferenzen-20261101",
        "previous_handoff_commit": "04e934f60", "engine_report": args.engine_report,
        "engine_report_sha256": sha(ROOT / args.engine_report),
        "engine_checks_passed": checks["summary"]["passed"],
        "engine_checks_selected": checks["summary"]["selected"],
        "native_captures": len(pack["captures"]), "capture_records": pack["captures"], "pairs": pack["pairs"],
        "runtime_sources_sha256": after["runtime_sources_sha256"],
        "after_capture_sha256": sha(PACKAGE / "pass06_environment_after_capture.json"),
        "before_capture_sha256": sha(PACKAGE / "pass06_environment_before_capture.json"),
        "before_manifest": "output/grafik_20261101/pass06_environment_before_manifest.json",
        "before_manifest_sha256": sha(PACKAGE / "pass06_environment_before_manifest.json"),
        "archived_pass05_html_sha256": ARCHIVE_SHA,
        "source_packages": {name: {"path": row["path"], "sha256": row["sha256"]} for name, row in pack["source_packages"].items()},
        "primary_glb_hashes_unchanged": True, "raw_stock_sources_unchanged": True,
        "renderer_match": True, "lighting_match": True, "camera_transforms_match": True,
        "material_route": "Intentionally revised: ground/rock/building wear is part of P06, not a constant material assumption.",
        "scope": "Relief limited to protected geology envelopes; finer erosion and material wear. Playable hex centers, paths/pads, height/LOS facts, ships/citizens/Astra and global lighting are not migrated.",
        "remaining_visual_differences": "Playable ground remains flat and real relief is limited to the existing protected geology envelopes. Cliff masses/crowns remain broad and prismatic. The2Dreferences retain more small depressions, denser usage detail and richer composition. Wear concerns authored closed shells; original GLB cutaways/citizens/ships remain unchanged. Technical checks are not user artistic or general performance/release acceptance.",
        "ship_user_status": "Retained criticized R02 models; separate Astra work is not automatically adopted.",
    }
    if args.include_browser:
        path = PACKAGE / "browser_qa_pass06_environment/browser_qa.json"
        qa = read(path)
        assert qa.get("status") == "pass" and qa.get("pass") is True
        assert qa.get("visual_inspection", {}).get("pass") is True
        assert qa.get("checks") and all(row["pass"] for row in qa["checks"])
        assert not qa.get("console_errors") and not qa.get("page_errors") and not qa.get("external_requests")
        assert qa["html_sha256_start"] == qa["html_sha256_end"] == sha(ROOT / "docs/reports/STERNENBUERGERCHEN_GRAFIK_2026-11-01.html")
        result.update(browser_report=path.relative_to(ROOT).as_posix(), browser_report_sha256=sha(path),
                      browser_checks_passed=len(qa["checks"]), browser_html_sha256=qa["html_sha256_end"])
    write(PACKAGE / "pass06_environment_verification_manifest.json", result)
    validation = read(PACKAGE / "report_validation.json")
    validation.update({
        "pass06_environment_local_checks": f"Pass06: {checks['summary']['passed']}/{checks['summary']['selected']} strenge Godot-Laeufe; {len(pack['captures'])} native PNGs und zwoelf kamera-/licht-/renderer-/sichtzustandsgleiche1600x900-Paare. Runtimequellen gegen gepushten Gitblob geprueft. Neun primaere GLBs plus drei originale Stock-/Atlas-/Lizenzquellen hashgleich. Materialroute bewusst geaendert. Quelle/Relief-/Materialtests siehe Enginebericht; keine kuenstlerische Nutzerabnahme.",
        "pass06_environment_git_status": f"Code {code} auf weiterhin unintegriertem task/grafikreferenzen-20261101 gepusht; Grundlage04e934f60. HTML/Browsernachweise separates Uebergabepaket. Keine Main-Integration oder Astra-Adoption.",
    })
    write(PACKAGE / "report_validation.json", validation)
    print(f"P06: {checks['summary']['passed']} engine checks, {len(pack['pairs'])} fixed pairs, {len(pack['captures'])} captured PNGs pinned.")


if __name__ == "__main__":
    main()
