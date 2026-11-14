"""Prepare unchanged graphics fixtures; never start Godot, import, or generators.

Repeat --script and --copy-resource for entries selected by the caller. Literal
res:// references, import settings, script UIDs and glTF external dependencies
form the copy graph. Computed paths cannot be inferred: unresolved literals are
reported, and --copy-resource supplies the missing concrete resources.
"""

import argparse
import base64
import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import uuid
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[2]
TEXT_SUFFIXES = {".gd", ".json", ".tscn", ".tres", ".gdshader", ".gdshaderinc", ".import", ".uid", ".gltf"}
RES_LITERAL = re.compile(r'''["']res://([^"'\r\n]+)["']''')
PRELOAD = re.compile(r'''preload\(\s*["']res://([^"'\r\n]+)["']\s*\)''')
EXTENSIONS = {
    "navigation": (
        "native/navigation/navigation.gdextension",
        "native/navigation/bin/native_navigation.windows.template_release.x86_64.dll",
    ),
    "limboai": (
        "addons/limboai/bin/limboai.gdextension",
        "addons/limboai/bin/liblimboai.windows.editor.x86_64.dll",
        "addons/limboai/bin/liblimboai.windows.template_release.x86_64.dll",
    ),
}


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def source_path(value):
    path = (ROOT / value.removeprefix("res://")).resolve()
    if not path.is_relative_to(ROOT) or ".godot" in path.relative_to(ROOT).parts:
        raise ValueError("Source must be inside the repository, outside generated .godot: " + value)
    return path


def gltf_dependencies(path, data):
    """Validate container/buffer/image ranges; return exact external source files."""
    binary = None
    if path.suffix.lower() == ".glb":
        if len(data) < 20 or struct.unpack_from("<III", data) != (0x46546C67, 2, len(data)):
            raise ValueError(f"Invalid GLB header: {path}")
        chunks = []
        offset = 12
        while offset < len(data):
            if offset + 8 > len(data):
                raise ValueError(f"Truncated GLB chunk header: {path}")
            length, kind = struct.unpack_from("<II", data, offset)
            offset += 8
            if length % 4 or offset + length > len(data):
                raise ValueError(f"Invalid GLB chunk range: {path}")
            chunks.append((kind, data[offset:offset + length]))
            offset += length
        if not chunks or chunks[0][0] != 0x4E4F534A:
            raise ValueError(f"GLB JSON chunk missing: {path}")
        document = json.loads(chunks[0][1].decode("utf-8").rstrip("\x00 "))
        bins = [chunk for kind, chunk in chunks[1:] if kind == 0x004E4942]
        if len(bins) > 1:
            raise ValueError(f"Multiple GLB BIN chunks: {path}")
        binary = bins[0] if bins else None
    else:
        document = json.loads(data.decode("utf-8-sig"))
    external = []

    def uri_bytes(uri):
        if uri.startswith("data:"):
            header, payload = uri.split(",", 1)
            if ";base64" not in header:
                raise ValueError(f"Unsupported non-base64 glTF data URI: {path}")
            return base64.b64decode(payload, validate=True)
        parsed = urlsplit(uri)
        if parsed.scheme or parsed.netloc or parsed.query or parsed.fragment:
            raise ValueError(f"Nonlocal glTF dependency: {path}: {uri}")
        candidate = (path.parent / unquote(parsed.path)).resolve()
        if not candidate.is_relative_to(ROOT) or not candidate.is_file():
            raise ValueError(f"Missing or external glTF dependency: {path}: {uri}")
        external.append(candidate.relative_to(ROOT).as_posix())
        return candidate.read_bytes()

    buffers = []
    for index, item in enumerate(document.get("buffers", [])):
        contents = uri_bytes(item["uri"]) if "uri" in item else binary if index == 0 else None
        length = item.get("byteLength", -1)
        if contents is None or not isinstance(length, int) or length < 0 or length > len(contents):
            raise ValueError(f"Invalid glTF buffer {index}: {path}")
        buffers.append(contents[:length])
    views = []
    for item in document.get("bufferViews", []):
        index, start, length = item.get("buffer", -1), item.get("byteOffset", 0), item.get("byteLength", -1)
        if not all(isinstance(x, int) for x in (index, start, length)) or not 0 <= index < len(buffers) or start < 0 or length < 0 or start + length > len(buffers[index]):
            raise ValueError(f"Invalid glTF bufferView: {path}")
        views.append(buffers[index][start:start + length])
    embedded = 0
    for item in document.get("images", []):
        if "uri" in item:
            image = uri_bytes(item["uri"])
            embedded += int(item["uri"].startswith("data:"))
        else:
            index = item.get("bufferView", -1)
            if not isinstance(index, int) or not 0 <= index < len(views) or not item.get("mimeType", "").startswith("image/"):
                raise ValueError(f"Invalid embedded glTF image: {path}")
            image = views[index]
            embedded += 1
        mime = item.get("mimeType")
        if not image or (mime == "image/png" and not image.startswith(b"\x89PNG\r\n\x1a\n")) or (mime == "image/jpeg" and not image.startswith(b"\xff\xd8")):
            raise ValueError(f"Invalid glTF image content: {path}")
    return external, {"images": len(document.get("images", [])), "embedded_images": embedded, "external_files": external, "buffer_ranges_valid": True}


