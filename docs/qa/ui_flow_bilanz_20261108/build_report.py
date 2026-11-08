"""Freeze the reviewed source pin and build the offline documentation workbench."""
from __future__ import annotations

import hashlib
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
SOURCE = Path(r"C:\dev\SternenBuergerchen")
REPORT_NAME = "STERNENBUERGERCHEN_UI_FLOW_BILANZ_2026-11-08.html"
ASSET_REL = "assets/ui-flow-bilanz-2026-11-08"
REPORTS = REPO / "docs/reports"
ASSETS = REPORTS / ASSET_REL
PIN = "33bc504c4"


def git(*args: str) -> bytes:
    return subprocess.check_output(["git", "-C", str(SOURCE), *args], stderr=subprocess.PIPE)


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def freeze(origin: str, allow_working: bool = False) -> tuple[bytes, str]:
    try:
        return git("show", f"{PIN}:{origin}"), "git:" + PIN
    except subprocess.CalledProcessError:
        if not allow_working:
            raise RuntimeError(f"Missing pinned source: {origin}") from None
        return (SOURCE / origin).read_bytes(), "working-copy; captured immutable for this report"


def main() -> None:
    data = json.loads((HERE / "report_data.json").read_text(encoding="utf-8"))
    pin_full = git("rev-parse", PIN).decode().strip()
    data["meta"].update(pin=pin_full, captured_at=datetime.now(timezone.utc).isoformat(),
                        report_id="ui_flow_bilanz_20261108",
                        scope="Documentation snapshot; no new Godot run; parallel R5 results excluded")
    for part in ("images", "sources"):
        (ASSETS / part).mkdir(parents=True, exist_ok=True)
    manifest = {"schema": "sternenbuergerchen.ui_flow_snapshot.v1",
                "source_commit": pin_full, "captured_at": data["meta"]["captured_at"],
                "report_branch": data["meta"]["report_branch"],
                "branch_base": data["meta"]["branch_base"], "files": []}
    for key, entry in data["images"].items():
        raw, binding = freeze(entry["origin"], entry["origin"].startswith("output/"))
        local = "images/" + key + Path(entry["origin"]).suffix
        (ASSETS / local).write_bytes(raw)
        entry.update(src=ASSET_REL + "/" + local, sha256=sha(raw), binding=binding)
        manifest["files"].append({"kind": "image", "id": key, "file": local,
                                  "origin": entry["origin"], "sha256": sha(raw),
                                  "bytes": len(raw), "binding": binding,
                                  "status": entry["status"], "date": entry["date"]})
    for entry in data["sources"]:
        raw, binding = freeze(entry["origin"], entry.get("mode") == "working")
        if entry.get("mode") == "working":
            entry["lines"] += " · Separat erfasster laufender Auftrag außerhalb des Produktpins; keine Ergebnisabnahme"
        source_suffix = Path(entry["origin"]).suffix
        local = "sources/" + entry["id"] + source_suffix
        if source_suffix == ".gd":
            # Read-only evidence must not register duplicate Godot script classes.
            obsolete = ASSETS / local
            if obsolete.exists():
                assert obsolete.resolve().is_relative_to((ASSETS / "sources").resolve())
                obsolete.unlink()
            local += ".txt"
        (ASSETS / local).write_bytes(raw)
        entry.update(path=ASSET_REL + "/" + local, sha256=sha(raw), binding=binding)
        manifest["files"].append({"kind": "source", "id": entry["id"], "file": local,
                                  "origin": entry["origin"], "sha256": sha(raw),
                                  "bytes": len(raw), "binding": binding, "lines": entry["lines"]})
    template = (HERE / "report_template.html").read_text(encoding="utf-8")
    if template.count("__REPORT_DATA__") != 1:
        raise RuntimeError("Expected exactly one report data placeholder")
    payload = json.dumps(data, ensure_ascii=False).replace("<", "\\u003c")
    html = template.replace("__REPORT_DATA__", payload)
    REPORTS.mkdir(parents=True, exist_ok=True)
    (REPORTS / REPORT_NAME).write_text(html, encoding="utf-8", newline="\n")
    inherited, _ = freeze("docs/reports/_html_workbench_template.html")
    manifest["template_derived_from"] = {
        "origin": "docs/reports/_html_workbench_template.html", "sha256": sha(inherited),
        "commit": pin_full, "adaptation": "report_template.html; offline export schema/controls adapted"}
    manifest["report"] = {"file": REPORT_NAME, "sha256": sha(html.encode("utf-8"))}
    (ASSETS / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    (HERE / "snapshot_data.json").write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"report": str(REPORTS / REPORT_NAME), "assets": len(manifest["files"]),
                      "bytes": sum(x["bytes"] for x in manifest["files"]), "pin": pin_full}, indent=2))


if __name__ == "__main__":
    main()
