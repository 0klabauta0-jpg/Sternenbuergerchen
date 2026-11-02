"""Reference assignments and a native, explicitly gated Pass-04 comparison."""
from __future__ import annotations

import hashlib
import json
from html import escape
from pathlib import Path

VIEWS = [("overview", "Übersicht"), ("workshop", "Werkstatt"),
         ("crew", "Crew"), ("hex_grid", "Hexraster"), ("landscape", "Gelände"), ("cutaway", "Basis")]
REPORT_REVISION = "r02"
SHIP_USER_STATUS = "criticized_not_accepted"
SHIP_FOLLOWUP = {"model": "Astra Ultra", "chat_id": "01a197d8-ebd0-7100-8d12-21ff6bc52c0d",
                 "output": "pass05_astra_ultra", "scope": "Separate Blender-Schiffsrevision nach denselben vier 2D-Zielen; keine automatische Runtime-Uebernahme."}
SHIP_MANIFESTS = {ship: f"art/frontier_illustrated_20261101/ships/pass04_r02/{ship}/manifest.json"
                  for ship in ("cutlass", "buccaneer")}
SHIP_TARGETS = {"cutlass": {"front": "cutlass_front", "rear": "cutlass_rear"},
                "buccaneer": {"front": "buccaneer_front", "rear": "buccaneer_rear"}}


