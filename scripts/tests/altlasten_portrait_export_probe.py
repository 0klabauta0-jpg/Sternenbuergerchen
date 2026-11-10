"""Prepare an isolated portrait-only PCK probe. Never edits the game project.

Usage: python scripts/tests/altlasten_portrait_export_probe.py --phase baseline
       python scripts/tests/altlasten_portrait_export_probe.py --phase baseline --run

--run launches Godot only against the generated scratch projects, not the game.
The isolated package contains actual imported textures, the current catalog,
and automatically extracted, unchanged consumer method bodies.
"""
from __future__ import annotations

import argparse
import fnmatch
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys


SCRIPT_DIR = Path(__file__).resolve().parent
REPO = SCRIPT_DIR.parents[1]
HERE = REPO / ".godot/altlasten/portrait-probe"
TEXT = {"encoding": "utf-8"}


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig")


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def extract_method(path: Path, method: str) -> str:
    source = read(path)
    match = re.search(rf"^(?:static )?func {re.escape(method)}\([^\n]*\n", source, re.M)
    if match is None:
        raise RuntimeError(f"Missing probe method {method}: {path}")
    remainder = source[match.end():]
    following = re.search(r"^(?=\S)", remainder, re.M)
    end = match.end() + (following.start() if following else len(remainder))
    return source[match.start():end].rstrip() + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--phase", choices=["baseline", "final"], default="baseline")
    parser.add_argument("--backend", choices=["manual", "exporter"], default="manual")
    parser.add_argument("--label", help="Optional scratch evidence directory label; preserves separate red/final runs")
    parser.add_argument("--filters", choices=["draft", "production"], help="Exporter filters: draft adds the catalog-derived 42 patterns; production reads the unchanged release contract")
    parser.add_argument("--run", action="store_true", help="Build and run the isolated PCK; requires parent authorization")
    args = parser.parse_args()
    if args.label and not re.fullmatch(r"[a-z0-9-]+", args.label):
        raise RuntimeError("Scratch evidence label must contain only lowercase letters, digits and hyphens")
    destination = HERE / (args.label or (args.phase if args.backend == "manual" else args.phase + "-exporter"))
    payload = destination / "payload"
    packer = destination / "packer"
    isolated = destination / "isolated"
    for directory in (payload, packer, isolated):
        directory.mkdir(parents=True, exist_ok=True)

    catalog_relative = "data/portrait_identity_catalog.json"
    catalog = json.loads(read(REPO / catalog_relative))
    entries = catalog["entries"]
    aliases = sorted({old for entry in entries for old in entry.get("legacy_paths", [])})
    originals = sorted("res://" + p.relative_to(REPO).as_posix() for p in (REPO / "Assets/Char").glob("*.png"))
    retained = sorted(set(originals) - set(aliases))
    if len(aliases) != 42 or len(retained) != 57:
        raise RuntimeError(f"Inventory drift: {len(aliases)} aliases / {len(retained)} retained")
    patterns = [path.removeprefix("res://").replace(",", "?") for path in aliases]
    export_contract_path = REPO / "data/export_runtime_package_contract.json"
    export_contract = json.loads(read(export_contract_path))
    filter_source = args.filters or ("draft" if args.phase == "baseline" else "production")
    effective_patterns = list(export_contract["exclude_filter_patterns"])
    if filter_source == "draft":
        effective_patterns += [pattern for pattern in patterns if pattern not in effective_patterns]
    if args.backend == "exporter":
        matching = {path for path in originals if any(fnmatch.fnmatchcase(path.removeprefix("res://").casefold(), pattern.casefold()) for pattern in effective_patterns)}
        if matching != set(aliases):
            raise RuntimeError(f"Actual exporter filters do not isolate the 42 aliases: missing={sorted(set(aliases)-matching)}, extra={sorted(matching-set(aliases))}")
        if any("," in pattern for pattern in effective_patterns):
            raise RuntimeError("An export filter contains an unescaped comma separator")

    resources: dict[str, Path] = {}
    missing_imports: list[str] = []

    def add(relative: str, absolute: Path | None = None) -> None:
        path = absolute or REPO / relative
        if not path.is_file():
            raise RuntimeError(f"Missing package input: {path}")
        resources[relative] = path

    def add_imported_texture(res_path: str) -> None:
        relative = res_path.removeprefix("res://")
        sidecar_relative = relative + ".import"
        sidecar = REPO / sidecar_relative
        add(sidecar_relative)
        imported = re.search(r'^path="res://([^\"]+)"', read(sidecar), re.M)
        if imported is None:
            raise RuntimeError(f"Texture import has no remap: {sidecar}")
        cache_relative = imported.group(1)
        cache = REPO / cache_relative
        if not cache.is_file():
            missing_imports.append(cache_relative)
        else:
            add(cache_relative)

    # Freeze code/data inputs so an already prepared baseline remains reviewable
    # while unrelated product work continues in the shared worktree.
    for relative in [catalog_relative, "scripts/meta/portrait_identity_catalog.gd"]:
        snapshot = payload / relative
        snapshot.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(REPO / relative, snapshot)
        add(relative, snapshot)
    for entry in entries:
        add(entry["path"].removeprefix("res://"))
    sheets = sorted({entry["sheet_path"] for entry in entries})
    for res_path in sheets + (originals if args.backend == "exporter" else retained):
        add_imported_texture(res_path)

    excluded_import_payloads = []
    for alias in aliases:
        sidecar = REPO / (alias.removeprefix("res://") + ".import")
        imported = re.search(r'^path="res://([^\"]+)"', read(sidecar), re.M)
        if imported is None:
            raise RuntimeError(f"Missing legacy import remap: {sidecar}")
        excluded_import_payloads.append("res://" + imported.group(1))

    tactical_candidates = [path for path in (REPO / "scripts").rglob("mission_tactical_sandbox_controller.gd") if re.search(r"^func _load_portrait_texture\(", read(path), re.M)]
    if len(tactical_candidates) != 1:
        raise RuntimeError(f"Expected one owning tactical controller, found {tactical_candidates}")
    consumer_specs = {
        "fob": (REPO / "scripts/meta/fob_screen.gd", "_load_portrait_texture"),
        "tactical": (tactical_candidates[0], "_load_portrait_texture"),
        "menu": (REPO / "scripts/ui/main_menu_screen.gd", "_load_res_texture"),
        "emblem": (REPO / "scripts/meta/start_roster_generator.gd", "_resolve_team_emblem"),
    }
    provenance = []
    for name, (source, method) in consumer_specs.items():
        body = extract_method(source, method)
        snapshot = payload / f"probe/{name}.gd"
        snapshot.parent.mkdir(parents=True, exist_ok=True)
        snapshot.write_text('extends RefCounted\n\nconst PORTRAIT_IDENTITY_CATALOG_SCRIPT: GDScript = preload("res://scripts/meta/portrait_identity_catalog.gd")\n\n' + body, **TEXT)
        add(f"probe/{name}.gd", snapshot)
        provenance.append({"consumer": name, "source": source.relative_to(REPO).as_posix(), "method": method, "source_sha256": digest(source), "method_sha256": hashlib.sha256(body.encode()).hexdigest()})

    project = payload / "project.godot"
    project.write_text('config_version=5\n\n[application]\nconfig/name="Portrait PCK compatibility probe"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="SternenbuergerchenPortraitPckProbe"\n\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n', **TEXT)
    add("project.godot", project)
    add("probe/portrait_probe.gd", SCRIPT_DIR / "altlasten_portrait_pack_verifier.gd.txt")
    report_path = destination / "result.json"
    metadata = {
        "phase": args.phase,
        "report_path": report_path.as_posix(),
        "source_root": REPO.as_posix(),
        "aliases": aliases,
        "retained": retained,
        "patterns": patterns,
        "effective_export_patterns": effective_patterns,
        "excluded_import_payloads": excluded_import_payloads,
        "backend": args.backend,
        "export_filter_source": filter_source,
        "export_contract_sha256": digest(export_contract_path),
        "consumers": provenance,
        "catalog_sha256": digest(REPO / catalog_relative),
        "catalog_script_sha256": digest(REPO / "scripts/meta/portrait_identity_catalog.gd"),
        "limitation": "Standalone portrait package. Consumer bodies are exact automatic source extracts, not full instantiated scenes. " + ("Actual Godot exporter starts with all 99 original PNGs plus their import metadata/cache and applies recorded export filters." if args.backend == "exporter" else "PCKPacker explicitly omits aliases; this is not a full export-filter integration proof."),
    }
    metadata_path = payload / "probe/input.json"
    metadata_path.parent.mkdir(parents=True, exist_ok=True)
    metadata_path.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", **TEXT)
    add("probe/input.json", metadata_path)
    pack_path = destination / "portraits.pck"
    manifest = {"output": pack_path.as_posix(), "files": [{"path": "res://" + relative, "source": path.as_posix(), "bytes": path.stat().st_size, "sha256": digest(path)} for relative, path in sorted(resources.items())]}
    manifest_path = packer / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", **TEXT)
    (packer / "project.godot").write_text('config_version=5\n\n[application]\nconfig/name="Portrait pack builder"\n', **TEXT)
    shutil.copyfile(SCRIPT_DIR / "altlasten_portrait_pack_builder.gd", packer / "pack_builder.gd")
    godot = shutil.which("godot_console.exe")
    executable = godot or "godot_console.exe"
    commands = [[executable, "--headless", "--path", str(packer), "--script", "res://pack_builder.gd"]]
    command_names = ["build"]
    source_texture_count = 0
    copied_import_bytes = 0
    if args.backend == "exporter":
        mini = destination / "export-project"
        mini.mkdir(parents=True, exist_ok=True)
        # Full copies isolate both import sidecars and generated caches. A Godot
        # reimport in this mini-project cannot overwrite original hardlink data.
        for relative, source in resources.items():
            target = mini / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
            if relative.endswith(".ctex"):
                copied_import_bytes += target.stat().st_size
                md5_source = source.with_suffix(".md5")
                if md5_source.is_file():
                    shutil.copy2(md5_source, target.with_suffix(".md5"))
        for res_path in sheets + originals:
            relative = res_path.removeprefix("res://")
            target = mini / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO / relative, target)
            source_texture_count += 1
        scene = mini / "probe/empty.tscn"
        scene.write_text('[gd_scene format=3]\n\n[node name="PortraitExportProbe" type="Node"]\n', **TEXT)
        mini_project = mini / "project.godot"
        mini_project.write_text(read(mini_project).replace('config/name="Portrait PCK compatibility probe"', 'config/name="Portrait PCK compatibility probe"\nrun/main_scene="res://probe/empty.tscn"'), **TEXT)
        preset = '[preset.0]\n\nname="Portrait Export Probe"\nplatform="Windows Desktop"\nrunnable=true\ndedicated_server=false\ncustom_features=""\nexport_filter="all_resources"\ninclude_filter="*.json"\nexclude_filter="' + ",".join(effective_patterns) + '"\nexport_path="../portraits.pck"\nscript_export_mode=1\n\n[preset.0.options]\n\nbinary_format/architecture="x86_64"\ntexture_format/s3tc_bptc=true\ntexture_format/etc2_astc=false\n'
        (mini / "export_presets.cfg").write_text(preset, **TEXT)
        commands = [[executable, "--headless", "--editor", "--path", str(mini), "--import"], [executable, "--headless", "--path", str(mini), "--export-pack", "Portrait Export Probe", str(pack_path)]]
        command_names = ["import", "export"]
    commands.append([executable, "--headless", "--path", str(isolated), "--main-pack", str(pack_path), "--script", "res://probe/portrait_probe.gd"])
    command_names.append("run")
    preflight = {"phase": args.phase, "backend": args.backend, "filter_source": filter_source, "inputs": len(resources), "imported_texture_inputs": len(sheets) + (len(originals) if args.backend == "exporter" else len(retained)), "copied_source_pngs": source_texture_count, "copied_import_bytes": copied_import_bytes, "missing_imports": missing_imports, "godot": godot, "manifest": str(manifest_path), "package": str(pack_path), "report": str(report_path), "source_tree_untouched": True, "commands": commands, "command_names": command_names}
    (destination / "preflight.json").write_text(json.dumps(preflight, ensure_ascii=False, indent=2) + "\n", **TEXT)
    print(json.dumps(preflight, ensure_ascii=False, indent=2))
    if missing_imports:
        raise RuntimeError("Missing imported texture cache; prepare cannot build a real-resource pack")
    if not args.run:
        return
    if not godot:
        raise RuntimeError("godot_console.exe not found")
    for index, command in enumerate(preflight["commands"]):
        result = subprocess.run(command, cwd=isolated, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=240)
        (destination / f"{command_names[index]}.log").write_text(result.stdout + result.stderr, **TEXT)
        print(f"{command_names[index]}: exit={result.returncode}; full output in {destination / (command_names[index] + '.log')}")
        if command_names[index] == "run":
            lines = result.stdout.splitlines()
            print("\n".join(lines if len(lines) <= 12 else lines[:6] + ["... full consumer output retained in run.log ..."] + lines[-3:]))
        if result.stderr:
            error_lines = result.stderr.splitlines()
            print("\n".join(error_lines[:12]) + ("\n... full stderr retained in stage log ..." if len(error_lines) > 12 else ""), file=sys.stderr)
        if result.returncode:
            raise RuntimeError(f"Probe command {index + 1} exited {result.returncode}")
    if not report_path.is_file():
        raise RuntimeError("Pack runtime produced no result.json")
    print(read(report_path))


if __name__ == "__main__":
    main()
