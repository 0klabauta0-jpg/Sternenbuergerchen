"""Bounded audit of actually authored useful Kenney assets, not the full library.

Counts are map records, not a claim that every model is instantiated at once.
Runtime visual replacements are called out separately from authored identifiers.
"""
from collections import defaultdict
import hashlib
import html
import json
import re
from urllib.parse import unquote


def source_dependencies(root, model_file):
    if model_file.suffix.lower() != '.gltf' or not model_file.is_file(): return []
    source = json.loads(model_file.read_text(encoding='utf-8'))
    paths = set()
    for item in source.get('buffers', []) + source.get('images', []):
        uri = item.get('uri', '')
        if not uri or uri.startswith('data:'): continue
        path = (model_file.parent / unquote(uri)).resolve()
        if not path.is_relative_to(root.resolve()) or not path.is_file():
            raise RuntimeError('Missing local model dependency: '+uri)
        paths.add(path)
    return [{'path':p.relative_to(root.resolve()).as_posix(), 'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(paths)]


def build(root):
    catalog = json.loads((root / 'data/terrain_tile_catalog.json').read_text(encoding='utf-8'))
    definitions = {item['type_id']: item for item in catalog['tile_types']}
    models = json.loads((root / 'data/terrain_3d_asset_mapping.json').read_text(encoding='utf-8'))['models']
    source = (root / 'scripts/mission/productive_ground_maps.gd').read_text(encoding='utf-8')
    paths = re.findall(r'"res://(maps/[^"\n]+\.json)"', source.split('const HISTORICAL_FIXTURES')[0])
    usages = defaultdict(lambda: defaultdict(list))
    input_hashes = {}
    excluded = defaultdict(int)
    for path in paths:
        raw = (root / path).read_bytes()
        input_hashes[path] = hashlib.sha256(raw).hexdigest()
        data = json.loads(raw)
        for tile in data['tiles']:
            for field in ('type_id', 'object_type_id'):
                type_id = tile.get(field, '')
                key = type_id if type_id in models else re.sub(r'_(ne|nw|se|sw)$', '', type_id)
                entry = models.get(key, {})
                origin = (entry.get('model_path', '') + ' ' + entry.get('source_id', '')).lower()
                if 'kenney' not in origin and 'space_station' not in origin:
                    continue
                if type_id.startswith(('ground_', 'slope_', 'cliff_', 'pipe_', 'spacekit_pipe_')):
                    excluded[type_id] += 1
                    continue
                if type_id.startswith('nature_') and 'rock' not in type_id:
                    excluded[type_id] += 1
                    continue
                usages[type_id][path].append({
                    'cell': tile['grid_position'], 'layer': field,
                    'walkable': bool(tile.get('walkable', True)),
                    'blocks_los': bool(tile.get('blocks_los', False)),
                    'cover_value': tile.get('cover_value', 0),
                })
    assets = []
    for type_id, locations in sorted(usages.items()):
        definition = definitions.get(type_id, {})
        key = type_id if type_id in models else re.sub(r'_(ne|nw|se|sw)$', '', type_id)
        model = models.get(key, {})
        path = model.get('model_path', '').removeprefix('res://')
        preview = definition.get('texture_path', '').removeprefix('res://')
        if not preview or not (root / preview).is_file(): preview = ''
        group, purpose, adaptation, review = describe(type_id)
        model_file = root / path
        assets.append({
            'id': type_id, 'title': definition.get('display_name', type_id),
            'group': group, 'purpose': purpose, 'adaptation': adaptation,
            'review': review, 'model_key': key, 'model_path': path,
            'model_sha256': hashlib.sha256(model_file.read_bytes()).hexdigest() if model_file.is_file() else '',
            'source_dependencies': source_dependencies(root, model_file),
            'preview_path': preview,
            'preview_sha256': hashlib.sha256((root / preview).read_bytes()).hexdigest() if preview else '',
            'preview_status': 'Original-Katalogbild; keine Vorschau der aktuellen Hexanpassung',
            'uses': [{'map': p, 'count': len(cells), 'cells': cells} for p, cells in sorted(locations.items())],
            'count': sum(len(cells) for cells in locations.values()),
        })
    result = {
        'schema': 'sternenbuergerchen.kenney_usage.v1',
        'scope': 'Praktischer, tatsächlich in den 17 gelisteten Spiel-/Basiskarten referenzierter Subset. Keine Vollanpassung der Kenney-Bibliothek.',
        'count_basis': 'Authored Kartenrecords. Streaming, Themeersatz und explizite Visualowner können die konkrete Darstellung ändern.',
        'map_sha256': input_hashes, 'assets': assets,
        'runtime_visual_overrides': [
            {'authored_id': 'nature_rock_cover', 'visual_source': 'Assets/used/terrain/nature_kit_classic/rocks/rock_large1.gltf',
             'use': 'Vorhandenes Deckungsgestein; Modell erhalten, aride Materialfarbe a56847 und enge deterministische Variation innerhalb der Zelle.'},
            {'authored_id': 'nature_tree_blocker', 'visual_source': 'glut_sandstone_04',
             'maps': ['maps/station_outpost_64x64.json', 'maps/station_outpost_192x192.json'],
             'use': 'Vorhandene logische Baumblocker erscheinen in diesen Wüstenstationen als Sandstein. Keine neuen Bäume oder Gameplayfakten.'},
            {'authored_id': 'cliff_*', 'visual_source': 'glut_sandstone_04 oder eigene Hex-Höhenflächen',
             'use': 'Nur alte aride Square-Ornamente ohne eigene Objekthöhe: unabhängige Blocker bleiben als Stein sichtbar; funktionslose alte Hügelmodelle entfallen. Andere Biome und eigenständige Objekte bleiben erhalten.'},
        ],
        'excluded_authored_references': dict(sorted(excluded.items())),
        'exclusions': [
            'Hügel, Rampen und Gelände bleiben unsere eigenen Hexformen; alte Cliff-IDs sind keine Auswahl von Kenney-Hügelmodellen.',
            'Rohrstrecken sind nicht ausgewählt. 33 beziehungsweise 265 Rohrzellen der beiden Stationen sind samt ihren Objektblockaden entfernt; Gelände und Lagerhaus bleiben erhalten.',
            'Auf Station64 und Station192 werden alte Baumblocker als vorhandene Sandsteinmodelle dargestellt. Ihre logischen Blockerfakten bleiben erhalten; Vegetation anderer Karten wird dadurch nicht ersetzt.',
            'Helle Bodenflecken bleiben vorerst. Neue kleine Kiesel sind reine Darstellung ohne Gameplayfakten und werden separat vom Deckungsgestein geführt.',
        ],
    }
    output = root / 'docs/qa/review_completion_20261113/kenney_usage_catalog.json'
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return result


def describe(type_id):
    station = type_id.startswith('station_set_')
    if 'door' in type_id:
        return ('Mauern und Tore', 'Zugänge, Türrahmen und Torblätter.', 'Stationsrahmen und Türblätter sind auf die freigegebenen Wandachsen und ihre tatsächliche Hexhülle ausgerichtet.' if station else 'Vorhandener ortsgebundener Türbaustein; keine pauschale Modellüberarbeitung.', 'Nur mit Szenariobinding interaktiv; ein platziertes Modell allein ist noch keine bedienbare Tür. Native Stationsvergleiche zeigen die korrigierten Anschlüsse.')
    if 'wall' in type_id or 'barrier' in type_id:
        return ('Mauern und Tore', 'Räume und Außenposten abgrenzen.', 'Freigegebener Lagerhauswinkel erhalten; Fugen und Eckverbinder der neun Stationsensembles korrigiert.' if station else 'Vorhandener ortsgebundener Wandbaustein; keine pauschale Modellüberarbeitung.', 'Schmalere helle Varianten mit gelbem Streifen bleiben ein Auswahlvorschlag. Die aktuelle Stationskorrektur ersetzt keine allgemeine Überarbeitung aller Wandmodelle.')
    if 'floor' in type_id or 'balcony' in type_id:
        return ('Böden', 'Begehbare Stations- und Gebäudeflächen.', 'Passende zellgebundene Bodenfamilien sind dünne Hexauflagen; Originaldateien und tatsächliche Gelände-/Stützhöhen bleiben erhalten.', 'Stationsboden unter Mauern und Props sowie geteilte rot/helle Randflächen sind nativ geprüft. Nur die konkret auf 0,028 m abgeleiteten Bodenhäute werfen keinen eigenen Schatten mehr; sie empfangen weiterhin Wand- und Klippenschatten. Massive Decks und Rampen behalten ihren Schattenwurf.')
    if 'rock' in type_id:
        return ('Gestein', 'Felsgruppen und vorhandene Deckungsobjekte.', 'Form vom Nutzer positiv beurteilt; aride Palette, enge visuelle Variation und gezielte Gruppen auf beiden Wüstenstationen.', 'Einige große Reihen bleiben wegen geschützter Wege und Anschlüsse erhalten. Diese Gameplayblocker sind von den neuen winzigen, rein dekorativen Kieseln auf freien Flächen zu unterscheiden.')
    if any(word in type_id for word in ('chair', 'computer', 'table', 'container', 'barrel', 'desk')):
        return ('Raum-Props', 'Räume als Arbeits-, Lager- oder Aufenthaltsbereiche erkennbar machen.', 'Vorhandene nützliche Ausstattung bleibt; keine pauschale Hexverformung der Möbel.', 'Grundauswahl positiv beurteilt. Weitere Stilüberarbeitung ausdrücklich später; aktuelle Kollision/Deckung steht im Rohkatalog.')
    return ('Anlagen und Details', 'Werkhöfe, Technik und einzelne Missionsorte charakterisieren.', 'Nur tatsächlich benötigte Bestandsteile; keine vollständige Bibliotheksmigration.', 'Verwendung und Funktionsbindung ortsbezogen prüfen. Modellpräsenz belegt keine neue Interaktion.')


def section(root):
    data = build(root)
    esc = lambda value: html.escape(str(value), quote=True)
    cards = []
    for asset in data['assets']:
        places = ' · '.join(f"{item['map'].split('/')[-1].removesuffix('.json')} ({item['count']})" for item in asset['uses'])
        image = ''
        if asset['preview_path']:
            image = f'<img loading="lazy" src="../../{esc(asset["preview_path"])}" alt="Originalvorschau {esc(asset["title"])}"><small>{esc(asset["preview_status"])}</small>'
        else:
            image = '<p class="source">Kein isoliertes Katalogbild vorhanden. Die genaue Modellquelle steht unten.</p>'
        rows = ''.join(f'<li>{esc(use["map"])}: {use["count"]} Referenzen</li>' for use in asset['uses'])
        cards.append(f'''<details class="usage-asset" data-usage-group="{esc(asset['group'])}" data-usage-search="{esc((asset['title']+' '+asset['id']+' '+places).lower())}"><summary>{esc(asset['title'])} <small>· {asset['count']} Referenzen</small></summary>{image}<p><strong>Zweck:</strong> {esc(asset['purpose'])}</p><p><strong>Anpassung:</strong> {esc(asset['adaptation'])}</p><p><strong>Prüfen:</strong> {esc(asset['review'])}</p><ul>{rows}</ul><p class="source">ID: {esc(asset['id'])}<br>{esc(asset['model_path'])}<br>SHA-256: {esc(asset['model_sha256'])}</p><label>Befund / Entscheidung<textarea rows="2" data-export-key="kenney.{esc(asset['id'])}.note"></textarea></label></details>''')
    groups = ''.join(f'<option>{esc(group)}</option>' for group in sorted({a['group'] for a in data['assets']}))
    exclusions = ''.join(f'<li>{esc(item)}</li>' for item in data['exclusions'])
    return f'''<article class="card full" id="kenney-usage"><div class="eyebrow">GEZIELTE AUSWAHL · KEINE VOLLANPASSUNG</div><h2>Welche Kenney-Teile werden wofür benutzt?</h2><p>Raum-Props, passende Steine und brauchbare Wand-/Torteile. Die Liste kommt aus den tatsächlichen Kartenreferenzen; sie behauptet keine gleichzeitige Darstellung sämtlicher Objekte. Originalvorschauen zeigen nicht die fertige Hexanpassung.</p><label>Suchen<input id="usage-search" type="search" placeholder="Name, Asset-ID oder Karte"></label><label>Bereich<select id="usage-group"><option value="all">Alle Bereiche</option>{groups}</select></label><p id="usage-count"></p><div class="usage-grid">{''.join(cards)}</div><details><summary>Bewusst ausgenommen und Grenzen</summary><ul>{exclusions}</ul></details><p><a href="../qa/review_completion_20261113/kenney_usage_catalog.json">Vollständiger Katalog mit Zellkoordinaten, Gameplayfakten und Prüfsummen</a></p></article>'''


CSS = '''#kenney-usage{scroll-margin-top:80px}#kenney-usage label{display:grid;gap:6px;margin:10px 0}#kenney-usage input,#kenney-usage select,#kenney-usage textarea{box-sizing:border-box;width:100%;min-width:0}.usage-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}.usage-asset{border:1px solid #395460;padding:12px;min-width:0;overflow-wrap:anywhere;align-self:start}.usage-asset[hidden]{display:none}.usage-asset summary{cursor:pointer}.usage-asset img{display:block;max-width:180px;max-height:160px;object-fit:contain;margin:12px auto}.usage-asset small{font-size:12px;opacity:.8}.usage-asset .source{font-size:12px}@media(max-width:700px){.usage-grid{grid-template-columns:minmax(0,1fr)}}'''
JS = '''(()=>{const search=document.querySelector('#usage-search'),group=document.querySelector('#usage-group');if(!search)return;const cards=[...document.querySelectorAll('.usage-asset')];function update(){let count=0;for(const card of cards){card.hidden=!(group.value==='all'||card.dataset.usageGroup===group.value)||!card.dataset.usageSearch.includes(search.value.toLocaleLowerCase());if(!card.hidden)count++}document.querySelector('#usage-count').textContent=count+' von '+cards.length+' verwendeten Assettypen'}search.addEventListener('input',update);group.addEventListener('change',update);update()})();'''
