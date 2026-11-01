"""Pin P07 evidence after Root's freeze. Git calls are read-only; no commit/push."""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess

from pass07_paths_common import ROOT, PACKAGE, ARCHIVE_SHA, load_package, local, read, sha


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
    for path, digest in pack["runtime_sources_sha256"].items():
        committed = subprocess.check_output(["git", "show", code + ":" + path.removeprefix("res://")], cwd=ROOT)
        assert hashlib.sha256(committed).hexdigest() == digest == sha(local(path)), path
    result = {
        "schema": "sternenbuergerchen.graphics_pass07_paths_verification.v1",
        "report_revision": "env07", "code_commit": code, "code_commit_pushed": True,
        "based_on_unintegrated_graphics_branch": "task/grafikreferenzen-20261101",
        "previous_handoff_commit": "501201b0c", "engine_report": args.engine_report,
        "engine_report_sha256": sha(ROOT / args.engine_report),
        "engine_checks_passed": checks["summary"]["passed"],
        "engine_checks_selected": checks["summary"]["selected"],
        "native_captures": len(pack["captures"]) + len(pack["runtime_controls"]),
        "preview_capture_count": len(pack["captures"]), "runtime_control_count": len(pack["runtime_controls"]),
        "capture_records": pack["captures"] + pack["runtime_controls"], "pairs": pack["pairs"],
        "runtime_controls": pack["runtime_controls"],
        "runtime_sources_sha256": pack["runtime_sources_sha256"],
        "runtime_evidence": {"path": pack["runtime_evidence"]["path"], "sha256": pack["runtime_evidence"]["sha256"]},
        "legacy_evidence": {"path": pack["legacy_evidence"]["path"], "sha256": pack["legacy_evidence"]["sha256"]},
        "legacy_tests_remain_failed": True, "engine_evidence_kind": "consolidated_actual_runs",
        "after_capture_sha256": sha(PACKAGE / "pass07_paths_after_capture.json"),
        "before_capture_sha256": sha(PACKAGE / "pass07_paths_before_capture.json"),
        "before_manifest": "output/grafik_20261101/pass07_paths_before_manifest.json",
        "before_manifest_sha256": sha(PACKAGE / "pass07_paths_before_manifest.json"),
        "archived_pass06_html_sha256": ARCHIVE_SHA,
        "source_packages": {name: {"path": row["path"], "sha256": row["sha256"]} for name, row in pack["source_packages"].items()},
        "primary_glb_hashes_unchanged": True, "raw_stock_sources_unchanged": True,
        "renderer_match": True, "lighting_match": True, "camera_transforms_match": True,
        "material_route": "Paths, entrances, apron interfaces and graphic corrections are part of P07; global lighting is fixed for the preview pairs.",
        "scope": "Entrance-aligned paths and bounded graphic corrections in the art preview; a first explicitly themed map uses the regular MapData/Registry/View entry. Runtime controls are new, separate map evidence without before pairs. No whole-campaign, ship or gameplay migration.",
        "remaining_visual_differences": "The regular map slice is bounded and does not complete editor/content/campaign migration. Playable ground remains flat; real relief stays within protected geology envelopes. Cliff crowns remain broad and the2Dtargets contain richer small depressions and usage density. Ships remain criticized R02 candidates; separate Astra outputs are not adopted. Technical checks do not imply artistic or release acceptance.",
        "ship_user_status": "Retained criticized R02 models; separate Astra work is not automatically adopted.",
    }
    if args.include_browser:
        path = PACKAGE / "browser_qa_pass07_paths/browser_qa.json"
        qa = read(path)
        assert qa.get("status") == "pass" and qa.get("pass") is True
        assert qa.get("visual_inspection", {}).get("pass") is True
        assert qa.get("checks") and all(row["pass"] for row in qa["checks"])
        assert not qa.get("console_errors") and not qa.get("page_errors") and not qa.get("external_requests")
        assert qa["html_sha256_start"] == qa["html_sha256_end"] == sha(ROOT / "docs/reports/STERNENBUERGERCHEN_GRAFIK_2026-11-01.html")
        result.update(browser_report=path.relative_to(ROOT).as_posix(), browser_report_sha256=sha(path),
                      browser_checks_passed=len(qa["checks"]), browser_html_sha256=qa["html_sha256_end"])
    write(PACKAGE / "pass07_paths_verification_manifest.json", result)
    validation = read(PACKAGE / "report_validation.json")
    validation.update({
        "pass07_paths_local_checks": f"Pass07: {checks['summary']['passed']}/{checks['summary']['selected']} fokussierte Gates aus konsolidierten tatsaechlichen Godot-Laeufen inklusive Hex-Retry; {len(pack['captures']) + len(pack['runtime_controls'])} native PNGs und zwoelf kamera-/licht-/renderer-/sichtzustandsgleiche1600x900-Paare. Runtimequellen gegen gepushten Gitblob geprueft. Neun primaere GLBs plus drei originale Stock-/Atlas-/Lizenzquellen hashgleich. Wege-/Anschluss-/Runtime-Tests siehe Enginebericht; neue regulaere Kartenkontrollen getrennt und ohne erfundenen Vorherstand; TASK158 bleibt 29/13 und TASK159 86/6 mit identischen Fehlerlabels gegen Basis 501201b0c rot; urspruenglicher FileOpen-Timeout bleibt im Enginebericht. Keine allgemeine Release- oder kuenstlerische Nutzerabnahme.",
        "pass07_paths_git_status": f"Code {code} auf weiterhin unintegriertem task/grafikreferenzen-20261101 gepusht; Grundlage501201b0c. HTML/Browsernachweise separates Uebergabepaket. Keine Main-Integration oder Astra-Adoption.",
    })
    write(PACKAGE / "report_validation.json", validation)
    print(f"P07: {checks['summary']['passed']} engine checks, {len(pack['pairs'])} fixed pairs, {len(pack['captures'])} preview PNGs plus {len(pack['runtime_controls'])} regular map controls pinned.")


if __name__ == "__main__":
    main()