def isolated_config(original, run_id, renderer, user_guard=True):
    """Keep real display/input/physics/render settings; omit app state/autoloads."""
    sections = {}
    for match in re.finditer(r"(?ms)^\[([^\]\r\n]+)\]\s*\n(.*?)(?=^\[|\Z)", original):
        sections[match[1]] = match[2]
    rendering = sections.get("rendering", "")
    if renderer != "project":
        rendering = re.sub(r"(?m)^(?:renderer/rendering_method(?:\.mobile)?|rendering_device/driver\.windows)=.*\n?", "", rendering)
        rendering += '\nrenderer/rendering_method="' + renderer + '"\n'
        if renderer == "forward_plus":
            rendering += 'rendering_device/driver.windows="d3d12"\n'
    feature = '"4.6", "GL Compatibility"' if renderer == "gl_compatibility" else '"4.6", "Forward Plus"'
    config = ('config_version=5\n\n[application]\nconfig/name="SB-Codex-Review2-Grafikpass-' + run_id +
              '"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="SB-Codex-Review2/Grafikpass/' + run_id +
              '"\nconfig/features=PackedStringArray(' + feature + ')\n')
    if user_guard:
        config += '\n[autoload]\nReview2IsolationGuard="*res://scripts/tests/review2_isolated_user_guard.gd"\n'
    for name in ("display", "input", "physics", "layer_names"):
        if name in sections:
            config += "\n[" + name + "]\n" + sections[name]
    return config + "\n[rendering]\n" + rendering


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--script", action="append", required=True, help="Repeat: tests basename or project-relative .gd entry")
    parser.add_argument("--copy-resource", action="append", default=[], help="Repeat: concrete file needed by a computed runtime path")
    parser.add_argument("--output-dir", help="Fresh evidence directory; project is its project/ child")
    parser.add_argument("--renderer", choices=("project", "forward_plus", "gl_compatibility"), default="project")
    parser.add_argument("--without-native", action="store_true")
    parser.add_argument("--with-limboai", action="store_true")
    parser.add_argument("--without-user-guard", action="store_true", help="Omit test-only guard autoload; unique user directory is still mandatory")
    args = parser.parse_args()
    run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8]
    output = Path(args.output_dir).resolve() if args.output_dir else ROOT / "tmp/grafikpass_prepare" / run_id
    project = output / "project"
    entries = ["scripts/tests/" + name if "/" not in name and "\\" not in name else name.removeprefix("res://") for name in args.script]
    selected_extensions = ([] if args.without_native else ["navigation"]) + (["limboai"] if args.with_limboai else [])
    seeds = entries + args.copy_resource + [name for ext in selected_extensions for name in EXTENSIONS[ext]]
    if not args.without_user_guard:
        seeds.append("scripts/tests/review2_isolated_user_guard.gd")
    if not os.environ.get("APPDATA"):
        parser.error("This Windows fixture requires APPDATA to declare the exact isolated user directory")
    user_directory = Path(os.environ["APPDATA"]) / "SB-Codex-Review2/Grafikpass" / run_id
    if user_directory.exists():
        parser.error("Fresh isolated user directory already exists: " + str(user_directory))
    for name in seeds:
        if not source_path(name).is_file():
            parser.error("Required input is missing: " + name)
    if any(Path(name).suffix != ".gd" for name in entries):
        parser.error("--script entries must be .gd files")
    if output.exists():
        parser.error("Output directory must not already exist: " + str(output))
    project.mkdir(parents=True, exist_ok=False)
    copied, normalized, parents, unresolved, gltf = {}, {}, {}, {}, {}
    queue = [(name, "explicit input", True) for name in seeds]
    while queue:
        relative, origin, required = queue.pop()
        if relative.startswith(".godot/"):
            continue  # Rebuilt by the caller's fresh import; never reuse old cache.
        source = source_path(relative)
        relative = source.relative_to(ROOT).as_posix()
        parents.setdefault(relative, set()).add(origin)
        if relative in copied:
            continue
        if not source.is_file():
            if required:
                raise ValueError("Required dependency missing: " + relative + " from " + origin)
            unresolved.setdefault(relative, set()).add(origin)
            continue
        data = source.read_bytes()
        destination = project / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        if destination.read_bytes() != data or source.read_bytes() != data:
            raise ValueError("Source changed during copy: " + relative)
        copied[relative] = sha256(data)
        for suffix in (".import", ".uid"):
            if not relative.endswith(suffix) and Path(str(source) + suffix).is_file():
                queue.append((relative + suffix, relative, True))
        if source.suffix.lower() in {".glb", ".gltf"}:
            dependencies, gltf[relative] = gltf_dependencies(source, data)
            queue += [(name, relative, True) for name in dependencies]
        if source.suffix in TEXT_SUFFIXES:
            normalized[relative] = sha256(data.replace(b"\r\n", b"\n"))
            text = data.decode("utf-8-sig")
            required_paths = set(PRELOAD.findall(text))
            for dependency in RES_LITERAL.findall(text):
                queue.append((dependency, relative, dependency in required_paths or source.suffix in {".tscn", ".tres"}))
        elif source.suffix == ".gdextension":
            # Preserve descriptor bytes; Windows x64 libraries are explicit above.
            normalized[relative] = sha256(data.replace(b"\r\n", b"\n"))
            for dependency in RES_LITERAL.findall(data.decode("utf-8-sig")):
                if dependency.endswith(".svg"):
                    queue.append((dependency, relative, False))
    original_config = (ROOT / "project.godot").read_bytes()
    config = isolated_config(original_config.decode("utf-8-sig"), run_id, args.renderer, not args.without_user_guard)
    (project / "project.godot").write_text(config, encoding="utf-8")
    generated = {"project.godot": sha256((project / "project.godot").read_bytes())}
    if selected_extensions:
        extension_list = "\n".join("res://" + EXTENSIONS[name][0] for name in selected_extensions) + "\n"
        (project / ".godot").mkdir(exist_ok=True)
        (project / ".godot/extension_list.cfg").write_text(extension_list, encoding="utf-8")
        generated[".godot/extension_list.cfg"] = sha256((project / ".godot/extension_list.cfg").read_bytes())
    # Detect concurrent source changes before claiming a coherent fixture.
    changed = [name for name, digest in copied.items() if sha256((ROOT / name).read_bytes()) != digest]
    if changed:
        raise ValueError("Source changed while preparing fixture: " + ", ".join(changed))
    manifest = {
        "source_head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "run_id": run_id, "minimal_project": str(project), "scripts": entries,
        "source_sha256": dict(sorted(copied.items())), "source_lf_sha256": dict(sorted(normalized.items())),
        "source_project_config_sha256": sha256(original_config), "generated_sha256": generated,
        "dependency_origins": {name: sorted(origins) for name, origins in sorted(parents.items()) if name in copied},
        "unresolved_literals": {name: sorted(origins) for name, origins in sorted(unresolved.items())},
        "gltf_validation": gltf, "renderer": args.renderer, "extensions": selected_extensions,
        "player_profile": "unique custom user directory", "user_directory": str(user_directory),
        "environment": {"SB_REVIEW2_USER_DIR": str(user_directory)},
        "autoloads": [] if args.without_user_guard else ["Review2IsolationGuard"],
        "engine_started": False, "import_performed": False,
        "limits": "Literal dependency closure only; computed paths need --copy-resource. glTF validation is structural, not visual or engine-import acceptance.",
        "suggested_import_argv": ["godot_console.exe", "--headless", "--path", str(project), "--editor", "--import"],
    }
    (output / "source_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(json.dumps({"project": str(project), "manifest": str(output / "source_manifest.json"), "files": len(copied), "unresolved_literals": len(unresolved), "engine_started": False}, indent=2))


if __name__ == "__main__":
    main()
