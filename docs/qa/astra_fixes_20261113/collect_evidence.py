"""Build the fix report from explicitly selected successful regression runs."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[3]
QA = Path(__file__).resolve().parent
RESOLVED = [
    ('C1', 'Host bestimmt Laufzeitmodifikatoren', 'Remote-Befehle enthalten nur Spielerabsichten; interne Befehle behalten ihre legitimen Modifikatoren.'),
    ('C2', 'Missionsinteraktionen bleiben beim Host', 'Ziel, Radius, Dauer, Voraussetzungen und Bediener stammen aus dem geladenen Szenario. Abbruch, Ausfall, Einschiffung und konkurrierende Trupps sind geprüft.'),
    ('C3', 'Raumkampf erreicht einen vollständigen Abschluss', 'Sieg, Rückzug und beide Verlustfälle wechseln atomar in den lokalen Orbit. Kraftstoff und Ergebnis werden einmal verbucht; ein vorübergehend abgelehnter Abschluss wird erneut versucht.'),
    ('C4', 'Alte beschädigte Einsatzstände blockieren keinen Neustart', 'Neue Kampagnen trennen den alten Einsatzstand erst beim sicheren Basis-Commit ab. Seine Bytes bleiben im Archiv; ein unterbrochener Archivschritt macht den neuen Stand nicht unzugänglich.'),
    ('C5', 'Basis-Rückkehr lädt ausdrücklich die Basis', 'Normales Fortsetzen erhält einen gültigen Einsatzstand. Debrief und bestätigte Wiederherstellung nutzen einen eigenen Basis-Intent; Speichertexte stimmen mit dem Verhalten überein.'),
    ('C6', 'Halbe Rampenhöhen bleiben präzise', 'Sichthöhe 2,5 wird bis zum Hindernisvergleich erhalten. Beide Richtungen, Cache und unveränderte ganzzahlige Legacyfälle sind geprüft.'),
    ('C7', 'Tatsächliche Schüsse verwenden logische Hexsicht', 'Richtung, Reichweite, Gelände und Zulassung folgen im aktiven Hexpfad dem vorhandenen Sichtadapter. Alle sechs Achsen und Legacy-Verhalten sind abgedeckt.'),
    ('C8', 'Diagnosen würfeln und mutieren nicht', 'HUD-Lesen verändert weder Zufallszustand noch Cooldowns, Ereignisse oder Befehle. Tatsächliche Disziplinentscheidungen bleiben Teil der autoritativen Feuerwahl.'),
    ('C9', 'Spielmenü hält Eingaben und Fokus zusammen', 'Menü, Einstellungen und Hilfe halten den Fokus. Kameratasten und unterbrochene Mausgesten lösen keine verdeckten Aktionen aus; Simulation und gültiger Fokus werden korrekt weitergeführt.'),
    ('C10', 'Vollständiger Truppausfall verursacht keine Rekursion', 'Der vollständige Kampagnentest fand zusätzlich eine rekursive Anführer-/Auswahlabfrage. Ohne fitte Mitglieder gibt es keinen Verhaltens-Leader; der reine Anzeigeanker bleibt erhalten. Der tatsächliche CombatLoopDriver ist korrekt angebunden.'),
]
LIMITS = ('Gezielte Headless- und lokale ENet-Prüfungen auf Godot 4.6.2; keine Desktopübernahme. '
          'Originalspielerprofile und Quellen blieben während der freigegebenen Läufe unverändert. '
          'Kein vollständiger menschlicher Kampagnendurchlauf, WAN-Test, neues GPU-/FPS-Gate oder EXE-Export. '
          'Gestaltungs- und größere Architekturvorschläge des ursprünglichen Reviews bleiben separat offen.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--product-commit', required=True)
    args = parser.parse_args()
    commit = subprocess.check_output(['git', 'rev-parse', args.product_commit + '^{commit}'], cwd=ROOT, text=True).strip()
    selected = json.loads((QA/'selection.json').read_text(encoding='utf-8'))
    checks = []
    archive_paths = set()
    for item in selected:
        path = ROOT/item['report']
        report = json.loads(path.read_text(encoding='utf-8'))
        assert report.get('passed', report.get('status') == 'passed'), item['report']
        assert not report.get('errors'), item['report']
        log = path.parent/'output.log'
        raw = log.read_text(encoding='utf-8', errors='replace')
        assertions = report.get('assertions')
        if assertions is None:
            match = re.search(item['count_pattern'], raw)
            assert match and int(match[2]) == 0
            assertions = int(match[1])
        assert assertions > 0
        checks.append(dict(name=item['name'], assertions=assertions, report=item['report'], log_sha256=hashlib.sha256(log.read_bytes()).hexdigest()))
        archive_paths.update([path, log])
    # Retain both failed attempts and successful final attempts. The failed
    # network fixture and real campaign recursion are explicitly distinguished.
    for path in QA.rglob('*'):
        if path.name in ['report.json', 'output.log']:
            archive_paths.add(path)
    archive_paths.update((ROOT/'scripts/tests').glob('astra_*_20261113.gd'))
    archive_paths.add(ROOT/'scripts/tests/run_astra_fixes_20261113.py')
    for item in selected:
        if 'script' in item:
            archive_paths.add(ROOT/item['script'])
    with zipfile.ZipFile(QA/'regression_evidence.zip', 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(archive_paths):
            assert path.resolve().is_relative_to(ROOT)
            archive.write(path, path.relative_to(ROOT).as_posix())
    total = sum(check['assertions'] for check in checks)
    summary = dict(date='2026-11-13', product_commit=commit, base_main='9fdeb866b71749fe5d3154d4da35c6cf3f2c1611',
                   resolved=[dict(id=id, title=title, result=result) for id, title, result in RESOLVED],
                   assertions=total, checks=checks, limits=LIMITS,
                   incidents=[
                       dict(run='network/7cf83b5297f64421ae357c7581b3efe1', kind='test_fixture', detail='Ungültiger Testzugriff auf UnitRuntimeStatus-Feld; Runner blieb trotz 64/0 rot. Zugriff korrigiert, ausgelassene positive Fälle danach ausgeführt.'),
                       dict(run='campaign/79b34e4c27994a3e901d8cef9c648f81', kind='confirmed_product_defect_C10', detail='Echter Stackoverflow bei vollständigem Truppausfall. Eigener Testprozess nach reproduziertem Fehler beendet; anschließend Resolver korrigiert und voller Kampagnenlauf erneut geprüft.'),
                       dict(run='campaign/cd369ebd3dde49ff8db69c10ce76002b', kind='time_budget', detail='Nach C10-Fix ohne Enginefehler bis zum letzten Neustart fortgeschritten; 300-Sekunden-Grenze erreicht. Nicht als bestanden gewertet, vollständiger Wiederholungslauf mit 480 Sekunden Grenze.'),
                   ])
    (QA/'summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    rows = '\n'.join(f'| {c["name"]} | {c["assertions"]} | 0 |' for c in checks)
    fixes = '\n'.join(f'- **{id} · {title}:** {result}' for id, title, result in RESOLVED)
    readme = f'''# Reviewfehler behoben · 13.11.2026

Die neun ursprünglichen Codebefunde und der im vollständigen Regressionstest
zusätzlich entdeckte Fehler C10 sind behoben. Produktcommit: `{commit}`.
Basis: Main `9fdeb866b`; Umsetzung im Taskbranch, keine fremden Produktänderungen.

## Korrekturen

{fixes}

## Erfolgreiche Regressionen

{total} Assertions in {len(checks)} Prüfläufen; erfolgreiche Läufe ohne Engine-/Scriptfehler.
Quellhash-, Originalprofil- und private Profilguards sind Bestandteil der Rohbelege.
Zwei private inkrementelle Editorimports liefen sauber durch; bestehender Cache,
kein behaupteter neuer Kaltimport. Tests laufen seriell mit Prozesszeitlimits.

| Prüfung | Assertions | Fehler |
| --- | ---: | ---: |
{rows}

## Verworfen und erneut geprüft

- Erster Netzwerkversuch: Test-API-Fehler, kein akzeptiertes grünes Gate trotz
  ausgegebener 64/0. Der Runner erkennt zusätzlich Enginefehler; die korrigierte
  Probe führt auch die zuvor ausgelassenen positiven Fälle aus.
- Erster Kampagnenversuch: tatsächlicher rekursiver Produktfehler C10. Nur der
  identifizierte eigene Godot-Prozess wurde beendet; Profile blieben unverändert.
  Der gezielte Anführer-Test und der vollständige neue Kampagnenlauf sichern den Fix.
- Ein anschließender Kampagnenlauf erreichte ohne Enginefehler die 300-Sekunden-
  Grenze kurz vor dem Abschluss. Er zählt nicht als bestanden. Der vollständige
  Wiederholungslauf nutzt ein begrenztes 480-Sekunden-Fenster.
- Frühere Interaktionsfixtures 1093/1102 liefern nun echte Hostbindings und ihre
  passenden geladenen Marker; ihre fachlichen Assertions wurden nicht abgeschwächt.
- Der Encounter-Readtest unterscheidet den sichtbaren ausstehenden Rückkehrcommit
  vom bereits verbuchten Ergebnis. Der enge Readpfad bleibt erhalten.

## Nachvollziehbarkeit und Grenzen

Der Testindex steht in `summary.json`; `selection.json` bindet die finalen Läufe
ausdrücklich. `regression_evidence.zip` enthält Rohlogs, Quellhashberichte und
Testskripte, jedoch keine Originalspielerprofile. Die ursprüngliche Reviewevidenz
unter `docs/qa/astra_review_20261113` bleibt unverändert.

{LIMITS}

Unabhängige Gegenreviews für Netzwerk, Kampagne, Hex/Diagnose und den zusätzlichen
Anführerfix sind abgeschlossen. Beim Menü gefundene Lücken (Polling, Fokus-Kreis,
unterbrochene Gesten) sind implementiert und mit realer Godot-Eingabeverarbeitung geprüft.
'''
    (QA/'README.md').write_text(readme, encoding='utf-8')
    print(json.dumps(dict(assertions=total, runs=len(checks), archive_bytes=(QA/'regression_evidence.zip').stat().st_size)))


if __name__ == '__main__':
    main()
