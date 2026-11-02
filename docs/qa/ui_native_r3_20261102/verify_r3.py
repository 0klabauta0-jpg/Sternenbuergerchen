"""Check the pinned source and actual native/runner/HTML evidence together."""
from pathlib import Path
import datetime
import hashlib
import json
import re
import runpy

ROOT = Path(__file__).resolve().parents[3]
QA = Path(__file__).resolve().parent


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def relative(path):
    return Path(path).resolve().relative_to(ROOT).as_posix()


def main():
    expected = json.loads((QA / "checks_final.json").read_text())["checks"]
    reports = []
    for folder in ("checks_final", "checks_post_review"):
        reports.extend((QA / folder).glob("*/metadata/report.json"))
    reports.sort(key=lambda path: json.loads(path.read_text())["finished_at"])
    latest = {}
    for path in reports:
        for record in json.loads(path.read_text())["checks"]:
            latest[record["name"]] = (path, record)
    accepted = []
    for spec in expected:
        path, record = latest[spec["name"]]
        assert record["passed"] and record["exit_code"] == 0 and record["marker_found"] and record["error_count"] == 0, spec["name"]
        log_path = Path(record["log"])
        log = log_path.read_text(encoding="utf-8", errors="replace")
        match = re.search(r"(?:RESULTS:|(?:Native A5|Mission R2|Mission R3 readout):)\s*(\d+)\s*(?:passed|checks),\s*(\d+)\s*(?:failed|failures)", log)
        assert match and int(match[1]) > 0 and int(match[2]) == 0, spec["name"] + " has no positive clean assertion summary"
        assert spec["success_marker"] in log, spec["name"] + " current end marker"
        accepted.append({"name": spec["name"], "passed": True, "assertions": int(match[1]),
                         "exit_code": 0, "error_count": 0, "marker_found": True,
                         "report": relative(path), "log": relative(log_path)})
    source = json.loads((QA / "SOURCE_SNAPSHOT.json").read_text())
    for filename, expected_hash in source["sha256"].items():
        assert digest(ROOT / filename) == expected_hash, "Source changed since final checks: " + filename
    captures = json.loads((QA / "capture_results.json").read_text())
    cases = set(runpy.run_path(str(QA / "capture_r3.py"))["CASES"])
    assert {(item["view"], item["variant"], item["size"]) for item in captures} == cases and len(captures) == len(cases)
    for item in captures:
        assert item["passed"] and item["exit_code"] == 0 and item["error_count"] == 0
        evidence = item["evidence"]
        assert evidence["source_capture"] and not evidence["synthetic_image_fallback"] and not evidence["scaled_capture"]
        assert evidence["logical_size"] == evidence["image_size"] == evidence["requested_window_size"]
        assert digest(QA / "captures" / (item["file"] + ".png")) == item["image_sha256"]
    imported = json.loads((QA / "import_result.json").read_text())
    assert imported["passed"] and imported["project_restored_byte_exact"] and not imported["gdextensions_disabled"]
    assert digest(ROOT / "project.godot") == imported["project_sha256"]
    for item in captures:
        if item["view"] == "debrief":
            metrics = item["evidence"]["ui_metrics"]
            row, slot, card = (metrics[key]["rect"] for key in ("return_row", "return_slot", "return_card"))
            assert all(abs(a - b) <= 1 for a, b in zip(row, slot)), item["file"] + " footer slot"
            assert row[0] >= card[0] and row[1] >= card[1] and row[0] + row[2] <= card[0] + card[2] + 1 and row[1] + row[3] <= card[1] + card[3] + 1, item["file"] + " footer bounds"
            summary = item["evidence"]["fixture_summary"]
            if item["variant"] == "rich":
                assert summary["person_count"] >= 12 and summary["has_aar"] and summary["award_applied"]
            elif item["variant"] in ("empty", "partial"):
                assert summary["person_count"] == 0 and not summary["has_aar"] and not summary["award_applied"]
            else:
                assert summary["person_count"] == 3 and not summary["has_aar"]
    navigation = json.loads((QA / "concept_navigation.json").read_text())
    assert navigation["inline_scripts_unchanged"] and navigation["export_note_keys_unchanged"] and navigation["target_exists"]
    html = json.loads((QA / "html_export_qa.json").read_text())
    assert html["status"] == "PASS" and html["screens"] == len(cases) and html["hidden_records_exported"] == len(cases)
    assert digest(ROOT / html["report"]) == html["report_sha256"]
    artifacts = [ROOT / html["report"], QA / "checks_final.json", QA / "SOURCE_SNAPSHOT.json", QA / "html_export_qa.json", QA / "capture_results.json"]
    artifacts.extend(QA / name for name in ("import_result.json", "concept_navigation.json", "density_comparison.json", "README.md", "REVIEW.md", "PROGRESS.md", "capture_r3.py", "html_qa.cjs", "verify_r3.py"))
    artifacts.extend(ROOT / name for name in ("docs/tasks/TASK_UI_VERDICHTUNG_R3_20261102.md", "docs/dev/ui_native_design_contract.md", "docs/superpowers/plans/2026-11-02-ui-verdichtung-r3.md", "docs/IMPLEMENTATION_STATUS.md"))
    artifacts.extend(sorted((QA / "captures").glob("*.png")))
    artifacts.extend(sorted((QA / "captures").glob("*.json")))
    result = {
        "status": "PASS_SCOPED_NATIVE_UI_R3", "verified_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "branch": "task/ui-verdichtung-r3-20261102", "base_sha": "b1342b939", "integration_base_sha": "3cae5a216",
        "engine": "4.6.2.stable.official.71f334935", "selected_checks": len(accepted),
        "assertions": sum(item["assertions"] for item in accepted), "accepted_checks": accepted,
        "native_captures": len(captures), "small_captures": "4 real logical/physical 1280x720 viewports, no scaled fallback",
        "html_checks": len(html["checks"]), "html_scope": "Actual inline JavaScript in Node VM; no browser layout or real download acceptance",
        "source_snapshot": "SOURCE_SNAPSHOT.json", "artifact_sha256": {relative(path): digest(path) for path in artifacts},
        "review": "Independent source review plus real rendered views; details in README.md and REVIEW.md",
        "limits": ["No human complete playthrough", "Presenter and fixture checks only; no complete human playthrough or real peer session", "Existing lobby map payload UI transport is incomplete", "No release, EXE export or long-run performance acceptance"],
    }
    (QA / "VERIFIKATION.json").write_bytes((json.dumps(result, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))
    print(f"PASS: {len(accepted)} checks / {result['assertions']} assertions, {len(captures)} native captures, {len(html['checks'])} offline HTML checks")


if __name__ == "__main__":
    main()
