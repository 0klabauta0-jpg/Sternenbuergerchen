"""Environment analysis and gated Pass04 -> environment05 native comparison."""
from __future__ import annotations

import hashlib
import json
from html import escape
from pathlib import Path

REVISION = "env05"
VIEWS = [("closed_outpost", "Außenposten geschlossen"), ("closed_habitat", "Basis geschlossen"),
         ("closed_hall", "Halle geschlossen"), ("landscape", "Gelände"), ("overview", "Übersicht"),
         ("workshop", "Werkstatt / Schnitt"), ("crew", "Crew"), ("hex_grid", "Hexraster"),
         ("cutaway", "Basis / Schnitt")]
CAMERA_FIELDS = ("camera_size", "camera_transform", "camera_projection", "viewport_size")


def read(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def capture_is_current(metadata: dict) -> bool:
    return metadata.get("report_ready") is True and metadata.get("report_revision") == REVISION


def prepare_environment(root: Path, art: Path, add) -> dict:
    base = root / "output/grafik_20261101"
    analysis = read(base / "pass05_environment_analysis.json")
    packages = {name: {"path": f"art/frontier_illustrated_20261101/environment/pass05/{name}/manifest.json",
                       "data": read(root / f"art/frontier_illustrated_20261101/environment/pass05/{name}/manifest.json")}
                for name in ("buildings", "geology")}
    for row in analysis["images"]:
        if sha(root / row["path"]) != row["sha256"]:
            raise ValueError(f'Changed baseline analysis source: {row["path"]}')
    before = read(base / "pass05_environment_before_capture.json")
    candidate_path = base / "pass05_environment_after_capture.json"
    candidate = read(candidate_path) if candidate_path.is_file() else {}
    ready = capture_is_current(candidate)
    after = candidate if ready else {}
    old_cameras = {row["id"]: row for row in before["captures"]}
    new_cameras = {row["id"]: row for row in after.get("captures", [])}
    if ready:
        if before.get("renderer") != after.get("renderer") or before.get("light") != after.get("light"):
            raise ValueError("Environment pairs require unchanged renderer and global lighting")
        sources = after.get("runtime_sources_sha256", {})
        if not sources:
            raise ValueError("Released environment capture needs actual runtime source hashes")
        for source, expected in sources.items():
            if sha(root / source.removeprefix("res://")) != expected:
                raise ValueError(f"Changed environment runtime source: {source}")
        before_models = {m["path"].removeprefix("res://"): m["source_sha256"] for m in before["models"]}
        after_models = {m["path"].removeprefix("res://"): m["source_sha256"] for m in after["models"]}
        if before_models != after_models:
            raise ValueError("Environment pass must retain the same GLB sources, including ships/citizens")
        for path, expected in after_models.items():
            if sha(root / path) != expected:
                raise ValueError(f"Changed retained model bytes: {path}")
        for name, package in packages.items():
            data = package["data"]
            source = data["source"] if name == "buildings" else data["runtime_source"]
            path = source.get("runtime_path", source.get("path"))
            if sha(root / path) != source["sha256"] or sources.get("res://" + path) != source["sha256"]:
                raise ValueError(f"Current native capture does not match the frozen {name} package")
        for source in after.get("worklife_sources", []):
            if sha(root / source["path"].removeprefix("res://")) != source["source_sha256"]:
                raise ValueError("Changed original Kenney worklife source")
        if len(after.get("worklife_sources", [])) != 3 or len(after.get("use_groups", [])) != 3:
            raise ValueError("Released environment capture needs the three actual worklife sources/groups")
    pairs = []
    for view, title in VIEWS:
        before_path = art / "engine_pass05_environment/before" / f"{view}.png"
        if before_path.read_bytes() != (art / "engine_pass04/after" / f"{view}.png").read_bytes():
            raise ValueError(f"Pass04 before image changed: {view}")
        before_id = f"env05_before_{view}"
        add(before_id, before_path, f"Vorher · Pass04 · {title}", "engine",
            "Native Godot-Aufnahme · bytegleicher Pass04-Vorherstand",
            "Gesicherter Ausgangsstand für den Umgebungspass. Schiffs-/Citizen-GLBs und ihre Beurteilung bleiben davon getrennt.",
            kind="environment_before", view=view, synthetic_fixture=True,
            source_model="output/grafik_20261101/pass05_environment_before_capture.json")
        row = {"id": view, "title": title, "before_id": before_id, "after_id": None,
               "before_path": before_path.relative_to(root).as_posix(), "before_sha256": sha(before_path),
               "before_camera": old_cameras[view], "closed": view.startswith("closed_")}
        if view == "crew":
            row["change_scope"] = "Aufstellung und Blickrichtung der vier vorhandenen Citizens; GLBs/Ausruestung/Idle-Walk unveraendert. Der alte Crewbildausschnitt zeigt nach der Tiefenstaffelung nur drei Figuren."
        if ready:
            camera = new_cameras[view]
            for field in CAMERA_FIELDS:
                if field not in old_cameras[view] or field not in camera or old_cameras[view][field] != camera[field]:
                    raise ValueError(f"Environment comparison camera differs: {view}, {field}")
            if camera.get("building_shells_visible") is not row["closed"]:
                raise ValueError(f"Environment pair has wrong building display state: {view}")
            after_path = art / "engine_pass05_environment/after" / f"{view}.png"
            after_id = f"env05_after_{view}"
            add(after_id, after_path, f"Nachher · Pass05 Umgebung · {title}", "engine",
                "Native Godot-Aufnahme · freigegebener Umgebungspass env05",
                "Tatsächlich gerenderter Umgebungskandidat bei gleicher Kamera und gleichem globalem Licht. Technische Capturefreigabe ist keine gestalterische Nutzerannahme. Schiffs-/Citizen-GLBs bleiben erhalten.",
                kind="environment_after", view=view, synthetic_fixture=True,
                source_model="output/grafik_20261101/pass05_environment_after_capture.json")
            row.update(after_id=after_id, after_path=after_path.relative_to(root).as_posix(),
                       after_sha256=sha(after_path), after_camera=camera, camera_match=True)
        pairs.append(row)
    extras = []
    extra_labels = {"lived_outpost": ("Arbeitsbereich · nähere Außenpostenansicht", "Neue nähere Kamera für die funktionalen Arbeitsgruppen und die geschlossenen Gebäude. Zusätzliche Nachheransicht ohne identisches Vorherbild."),
                    "ground_detail": ("Bodenanschlüsse · Versorgung und Spuren", "Neue Detailkamera für Versorgung, lokale Gebrauchsspuren und Bodenkontakte. Kein historisches Vorherpaar."),
                    "geology_detail": ("Geologie · Felswand im Detail", "Neue Detailkamera für gebrochene Felsprofile und Kontaktzonen. Kein identischer Vorherblick vorhanden.")}
    if ready:
        for row in after["captures"]:
            view = row["id"]
            if view in {v for v, _ in VIEWS} or view.startswith(("cutlass_", "buccaneer_")):
                continue
            identifier = f"env05_after_{view}"
            title, description = extra_labels.get(view, (f"Pass05 Umgebung · {view}", "Ergänzende Detail-/Profilansicht des tatsächlichen Umgebungspasses. Feste historische Vergleichspaare bleiben separat."))
            add(identifier, art / "engine_pass05_environment/after" / f"{view}.png",
                title, "engine", "Zusätzliche native Umgebungssicht · kein identisches Vorherpaar", description,
                kind="environment_extra", view=view, synthetic_fixture=True,
                source_model="output/grafik_20261101/pass05_environment_after_capture.json")
            extras.append({"id": identifier, "view": view, "title": title, "description": description})
    return {"revision": REVISION, "after_ready": ready, "before_metadata": before,
            "after_metadata": after, "pairs": pairs, "extras": extras, "analysis": analysis,
            "source_packages": packages, "worklife_sources": after.get("worklife_sources", []),
            "use_groups": after.get("use_groups", []), "contact_gravel_count": after.get("contact_gravel_count"),
            "model_glbs_unchanged": True if ready else None,
            "scope": "Environment only; Godot forms/dressing/shader, no ship or character remodeling. Astra outputs remain separate."}


def render_analysis(data: dict) -> str:
    cards = []
    for row in data["analysis"]["findings"]:
        cards.append(f'<article class="environment-finding"><div class="eyebrow">Priorität {row["rank"]:02d}</div>'
                     f'<h3>{escape(row["category"])}</h3><p>{escape(row["gap"])}</p>'
                     f'<p><strong>Arbeitsziel.</strong> {escape(row["change"])}</p>'
                     f'<p><strong>Gegenprobe.</strong> {escape(row["check"])}</p>'
                     f'<label>Deine Beobachtung<textarea data-export-key="environment.findings.p{row["rank"]}.note"></textarea></label></article>')
    return ('<section id="umgebungsanalyse" class="section"><div class="section-head"><div><div class="eyebrow">Pass05 Umgebung / vor dem Grafikpass geöffnet</div>'
            '<h2>Warum der Außenposten noch steril wirkt.</h2></div><p>Drei 2D-Hauptvorlagen und drei native Pass04-Ansichten wurden direkt verglichen. '
            'Die größte Lücke liegt bei Hauptformen und Bodenanschlüssen. Mehr kleine Details oder ein globaler Lichtwechsel allein schließen sie nicht.</p></div>'
            '<div class="segmented" role="group" aria-label="Analysebilder auswählen"><button type="button" data-analysis-view="outpost" aria-pressed="true">Außenposten</button>'
            '<button type="button" data-analysis-view="hall" aria-pressed="false">Halle</button><button type="button" data-analysis-view="terrain" aria-pressed="false">Gelände</button></div>'
            '<div id="environmentAnalysisImages" class="new-ship-pair"></div><p class="section-footnote">2D-Ziel und nativer Pass04-Befund haben unterschiedliche Kameras und Darstellungstechniken. '
            'Der gleiche native Kameravergleich beginnt im nächsten Bereich.</p><div class="environment-findings">' + ''.join(cards) + '</div>'
            '<p><a href="FRONTIER_UMGEBUNG_ANALYSE_2026-11-01.md">Bildanalyse mit sechs Quellen und Hashes ↗</a></p></section>')


def render_environment(data: dict) -> str:
    controls = ''.join(f'<button type="button" data-env-view="{v}" aria-pressed="{"true" if i == 0 else "false"}">{escape(t)}</button>' for i, (v, t) in enumerate(VIEWS))
    pending = '' if data["after_ready"] else '<p class="pass04-pending">Der neue Umgebungspass ist in Arbeit. Nachherbilder erscheinen erst mit expliziter Capturefreigabe env05; die alten R02-Metadaten schalten sie nicht frei.</p>'
    def extra_figure(row):
        return f'<figure><button type="button" data-open="{row["id"]}"><img data-src-id="{row["id"]}" alt="{escape(row["title"])}"></button><figcaption><strong>{escape(row["title"])}</strong><p>{escape(row["description"])}</p></figcaption></figure>'
    featured_ids = {"lived_outpost", "ground_detail", "geology_detail"}
    featured = ''.join(extra_figure(row) for row in data["extras"] if row["view"] in featured_ids)
    extras = ''.join(extra_figure(row) for row in data["extras"] if row["view"] not in featured_ids)
    return ('<section id="vergleich" class="section"><div class="section-head"><div><div class="eyebrow">Pass04 → Pass05 Umgebung / neun feste Kamerapaare</div>'
            '<h2>Formen, Kontakte und Nutzungsgruppen vergleichen.</h2></div><p>Geschlossene Ansichten und Schnitte werden jeweils mit demselben alten Sichtzustand verglichen. '
            'Kamera, globales Licht, Renderer und Viewport bleiben je Paar gleich; die 2D-Ziele stehen separat darüber.</p></div>' + pending +
            '<div class="pass04-toolbar"><div class="segmented environment-view-controls" role="group" aria-label="Umgebungsvergleich auswählen">' + controls + '</div>'
            '<div class="segmented" role="group" aria-label="Umgebungsbilder darstellen"><button type="button" data-env-mode="side" aria-pressed="true">Nebeneinander</button>'
            '<button type="button" data-env-mode="wipe" aria-pressed="false"' + ('' if data["after_ready"] else ' disabled') + '>Wischen</button></div></div>'
            '<div id="envSide" class="pass04-pair"><figure><div class="pair-label">Vorher · Pass04</div><button type="button" id="envBeforeButton"><img id="envBeforeImage" alt="Vorher"><span class="zoom-cue">Vorher vergrößern ↗</span></button><figcaption id="envBeforeCaption"></figcaption></figure>'
            '<figure><div class="pair-label">Nachher · Pass05 Umgebung</div><button type="button" id="envAfterButton"><img id="envAfterImage" alt="Nachher"><span class="zoom-cue">Nachher vergrößern ↗</span></button><div id="envPending" class="pass04-awaiting">Freigegebene Nachheraufnahme folgt</div><figcaption id="envAfterCaption"></figcaption></figure></div>'
            '<div id="envWipe" class="pass04-wipe" hidden><div class="pass04-wipe-stage"><img id="envWipeAfter" alt="Nachher"><div id="envWipeBeforeLayer" class="pass04-wipe-before"><img id="envWipeBefore" alt="Vorher"></div><div id="envWipeLine" class="pass04-wipe-line"></div><span class="wipe-label before-label">Vorher · P4</span><span class="wipe-label after-label">Nachher · Umgebung05</span></div>'
            '<label for="envWipeRange">Trennlinie verschieben <output id="envWipeValue">50 %</output></label><input id="envWipeRange" type="range" min="0" max="100" value="50" data-export-key="environment.wipe"></div>'
            '<p class="section-footnote" id="envConditions"></p><div class="pass04-review"><label>Umgebungsurteil<select data-export-key="environment.decision"><option value="open">Noch offen</option><option value="closer">Näher am Ziel</option><option value="revise">Weiter überarbeiten</option><option value="accepted">Für diesen Ausschnitt passend</option></select></label>'
            '<label>Welche Form-/Kontaktunterschiede bleiben?<textarea data-export-key="environment.note"></textarea></label></div>'
            '<details class="capture-metadata"><summary>Kameras, Hashes und Prüfgrenze</summary><pre id="envMetadata"></pre></details>'
            + ('<div class="environment-new-details"><h3>Neue Nahansichten · nur Nachher.</h3><p>Diese drei Kameras wurden für die Lesbarkeit ergänzt. Sie haben kein identisches historisches Vorherbild und zählen nicht zu den neun Paaren.</p><div class="pass04-extra-pair environment-featured">' + featured + '</div></div>' if featured else '')
            + ('<details class="environment-extra"><summary>Zusätzliche Umgebungssichten</summary><div class="pass04-extra-pair">' + extras + '</div></details>' if extras else '') + '</section>')


def render_environment_sources(data: dict) -> str:
    buildings = data["source_packages"]["buildings"]["data"]
    geology = data["source_packages"]["geology"]["data"]
    model_rows = ''.join(f'<tr><th scope="row">{"Basis" if row["id"] == "habitat" else "Halle"}</th><td>{row["triangles"]:,}</td><td>{row["mesh_count"]}</td></tr>'.replace(',', '.') for row in buildings["assets"])
    worklife = ''.join('<tr><th scope="row">' + escape(row["id"]) + '</th><td><code>' + escape(row["path"]) + '</code><code>SHA-256: ' + row["source_sha256"] + '</code></td><td>' + escape(str(row["scale"])) + ' / ' + escape(str(row["support_height"])) + '</td></tr>' for row in data["worklife_sources"])
    return ('<section id="umgebungsquellen" class="section"><div class="section-head"><div><div class="eyebrow">Eigenständige Quellen / aktuelle Nachweisgrenzen</div><h2>Was sich wirklich verändert.</h2></div>'
            '<p>Neue Gebäudehüllen und Felsen sind eigene Godot-Geometrie. Die bestehenden Kenney-GLBs bleiben Grundlage; es entstehen hier keine neuen Blender-/GLB-Exporte oder Figurenmodelle.</p></div>'
            '<div class="provenance-grid"><article><span class="tag teal">Gebäude · eigene Godot-Hüllen</span><h3>Unterschiedliche Dach- und Vorzonen.</h3><p>Basis mit gestaffelten Dachmassen und Life-Support; Halle mit höherer Industriebucht und niedrigerem Büroprofil. Tiefe Portale, dunkle Sockel und warme Materialflächen. Keine neuen Licht-, Kollisions- oder Navigationsnodes.</p><p>Geometriecheck 21/21 und P4-Regression 22/22. Konservative AABB-Kontaktprüfung, kein exakter Dreiecksschnitt-Oracle.</p><a href="../../art/frontier_illustrated_20261101/environment/pass05/buildings/manifest.json">Gebäudequelle, isolierte Bilder und Grenzen ↗</a></article>'
            '<article><span class="tag teal">Felsen · eigene Godot-Geometrie</span><h3>Lokale Brüche statt durchlaufender Bänder.</h3><p>54 Meshes, 23.112 Vertices, 7.704 Dreiecke. Die 14 Anker und konservativen Navhüllen bleiben erhalten. 12/12 unveränderte Vertragschecks.</p><p>Große Topflächen und ruhigere Rückwände bleiben sichtbar vorlagenfern. Isolierte Geometriepaare nutzen eine gemeinsame Proberoute; sie behaupten keine Materialgleichheit mit dem historischen P4-Gesamtbild.</p><a href="../../art/frontier_illustrated_20261101/environment/pass05/geology/manifest.json">Geologiequelle, acht isolierte Bilder und Restabstand ↗</a></article>'
            '<article><span class="tag ochre">Figuren / Schiffe · erhaltene GLBs</span><h3>Aufstellung verändert, Körper erhalten.</h3><p>Vier originale Kenney-Citizens mit der bestehenden Pass02-Ausrüstung sowie Idle/Walk bleiben unverändert. Die neue Tiefenstaffelung verteilt sie auf drei Arbeitsgruppen; die alte enge Crewkamera zeigt deshalb nur drei Figuren. Das ist ein Platzierungsvergleich.</p><p>R02-Schiffe bleiben kritisierte Zwischenstände. Astra-Ausgaben sind separat beauftragt und hier nicht automatisch integriert.</p></article></div>'
            '<div class="table-scroll"><table class="qa-table"><thead><tr><th>Zusätzliche Gebäudehülle</th><th>Dreiecke</th><th>Meshes</th></tr></thead><tbody>' + model_rows + '</tbody></table></div>'
            + ('<p>Aktueller nativer Stand: ' + str(len(data["use_groups"])) + ' funktionale Arbeitsgruppen · ' + str(data["contact_gravel_count"]) + ' gezielte Kontakt-Geröllinstanzen. Die begehbaren Wegzentren bleiben eigene technische Prüffrage.</p>'
               '<h3>Drei echte Kenney-Originalquellen für Arbeitsgruppen.</h3><p>Originaldateien, UVs und Texturen bleiben erhalten; nur pro Instanz duplizierte Materialien erhalten einen wärmeren Farbton. Maßstab und Auflagehöhe gehören zur Montage, keine neue GLB-Geometrie.</p>'
               '<div class="table-scroll"><table class="qa-table"><thead><tr><th>Arbeitsobjekt</th><th>Originalquelle / Hash</th><th>Skalierung / Auflagehöhe</th></tr></thead><tbody>' + worklife + '</tbody></table></div>' if data["after_ready"] else '<p>Die Pakete sind als isoliert geprüfte Kandidaten dokumentiert. Die gemeinsame native env05-Capturefreigabe steht noch aus.</p>')
            + '</section>')


ENVIRONMENT_CSS = '''
.environment-findings{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:18px;margin-top:24px}.environment-finding{padding:24px;border:1px solid var(--line);border-radius:12px;background:var(--card)}.environment-finding h3{font:27px Georgia,serif;margin:9px 0 14px}.environment-finding p{font-size:13px;color:var(--muted);margin:11px 0}.environment-finding label{display:grid;gap:8px;font-size:12px;margin-top:16px}.environment-view-controls{flex-wrap:wrap;max-width:100%;gap:2px}.environment-extra{margin-top:24px}.environment-extra>summary,.pass04-history>summary{cursor:pointer;font-size:16px;font-weight:650}.pass04-history{border:1px solid var(--line);border-radius:12px;padding:22px;margin:26px 0}.pass04-history>p{font-size:13px;color:var(--muted);margin:14px 0}#environmentAnalysisImages{margin-top:18px}#environmentAnalysisImages figure{margin:0;background:var(--card);border:1px solid var(--line);border-radius:10px;overflow:hidden}#environmentAnalysisImages figcaption{font-size:12px;padding:13px 16px;color:var(--muted)}#environmentAnalysisImages img{width:100%;height:340px;object-fit:contain;background:#24241f}#environmentAnalysisImages button{padding:0;width:100%;display:block;border:0}#envPending[hidden]{display:none}.environment-view-controls button{font-size:11px;padding:9px 12px}.environment-new-details{margin-top:30px}.environment-new-details>p{font-size:13px;color:var(--muted);margin:12px 0 18px}.environment-featured{grid-template-columns:repeat(3,minmax(0,1fr))}@media(max-width:760px){.environment-findings,.environment-featured{grid-template-columns:1fr}.environment-finding{padding:18px}#environmentAnalysisImages img{height:auto}.pass04-history{padding:16px}}
'''

ENVIRONMENT_JS = r'''
function environmentChoices(){const ids=DATA.env05.pairs.map(p=>p.id);return {view:ids.includes(state.values['environment.view'])?state.values['environment.view']:'closed_outpost',mode:state.values['environment.mode']==='wipe'&&DATA.env05.after_ready?'wipe':'side',wipe:Math.max(0,Math.min(100,Number(state.values['environment.wipe']??50))),analysis_view:['outpost','hall','terrain'].includes(state.values['environment.analysis_view'])?state.values['environment.analysis_view']:'outpost'};}
function renderEnvironmentAnalysis(){const c=environmentChoices(),map={outpost:['ref_rostgrenze','env05_before_closed_outpost'],hall:['ref_freihafen','env05_before_closed_hall'],terrain:['ref_tactical','env05_before_landscape']};$('#environmentAnalysisImages').innerHTML=map[c.analysis_view].map((id,i)=>'<figure>'+imageButton(byId[id])+'<figcaption>'+(i?'Native Godot-Aufnahme · Pass04-Ausgangsbefund':'2D-Nutzerziel · eigener Kameraplan')+'</figcaption></figure>').join('');$$('[data-analysis-view]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.analysisView===c.analysis_view)));}
function renderEnvironment(){const c=environmentChoices(),p=DATA.env05.pairs.find(p=>p.id===c.view),a=byId[p.before_id],b=p.after_id?byId[p.after_id]:null;$('#envBeforeImage').src=a.full;$('#envBeforeImage').alt=a.title;$('#envBeforeButton').dataset.open=a.id;$('#envBeforeCaption').textContent=a.title+' · unverändert gesicherte Aufnahme';$('#envAfterButton').hidden=!b;$('#envPending').hidden=!!b;if(b){$('#envAfterImage').src=b.full;$('#envAfterImage').alt=b.title;$('#envAfterButton').dataset.open=b.id;$('#envAfterCaption').textContent=b.title+' · technischer Capturestand, Urteil separat';$('#envWipeAfter').src=b.full;$('#envWipeBefore').src=a.full;}$('#envSide').hidden=c.mode==='wipe';$('#envWipe').hidden=c.mode!=='wipe';$('#envWipeRange').value=c.wipe;$('#envWipeValue').textContent=c.wipe+' %';$('#envWipeBeforeLayer').style.clipPath='inset(0 '+(100-c.wipe)+'% 0 0)';$('#envWipeLine').style.left=c.wipe+'%';$$('[data-env-view]').forEach(x=>x.setAttribute('aria-pressed',String(x.dataset.envView===p.id)));$$('[data-env-mode]').forEach(x=>x.setAttribute('aria-pressed',String(x.dataset.envMode===c.mode)));$('#envConditions').textContent=b?'Gleiche Kamera, gleicher Viewport und gleiches globales Licht · '+(p.closed?'beide Zustände geschlossen':'beide Zustände grafischer Schnitt')+' · Schiffs-/Citizen-GLBs unverändert.'+(p.id==='crew'?' Vier erhaltene Citizens stehen in drei Tiefen; die alte Crewkamera zeigt drei. Geändert sind Aufstellung/Blickrichtung.':''):'Gesicherter Pass04-Vorherstand · freigegebener Umgebungspass env05 ausstehend.';$('#envMetadata').textContent=JSON.stringify({pair:p,before_renderer:DATA.env05.before_metadata.renderer,after_renderer:DATA.env05.after_metadata.renderer,scope:DATA.env05.scope},null,2);}
document.addEventListener('click',ev=>{const v=ev.target.closest('[data-env-view]'),m=ev.target.closest('[data-env-mode]'),a=ev.target.closest('[data-analysis-view]');if(v||m||a){if(v)state.values['environment.view']=v.dataset.envView;if(m)state.values['environment.mode']=m.dataset.envMode;if(a)state.values['environment.analysis_view']=a.dataset.analysisView;renderEnvironment();renderEnvironmentAnalysis();save();}});$('#envWipeRange').addEventListener('input',ev=>{state.values['environment.wipe']=ev.target.value;renderEnvironment();save();});renderEnvironment();renderEnvironmentAnalysis();
'''