def read(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def capture_is_current(metadata: dict) -> bool:
    return metadata.get("report_ready") is True and metadata.get("report_revision") == REPORT_REVISION


def prepare_pass04(root: Path, art: Path, add, *, verify_current_runtime: bool = True) -> dict:
    references = read(root / "output/grafik_20261101/reference_manifest.json")
    pass04_references = read(root / "output/grafik_20261101/pass04_reference_manifest.json")
    for row in pass04_references["references"]:
        add(row["id"], root / row["package_path"], row["title"], "references",
            "Externe visuelle Padreferenz · Community-Ingame-Screenshot",
            row["assignment"] + " " + row["attribution"], kind="reference",
            source_original_path=row["source_path"], origin=row["attribution"],
            original_source_url=row["image_url"], page_url=row["page_url"],
            reference_label="Externe Community-Bildquelle · Star Citizen Wiki",
            copy_byte_identical=True)
    for row in references["current_user_references"]:
        add(row["id"], root / row["package_path"], row["title"], row["group"],
            "Aktuelle Nutzerreferenz · Grafikpass 04", row["description"],
            kind="primary_reference", assignments=row["assignments"], limits=row["limits"],
            source_original_path=row["source_path"], origin=row["origin"],
            copy_byte_identical=row["copy_byte_identical"], active_model_reference=True)
    for row in references["historical_context"]:
        add(row["id"], root / row["package_path"], row["title"], "references",
            "Historischer Kontext · keine aktive Modellfreigabe", row["description"],
            kind="historical_reference", source_original_path=row["source_path"],
            origin=row["origin"], copy_byte_identical=row["copy_byte_identical"],
            active_model_reference=False)

    rejected = read(root / "output/grafik_20261101/pass04_rejected_r01_manifest.json")
    archived_metadata = root / rejected["capture_metadata_archive"]
    if hashlib.sha256(archived_metadata.read_bytes()).hexdigest() != rejected["capture_metadata_sha256"]:
        raise ValueError("Changed rejected R01 capture metadata")
    for row in rejected["views"]:
        if hashlib.sha256((root / row["archive_path"]).read_bytes()).hexdigest() != row["sha256"]:
            raise ValueError(f'Changed rejected R01 native archive: {row["archive_path"]}')
        add(row["id"], root / row["archive_path"],
            f'{row["ship"].title()} · R01 abgelehnt · {"Vorn" if row["view"] == "front" else "Heck"}',
            row["ship"], "Vom Nutzer ausdrücklich abgelehnt · R01",
            "Archivierter nativer R01-Zwischenstand. Keine Modellfreigabe und kein aktuelles R02-Nachherbild. Die nächste Revision hat eigene Quellen und Notizen.",
            kind="rejected_r01_native_ship", revision="r01", user_rejected=True,
            source_model=rejected["source_manifest"], current_model_approval=False)

    before = read(root / "output/grafik_20261101/pass04_before_capture.json")
    after_path = root / "output/grafik_20261101/pass04_after_capture.json"
    candidate_metadata = read(after_path) if after_path.is_file() else {}
    released = capture_is_current(candidate_metadata)
    after = candidate_metadata if released else {}
    after_paths = [art / "engine_pass04/after" / f"{view}.png" for view, _ in VIEWS]
    ready = released and all(path.is_file() for path in after_paths)
    if released and not ready:
        raise FileNotFoundError("Pass04 metadata releases captures, but an archived after image is missing")
    before_cameras = {item["id"]: item for item in before.get("captures", [])}
    after_cameras = {item["id"]: item for item in after.get("captures", [])}
    pairs = []
    for view, title in VIEWS:
        before_path = art / "engine_pass04/before" / f"{view}.png"
        before_id = f"pass04_before_{view}"
        add(before_id, before_path, f"Vorher · Pass 03 · {title}", "engine",
            "Native Godot-Aufnahme · unverändert gesicherter Vorherstand",
            "Unveränderter Ausgangsstand aus Pass 03: Kenney-basierte Cutaway-/Hallenassemblies, gebrochene Felsen, bisherige Wege/Padform und beibehaltene Kenney-Ausrüstung.",
            kind="pass04_before", view=view, synthetic_fixture=True,
            source_model="output/grafik_20261101/pass04_before_capture.json")
        row = {"id": view, "title": title, "before_id": before_id,
               "before_path": before_path.relative_to(root).as_posix(),
               "before_sha256": hashlib.sha256(before_path.read_bytes()).hexdigest(),
               "before_camera": before_cameras.get(view, {}), "after_id": None}
        if ready:
            after_image = art / "engine_pass04/after" / f"{view}.png"
            after_id = f"pass04_after_{view}"
            add(after_id, after_image, f"Nachher · Grafikpass 04 · {title}", "engine",
                "Native Godot-Aufnahme · gesicherter Grafikpass 04",
                "Tatsächlich gerenderter Pass-04-Kandidat. Mit dem gesicherten Vorherbild derselben Ansichts-ID vergleichen; Kamera-, Renderer- und Lichtangaben stehen in den Metadaten.",
                kind="pass04_after", view=view, synthetic_fixture=True,
                source_model="output/grafik_20261101/pass04_after_capture.json")
            row.update({"after_id": after_id,
                        "after_path": after_image.relative_to(root).as_posix(),
                        "after_sha256": hashlib.sha256(after_image.read_bytes()).hexdigest(),
                        "after_camera": after_cameras.get(view, {}),
                        "camera_size_match": before_cameras.get(view, {}).get("camera_size") == after_cameras.get(view, {}).get("camera_size"),
                        "camera_transform_match": before_cameras.get(view, {}).get("camera_transform") == after_cameras.get(view, {}).get("camera_transform"),
                        "camera_projection_match": before_cameras.get(view, {}).get("camera_projection") == after_cameras.get(view, {}).get("camera_projection"),
                        "viewport_size_match": before_cameras.get(view, {}).get("viewport_size") == after_cameras.get(view, {}).get("viewport_size")})
            for field in ("camera_size", "camera_transform", "camera_projection", "viewport_size"):
                if field not in before_cameras.get(view, {}) or field not in after_cameras.get(view, {}):
                    raise ValueError(f"Missing comparison camera evidence: {view}, {field}")
                if before_cameras[view][field] != after_cameras[view][field]:
                    raise ValueError(f"Comparison camera differs: {view}, {field}")
            if after_cameras[view].get("building_shells_visible") is not False:
                raise ValueError(f"Comparison must retain the explicitly open building state: {view}")
        pairs.append(row)
    extras = []
    citizens = []
    structures = {}
    ships = {}
    ship_views = []
    building_views = []
    r01_ship_cameras = {}
    if ready:
        if verify_current_runtime:
            for source_path, expected_hash in after.get("runtime_sources_sha256", {}).items():
                if hashlib.sha256((root / source_path.removeprefix("res://")).read_bytes()).hexdigest() != expected_hash:
                    raise ValueError(f"Capture runtime source differs from current bytes: {source_path}")
        if not after.get("runtime_sources_sha256"):
            raise ValueError("Released R02 capture must identify runtime source hashes")
        if not {"res://scripts/terrain/frontier_closed_buildings.gd", "res://scripts/tests/frontier_art_preview.gd"}.issubset(after["runtime_sources_sha256"]):
            raise ValueError("Released closed views must identify the own Godot shell builder and preview source")
        structures = read(root / "art/frontier_illustrated_20261101/structures/pass04/manifest.json")
        ships = {"revision": REPORT_REVISION, "manifests": {}, "assets": []}
        captured_models = {row["path"].removeprefix("res://"): row["source_sha256"] for row in after["models"]}
        for ship, manifest_path in SHIP_MANIFESTS.items():
            manifest = read(root / manifest_path)
            ships["manifests"][ship] = {"path": manifest_path, "data": manifest}
            if isinstance(manifest.get("assets"), list):
                assets = manifest["assets"]
            elif isinstance(manifest.get("asset"), dict):
                assets = [manifest["asset"]]
            elif isinstance(manifest.get("asset"), str) and "export" in manifest:
                assets = [manifest]
            else:
                raise ValueError(f"No explicit R02 ship asset in {manifest_path}")
            for asset in assets:
                exported = asset["export"]
                export_path = exported["path"].replace("\\", "/")
                if "/ships_pass04_r02/" not in export_path:
                    raise ValueError("R02 source manifest points at a superseded ship export")
                if hashlib.sha256((root / export_path).read_bytes()).hexdigest() != exported["sha256"]:
                    raise ValueError(f"Changed R02 ship export: {export_path}")
                if captured_models.get(export_path) != exported["sha256"]:
                    raise ValueError(f"Native capture did not use the selected R02 ship: {export_path}")
                ships["assets"].append({**asset, "report_ship": ship, "report_manifest": manifest_path})
        for index, row in enumerate(structures.get("official_industrial_references", []), 1):
            if hashlib.sha256((root / row["path"]).read_bytes()).hexdigest() != row["sha256"]:
                raise ValueError("Changed official industrial reference image")
            add(f"ref_rsi_industrial_{index}", root / row["path"],
                f"RSI · Idris-Industrie · WIP 2013 · {index}", "references",
                "Offizielle RSI-WIP-In-Engineaufnahme von 2013 · kein aktueller Gameplay-Screenshot",
                "Vorlage für getragene Industriegruppen, lesbare Rohr-/Kontrollanschlüsse und zurückhaltende Materialkontraste. Keine exakte Geometrie oder Spieltextur übernommen.",
                kind="reference", original_source_url=row["url"], page_url=row["page"],
                origin="Roberts Space Industries, WIP: Idris Deck Gallery, 04.11.2013",
                reference_label="Offizielle RSI-WIP-Bildquelle · 2013")
        capture_ids = {row["id"] for row in after["captures"]}
        if not {f"{ship}_{view}" for ship in SHIP_TARGETS for view in ("front", "rear")}.issubset(capture_ids):
            raise ValueError("Released Pass04 requires four native ship front/rear views")
        if not {"closed_habitat", "closed_hall", "closed_outpost"}.issubset(capture_ids):
            raise ValueError("Released R02 capture must show closed building views")
        old_ship_cameras = {row["id"]: row for row in read(archived_metadata)["captures"]}
        for ship in SHIP_TARGETS:
            for view in ("front", "rear"):
                camera_id = f"{ship}_{view}"
                previous = old_ship_cameras[camera_id]
                current = after_cameras[camera_id]
                for field in ("camera_size", "camera_transform", "camera_projection", "viewport_size"):
                    if field not in previous or field not in current or previous[field] != current[field]:
                        raise ValueError(f"Rejected R01/R02 ship comparison camera differs: {camera_id}, {field}")
                r01_ship_cameras[camera_id] = {"camera_match": True, "r01": previous, "r02": current}
        for closed_id, open_id in (("closed_habitat", "cutaway"), ("closed_hall", "workshop"), ("closed_outpost", "outpost")):
            for field in ("camera_size", "camera_transform", "camera_projection", "viewport_size"):
                if field not in after_cameras[closed_id] or field not in after_cameras[open_id]:
                    raise ValueError(f"Missing building camera evidence: {closed_id}/{open_id}, {field}")
                if after_cameras[closed_id][field] != after_cameras[open_id][field]:
                    raise ValueError(f"Building state cameras differ: {closed_id}/{open_id}, {field}")
            if after_cameras[open_id].get("building_shells_visible") is not False:
                raise ValueError(f"Open building view lacks explicit state evidence: {open_id}")
        if not structures.get("kenney_sources"):
            raise ValueError("Released Pass04 structures must document the actual Kenney source geometry")
        for source in structures["kenney_sources"]:
            for file_key, hash_key in (("path", "sha256"), ("license_path", "license_sha256")):
                actual = hashlib.sha256((root / source[file_key]).read_bytes()).hexdigest()
                if actual != source[hash_key]:
                    raise ValueError(f"Changed Kenney source/license: {source[file_key]}")
        pair_ids = {view for view, _ in VIEWS}
        extra_labels = {
            "walk_pose": ("Crew · Gehpose", "Native Walk-Momentaufnahme. Die Ausrüstungskandidaten aus Pass 02 bleiben erhalten; eine Pose ersetzt keinen vollständigen Bewegungstest."),
            "baseline": ("Pass 04 · Farbprofil aus", "Derselbe Pass-04-Ausschnitt mit ausgeschaltetem Frontier-Farbprofil. Das ist ein Profilvergleich, kein zusätzlicher Vorherstand."),
            "utility": ("Versorgung · neue Baugruppe", "Zusätzliche native Ansicht der überarbeiteten Versorgungsbaugruppe. Kein identisches Vorherpaar; keine neue Betankungs- oder Fahrzeugmechanik."),
            "outpost": ("Außenposten · neue weite Ansicht", "Neue weite Kamera für Schiffe, größere Pads und verbundene Wege. Kein identisches Vorherbild; Fahrzeugmaßstab bewusst stilisiert."),
            "closed_habitat": ("Basis · geschlossen", "Zusätzliche native Ansicht mit geschlossener Gebäudehülle. Visueller Dach-/Wandzustand, keine Innenraumsimulation."),
            "closed_hall": ("Halle · geschlossen", "Zusätzliche native geschlossene Hallenansicht; derselbe Standort wie die aktuelle Schnittdarstellung."),
            "closed_outpost": ("Außenposten · geschlossene Gebäude", "Neue weite Nachheransicht mit geschlossenen Gebäudehüllen. Kein gleiches geschlossenes Vorherbild vorhanden."),
        }
        for capture in after.get("captures", []):
            view = capture["id"]
            if view in pair_ids:
                continue
            if view in {f"{ship}_{angle}" for ship in SHIP_TARGETS for angle in ("front", "rear")}:
                ship, angle = view.rsplit("_", 1)
                identifier = f"pass04_after_{view}"
                add(identifier, art / "engine_pass04/after" / f"{view}.png",
                    f'{ship.title()} · Revision R02 · {"Vorn" if angle == "front" else "Heck"}', ship,
                    "Native Godot-Aufnahme · R02 vom Nutzer weiterhin kritisiert · keine Gestaltungsfreigabe",
                    "Technischer Zwischenstand nach dem zugeordneten 2D-Bildpaar. Der Nutzer beurteilt auch R02 noch als zu weit vom Ziel entfernt; beide Schiffe werden im separaten Astra-Ultra-Blender-Chat weiter überarbeitet. Die früheren Rohmaterialstudien sind keine Geometriequelle. Preview-Maßstab bewusst stilisiert, keine kanonischen Star-Citizen-Maße.",
                    kind="pass04_ship", ship=ship, view=angle,
                    source_model=SHIP_MANIFESTS[ship], geometry_unchanged=False, revision=REPORT_REVISION,
                    current_model_approval=False, user_status=SHIP_USER_STATUS)
                ship_views.append({"id": identifier, "ship": ship, "view": angle,
                                   "target_id": SHIP_TARGETS[ship][angle]})
                continue
            title, description = extra_labels.get(view, (f"Pass 04 · {view}", "Zusätzliche native Pass-04-Ansicht ohne identische Vorherkamera. Die Aufnahmebedingungen stehen in den Metadaten."))
            identifier = f"pass04_after_{view}"
            add(identifier, art / "engine_pass04/after" / f"{view}.png", title, "engine",
                "Native Godot-Aufnahme · zusätzliche Pass-04-Ansicht", description,
                kind="pass04_extra", view=view, synthetic_fixture=True,
                source_model="output/grafik_20261101/pass04_after_capture.json")
            extras.append({"id": identifier, "view": view, "title": title, "description": description})
            if view.startswith("closed_"):
                if capture.get("building_shells_visible") is not True:
                    raise ValueError(f"Closed view lacks explicit closed-state evidence: {view}")
                building_views.append({"id": identifier, "view": view, "closed": True})

    citizen_manifest = read(root / "art/frontier_illustrated_20261101/citizens/pass02/manifest.json")
    citizens = [{"role": row["role"], "triangles": row["stats_rest"]["triangles"],
                 "meshes": row["mesh_count_glb"], "materials": row["material_count_glb"],
                 "skins": row["skin_count_glb"], "stock_body_triangles": row["body_triangles"],
                 "stock_files_unchanged": row["stock_files_unchanged_against_pass01_manifest"],
                 "path": row["glb"], "sha256": row["glb_sha256"]} for row in citizen_manifest["assets"]]
    return {"references": references, "before_metadata": before, "after_metadata": after,
            "after_ready": ready, "pairs": pairs, "after_extras": extras,
            "citizen_candidates": citizens,
            "structure_candidates": structures.get("assets", []),
            "kenney_sources": structures.get("kenney_sources", []),
            "kenney_supporting_files": structures.get("kenney_supporting_files", structures.get("supporting_files", [])),
            "external_visual_references": pass04_references,
            "official_industrial_references": structures.get("official_industrial_references", []),
            "ship_manifest": ships,
            "ship_manifest_paths": SHIP_MANIFESTS,
            "ship_views": ship_views,
            "building_views": building_views,
            "r01_ship_camera_comparison": r01_ship_cameras,
            "ship_user_status": SHIP_USER_STATUS, "ship_followup": SHIP_FOLLOWUP,
            "revision": REPORT_REVISION, "rejected_r01": rejected,
            "runtime_source_validation": "current_files" if verify_current_runtime else "historical_capture_snapshot",
            "renderer_match": before.get("renderer") == after.get("renderer") if ready else None,
            "light_unchanged": before.get("light") == after.get("light") if ready else None,
            "scope": "synthetic graphics fixture; no campaign/editor migration or release acceptance"}


def render_structure_provenance(data: dict) -> str:
    ready = data["after_ready"]
    sources = data["kenney_sources"]
    rows = []
    for source in sources:
        usage_counts = {}
        for row in source["usages"]:
            count = len(row["instances"]) if "instances" in row else 1 if row.get("instance") else 0
            usage_counts[row["asset"]] = usage_counts.get(row["asset"], 0) + count
        usages = ", ".join(f'{asset}: {count} Instanz(en)' for asset, count in usage_counts.items())
        adaptation = ("Originale Pfosten-/Sturzgeometrie zum offenen U-Rahmen abgeleitet; geschlossenes Türblatt und untere Schwelle entfernt, Schnitte geschlossen."
                      if Path(source["path"]).name == "door.glb" else
                      "Originalgeometrie importiert, als abgeleitete Montage bereinigt, Farbflächen ersetzt und je Instanz passend skaliert/gedreht.")
        rows.append(
            '<tr><th scope="row">' + escape(Path(source["path"]).name) + '<small>' + escape(source["pack"]) + '</small></th>'
            '<td>' + escape(usages) + '</td><td>' + escape(adaptation) + '</td><td>' + escape(source["license"]) +
            '<details><summary>Pfad, Hash und Originalangaben</summary><a href="../../' + escape(source["path"], quote=True) + '">Original-GLB ↗</a>'
            '<code>' + escape(source["path"]) + '</code><code>SHA-256: ' + escape(source["sha256"]) + '</code>'
            '<a href="../../' + escape(source["license_path"], quote=True) + '">Lizenz ↗</a><code>Lizenz-SHA-256: ' + escape(source["license_sha256"]) + '</code>'
            '<p>Originaldatei unverändert: ' + ("ja" if source["original_file_unchanged"] else "nein") + '</p>'
            '<pre>' + escape(json.dumps(source, ensure_ascii=False, indent=2)) + '</pre></details></td></tr>')
    table = ('<p class="provenance-count"><strong>' + str(len(sources)) + ' tatsächlich verwendete Original-GLBs</strong> aus Space Station und Factory. '
             'Gezählt werden ausschließlich tatsächlich in den aktuellen Assemblies verwendete Quelldateien. '
             'Zur Farbzuordnung gelesene Atlanten bleiben Hilfsquellen und zählen nicht als Geometriemodule.</p>'
             '<div class="table-scroll"><table class="qa-table provenance-source-table"><thead><tr><th>Originalmodul / Paket</th><th>Tatsächlicher Einsatz</th><th>Anpassung der Ableitung</th><th>Lizenz und Nachweis</th></tr></thead><tbody>'
             + "".join(rows) + '</tbody></table></div>') if ready else ''
    models = []
    for model in data["structure_candidates"]:
        export = model["export"]
        models.append(f'<tr><th scope="row">{escape(model["asset"])}</th><td>{export["triangles"]:,}</td><td>{export["meshes"]} / {export["materials"]}</td><td>{len(model.get("qa_errors", model.get("qa", {}).get("source_errors", [])))} / {len(model.get("qa_warnings", model.get("qa", {}).get("source_warnings", [])))}</td></tr>'.replace(",", "."))
    model_table = ('<h3>Neue Kenney-basierte Assemblies mit eigenen Ergänzungen</h3><div class="table-scroll"><table class="qa-table"><thead><tr><th>Kandidat</th><th>Dreiecke</th><th>Meshes / Materialien</th><th>Source-QA: Fehler / akzeptierte Warnungen</th></tr></thead><tbody>'
                   + "".join(models) + '</tbody></table></div><p class="section-footnote">Warnungen betreffen dokumentierte verdeckte Modulstirnkontakte und Montage-/Attributkanten. Sie wurden im Rohbericht belassen und begründet akzeptiert; bestandene QA bedeutet hier keine warnungsfreie Geometrie. Diese Assemblies sind angepasste Zusammenstellungen, keine unveränderten Kit-Exporte und keine vollständig unabhängig modellierten Strukturen.</p>') if ready else ''
    evidence = (
        '<details class="capture-metadata"><summary>Tatsächliche Kenney-Quellen: Herkunft, Hash, Lizenz und Anpassungen</summary>'
        '<pre>' + escape(json.dumps({"kenney_sources": sources, "supporting_color_atlases": data["kenney_supporting_files"]}, ensure_ascii=False, indent=2)) + '</pre></details>'
        if ready else
        '<p class="section-footnote">Die Strukturrevision und ihr Herkunftsmanifest werden gerade fertiggestellt. Quellübernahmen sind erst zusammen mit dem finalen Manifest und den freigegebenen nativen Aufnahmen als Nachherstand belegt.</p>')
    return (
        '<section id="bauteilherkunft" class="section provenance-section" aria-labelledby="provenance-heading">'
        '<div class="section-head"><div><div class="eyebrow">Echte Bauteilgrundlage / eigene Ergänzung / Bildziel</div>'
        '<h2 id="provenance-heading">Kenney-Geometrie statt bloßem Stilnamen.</h2></div>'
        '<p>Space Station, Wandmodule und Factory dienen nach der aktuellen Nutzersteuerung als tatsächliche Baukastengrundlage. Der Herkunftsnachweis unterscheidet übernommene Bauteile und eigene Konstruktion.</p></div>'
        '<div class="provenance-grid"><article><span class="tag teal">Übernommene Originalgeometrie</span>'
        '<h3>Kenney Space Station / Factory</h3><p>Wandpaneele, Betten, Display, Computer und Container sowie Factory-Torrahmen, Kran und Tank. '
        'Welche Original-GLBs tatsächlich verwendet und wie sie angepasst wurden, führt das finale Quellmanifest mit Hash und Lizenz auf. Die Originaldateien bleiben erhalten.</p></article>'
        '<article><span class="tag ochre">Eigene Ergänzung und Montage</span><h3>Rostgrenze und Freihafen</h3>'
        '<p>Eigene Raum-/Hallenkonstruktion, Schnittdarstellung und Zusammenstellung ergänzen die übernommenen Module. Änderungen an Form, Maßstab, Orientierung, Farbmaterial oder Platzierung müssen im jeweiligen Quellnachweis nachvollziehbar bleiben.</p></article>'
        '<article><span class="tag">Nur visuelles Ziel</span><h3>Die drei Hauptvorlagen</h3>'
        '<p>Rostgrenze, Freihafen und taktische Gesamtkarte führen Komposition, Silhouette und Farbgruppen. Aus ihren Pixeln wird keine fertige Modellgeometrie übernommen. Bildbeschriftungen erzeugen keine Innenraum- oder Wirtschaftssimulation.</p></article></div>'
        + table + model_table + evidence +
        ('<p>Ergänzende Industrie-Bildsprache: <a href="' + escape(data["official_industrial_references"][0]["page"], quote=True) + '">RSI: WIP Idris Deck Gallery, 04.11.2013 ↗</a>. Offizielle damalige In-Engine-WIP-Bilder, keine heutigen Gameplay-Screenshots; keine übernommenen Texturen oder exakten Modellgeometrien.</p>' if data["official_industrial_references"] else '') +
        '<p><a href="../../art/frontier_illustrated_20261101/structures/pass04/manifest.json">Strukturmanifest mit tatsächlichen Bauteilquellen ↗</a></p></section>')


def render_ship_comparison(data: dict) -> str:
    pending = ('<p class="pass04-pending" id="shipUserStatus"><strong>Auch R02 trifft das Bildziel für den Nutzer noch nicht.</strong> '
               'Die Modelle bleiben technische Zwischenstände ohne gestalterische Annahme. Beide Schiffe werden im beauftragten separaten Astra-Ultra-Blender-Chat nach denselben vier Bildzielen erneut überarbeitet. '
               + ('Die aktuellen nativen R02-Bilder zeigen den tatsächlichen Stand für den direkten Vergleich.' if data["after_ready"] else 'Native R02-Bilder erscheinen hier erst nach der technischen Capturefreigabe; alte R01-Bilder schalten sie nicht frei.')
               + '</p>')
    manifest_links = " · ".join(f'<a href="../../{escape(path, quote=True)}">{escape(ship.title())} R02-Manifest ↗</a>' for ship, path in data["ship_manifest_paths"].items())
    rejected = "".join(
        f'<figure><button type="button" data-open="{row["id"]}"><img data-src-id="{row["id"]}" alt="{escape(row["ship"].title())} R01 {row["view"]}, vom Nutzer abgelehnt"></button>'
        f'<figcaption>{escape(row["ship"].title())} · {"Vorn" if row["view"] == "front" else "Heck"} · <strong>R01 ausdrücklich abgelehnt</strong></figcaption></figure>'
        for row in data["rejected_r01"]["views"])
    return (
        '<section id="neue-schiffe" class="section" aria-labelledby="new-ships-heading">'
        '<div class="section-head"><div><div class="eyebrow">Pass 04 / R02 nach Ablehnung der ersten Modelle</div>'
        '<h2 id="new-ships-heading">Schiffe: Zwischenstand und offenes Bildziel.</h2></div>'
        '<p>Die vereinfachten Bildpaare führen die neuen Modellkandidaten: Cutlass 08/09, Buccaneer 13/11. '
        'Die früheren Roh-OBJ-/Materialstudien werden nicht als Geometriequelle übernommen.</p></div>' + pending +
        '<div class="pass04-toolbar"><div class="segmented" role="group" aria-label="Schiffvergleich auswählen">'
        '<button type="button" data-ship-compare="target" aria-pressed="true">2D-Ziel ↔ R02</button>'
        '<button type="button" data-ship-compare="rejected" aria-pressed="false">R01 abgelehnt ↔ R02</button></div>'
        '<div class="segmented" role="group" aria-label="Neue Schiffe: Ziel und Modell synchron ansehen">'
        '<button type="button" data-pass04-ship-view="front" aria-pressed="true">Vorn / oben</button>'
        '<button type="button" data-pass04-ship-view="rear" aria-pressed="false">Heck / oben</button></div></div>'
        '<div id="newShipComparisons"></div>'
        '<p class="section-footnote">R01 wurde ausdrücklich abgelehnt. Der direkte native R01/R02-Vergleich nutzt dieselben Schiffskameras; Materialien, Boden und weitere Umgebungsdetails dürfen sich in dieser Grafikrevision ändern. Das ist keine Behauptung konstanter Aufnahmebedingungen oder eine Nutzerabnahme.</p>'
        '<p class="section-footnote">Beauftragte Fortsetzung: Astra Ultra · separater Blender-Chat <code>01a197d8-ebd0-7100-8d12-21ff6bc52c0d</code> · eigener Ausgabebereich <code>pass05_astra_ultra</code>. Dessen Ergebnisse sind hier noch nicht integriert oder abgenommen.</p>'
        '<p class="section-footnote">Die native Darstellung und die Displaylängen sind bewusst stilisiert; keine kanonischen Star-Citizen-Maße. '
        'Eigene editierbare Quellen, Exporte, Modellmaße und QA stehen im '
        + manifest_links + '. Die Bildvorlagen sind Illustrationen; sie teilen keine identische Kamera mit dem nativen Modell.</p>'
        '<details id="rejectedR01Ships" class="history-references"><summary>Abgelehnte R01-Schiffe · vier native Archivbilder</summary>'
        '<p>Beide ersten Modelle wurden vom Nutzer ausdrücklich abgelehnt. Diese Aufnahmen sind unverändert erhalten; ihre technischen Checks oder lokale Notizen sind keine Freigabe für R02.</p>'
        '<div class="pass04-extra-pair">' + rejected + '</div>'
        '<p><a href="../../output/grafik_20261101/pass04_rejected_r01_manifest.json">R01-Ablehnung, Herkunft und Archivhashes ↗</a></p></details></section>')


def render_building_states(data: dict) -> str:
    if not data["after_ready"]:
        return ('<section id="gebaeudeansichten" class="section"><div class="eyebrow">Neue Nutzerkorrektur / R02 in Arbeit</div>'
                '<h2>Gebäude auch geschlossen zeigen.</h2><p>Geschlossene Hüllen und grafische Schnittansichten, mehr Schrägen/Fasen und gezielte Nieten werden überarbeitet. '
                'Die zusätzlichen geschlossenen Hüllen entstehen als eigene Godot-Geometrie über den Kenney-Cutaway-GLBs, nicht aus einem vorgetäuschten Kenney-Dach-GLB. Native Umschaltung und passende Bilder folgen erst nach der neuen Capturefreigabe. Boden, Felsen und Wege bleiben Teil derselben Grafikrevision.</p></section>')
    return (
        '<section id="gebaeudeansichten" class="section" aria-labelledby="building-state-heading"><div class="section-head"><div><div class="eyebrow">Pass 04 / R02 · zwei aktuelle Sichtzustände</div>'
        '<h2 id="building-state-heading">Geschlossene Hülle und Cutaway.</h2></div><p>Beide Zustände zeigen den aktuellen Nachherstand. Die äußeren Dach-/Fassadenschalen sind zusätzliche eigene Godot-Geometrie über den Kenney-Cutaway-GLBs, kein importierter Kenney-Dach-GLB. Der Bildumschalter ist kein Vorher-/Nachhervergleich und verändert keine Spielzustände.</p></div>'
        '<div class="pass04-toolbar"><div class="segmented" role="group" aria-label="Gebäude auswählen"><button type="button" data-building-view="habitat" aria-pressed="true">Basis</button><button type="button" data-building-view="hall" aria-pressed="false">Halle</button><button type="button" data-building-view="outpost" aria-pressed="false">Außenposten</button></div>'
        '<div class="segmented" role="group" aria-label="Sichtzustand auswählen"><button type="button" data-building-mode="closed" aria-pressed="true">Geschlossen</button><button type="button" data-building-mode="open" aria-pressed="false">Schnittansicht</button></div></div>'
        '<figure class="pass04-landscape"><button type="button" id="buildingStateButton"><img id="buildingStateImage" alt="Aktuelle Gebäudeansicht"><span class="zoom-cue">Ansicht vergrößern ↗</span></button><figcaption id="buildingStateCaption"></figcaption></figure>'
        '<label>Offene Unterschiede der Gebäudehülle<textarea data-export-key="buildings.note" placeholder="Dach, Fasen, Schrägen, Nieten oder Einbindung …"></textarea></label></section>')


def render_pad_reference(data: dict) -> str:
    native = next((row for row in data["after_extras"] if row["view"] == "outpost"), None)
    after = (f'<button type="button" data-open="{native["id"]}"><img data-src-id="{native["id"]}" alt="Neuer nativer Außenposten mit Schiffen und Pads"></button>'
             if native else '<div class="pass04-awaiting"><span>Neue Außenpostenansicht folgt</span><p>Freigegebener nativer Pass-04-Stand ausstehend.</p></div>')
    return (
        '<section id="padvorlage" class="section" aria-labelledby="pad-reference-heading">'
        '<div class="section-head"><div><div class="eyebrow">SC-Außenposten / konkrete visuelle Vorlage</div>'
        '<h2 id="pad-reference-heading">Flache Metalldecks und klare Zugänge.</h2></div>'
        '<p>Thedus führt die Padform: flach, rechteckig und leicht gefast, mit gebrochenen Landelinien, Randlichtern und seitlichen Rampen. '
        'Die neue weite Außenpostenkamera hat kein identisches Vorher-Gegenstück; feste Bildpaare bleiben oben separat.</p></div>'
        '<div class="new-ship-pair"><figure><button type="button" data-open="ref_thedus"><img data-src-id="ref_thedus" alt="Historischer Star-Citizen-Ingame-Screenshot von HDMS-Thedus mit flachen Außenposten-Pads"></button>'
        '<figcaption>Externe visuelle Vorlage · Community-gehosteter Ingame-Screenshot. '
        '<a href="https://starcitizen.tools/HDMS-Thedus" target="_blank" rel="noopener">Star Citizen Wiki: HDMS-Thedus ↗</a> · '
        '<a href="https://media.starcitizen.tools/d/d3/HDMS_Thedus.png" target="_blank" rel="noopener">Originalbild ↗</a>. '
        'Historische Bildquelle, keine offizielle aktuelle Technik- oder Performancequelle.</figcaption></figure><figure>' + after +
        '<figcaption>Neue native Außenpostenansicht · stilisierte Schiffsmaße und eigene Komposition, keine identische Screenshot-Kamera.</figcaption></figure></div></section>')


def render_after_extras(data: dict) -> str:
    if not data["after_ready"]:
        return ""
    extras = "".join(
        f'<figure class="{'pass04-extra-feature' if row["view"] == "cutaway" else ''}"><button type="button" data-open="{escape(row["id"])}" aria-label="{escape(row["title"])} vergrößern">'
        f'<img data-src-id="{escape(row["id"])}" alt="{escape(row["title"])}"></button>'
        f'<figcaption><strong>{escape(row["title"])}</strong><p>{escape(row["description"])}</p></figcaption></figure>'
        for row in data["after_extras"] if not row["view"].startswith("closed_"))
    rows = "".join(f'<tr><th scope="row">{escape(row["role"])}</th><td>{row["triangles"]:,}</td><td>{row["meshes"]} / {row["materials"]} / {row["skins"]}</td></tr>'.replace(",", ".") for row in data["citizen_candidates"])
    return (
        '<section id="pass04-zusatzansichten" class="section pass04-extras" aria-labelledby="pass04-extra-heading">'
        '<div class="section-head"><div><div class="eyebrow">Zusätzliche Nachheransichten / ohne identisches Vorherpaar</div>'
        '<h2 id="pass04-extra-heading">Die neuen Funktionsgruppen näher ansehen.</h2></div>'
        '<p>Übersicht, Halle, Crew, Hexraster, Gelände und Basis behalten feste Vorher-/Nachherkameras. Neue Utility-, Außenposten-, Geh- und Profilansichten ergänzen den Vergleich ohne identisches Vorher-Gegenstück.</p></div>'
        '<div class="pass04-extra-pair">' + extras + '</div>'
        '<div class="pass04-model-summary"><h3>Kenney-Ausrüstung aus Pass 02 bleibt erhalten.</h3>'
        '<p>Pass 04 verändert Schiffe, Setwirkung, Versorgung, Wege und Pads. Die modular ausgerüsteten Kenney-Figuren werden als bestehender Stand beibehalten: '
        '<strong>zwei Meshes, vier Materialien und ein Skin</strong> je Figur, mit originalen Idle-/Walk-Clips. Diese Zahlen sind keine neue Figurenrevision oder Nutzerfreigabe.</p>'
        '<div class="table-scroll"><table class="qa-table"><thead><tr><th>Rolle</th><th>Beibehaltene Dreiecke</th><th>Meshes / Materialien / Skins</th></tr></thead><tbody>' + rows + '</tbody></table></div>'
        '<p><a href="../../art/frontier_illustrated_20261101/citizens/pass02/manifest.json">Erhaltene Pass-02-Figurenquellen und QA ↗</a></p></div>'
        '<aside class="pass04-open-gap"><h3>Bildfortschritt und Spielumfang getrennt beurteilen.</h3>'
        '<p>Die sechs festen Ansichten zeigen den tatsächlich aufgenommenen Stand. Weniger sterile Arbeitsbereiche, die Versorgungsbaugruppe, verbundene Wege und die größeren Pads werden gegen dieselben Hauptvorlagen beurteilt. '
        'Gegenüber den gemalten Vorlagen bleiben die großen Bodenflächen ruhiger und leerer, die Klippen stärker in regelmäßigen horizontalen Bändern aufgebaut und die geschlossenen Gebäude kompakter und rechteckiger. Materialabrieb, Geländeübergänge und die dichte Ausstattung der 2D-Außenposten sind noch nicht erreicht. '
        'Eine grafische Cutaway-Ansicht belegt keine begehbaren Innenräume; dargestellte Lager- und Werkbereiche erzeugen keine Wirtschaftssimulation. '
        'Die vorherige Kritik bleibt der Maßstab: Sets sollen benutzter wirken, Tank/Wagen plausibler und Wege/Pads näher an den SC-Außenposten. Auch die R02-Schiffe bleiben nach Nutzerurteil deutlich vom 2D-Ziel entfernt. Weitere Modellarbeit ist an den separaten Astra-Ultra-Blender-Chat beauftragt und hier noch nicht integriert. Verbleibende sichtbare Unterschiede der Umgebung werden anhand der tatsächlichen nativen Bilder benannt. '
        'Vollständige Kampagnen-/Editorübernahme, Flug-/Betankungs-/Fahrzeugmechanik und Performanceabnahme bleiben eigene Aufgaben.</p></aside></section>')


def render_primary_references(data: dict) -> str:
    cards = []
    for index, row in enumerate(data["references"]["current_user_references"], 1):
        identifier = escape(row["id"])
        search = escape(" ".join([row["title"], row["description"], *row["assignments"]]), quote=True)
        assignments = "".join(f"<li>{escape(text)}</li>" for text in row["assignments"])
        cards.append(
            f'<article class="primary-reference-card" data-reference-search="{search}" data-reference-kind="current">'
            f'<button type="button" data-open="{identifier}" aria-label="{escape(row["title"])} vergrößern">'
            f'<img data-src-id="{identifier}" alt="{escape(row["title"])}"><span class="zoom-cue">Originalvorlage vergrößern ↗</span></button>'
            f'<div class="primary-reference-body"><span class="tag teal">Aktuelle Nutzerreferenz {index:02d}</span>'
            f'<h3>{escape(row["title"])}</h3><p>{escape(row["description"])}</p>'
            f'<h4>Konkrete Zielzuordnung</h4><ul>{assignments}</ul>'
            f'<p class="reference-limit">{escape(row["limits"])}</p>'
            f'<label for="reference-decision-{identifier}">Urteil zur Umsetzung dieser Vorlage</label>'
            f'<select id="reference-decision-{identifier}" data-export-key="references.{identifier}.decision">'
            '<option value="open">Noch offen</option><option value="closer">Sichtbar näher am Ziel</option>'
            '<option value="revise">Weiter überarbeiten</option><option value="accepted">Für diesen Ausschnitt passend</option></select>'
            f'<label for="reference-note-{identifier}">Wichtigster verbleibender Abstand</label>'
            f'<textarea id="reference-note-{identifier}" data-export-key="references.{identifier}.note" placeholder="Form, Gelände, Wege, Farbflächen …"></textarea>'
            '</div></article>')
    history = []
    for row in data["references"]["historical_context"]:
        history.append(
            f'<article class="history-reference-card" data-reference-search="{escape(row["title"] + " " + row["description"], quote=True)}" data-reference-kind="historical">'
            f'<button type="button" data-open="{escape(row["id"])}"><img data-src-id="{escape(row["id"])}" alt="{escape(row["title"])}" loading="lazy"></button>'
            f'<div><h4>{escape(row["title"])}</h4><p>{escape(row["description"])}</p>'
            '<span class="tag ochre">Historischer Kontext</span></div></article>')
    return (
        '<section id="hauptvorlagen" class="section primary-reference-section" aria-labelledby="primary-reference-heading">'
        '<div class="section-head"><div><div class="eyebrow">Die vollständigen Hauptvorlagen / Nutzerbilder</div>'
        '<h2 id="primary-reference-heading">Rostgrenze, Freihafen und die weite Karte.</h2></div>'
        '<p>Diese drei erneut gelieferten Bilder ergänzen die bisherigen Landschafts-, Außenposten- und Personenstudien. '
        'Sie führen Gelände, Architektur und Komposition des dritten Grafikpasses. Die Originale sind bytegleich gesichert.</p></div>'
        '<label class="search reference-search"><span class="sr-only">Hauptvorlagen und historische Quellen suchen</span>'
        '<input type="search" id="referenceSearchInput" data-export-key="reference_search" placeholder="Referenzen suchen: Rostgrenze, Freihafen, Klippen …"></label>'
        '<p id="referenceSearchCount" class="result-count" role="status" aria-live="polite"></p>'
        '<div class="primary-reference-grid">' + "".join(cards) + '</div>'
        '<details class="history-references"><summary>Historischer Kontext · 7 ältere UI-/Stimmungsbilder und die Shadowfall-Karte</summary>'
        '<p>Diese Quellen dokumentieren frühere Menüs, Hintergründe und Kartenideen. Sie sind keine aktive Modellfreigabe. '
        'Die graue Shadowfall-Karte mit Alpha/Bravo/Charlie/Delta ist ein anderes Bild als die aktuelle rote taktische Gesamtansicht.</p>'
        '<div class="history-reference-grid">' + "".join(history) + '</div></details>'
        '<p class="section-footnote">Pfad, Herkunft und vollständiger SHA-256 stehen im Bilddialog und im '
        '<a href="../../output/grafik_20261101/reference_manifest.json">Referenzmanifest</a>. '
        'Die Bildgenerator-Ausgaben bleiben separat gezählt: 13 generierte Bilder, dazu drei Nutzeroriginale und acht historische Quellen.</p></section>')


def render_comparison(data: dict) -> str:
    ready = data["after_ready"]
    buttons = "".join(f'<button type="button" data-pass04-view="{view}" aria-pressed="{str(view == "overview").lower()}">{title}</button>' for view, title in VIEWS)
    pending = '' if ready else '<p class="pass04-pending" role="status"><strong>Nachheraufnahmen noch ausstehend.</strong> Der unveränderte Pass-03-Vorherstand ist gesichert. Hier erscheinen erst ausdrücklich freigegebene native Pass-04-Aufnahmen; Pass 03 wird nicht als neues Nachher umetikettiert.</p>'
    after = ('<button type="button" id="pass04AfterButton"><img id="pass04AfterImage" alt="Nachheransicht von Grafikpass 04"><span class="zoom-cue">Nachher vergrößern ↗</span></button>' if ready else '<div class="pass04-awaiting"><span>Nachher</span><p>Native Aufnahme folgt nach dem Grafikpass.</p></div>')
    disabled = '' if ready else ' disabled'
    wipe = ('<div id="pass04Wipe" class="pass04-wipe" hidden><div class="pass04-wipe-stage"><img id="pass04WipeAfter" alt="Nachheransicht für Wischvergleich"><div id="pass04WipeBeforeLayer" class="pass04-wipe-before"><img id="pass04WipeBefore" alt="Vorheransicht für Wischvergleich"></div><span class="wipe-label before-label">Vorher</span><span class="wipe-label after-label">Nachher</span><div id="pass04WipeLine" class="pass04-wipe-line"></div></div><label for="pass04WipeRange">Trennlinie verschieben <output id="pass04WipeValue" for="pass04WipeRange">50 %</output></label><input id="pass04WipeRange" type="range" min="0" max="100" value="50" data-export-key="comparison.wipe" aria-label="Vorher-Nachher-Trennlinie"></div>' if ready else '')
    return (
        '<section id="vergleich" class="section pass04-comparison" aria-labelledby="pass04-heading">'
        '<div class="section-head"><div><div class="eyebrow">Grafikpass 04 / echter Vorher-Nachher-Vergleich</div>'
        '<h2 id="pass04-heading">Was sich im Spielbild verändert.</h2></div>'
        '<p>Gesicherte native Godot-Bilder derselben sechs Ansichten. Vor allem Gelände, Verbindungen, Gebäudemassen und Lesbarkeit im Spielabstand vergleichen. '
        'Der Ausschnitt bleibt eine synthetische Hex-Testkarte.</p></div>' + pending +
        '<div class="pass04-toolbar"><div class="segmented" role="group" aria-label="Vorher-Nachher-Ansicht">' + buttons + '</div>'
        '<div class="segmented" role="group" aria-label="Vergleichsmodus"><button type="button" data-pass04-mode="side" aria-pressed="true">Nebeneinander</button>'
        f'<button type="button" data-pass04-mode="wipe" aria-pressed="false"{disabled}>Wischen</button></div></div>'
        '<div id="pass04Side" class="pass04-pair"><figure><div class="pair-label">Vorher · Pass 03</div>'
        '<button type="button" id="pass04BeforeButton"><img id="pass04BeforeImage" alt="Gesicherter Ausgangsstand vor Grafikpass 04"><span class="zoom-cue">Vorher vergrößern ↗</span></button>'
        '<figcaption id="pass04BeforeCaption"></figcaption></figure><figure><div class="pair-label">Nachher · Pass 04</div>' + after +
        '<figcaption id="pass04AfterCaption"></figcaption></figure></div>' + wipe +
        '<p id="pass04CaptureConditions" class="section-footnote" role="status" aria-live="polite"></p>'
        '<div class="pass04-review"><label>Vergleichsurteil<select data-export-key="comparison.decision"><option value="open">Noch offen</option><option value="closer">Näher an den Vorlagen</option><option value="revise">Weitere Revision nötig</option><option value="accepted">Für diesen Ausschnitt passend</option></select></label>'
        '<label>Was fehlt im tatsächlichen Bild noch?<textarea data-export-key="comparison.note" placeholder="Gelände, Silhouetten, gebaute Wege, Figurenmaßstab …"></textarea></label></div>'
        '<details class="capture-metadata"><summary>Aufnahmebedingungen und Grenzen</summary><p>Die Bildpaare verwenden feste Ansichts-IDs. '
        'Auflösung, Kameragröße, Renderer und Beleuchtung werden angegeben; eine Lichtänderung wird nicht als reine Modelländerung ausgegeben. '
        'Pass-04-Metadaten führen Kameratransform, Projektion und Größe; Abweichungen sind mit dem tatsächlichen Nachherstand abzugleichen. Die Bilder belegen diesen Ausschnitt, keine Kampagnenmigration oder Performanceabnahme.</p>'
        '<pre id="pass04Metadata"></pre></details></section>')


PASS04_CSS = r'''
.primary-reference-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}.primary-reference-card{border:1px solid var(--line);border-radius:12px;background:var(--card);overflow:hidden}.primary-reference-card:first-child{grid-column:1/-1}.primary-reference-card>button,.history-reference-card>button,.pass04-pair figure>button{display:block;position:relative;width:100%;padding:0;border:0;background:#201f1b;cursor:zoom-in}.primary-reference-card img{display:block;width:100%;height:auto}.primary-reference-body{padding:24px}.primary-reference-body h3{font:400 28px/1.2 Georgia,serif;margin:13px 0}.primary-reference-body h4{font-size:12px;text-transform:uppercase;letter-spacing:.08em;margin:20px 0 10px}.primary-reference-body p,.primary-reference-body li{font-size:13px;color:var(--muted);line-height:1.7}.primary-reference-body ul{padding-left:19px}.reference-limit{border-left:3px solid var(--ochre);padding-left:14px}.primary-reference-body label{display:block;font-size:12px;margin:15px 0 7px}.primary-reference-body textarea{min-height:72px}.reference-search{max-width:720px}.history-references{margin-top:25px;border:1px solid var(--line);border-radius:10px;padding:20px}.history-references>summary{cursor:pointer;font-weight:600}.history-references>p{color:var(--muted);font-size:13px}.history-reference-grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:16px;margin-top:20px}.history-reference-card{border:1px solid var(--line);border-radius:8px;overflow:hidden;background:var(--card)}.history-reference-card img{display:block;width:100%;aspect-ratio:16/10;object-fit:contain}.history-reference-card>div{padding:13px}.history-reference-card h4{font-size:14px;margin:0 0 8px}.history-reference-card p{font-size:12px;color:var(--muted)}.pass04-toolbar{display:flex;justify-content:space-between;flex-wrap:wrap;gap:12px;margin:20px 0}.pass04-pair{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:18px}.pass04-pair figure{margin:0;border:1px solid var(--line);border-radius:10px;overflow:hidden;background:var(--card)}.pass04-pair img{width:100%;display:block;height:auto}.pair-label{padding:12px 16px;text-transform:uppercase;letter-spacing:.12em;font-size:11px;font-weight:700}.pass04-pair figcaption{padding:12px 16px;font-size:12px;color:var(--muted)}.pass04-pending{padding:18px;border:1px solid var(--ochre);background:#f8f1dc;font-size:13px;line-height:1.7}.pass04-awaiting{min-height:220px;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:30px;background:repeating-linear-gradient(135deg,#ede9e1,#ede9e1 12px,#e8e3d9 12px,#e8e3d9 24px);color:var(--muted);text-align:center}.pass04-awaiting span{font:28px Georgia,serif;color:var(--body)}.pass04-review{display:grid;grid-template-columns:1fr 2fr;gap:20px;margin-top:24px}.pass04-review label{font-size:12px;display:grid;gap:8px;align-content:start}.pass04-review textarea{min-height:80px}.pass04-wipe-stage{position:relative;background:#25231e;overflow:hidden;border-radius:10px}.pass04-wipe-stage>img,.pass04-wipe-before img{display:block;width:100%;height:auto}.pass04-wipe-before{position:absolute;inset:0;clip-path:inset(0 50% 0 0)}.pass04-wipe-before img{width:100%;height:100%;object-fit:contain}.pass04-wipe-line{position:absolute;left:50%;top:0;bottom:0;border-left:2px solid #fff;pointer-events:none}.wipe-label{position:absolute;top:12px;padding:7px 10px;color:#fff;background:#182b2dcc;border-radius:5px;font-size:12px;pointer-events:none}.before-label{left:12px}.after-label{right:12px}.pass04-wipe>label{display:flex;justify-content:space-between;margin:15px 0;font-size:13px}.pass04-wipe input{width:100%;accent-color:var(--teal)}.capture-metadata{margin-top:18px;font-size:13px}.capture-metadata summary{cursor:pointer}.capture-metadata pre{white-space:pre-wrap;overflow-wrap:anywhere;max-height:400px;overflow:auto;font-size:11px;background:#eae7df;padding:16px}.engine-history{margin-top:20px;border:1px solid var(--line);border-radius:10px;padding:18px}.engine-history>summary{cursor:pointer;font-weight:600}.engine-history .section{padding-bottom:20px}.primary-reference-card[hidden],.history-reference-card[hidden]{display:none}
.pass04-pair[hidden],.pass04-wipe[hidden]{display:none}.pass04-quicklinks{font-size:13px;color:var(--teal);margin:0 0 22px}
.pass04-landscape,.pass04-extra-pair figure{margin:0;border:1px solid var(--line);border-radius:10px;overflow:hidden;background:var(--card)}.pass04-landscape>button,.pass04-extra-pair button{display:block;position:relative;border:0;padding:0;width:100%;background:#25231e;cursor:zoom-in}.pass04-landscape img,.pass04-extra-pair img{display:block;width:100%;height:auto}.pass04-landscape figcaption,.pass04-extra-pair figcaption{padding:15px 18px;font-size:13px;color:var(--muted)}.pass04-extra-feature{grid-column:1/-1}.pass04-extra-pair{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:20px;margin-top:20px}.pass04-extra-pair figcaption p{font-size:12px}.pass04-model-summary{margin-top:28px}.pass04-model-summary>p,.pass04-open-gap p{font-size:13px;line-height:1.7;color:var(--muted)}.pass04-open-gap{border-left:3px solid var(--ochre);padding:16px 20px;background:#f3eddd;margin-top:25px}.pass04-open-gap h3{margin:0 0 10px;font-size:19px}@media(max-width:760px){.pass04-extra-pair{grid-template-columns:1fr}}
.primary-reference-card .zoom-cue,.pass04-pair .zoom-cue,.pass04-landscape .zoom-cue{position:absolute;right:12px;bottom:12px;background:rgba(255,253,247,.96);color:var(--ink);border-radius:99px;padding:7px 12px;font-size:12px;line-height:1.4;pointer-events:none}@media(max-width:760px){.primary-reference-card .zoom-cue,.pass04-pair .zoom-cue,.pass04-landscape .zoom-cue{font-size:10px;right:8px;bottom:8px;padding:6px 10px}}
.provenance-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:20px}.provenance-grid article{padding:22px;border:1px solid var(--line);border-radius:10px;background:var(--card)}.provenance-grid h3{font:400 24px/1.2 Georgia,serif;margin:16px 0 12px}.provenance-grid p,.provenance-section>p{font-size:13px;line-height:1.7;color:var(--muted)}@media(max-width:850px){.provenance-grid{grid-template-columns:1fr}}
.provenance-count{margin:25px 0 16px}.provenance-source-table small{display:block;font-size:11px;font-weight:400;margin-top:7px}.provenance-source-table details{margin-top:10px}.provenance-source-table td{vertical-align:top}.provenance-source-table pre{white-space:pre-wrap;overflow-wrap:anywhere;max-height:300px;overflow:auto;font-size:10px}.provenance-source-table code{display:block;margin:10px 0;font-size:10px;overflow-wrap:anywhere}.provenance-source-table{min-width:780px}
.new-ship-card{border:1px solid var(--line);border-radius:12px;background:var(--card);overflow:hidden;margin-top:22px}.new-ship-card>header{padding:20px 24px}.new-ship-card h3{font:400 29px Georgia,serif;margin:0 0 9px}.new-ship-pair{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:1px;background:var(--line)}.new-ship-pair figure{margin:0;background:var(--card)}.new-ship-pair button{display:block;border:0;padding:0;width:100%;background:#25231e;cursor:zoom-in}.new-ship-pair img{display:block;width:100%;height:auto;aspect-ratio:16/10;object-fit:contain}.new-ship-pair figcaption{padding:12px 18px;font-size:12px;color:var(--muted)}.new-ship-review{display:grid;grid-template-columns:1fr 2fr;gap:20px;padding:20px 24px}.new-ship-review label{font-size:12px;display:grid;align-content:start;gap:8px}.new-ship-review textarea{min-height:80px}@media(max-width:760px){.new-ship-pair,.new-ship-review{grid-template-columns:1fr}.new-ship-card>header,.new-ship-review{padding:18px}}
@media(max-width:900px){.history-reference-grid{grid-template-columns:repeat(2,minmax(0,1fr))}}@media(max-width:760px){.primary-reference-grid,.pass04-pair,.pass04-review{grid-template-columns:1fr}.primary-reference-body{padding:18px}.primary-reference-body h3{font-size:25px}.pass04-toolbar{align-items:flex-start}.pass04-toolbar .segmented{flex-wrap:wrap}.pass04-awaiting{min-height:180px}.history-reference-grid{gap:10px}.history-reference-card>div{padding:10px}.history-references{padding:14px}.wipe-label{font-size:10px}}
'''

PASS04_JS = r'''
function buildingChoices(){return {view:['habitat','hall','outpost'].includes(state.values['buildings.view'])?state.values['buildings.view']:'habitat',mode:state.values['buildings.mode']==='open'?'open':'closed'};}
function renderBuildingStates(){if(!DATA.pass04.after_ready)return;const c=buildingChoices(),map={habitat:{open:'cutaway',closed:'closed_habitat'},hall:{open:'workshop',closed:'closed_hall'},outpost:{open:'outpost',closed:'closed_outpost'}},a=byId['pass04_after_'+map[c.view][c.mode]];$('#buildingStateImage').src=a.full;$('#buildingStateImage').alt=a.title;$('#buildingStateButton').dataset.open=a.id;$('#buildingStateButton').setAttribute('aria-label',a.title+' vergrößern');$('#buildingStateCaption').textContent=a.title+' · aktueller R02-Nachherstand · '+(c.mode==='closed'?'geschlossene Hülle':'grafische Schnittdarstellung');$$('[data-building-view]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.buildingView===c.view)));$$('[data-building-mode]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.buildingMode===c.mode)));}
document.addEventListener('click',ev=>{const v=ev.target.closest('[data-building-view]'),m=ev.target.closest('[data-building-mode]');if(v||m){if(v)state.values['buildings.view']=v.dataset.buildingView;if(m)state.values['buildings.mode']=m.dataset.buildingMode;renderBuildingStates();save();}});renderBuildingStates();
function shipComparisonMode(){return state.values['new_ships.compare']==='rejected'?'rejected':'target';}
function renderNewShips(){const view=state.values['new_ships.view']==='rear'?'rear':'front',comparison=shipComparisonMode();$('#newShipComparisons').innerHTML=['cutlass','buccaneer'].map(ship=>{const target=byId[(comparison==='rejected'?'rejected_r01_':'')+ship+'_'+view],spec=(DATA.pass04.ship_manifest.assets||[]).find(s=>s.report_ship===ship),native=DATA.pass04.ship_views.find(v=>v.ship===ship&&v.view===view),model=native?byId[native.id]:null,k='new_ships.'+ship,decision=state.values[k+'.decision']||'open';return `<article class="new-ship-card"><header><h3>${ship==='cutlass'?'Cutlass':'Buccaneer'} · R02</h3><span class="tag rust">R02 weiter kritisiert · keine Annahme</span>${spec?'<p>'+spec.export.triangles.toLocaleString('de-DE')+' Dreiecke · '+spec.export.meshes+' Mesh · '+spec.export.materials+' Materialien · eigene editierbare Quelle</p>':''}</header><div class="new-ship-pair"><figure>${imageButton(target)}<figcaption>${comparison==='rejected'?'R01 · vom Nutzer ausdrücklich abgelehnt · native Aufnahme':'2D-Ziel · '+(view==='front'?'Vorder-':'Heck')+'ansicht · '+(ship==='cutlass'?(view==='front'?'08':'09'):(view==='front'?'13':'11'))}</figcaption></figure><figure>${model?imageButton(model):'<div class="pass04-awaiting"><span>Native Aufnahme folgt</span><p>Kein alter Rohmesh als neuer Kandidat.</p></div>'}<figcaption>${model?'Technischer R02-Zwischenstand · vom Nutzer weiter kritisiert':'Freigabe des neuen Modell-/Capturestands ausstehend'}</figcaption></figure></div><div class="new-ship-review"><label>Urteil zum neuen Modell<select data-export-key="${k}.decision">${[['open','Noch offen'],['closer','Näher am Ziel'],['revise','Weiter überarbeiten'],['accepted','Für diesen Ausschnitt passend']].map(([value,label])=>`<option value="${value}"${value===decision?' selected':''}>${label}</option>`).join('')}</select></label><label>Offene Form- oder Farbunterschiede<textarea data-export-key="${k}.note">${esc(state.values[k+'.note']||'')}</textarea></label></div></article>`;}).join('');$$('[data-pass04-ship-view]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.pass04ShipView===view)));$$('[data-ship-compare]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.shipCompare===comparison)));}
document.addEventListener('click',ev=>{const b=ev.target.closest('[data-pass04-ship-view]'),c=ev.target.closest('[data-ship-compare]');if(b||c){if(b)state.values['new_ships.view']=b.dataset.pass04ShipView;if(c)state.values['new_ships.compare']=c.dataset.shipCompare;renderNewShips();save();}});renderNewShips();
function pass04Controls(){const view=state.values['comparison.view'],mode=state.values['comparison.mode'],raw=Number(state.values['comparison.wipe']??50);return {view:['overview','workshop','crew','hex_grid','landscape','cutaway'].includes(view)?view:'overview',mode:mode==='wipe'&&DATA.pass04.after_ready?'wipe':'side',wipe:Number.isFinite(raw)?Math.max(0,Math.min(100,raw)):50};}
function renderPass04(){const choices=pass04Controls(),pair=DATA.pass04.pairs.find(p=>p.id===choices.view)||DATA.pass04.pairs[0],before=byId[pair.before_id],after=pair.after_id?byId[pair.after_id]:null;$('#pass04BeforeImage').src=before.full;$('#pass04BeforeImage').alt=before.title;$('#pass04BeforeButton').dataset.open=before.id;$('#pass04BeforeButton').setAttribute('aria-label',before.title+' vergrößern');$('#pass04BeforeCaption').textContent=pair.title+' · '+before.dimensions.join(' × ')+' px · unverändert gesicherter Ausgangsstand';if(after){$('#pass04AfterImage').src=after.full;$('#pass04AfterImage').alt=after.title;$('#pass04AfterButton').dataset.open=after.id;$('#pass04AfterButton').setAttribute('aria-label',after.title+' vergrößern');$('#pass04AfterCaption').textContent=pair.title+' · '+after.dimensions.join(' × ')+' px · tatsächlicher Pass-04-Kandidat';$('#pass04WipeAfter').src=after.full;$('#pass04WipeBefore').src=before.full;$('#pass04WipeBeforeLayer').style.clipPath='inset(0 '+(100-choices.wipe)+'% 0 0)';$('#pass04WipeLine').style.left=choices.wipe+'%';$('#pass04WipeValue').textContent=choices.wipe+' %';$('#pass04WipeRange').value=choices.wipe;$('#pass04Side').hidden=choices.mode==='wipe';$('#pass04Wipe').hidden=choices.mode!=='wipe';const dimensionsMatch=before.dimensions.join('x')===after.dimensions.join('x');if(!dimensionsMatch){$('#pass04Wipe').hidden=true;$('#pass04Side').hidden=false;}}else{$('#pass04AfterCaption').textContent='Noch keine freigegebene Nachheraufnahme.';}
$$('[data-pass04-view]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.pass04View===pair.id)));$$('[data-pass04-mode]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.pass04Mode===choices.mode)));const b=DATA.pass04.before_metadata,a=DATA.pass04.after_metadata;$('#pass04CaptureConditions').textContent='Vorher: '+(b.renderer||'Renderer nicht protokolliert')+' · Kameragröße '+(pair.before_camera.camera_size??'nicht protokolliert')+(after?' | Nachher: '+(a.renderer||'Renderer nicht protokolliert')+' · Kameragröße '+(pair.after_camera.camera_size??'nicht protokolliert')+' · '+(DATA.pass04.light_unchanged?'Lichtangaben unverändert.':'Lichtangaben geändert; Teil des Grafikpasses.'):' | Nachher noch ausstehend.');$('#pass04Metadata').textContent=JSON.stringify({view:pair.id,before:{camera:pair.before_camera,renderer:b.renderer,light:b.light,path:pair.before_path,sha256:pair.before_sha256},after:after?{camera:pair.after_camera,renderer:a.renderer,light:a.light,path:pair.after_path,sha256:pair.after_sha256}:'pending',scope:DATA.pass04.scope},null,2);}
function filterReferences(){const query=($('#referenceSearchInput').value||'').trim().toLocaleLowerCase('de'),counts={current:0,historical:0};$$('[data-reference-search]').forEach(card=>{const hit=!query||card.dataset.referenceSearch.toLocaleLowerCase('de').includes(query);card.hidden=!hit;if(hit)counts[card.dataset.referenceKind]++;});$('#referenceSearchCount').textContent=counts.current+' aktuelle Nutzerreferenzen · '+counts.historical+' historische Quellen'+(query?' passend zur Suche':'');}
document.addEventListener('click',ev=>{const view=ev.target.closest('[data-pass04-view]'),mode=ev.target.closest('[data-pass04-mode]');if(view){state.values['comparison.view']=view.dataset.pass04View;renderPass04();save();}if(mode&&!mode.disabled){state.values['comparison.mode']=mode.dataset.pass04Mode;renderPass04();save();}});$('#referenceSearchInput').addEventListener('input',filterReferences);if($('#pass04WipeRange'))$('#pass04WipeRange').addEventListener('input',e=>{state.values['comparison.wipe']=Number(e.target.value);renderPass04();save();});if(!DATA.pass04.after_ready)state.values['comparison.mode']='side';renderPass04();filterReferences();
'''
