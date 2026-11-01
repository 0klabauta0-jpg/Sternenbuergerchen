"""Preserve user references byte for byte; catalog older images separately."""
from __future__ import annotations

import hashlib
import json
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = ROOT / "docs/reports/assets/grafik-2026-11-01/references"
LOCAL = Path("C:/Users/bjoer/Pictures/Sternenbürger")

CURRENT = [
    {
        "id": "ref_rostgrenze", "filename": "01_rostgrenze_cutaway.png",
        "source": "C:/Users/bjoer/AppData/Local/Temp/codex-clipboard-03f6c8c2-a842-4970-8104-e3c33497f729.png",
        "title": "Rostgrenze · Außenposten-Cutaway", "group": "buildings",
        "description": "Rote Schichtklippen, helle orange eingefasste Module, sichtbar gruppierte Arbeitsräume und ein gebauter Weg zwischen Eingang und Landepad.",
        "assignments": ["terrain: große unregelmäßige Schichtklippen und gestaffelte Felsgruppen", "structures: creme-orange Rahmen, Sockel, Eingänge und lesbare Funktionsgruppen", "connections: gemeinsame Wege, Pad und einzelne Anschlussgruppen"],
        "limits": "Raumaufteilung ist eine Formreferenz. Bettenzahlen, Erweiterungsmarken und Beschriftungen beauftragen keine Innenraum-, Basis- oder Wirtschaftssimulation.",
    },
    {
        "id": "ref_freihafen", "filename": "02_freihafen_distribution_center.png",
        "source": "C:/Users/bjoer/AppData/Local/Temp/codex-clipboard-1f877621-9b3e-4afa-919a-7c8e41fbe0cc.png",
        "title": "Freihafen · Distribution Center", "group": "buildings",
        "description": "Zusammengehörige creme-orange Hallen, breite Torrahmen, Arbeitsbuchten, geordnete Containergruppen und verbundene graue Plattformen vor roten Klippen.",
        "assignments": ["terrain: weite rostrote Landschaft mit kühlen grauen Bauflächen", "structures: kräftige Rahmen, große ruhige Dachformen und verständliche Arbeitsausstattung", "composition: Hauptgebäude, Nebenmodul und Pad über gebaute Flächen verbinden"],
        "limits": "Der Grafikpass übernimmt Formhierarchie und Funktionsgruppen. Eine komplette Lagerhalle, Warenwirtschaft, Fahrzeuge oder Logistiksimulation sind damit nicht implementiert oder zusätzlich beauftragt.",
    },
    {
        "id": "ref_tactical", "filename": "03_taktische_rostwelt_gesamtkarte.png",
        "source": "C:/Users/bjoer/AppData/Local/Temp/codex-clipboard-720890b3-d6c0-4574-8cc3-053eeede46f7.png",
        "title": "Rostwelt · Taktische Gesamtansicht", "group": "terrain",
        "description": "Weite isometrische Spiellandschaft mit geschichteter Klippenkante, einzelnen Felstürmen, offenen Bewegungsräumen und einer verbundenen Gruppe heller Cutaway-Module.",
        "assignments": ["terrain: natürlich gestaffelte Randklippen, ruhige offene Flächen und wenige große Felsgruppen", "composition: Gebäudemassen, Radar/Pad und Wegschleifen im Spielabstand lesbar halten", "people: kleine Gruppen und klare Auswahl vor ruhigem Boden beurteilen"],
        "limits": "Die sichtbaren Quadratfelder sind Bildinhalt. Der ausdrücklich beauftragte Spielvertrag bleibt hex_axial_v1; das Bild löst keine Rückmigration zu Quadratfeldern aus.",
    },
]

