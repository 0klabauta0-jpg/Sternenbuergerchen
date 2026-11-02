"""Explicitly freeze a small source/evidence set; default only verifies hashes."""
import argparse
from datetime import datetime, timezone
import hashlib
import html
import json
from pathlib import Path
import re
import subprocess

from _qa_common import QA, ROOT

BASELINE = [
    "project.godot",
    "docs/PROJECT_BRIEF.md", "docs/ARCHITECTURE.md", "docs/CODEX_RULES.md", "docs/IMPLEMENTATION_STATUS.md",
    "docs/tasks/UI_2026_11_02_zielbild_abgleich.md",
    "docs/dev/graphics_reference_revision_contract.md", "docs/dev/ui_native_design_contract.md",
    "docs/dev/ui_theme_component_library.md", "docs/dev/gm01_frontier_map_contract.md",
    "docs/ui_concepts/ui_20261102_r4/BILDPRUEFUNG_UND_UEBERGABE.md",
    "scripts/terrain/terrain_map_3d_view.gd", "scripts/terrain/frontier_gm01_layout.gd",
    "scripts/terrain/frontier_ship_visuals.gd", "scripts/ui/tactical_ui_theme.gd",
    "scripts/ui/mission_a5_hud_layout.gd", "scripts/ui/reference_panel_frame.gd",
    "scripts/meta/meta_ui_skin.gd", "scripts/meta/npc_compact_card.gd", "scripts/ui/tactical_event_log_panel.gd",
    "scripts/meta/drop_light_layout_contract.gd",
    "scripts/tests/frontier_main_startup_verifier.gd", "scripts/tests/gm01_frontier_normal_capture.gd",
    "scripts/tests/ui_zielbild_normal_capture.gd", "scripts/tests/ui_native_capture.gd",
    "maps/Ground_Mission01_32x32.json", "data/mission_scenarios/ground_mission01_default.json",
    "Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_03/cutlass_01.glb",
    "Assets/curated/ui_native_r4/cutlass_ref03_preview.png", "Assets/curated/ui_native_r4/cutlass_ref03_preview.json",
]


