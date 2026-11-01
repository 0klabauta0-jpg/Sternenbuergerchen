"""Reference assignments and a native, explicitly gated Pass-03 comparison."""
from __future__ import annotations

import hashlib
import json
from html import escape
from pathlib import Path

VIEWS = [("overview", "Übersicht"), ("workshop", "Werkstatt"),
         ("crew", "Crew"), ("hex_grid", "Hexraster"), ("landscape", "Gelände")]


def read(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def prepare_pass03(root: Path, art: Path, add) -> dict:
    references = read(root / "output/grafik_20261101/reference_manifest.json")
    for row in references["current_user_references"]:
        add(row["id"], root / row["package_path"], row["title"], row["group"],
            "Aktuelle Nutzerreferenz · Grafikpass 03", row["description"],
            kind="primary_reference", assignments=row["assignments"], limits=row["limits"],
            source_original_path=row["source_path"], origin=row["origin"],
            copy_byte_identical=row["copy_byte_identical"], active_model_reference=True)
    for row in references["historical_context"]:
        add(row["id"], root / row["package_path"], row["title"], "references",
            "Historischer Kontext · keine aktive Modellfreigabe", row["description"],
            kind="historical_reference", source_original_path=row["source_path"],
            origin=row["origin"], copy_byte_identical=row["copy_byte_identical"],
            active_model_reference=False)

    before = read(root / "output/grafik_20261101/pass03_before_capture.json")
    after_path = root / "output/grafik_20261101/pass03_after_capture.json"
    after = read(after_path) if after_path.is_file() else {}
    released = after.get("report_ready") is True
    after_paths = [art / "engine_pass03/after" / f"{view}.png" for view, _ in VIEWS]
    ready = released and all(path.is_file() for path in after_paths)
    if released and not ready:
        raise FileNotFoundError("Pass03 metadata releases captures, but an archived after image is missing")
    before_cameras = {item["id"]: item for item in before.get("captures", [])}
    after_cameras = {item["id"]: item for item in after.get("captures", [])}
    pairs = []
    for view, title in VIEWS:
        before_path = art / "engine_pass03/before" / f"{view}.png"
        before_id = f"pass03_before_{view}"
        add(before_id, before_path, f"Vorher · Pass 02 · {title}", "engine",
            "Native Godot-Aufnahme · unverändert gesicherter Vorherstand",
            "Unveränderter Ausgangsstand aus Pass 02: geschichtete Felsen, gebaute Wege, erste Werkstattausstattung und modular ausgerüstete Kenney-Figuren auf der synthetischen Hexkarte.",
            kind="pass03_before", view=view, synthetic_fixture=True,
            source_model="output/grafik_20261101/pass03_before_capture.json")
        row = {"id": view, "title": title, "before_id": before_id,
               "before_path": before_path.relative_to(root).as_posix(),
               "before_sha256": hashlib.sha256(before_path.read_bytes()).hexdigest(),
               "before_camera": before_cameras.get(view, {}), "after_id": None}
        if ready:
            after_image = art / "engine_pass03/after" / f"{view}.png"
            after_id = f"pass03_after_{view}"
            add(after_id, after_image, f"Nachher · Grafikpass 03 · {title}", "engine",
                "Native Godot-Aufnahme · gesicherter Grafikpass 03",
                "Tatsächlich gerenderter Pass-03-Kandidat. Mit dem gesicherten Vorherbild derselben Ansichts-ID vergleichen; Kamera-, Renderer- und Lichtangaben stehen in den Metadaten.",
                kind="pass03_after", view=view, synthetic_fixture=True,
                source_model="output/grafik_20261101/pass03_after_capture.json")
            row.update({"after_id": after_id,
                        "after_path": after_image.relative_to(root).as_posix(),
                        "after_sha256": hashlib.sha256(after_image.read_bytes()).hexdigest(),
                        "after_camera": after_cameras.get(view, {}),
                        "camera_size_match": before_cameras.get(view, {}).get("camera_size") == after_cameras.get(view, {}).get("camera_size"),
                        "camera_transform_match": before_cameras.get(view, {}).get("camera_transform") == after_cameras.get(view, {}).get("camera_transform"),
                        "camera_projection_match": before_cameras.get(view, {}).get("camera_projection") == after_cameras.get(view, {}).get("camera_projection")})
        pairs.append(row)
    extras = []
    citizens = []
    structures = {}
    if ready:
        structures = read(root / "art/frontier_illustrated_20261101/structures/pass03/manifest.json")
        if not structures.get("kenney_sources"):
            raise ValueError("Released Pass03 structures must document the actual Kenney source geometry")
        for source in structures["kenney_sources"]:
            for file_key, hash_key in (("path", "sha256"), ("license_path", "license_sha256")):
                actual = hashlib.sha256((root / source[file_key]).read_bytes()).hexdigest()
                if actual != source[hash_key]:
                    raise ValueError(f"Changed Kenney source/license: {source[file_key]}")
        pair_ids = {view for view, _ in VIEWS}
        extra_labels = {
            "cutaway": ("Rostgrenze · Cutaway-Nahansicht", "Zusätzliche native Nahansicht der grafischen Raumgruppen. Kein identisches Vorherbild; kein begehbarer oder simulierter Innenraum."),
            "walk_pose": ("Crew · Gehpose", "Native Walk-Momentaufnahme. Die Ausrüstungskandidaten aus Pass 02 bleiben erhalten; eine Pose ersetzt keinen vollständigen Bewegungstest."),
            "baseline": ("Pass 03 · Farbprofil aus", "Derselbe Pass-03-Ausschnitt mit ausgeschaltetem Frontier-Farbprofil. Das ist ein Profilvergleich, kein zusätzlicher Vorherstand."),
        }
        for capture in after.get("captures", []):
            view = capture["id"]
            if view in pair_ids:
                continue
            title, description = extra_labels.get(view, (f"Pass 03 · {view}", "Zusätzliche native Pass-03-Ansicht ohne identische Vorherkamera. Die Aufnahmebedingungen stehen in den Metadaten."))
            identifier = f"pass03_after_{view}"
            add(identifier, art / "engine_pass03/after" / f"{view}.png", title, "engine",
                "Native Godot-Aufnahme · zusätzliche Pass-03-Ansicht", description,
                kind="pass03_extra", view=view, synthetic_fixture=True,
                source_model="output/grafik_20261101/pass03_after_capture.json")
            extras.append({"id": identifier, "view": view, "title": title, "description": description})

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
            "kenney_supporting_files": structures.get("kenney_supporting_files", []),
            "renderer_match": before.get("renderer") == after.get("renderer") if ready else None,
            "light_unchanged": before.get("light") == after.get("light") if ready else None,
            "scope": "synthetic graphics fixture; no campaign/editor migration or release acceptance"}