HISTORY = [
    ("history_menu", "Use AI Image Apr 18, 2026, 23_16_45.jpeg", "Crew · Schiffsinnenraum", "Früherer Hauptmenühintergrund, TASK_199.", "Assets/curated/main_menu/sternenbuerger_main_menu_bg.jpeg"),
    ("history_explosion", "Use AI Image Apr 18, 2026, 23_21_53.jpeg", "Roter Außenposten · Explosion", "Früherer Debrief-/Ergebnishintergrund, TASK_245.", "Assets/used/backgrounds/ai_generated/bg_desert_explosion_base.jpg"),
    ("history_hangar", "Use AI Image Apr 18, 2026, 23_34_01.png", "Blaue Hangarhalle", "Früherer Lobby-/Setuphintergrund, TASK_245.", "Assets/used/backgrounds/ai_generated/bg_hangar_shiphall.png"),
    ("history_night", "Use AI Image Apr 18, 2026, 23_36_53.jpeg", "Nächtlicher Außenposten", "Ältere lokale Bildquelle; kein belegter Katalogeintrag oder Modellfreigabestatus.", None),
    ("history_space_simple", "Use AI Image Apr 18, 2026, 23_38_25.png", "Asteroidenflug · Flächige Fassung", "Ältere lokale Bildquelle; kein belegter Katalogeintrag oder Modellfreigabestatus.", None),
    ("history_space", "Use AI Image Apr 18, 2026, 23_41_57.png", "Asteroidenflug · Detailfassung", "Früherer Lade-/Lobbyhintergrund, TASK_245.", "Assets/used/backgrounds/ai_generated/bg_asteroid_flight.png"),
    ("history_desert", "Use AI Image Apr 18, 2026, 23_45_03.png", "Sandiger Raumhafen", "Früherer Missionsauswahl-/Setuphintergrund, TASK_245.", "Assets/used/backgrounds/ai_generated/bg_desert_outpost.png"),
    ("history_shadowfall", "../Shadowfall_Map_2.png", "Shadowfall · Alpha / Bravo / Charlie / Delta", "Ältere lokale taktische Karte auf grauem Boden mit Kompass. Eigenständiges Bild, ausdrücklich nicht identisch mit der neu gelieferten roten Gesamtkarte.", None),
]


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def preserve(source: Path, destination: Path) -> dict:
    source_hash = digest(source)
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.exists():
        if digest(destination) != source_hash:
            raise RuntimeError(f"Refusing to overwrite a different preserved original: {destination}")
    else:
        shutil.copyfile(source, destination)
    if digest(destination) != source_hash:
        raise RuntimeError(f"Reference copy differs from original: {destination}")
    with Image.open(destination) as picture:
        dimensions = list(picture.size)
    return {"source_path": source.as_posix(), "package_path": destination.relative_to(ROOT).as_posix(),
            "sha256": source_hash, "bytes": destination.stat().st_size,
            "dimensions": dimensions, "copy_byte_identical": True, "artwork_modified": False}


def main() -> None:
    current = []
    for spec in CURRENT:
        row = {key: value for key, value in spec.items() if key not in ("source", "filename")}
        row.update(preserve(Path(spec["source"]), PACKAGE / "current" / spec["filename"]))
        row.update({"origin": "user attachment re-supplied in the active chat on 2026-11-01",
                    "status": "current_user_reference", "native_engine_capture": False,
                    "earlier_generation_provenance": "not supplied; no prompt/tool attribution inferred",
                    "approval_scope": "visual target assignment for ART_2026_11_01_pass02; no automatic model or gameplay acceptance"})
        current.append(row)
    historical = []
    for identifier, filename, title, description, project_copy in HISTORY:
        source = (LOCAL / filename).resolve()
        row = {"id": identifier, "title": title, "description": description,
               "status": "historical_context_only", "active_model_reference": False,
               "origin": "older local image; original generation prompt/tool not available",
               "project_copy": project_copy}
        row.update(preserve(source, PACKAGE / "historical" / source.name))
        if project_copy:
            row["project_copy_byte_identical"] = digest(ROOT / project_copy) == row["sha256"]
            row["catalog_evidence"] = "docs/assets/background_image_catalog.md; docs/tasks/TASK_199_main_menu_shell_background_image.md; docs/tasks/TASK_245_background_image_catalog_and_screen_usage.md"
        historical.append(row)
    manifest = {"schema": "sternenbuergerchen.graphics_references.v1", "date": "2026-11-01",
                "task": "docs/tasks/ART_2026_11_01_pass02.md", "current_user_references": current,
                "historical_context": historical, "current_reference_count": len(current),
                "historical_count": len(historical), "runtime_topology": "hex_axial_v1",
                "notes": ["All packaged originals are byte-identical; report WebP derivatives are display packaging only.",
                          "Historical images document earlier UI/context, not current model approval.",
                          "The three current attachments complement generated 01/02/03 and ship targets; they are not three new generated outputs."]}
    output = ROOT / "output/grafik_20261101/reference_manifest.json"
    output.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"manifest": str(output), "current": len(current), "historical": len(historical), "all_copies_byte_identical": True}))


if __name__ == "__main__":
    main()
