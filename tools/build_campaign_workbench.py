"""Freeze current campaign definitions into the offline planning workbench.

No game state is read or written. Fail if the recipe declaration changes shape,
instead of silently substituting a second recipe catalog.
"""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / 'docs/reports/campaign_research_workbench.html'


def build_seed():
    paths = ['data/singleplayer/jobs.json', 'data/singleplayer/job_briefings.json',
             'data/singleplayer/trade_offers.json',
             'scripts/core/singleplayer_supply_state.gd',
             'scripts/core/singleplayer_campaign_state.gd']
    jobs = json.loads((ROOT / paths[0]).read_text(encoding='utf-8-sig'))
    briefs = json.loads((ROOT / paths[1]).read_text(encoding='utf-8-sig'))
    trade = json.loads((ROOT / paths[2]).read_text(encoding='utf-8-sig'))
    supply = (ROOT / paths[3]).read_text(encoding='utf-8-sig')
    match = re.search(r'^const CAMPAIGN_RECIPES:Dictionary=(\{[^\n]+\})$', supply, re.M)
    if not match:
        raise ValueError('Recipe source changed: update extraction against the owning class.')
    recipes = json.loads(match[1])
    nodes = []

    def node(id, title, kind, requires=(), reward='', cost=0, description='', proposal=False):
        result = dict(id=id, title=title, kind=kind, requires=list(requires),
                      reward=reward, cost=cost, description=description,
                      proposal=proposal, credits=0, note='', decision='offen')
        nodes.append(result)
        return result

    labels = {'light_armor': 'Leichte Rüstung', 'mining_tool': 'Hand-Mining-Tool',
              'assault_rifle': 'Sturmgewehr'}
    for id, job in jobs.items():
        required = [job['prerequisite_job_id']] if job['prerequisite_job_id'] else []
        if id == 'benit_delivery':
            required += ['recruit_outpost', 'load_crate']
        reward = job.get('reward', {})
        blueprint = reward.get('blueprint_id')
        text = f"{reward.get('credits', 0)} Credits"
        if blueprint:
            text += ' · Bauplan: ' + labels.get(blueprint, blueprint)
        objectives = ' → '.join(briefs.get(id, {}).get('objectives', job['required_step_ids']))
        n = node(id, job['title'], 'mission', required, text, description=objectives)
        n['credits'] = reward.get('credits', 0)
        n['source'] = paths[0] + '#' + id
        n['home_upload'] = job.get('home_upload', False)
        if blueprint:
            recipe = recipes[blueprint]
            n = node('craft_' + blueprint, labels[blueprint] + ' herstellen', 'research', [id],
                     '1 × ' + labels[blueprint], recipe['cost'],
                     'Bauplan ist mit Auftragsabschluss freigeschaltet. Einzelanfertigung an der Heimatbasis; erneute Herstellung kostet erneut Credits.')
            n['source'] = paths[3] + '#CAMPAIGN_RECIPES.' + blueprint
    node('recruit_outpost', 'Person am Außenposten aufnehmen', 'base', ['outpost_recovery'],
         'Zusätzliche Person', description='Für den nächsten Lieferauftrag erforderlich. Im Spiel bereits nach dem Sichern des noch aktiven Außenpostens möglich; diese Übersicht bündelt den Ausflug bis zum Abschluss.')
    node('load_crate', 'C-Benit-Kiste verladen', 'base', ['outpost_recovery'],
         'Lieferfracht an Bord', description='Auftrag abschließen und die vorhandene Kiste am Ort wirklich verladen. Voraussetzung für die Annahme des Lieferauftrags.')
    node('recruit_pilot', 'Geretteten Piloten aufnehmen', 'base', ['buccaneer_rescue'],
         'Pilot für die Buccaneer', description='Bestätigte Ortsinteraktion nach der erfolgreichen Rettung.')
    node('second_pad', 'Zweites Landepad bauen', 'base', ['recruit_pilot'],
         'Zusätzliches Landepad', 100, 'Nach der Pilotenrettung an der Heimatbasis bauen. Vorhandener Preis aus SingleplayerSupplyState._campaign_build.')

    # Design continuation, explicitly proposals, not claimed runtime unlocks.
    node('workshop_research', 'Werkstatt zur Entwicklung ausbauen', 'base', ['outpost_chip_recovery'],
         'Entwicklungsplatz an der Basis', 180,
         'Vorschlag: Einen gesicherten Bauplan im Basisgebäude entschlüsseln. Freischaltung und bezahlte Einzelanfertigung bleiben getrennt.', True)
    node('research_medium', 'Mittlere Rüstung entwickeln', 'research', ['craft_light_armor', 'workshop_research'],
         'Rezept: mittlere Rüstung · Fertigungspreis noch festzulegen', 120,
         'Vorschlag: Mehr Schutz mit höherem Gewicht. Entwicklung einmal bezahlen; jede zusätzliche Rüstung separat fertigen.', True)
    node('research_heavy', 'Schwere Rüstung entwickeln', 'research', ['research_medium'],
         'Rezept: schwere Rüstung · Fertigungspreis noch festzulegen', 240,
         'Vorschlag: Schwerer Schutz als Spezialisierung, mit erkennbaren Nachteilen bei Bewegung und Traglast.', True)
    node('research_industry', 'Bergung und Rohstoffverarbeitung', 'research', ['craft_mining_tool', 'workshop_research'],
         'Folgeaufträge für Vulture und Prospector', 160,
         'Vorschlag: Nicht das Schiff gratis vergeben. Bergungs- und Bergbauaufträge öffnen den Zugang zu Ersatzteilen und anschließend zu Kauf und Ausbau.', True)
    node('research_ground', 'Bodenfahrzeuge erschließen', 'research', ['workshop_research'],
         'Cyclone-/Nova-Aufträge', 180,
         'Vorschlag: Cyclone ist ein Jeep, Nova ein Panzer. Fahrer, Standfläche und tatsächlicher Fahrzeugtransport müssen vor dem Kauf spielbar integriert sein.', True)
    node('research_flight', 'Flottenwerkstatt und Frachtausbau', 'research', ['second_pad', 'workshop_research'],
         'Komponenten- und Frachteraufträge', 220,
         'Vorschlag: Nach der Buccaneer-Rettung geht die Kampagne über Schiffskomponenten und spezialisierte Folgeaufträge weiter. Keine kostenlose Flotte.', True)
    return dict(version=1, date='2026-11-11', initial_credits=trade['initial_credits'],
                nodes=nodes, source_hashes={p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in paths},
                design='Bauplan bergen → an der Basis entwickeln → einzelne Ausrüstung fertigen',
                scope='Ist-Baseline plus Vorschläge. Keine Runtime- oder Spielstandsänderung.')


def main():
    seed = build_seed()
    html = REPORT.read_text(encoding='utf-8')
    encoded = json.dumps(seed, ensure_ascii=False, indent=2).replace('</', '<\\/')
    html, count = re.subn(r'(<script id="baseline" type="application/json">).*?(</script>)',
                         lambda m: m[1] + '\n' + encoded + '\n' + m[2], html, count=1, flags=re.S)
    if count != 1:
        raise ValueError('Unique baseline script is missing')
    REPORT.write_text(html, encoding='utf-8')
    print(f'Workbench baseline: {len(seed["nodes"])} nodes, {len(seed["source_hashes"])} source hashes')


if __name__ == '__main__':
    main()