def render_structure_provenance(data: dict) -> str:
    ready = data["after_ready"]
    sources = data["kenney_sources"]
    rows = []
    for source in sources:
        usages = ", ".join(f'{row["asset"]}: {len(row["instances"])} Instanz(en)' for row in source["usages"])
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
             '13 Quellen wurden zuvor angesehen; hier zählen ausschließlich die zehn im finalen Modell enthaltenen Quellen. '
             'Die zwei zur Farbzuordnung gelesenen Atlanten sind Hilfsquellen, keine zusätzlichen Geometriemodule.</p>'
             '<div class="table-scroll"><table class="qa-table provenance-source-table"><thead><tr><th>Originalmodul / Paket</th><th>Tatsächlicher Einsatz</th><th>Anpassung der Ableitung</th><th>Lizenz und Nachweis</th></tr></thead><tbody>'
             + "".join(rows) + '</tbody></table></div>') if ready else ''
    models = []
    for model in data["structure_candidates"]:
        export = model["export"]
        models.append(f'<tr><th scope="row">{escape(model["asset"])}</th><td>{export["triangles"]:,}</td><td>{export["meshes"]} / {export["materials"]}</td><td>{len(model["qa_errors"])} / {len(model["qa_warnings"])}</td></tr>'.replace(",", "."))
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
        '<p><a href="../../art/frontier_illustrated_20261101/structures/pass03/manifest.json">Strukturmanifest mit tatsächlichen Bauteilquellen ↗</a></p></section>')