def local_path(value, relative_to=ROOT):
    if value.startswith("res://"):
        value = value.removeprefix("res://")
        relative_to = ROOT
    path = Path(value)
    resolved = (path if path.is_absolute() else relative_to / path).resolve()
    resolved.relative_to(ROOT)
    if not resolved.is_file():
        raise ValueError(f"Required source/evidence file missing: {resolved}")
    return resolved


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def record(args, target):
    if target.exists():
        raise ValueError("Snapshot already exists; select a new --snapshot path for an explicit new record.")
    if not args.normal_result or not args.fixture_result or not args.report:
        raise ValueError("--record requires --normal-result, --fixture-result and --report.")
    paths = {local_path(item) for item in BASELINE}
    paths.update(path.resolve() for path in QA.iterdir() if path.is_file() and path.suffix in {".py", ".md", ".js", ".mjs", ".cjs"} and path != target)
    paths.add(QA / "checks_final.json")
    manifest = json.loads((QA / "checks_final.json").read_text(encoding="utf-8"))
    paths.update(local_path(check["script"]) for check in manifest["checks"])
    # Only the current tracked source/doc diff, never a recursive asset crawl.
    changed = subprocess.run(["git", "diff", "--name-only", "--relative", "HEAD", "--"], cwd=ROOT, check=True, stdout=subprocess.PIPE, encoding="utf-8").stdout.splitlines()
    changed_sources = []
    for name in changed:
        if name.startswith(("scripts/", "scenes/", "maps/", "data/", "docs/dev/", "docs/tasks/")) and (ROOT / name).is_file():
            paths.add(local_path(name))
            changed_sources.append(name)
    paths.update(local_path(item) for item in args.source)
    for value in args.normal_result:
        result_path = local_path(value)
        paths.add(result_path)
        records = json.loads(result_path.read_text(encoding="utf-8"))
        if not records:
            raise ValueError(f"Empty normal capture manifest: {result_path}")
        for entry in records:
            if not (entry.get("normal_start_checks", 0) > 0 and entry.get("normal_start_failures") == 0 and entry.get("project_restored_byte_exact") is True):
                raise ValueError(f"Unaccepted normal capture record: {result_path}")
            image = local_path(entry["source_image"])
            if digest(image) != entry["image_sha256"]:
                raise ValueError(f"Normal capture hash disagrees: {image}")
            paths.add(image)
            startup_path = local_path(entry["source_report"])
            paths.add(startup_path)
            startup = json.loads(startup_path.read_text(encoding="utf-8"))
            for capture in startup["captures"]:
                image = local_path(capture["path"])
                if digest(image) != capture["sha256"]:
                    raise ValueError(f"Startup capture hash disagrees: {image}")
                paths.add(image)
    for value in args.fixture_result:
        result_path = local_path(value)
        paths.add(result_path)
        records = json.loads(result_path.read_text(encoding="utf-8"))
        if not records:
            raise ValueError(f"Empty fixture capture manifest: {result_path}")
        for entry in records:
            if entry.get("passed") is not True or entry.get("project_restored_byte_exact") is not True:
                raise ValueError(f"Unaccepted fixture capture record: {result_path}")
            image = local_path(entry["evidence"]["image"])
            if digest(image) != entry["image_sha256"]:
                raise ValueError(f"Fixture capture hash disagrees: {image}")
            paths.update([image, local_path(str(image.with_suffix(".json")))])
    for value in args.report:
        report = local_path(value)
        paths.add(report)
        # Also freeze referenced local target/native images without scanning folders.
        for source in re.findall(r'\bsrc=["\']([^"\']+)["\']', report.read_text(encoding="utf-8")):
            source = html.unescape(source).split("#", 1)[0].split("?", 1)[0]
            if not source or ":" in source or source.startswith("//"):
                continue
            paths.add(local_path(source, report.parent))
    payload = {
        "version": 1,
        "recorded_utc": datetime.now(timezone.utc).isoformat(),
        "scope": "Explicit current source/docs/map/scenario/Cutlass and selected capture/report byte snapshot; no engine or visual acceptance.",
        "changed_tracked_sources": changed_sources,
        "files": [{"path": path.relative_to(ROOT).as_posix(), "sha256": digest(path), "bytes": path.stat().st_size} for path in sorted(paths)],
    }
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open("x", encoding="utf-8") as handle:
        handle.write(json.dumps(payload, indent=2) + "\n")
    print(f"RECORDED {len(payload['files'])} files: {target}")


def verify(target):
    payload = json.loads(target.read_text(encoding="utf-8"))
    if payload.get("version") != 1 or not payload.get("files"):
        raise ValueError("Unsupported or empty source snapshot.")
    failures = []
    for entry in payload["files"]:
        try:
            path = local_path(entry["path"])
            if path.stat().st_size != entry["bytes"] or digest(path) != entry["sha256"]:
                failures.append(entry["path"])
        except (OSError, ValueError):
            failures.append(entry["path"])
    for name in failures:
        print("HASH_MISMATCH_OR_MISSING", name)
    print(f"SOURCE_SNAPSHOT {'PASS' if not failures else 'FAIL'}: {len(payload['files'])} frozen files / {len(failures)} mismatches; no repinning")
    return 1 if failures else 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--record", action="store_true")
    parser.add_argument("--snapshot", type=Path, default=QA / "source_snapshot.json")
    parser.add_argument("--normal-result", action="append", default=[])
    parser.add_argument("--fixture-result", action="append", default=[])
    parser.add_argument("--report", action="append", default=[])
    parser.add_argument("--source", action="append", default=[], help="Explicit additional asset/new source; no recursive lookup.")
    args = parser.parse_args()
    target = args.snapshot.resolve()
    target.relative_to(QA)
    if args.record:
        record(args, target)
        return 0
    if args.normal_result or args.fixture_result or args.report or args.source:
        parser.error("File selection requires explicit --record; default only verifies the frozen snapshot.")
    return verify(target)


if __name__ == "__main__":
    raise SystemExit(main())