def render_after_extras(data: dict) -> str:
    if not data["after_ready"]:
        return ""
    extras = "".join(
        f'<figure class="{'pass03-extra-feature' if row["view"] == "cutaway" else ''}"><button type="button" data-open="{escape(row["id"])}" aria-label="{escape(row["title"])} vergrößern">'
        f'<img data-src-id="{escape(row["id"])}" alt="{escape(row["title"])}"></button>'
        f'<figcaption><strong>{escape(row["title"])}</strong><p>{escape(row["description"])}</p></figcaption></figure>'
        for row in data["after_extras"])
    rows = "".join(f'<tr><th scope="row">{escape(row["role"])}</th><td>{row["triangles"]:,}</td><td>{row["meshes"]} / {row["materials"]} / {row["skins"]}</td></tr>'.replace(",", ".") for row in data["citizen_candidates"])
    return (
        '<section id="pass03-zusatzansichten" class="section pass03-extras" aria-labelledby="pass03-extra-heading">'
        '<div class="section-head"><div><div class="eyebrow">Zusätzliche Nachheransichten / ohne identisches Vorherpaar</div>'
        '<h2 id="pass03-extra-heading">Die neuen Funktionsgruppen näher ansehen.</h2></div>'
        '<p>Die weite Geländeansicht ist jetzt ein echtes fünftes Vorher-/Nachherpaar. Weitere Nah-, Geh- und Profilansichten ergänzen den Vergleich ausdrücklich ohne eigenes Vorher-Gegenstück.</p></div>'
        '<div class="pass03-extra-pair">' + extras + '</div>'
        '<div class="pass03-model-summary"><h3>Kenney-Ausrüstung aus Pass 02 bleibt erhalten.</h3>'
        '<p>Pass 03 verändert Gelände, Cutaway und Hallenensemble. Die modular ausgerüsteten Kenney-Figuren werden als eigener bestehender Stand beibehalten: '
        '<strong>zwei Meshes, vier Materialien und ein Skin</strong> je Figur, mit originalen Idle-/Walk-Clips. Diese Zahlen sind keine neue Figurenrevision oder Nutzerfreigabe.</p>'
        '<div class="table-scroll"><table class="qa-table"><thead><tr><th>Rolle</th><th>Beibehaltene Dreiecke</th><th>Meshes / Materialien / Skins</th></tr></thead><tbody>' + rows + '</tbody></table></div>'
        '<p><a href="../../art/frontier_illustrated_20261101/citizens/pass02/manifest.json">Erhaltene Pass-02-Figurenquellen und QA ↗</a></p></div>'
        '<aside class="pass03-open-gap"><h3>Bildfortschritt und Spielumfang getrennt beurteilen.</h3>'
        '<p>Die fünf festen Ansichten zeigen den tatsächlich aufgenommenen Stand. Organische Felsformen, sichtbare Raumgruppen und ein verbundenes Hallenensemble werden gegen dieselben drei Hauptvorlagen beurteilt. '
        'Eine grafische Cutaway-Ansicht belegt keine begehbaren Innenräume; dargestellte Lager- und Werkbereiche erzeugen keine Wirtschaftssimulation. '
        'Die Felsen haben jetzt gebrochene Umrisse und ungleiche Lagen, bleiben gegenüber den Illustrationen aber deutlich großflächiger und kantiger. '
        'Die sichtbaren Raumgruppen und das kleinere Hallenensemble führen die Hauptvorlagen weiter; ihre Dichte, weicheren Kanten und vollständige Umgebungskomposition sind noch nicht erreicht. '
        'Vollständige Kampagnen-/Editorübernahme, Schiffsmodellarbeit und Performanceabnahme bleiben eigene Aufgaben.</p></aside></section>')


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
    buttons = "".join(f'<button type="button" data-pass03-view="{view}" aria-pressed="{str(view == "overview").lower()}">{title}</button>' for view, title in VIEWS)
    pending = '' if ready else '<p class="pass03-pending" role="status"><strong>Nachheraufnahmen noch ausstehend.</strong> Der unveränderte Pass-02-Vorherstand ist gesichert. Hier erscheinen erst ausdrücklich freigegebene native Pass-03-Aufnahmen; Pass 02 wird nicht als neues Nachher umetikettiert.</p>'
    after = ('<button type="button" id="pass03AfterButton"><img id="pass03AfterImage" alt="Nachheransicht von Grafikpass 03"><span class="zoom-cue">Nachher vergrößern ↗</span></button>' if ready else '<div class="pass03-awaiting"><span>Nachher</span><p>Native Aufnahme folgt nach dem Grafikpass.</p></div>')
    disabled = '' if ready else ' disabled'
    wipe = ('<div id="pass03Wipe" class="pass03-wipe" hidden><div class="pass03-wipe-stage"><img id="pass03WipeAfter" alt="Nachheransicht für Wischvergleich"><div id="pass03WipeBeforeLayer" class="pass03-wipe-before"><img id="pass03WipeBefore" alt="Vorheransicht für Wischvergleich"></div><span class="wipe-label before-label">Vorher</span><span class="wipe-label after-label">Nachher</span><div id="pass03WipeLine" class="pass03-wipe-line"></div></div><label for="pass03WipeRange">Trennlinie verschieben <output id="pass03WipeValue" for="pass03WipeRange">50 %</output></label><input id="pass03WipeRange" type="range" min="0" max="100" value="50" data-export-key="comparison.wipe" aria-label="Vorher-Nachher-Trennlinie"></div>' if ready else '')
    return (
        '<section id="vergleich" class="section pass03-comparison" aria-labelledby="pass03-heading">'
        '<div class="section-head"><div><div class="eyebrow">Grafikpass 03 / echter Vorher-Nachher-Vergleich</div>'
        '<h2 id="pass03-heading">Was sich im Spielbild verändert.</h2></div>'
        '<p>Gesicherte native Godot-Bilder derselben fünf Ansichten. Vor allem Gelände, Verbindungen, Gebäudemassen und Lesbarkeit im Spielabstand vergleichen. '
        'Der Ausschnitt bleibt eine synthetische Hex-Testkarte.</p></div>' + pending +
        '<div class="pass03-toolbar"><div class="segmented" role="group" aria-label="Vorher-Nachher-Ansicht">' + buttons + '</div>'
        '<div class="segmented" role="group" aria-label="Vergleichsmodus"><button type="button" data-pass03-mode="side" aria-pressed="true">Nebeneinander</button>'
        f'<button type="button" data-pass03-mode="wipe" aria-pressed="false"{disabled}>Wischen</button></div></div>'
        '<div id="pass03Side" class="pass03-pair"><figure><div class="pair-label">Vorher · Pass 02</div>'
        '<button type="button" id="pass03BeforeButton"><img id="pass03BeforeImage" alt="Gesicherter Ausgangsstand vor Grafikpass 03"><span class="zoom-cue">Vorher vergrößern ↗</span></button>'
        '<figcaption id="pass03BeforeCaption"></figcaption></figure><figure><div class="pair-label">Nachher · Pass 03</div>' + after +
        '<figcaption id="pass03AfterCaption"></figcaption></figure></div>' + wipe +
        '<p id="pass03CaptureConditions" class="section-footnote" role="status" aria-live="polite"></p>'
        '<div class="pass03-review"><label>Vergleichsurteil<select data-export-key="comparison.decision"><option value="open">Noch offen</option><option value="closer">Näher an den Vorlagen</option><option value="revise">Weitere Revision nötig</option><option value="accepted">Für diesen Ausschnitt passend</option></select></label>'
        '<label>Was fehlt im tatsächlichen Bild noch?<textarea data-export-key="comparison.note" placeholder="Gelände, Silhouetten, gebaute Wege, Figurenmaßstab …"></textarea></label></div>'
        '<details class="capture-metadata"><summary>Aufnahmebedingungen und Grenzen</summary><p>Die Bildpaare verwenden feste Ansichts-IDs. '
        'Auflösung, Kameragröße, Renderer und Beleuchtung werden angegeben; eine Lichtänderung wird nicht als reine Modelländerung ausgegeben. '
        'Pass-03-Metadaten führen Kameratransform, Projektion und Größe; Abweichungen sind mit dem tatsächlichen Nachherstand abzugleichen. Die Bilder belegen diesen Ausschnitt, keine Kampagnenmigration oder Performanceabnahme.</p>'
        '<pre id="pass03Metadata"></pre></details></section>')


PASS03_CSS = r'''
.primary-reference-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}.primary-reference-card{border:1px solid var(--line);border-radius:12px;background:var(--card);overflow:hidden}.primary-reference-card:first-child{grid-column:1/-1}.primary-reference-card>button,.history-reference-card>button,.pass03-pair figure>button{display:block;position:relative;width:100%;padding:0;border:0;background:#201f1b;cursor:zoom-in}.primary-reference-card img{display:block;width:100%;height:auto}.primary-reference-body{padding:24px}.primary-reference-body h3{font:400 28px/1.2 Georgia,serif;margin:13px 0}.primary-reference-body h4{font-size:12px;text-transform:uppercase;letter-spacing:.08em;margin:20px 0 10px}.primary-reference-body p,.primary-reference-body li{font-size:13px;color:var(--muted);line-height:1.7}.primary-reference-body ul{padding-left:19px}.reference-limit{border-left:3px solid var(--ochre);padding-left:14px}.primary-reference-body label{display:block;font-size:12px;margin:15px 0 7px}.primary-reference-body textarea{min-height:72px}.reference-search{max-width:720px}.history-references{margin-top:25px;border:1px solid var(--line);border-radius:10px;padding:20px}.history-references>summary{cursor:pointer;font-weight:600}.history-references>p{color:var(--muted);font-size:13px}.history-reference-grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:16px;margin-top:20px}.history-reference-card{border:1px solid var(--line);border-radius:8px;overflow:hidden;background:var(--card)}.history-reference-card img{display:block;width:100%;aspect-ratio:16/10;object-fit:contain}.history-reference-card>div{padding:13px}.history-reference-card h4{font-size:14px;margin:0 0 8px}.history-reference-card p{font-size:12px;color:var(--muted)}.pass03-toolbar{display:flex;justify-content:space-between;flex-wrap:wrap;gap:12px;margin:20px 0}.pass03-pair{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:18px}.pass03-pair figure{margin:0;border:1px solid var(--line);border-radius:10px;overflow:hidden;background:var(--card)}.pass03-pair img{width:100%;display:block;height:auto}.pair-label{padding:12px 16px;text-transform:uppercase;letter-spacing:.12em;font-size:11px;font-weight:700}.pass03-pair figcaption{padding:12px 16px;font-size:12px;color:var(--muted)}.pass03-pending{padding:18px;border:1px solid var(--ochre);background:#f8f1dc;font-size:13px;line-height:1.7}.pass03-awaiting{min-height:220px;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:30px;background:repeating-linear-gradient(135deg,#ede9e1,#ede9e1 12px,#e8e3d9 12px,#e8e3d9 24px);color:var(--muted);text-align:center}.pass03-awaiting span{font:28px Georgia,serif;color:var(--body)}.pass03-review{display:grid;grid-template-columns:1fr 2fr;gap:20px;margin-top:24px}.pass03-review label{font-size:12px;display:grid;gap:8px;align-content:start}.pass03-review textarea{min-height:80px}.pass03-wipe-stage{position:relative;background:#25231e;overflow:hidden;border-radius:10px}.pass03-wipe-stage>img,.pass03-wipe-before img{display:block;width:100%;height:auto}.pass03-wipe-before{position:absolute;inset:0;clip-path:inset(0 50% 0 0)}.pass03-wipe-before img{width:100%;height:100%;object-fit:contain}.pass03-wipe-line{position:absolute;left:50%;top:0;bottom:0;border-left:2px solid #fff;pointer-events:none}.wipe-label{position:absolute;top:12px;padding:7px 10px;color:#fff;background:#182b2dcc;border-radius:5px;font-size:12px;pointer-events:none}.before-label{left:12px}.after-label{right:12px}.pass03-wipe>label{display:flex;justify-content:space-between;margin:15px 0;font-size:13px}.pass03-wipe input{width:100%;accent-color:var(--teal)}.capture-metadata{margin-top:18px;font-size:13px}.capture-metadata summary{cursor:pointer}.capture-metadata pre{white-space:pre-wrap;overflow-wrap:anywhere;max-height:400px;overflow:auto;font-size:11px;background:#eae7df;padding:16px}.engine-history{margin-top:20px;border:1px solid var(--line);border-radius:10px;padding:18px}.engine-history>summary{cursor:pointer;font-weight:600}.engine-history .section{padding-bottom:20px}.primary-reference-card[hidden],.history-reference-card[hidden]{display:none}
.pass03-pair[hidden],.pass03-wipe[hidden]{display:none}.pass03-quicklinks{font-size:13px;color:var(--teal);margin:0 0 22px}
.pass03-landscape,.pass03-extra-pair figure{margin:0;border:1px solid var(--line);border-radius:10px;overflow:hidden;background:var(--card)}.pass03-landscape>button,.pass03-extra-pair button{display:block;position:relative;border:0;padding:0;width:100%;background:#25231e;cursor:zoom-in}.pass03-landscape img,.pass03-extra-pair img{display:block;width:100%;height:auto}.pass03-landscape figcaption,.pass03-extra-pair figcaption{padding:15px 18px;font-size:13px;color:var(--muted)}.pass03-extra-feature{grid-column:1/-1}.pass03-extra-pair{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:20px;margin-top:20px}.pass03-extra-pair figcaption p{font-size:12px}.pass03-model-summary{margin-top:28px}.pass03-model-summary>p,.pass03-open-gap p{font-size:13px;line-height:1.7;color:var(--muted)}.pass03-open-gap{border-left:3px solid var(--ochre);padding:16px 20px;background:#f3eddd;margin-top:25px}.pass03-open-gap h3{margin:0 0 10px;font-size:19px}@media(max-width:760px){.pass03-extra-pair{grid-template-columns:1fr}}
.primary-reference-card .zoom-cue,.pass03-pair .zoom-cue,.pass03-landscape .zoom-cue{position:absolute;right:12px;bottom:12px;background:rgba(255,253,247,.96);color:var(--ink);border-radius:99px;padding:7px 12px;font-size:12px;line-height:1.4;pointer-events:none}@media(max-width:760px){.primary-reference-card .zoom-cue,.pass03-pair .zoom-cue,.pass03-landscape .zoom-cue{font-size:10px;right:8px;bottom:8px;padding:6px 10px}}
.provenance-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:20px}.provenance-grid article{padding:22px;border:1px solid var(--line);border-radius:10px;background:var(--card)}.provenance-grid h3{font:400 24px/1.2 Georgia,serif;margin:16px 0 12px}.provenance-grid p,.provenance-section>p{font-size:13px;line-height:1.7;color:var(--muted)}@media(max-width:850px){.provenance-grid{grid-template-columns:1fr}}
.provenance-count{margin:25px 0 16px}.provenance-source-table small{display:block;font-size:11px;font-weight:400;margin-top:7px}.provenance-source-table details{margin-top:10px}.provenance-source-table td{vertical-align:top}.provenance-source-table pre{white-space:pre-wrap;overflow-wrap:anywhere;max-height:300px;overflow:auto;font-size:10px}.provenance-source-table code{display:block;margin:10px 0;font-size:10px;overflow-wrap:anywhere}.provenance-source-table{min-width:780px}
@media(max-width:900px){.history-reference-grid{grid-template-columns:repeat(2,minmax(0,1fr))}}@media(max-width:760px){.primary-reference-grid,.pass03-pair,.pass03-review{grid-template-columns:1fr}.primary-reference-body{padding:18px}.primary-reference-body h3{font-size:25px}.pass03-toolbar{align-items:flex-start}.pass03-toolbar .segmented{flex-wrap:wrap}.pass03-awaiting{min-height:180px}.history-reference-grid{gap:10px}.history-reference-card>div{padding:10px}.history-references{padding:14px}.wipe-label{font-size:10px}}
'''

PASS03_JS = r'''
function pass03Controls(){const view=state.values['comparison.view'],mode=state.values['comparison.mode'],raw=Number(state.values['comparison.wipe']??50);return {view:['overview','workshop','crew','hex_grid','landscape'].includes(view)?view:'overview',mode:mode==='wipe'&&DATA.pass03.after_ready?'wipe':'side',wipe:Number.isFinite(raw)?Math.max(0,Math.min(100,raw)):50};}
function renderPass03(){const choices=pass03Controls(),pair=DATA.pass03.pairs.find(p=>p.id===choices.view)||DATA.pass03.pairs[0],before=byId[pair.before_id],after=pair.after_id?byId[pair.after_id]:null;$('#pass03BeforeImage').src=before.full;$('#pass03BeforeImage').alt=before.title;$('#pass03BeforeButton').dataset.open=before.id;$('#pass03BeforeButton').setAttribute('aria-label',before.title+' vergrößern');$('#pass03BeforeCaption').textContent=pair.title+' · '+before.dimensions.join(' × ')+' px · unverändert gesicherter Ausgangsstand';if(after){$('#pass03AfterImage').src=after.full;$('#pass03AfterImage').alt=after.title;$('#pass03AfterButton').dataset.open=after.id;$('#pass03AfterButton').setAttribute('aria-label',after.title+' vergrößern');$('#pass03AfterCaption').textContent=pair.title+' · '+after.dimensions.join(' × ')+' px · tatsächlicher Pass-03-Kandidat';$('#pass03WipeAfter').src=after.full;$('#pass03WipeBefore').src=before.full;$('#pass03WipeBeforeLayer').style.clipPath='inset(0 '+(100-choices.wipe)+'% 0 0)';$('#pass03WipeLine').style.left=choices.wipe+'%';$('#pass03WipeValue').textContent=choices.wipe+' %';$('#pass03WipeRange').value=choices.wipe;$('#pass03Side').hidden=choices.mode==='wipe';$('#pass03Wipe').hidden=choices.mode!=='wipe';const dimensionsMatch=before.dimensions.join('x')===after.dimensions.join('x');if(!dimensionsMatch){$('#pass03Wipe').hidden=true;$('#pass03Side').hidden=false;}}else{$('#pass03AfterCaption').textContent='Noch keine freigegebene Nachheraufnahme.';}
$$('[data-pass03-view]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.pass03View===pair.id)));$$('[data-pass03-mode]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.pass03Mode===choices.mode)));const b=DATA.pass03.before_metadata,a=DATA.pass03.after_metadata;$('#pass03CaptureConditions').textContent='Vorher: '+(b.renderer||'Renderer nicht protokolliert')+' · Kameragröße '+(pair.before_camera.camera_size??'nicht protokolliert')+(after?' | Nachher: '+(a.renderer||'Renderer nicht protokolliert')+' · Kameragröße '+(pair.after_camera.camera_size??'nicht protokolliert')+' · '+(DATA.pass03.light_unchanged?'Lichtangaben unverändert.':'Lichtangaben geändert; Teil des Grafikpasses.'):' | Nachher noch ausstehend.');$('#pass03Metadata').textContent=JSON.stringify({view:pair.id,before:{camera:pair.before_camera,renderer:b.renderer,light:b.light,path:pair.before_path,sha256:pair.before_sha256},after:after?{camera:pair.after_camera,renderer:a.renderer,light:a.light,path:pair.after_path,sha256:pair.after_sha256}:'pending',scope:DATA.pass03.scope},null,2);}
function filterReferences(){const query=($('#referenceSearchInput').value||'').trim().toLocaleLowerCase('de'),counts={current:0,historical:0};$$('[data-reference-search]').forEach(card=>{const hit=!query||card.dataset.referenceSearch.toLocaleLowerCase('de').includes(query);card.hidden=!hit;if(hit)counts[card.dataset.referenceKind]++;});$('#referenceSearchCount').textContent=counts.current+' aktuelle Nutzerreferenzen · '+counts.historical+' historische Quellen'+(query?' passend zur Suche':'');}
document.addEventListener('click',ev=>{const view=ev.target.closest('[data-pass03-view]'),mode=ev.target.closest('[data-pass03-mode]');if(view){state.values['comparison.view']=view.dataset.pass03View;renderPass03();save();}if(mode&&!mode.disabled){state.values['comparison.mode']=mode.dataset.pass03Mode;renderPass03();save();}});$('#referenceSearchInput').addEventListener('input',filterReferences);if($('#pass03WipeRange'))$('#pass03WipeRange').addEventListener('input',e=>{state.values['comparison.wipe']=Number(e.target.value);renderPass03();save();});if(!DATA.pass03.after_ready)state.values['comparison.mode']='side';renderPass03();filterReferences();
'''
