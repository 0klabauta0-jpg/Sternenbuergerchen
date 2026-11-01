"""Current Pass-04 targets, user criticism and separate native review criteria."""
from html import escape

STEPS = [{'title': 'Kritisierte R02-Schiffe im Astra-Chat neu überarbeiten',
  'reference': 'Cutlass08/09, Buccaneer13/11; eigene neue Blender-/GLB-Quellen',
  'reference_ids': ['cutlass_front', 'cutlass_rear', 'buccaneer_front', 'buccaneer_rear'],
  'status': 'r02_criticized_not_accepted_astra_revision_delegated',
  'gap': 'Nach R01 trifft auch R02 das 2D-Bildziel für den Nutzer noch nicht. Source-/Importchecks und '
         'freigegebene Captures sind technische Nachweise, keine gestalterische Annahme.',
  'change': 'Beide Schiffe im ausdrücklich beauftragten separaten Astra-Ultra-Blender-Chat nach '
            'Cutlass08/09 und Buccaneer13/11 überarbeiten. Eigener Ausgabebereich pass05_astra_ultra; '
            'keine automatische Runtime-Übernahme. R01 abgelehnt archivieren, R02 als kritisierten '
            'technischen Zwischenstand direkt vergleichbar halten.',
  'check': 'R02 nativ neben dem 2D-Ziel und neben R01 zeigen; Status weiter kritisiert klar ausweisen. '
           'Astra-Ergebnisse erst nach eigener Mehransichten-/Source-/Roundtripprüfung und gesonderter '
           'nativer Integration als neuen Stand zeigen.'},
 {'title': 'Gebäude geschlossen und im Cutaway zeigen',
  'reference': 'Rostgrenze-Cutaway, Freihafen und lokale SC-Industriequellen',
  'reference_ids': ['ref_rostgrenze', 'ref_freihafen', 'ref_industry'],
  'status': 'pass04_r02_in_progress_capture_pending',
  'gap': 'Der Nutzer empfindet die bisherigen sauberen, gleichförmigen Flächen und Ausstattungsgruppen '
         'als steril.',
  'change': 'Die Kenney-basierten Raum-/Hallensets um eigene in Godot erzeugte Außenhüllen ergänzen und '
            'zwischen geschlossenem Zustand und Schnittdarstellung umschalten. Mehr Schrägen, Fasen und '
            'wenige gezielte Nieten an großen Bauteilen erproben. Keine Kenney-Dach-GLBs vortäuschen; '
            'Quellhash des eigenen Schalenbuilders und tatsächliche native Sichtzustände belegen.',
  'check': 'Basis, Halle und Außenposten geschlossen/offen bei passender Kamera öffnen. Beide Bilder '
           'sind aktuelle Nachherzustände, keine historischen Vorherbilder. Sichtwechsel verändert '
           'keine Kartenfakten; Quellen und native Meshdarstellung getrennt prüfen.'},
 {'title': 'Versorgung: tragender Aufbau statt kritisiertem Tank/Wagen',
  'reference': 'Funktionale SC-Außenposten, Freihafen-Anschlüsse und Kenney-Factory-Grundteile',
  'reference_ids': ['ref_freihafen', 'ref_industry'],
  'status': 'pass04_r02_in_progress_capture_pending',
  'gap': 'Tank und Wagen des Vorherstands gefallen dem Nutzer nicht; Aufbau und Verbindung wirken noch '
         'nicht überzeugend.',
  'change': 'Eine verständliche Fuel-/Versorgungsbaugruppe mit getragenen Tanks, Rahmen und klaren '
            'Anschlüssen aufbauen. Echte Kenney-Grundbauteile nachweisbar verwenden; Versorgung als '
            'grafischen Funktionsbereich in die Basis einbinden.',
  'check': 'Neue Utility-Nahansicht, Gesamtbild und technische Montage-/Kontaktprüfung zeigen. Keine '
           'schwebenden Baugruppen; die grafischen Anschlüsse behaupten keine Betankungs- oder '
           'Fahrzeugmechanik.'},
 {'title': 'Wege und Pads an SC-Außenposten annähern',
  'reference': 'HDMS-Thedus · tatsächlich geöffnete Community-Ingame-Padvorlage; ergänzend '
               'Rostgrenze/Freihafen',
  'reference_ids': ['ref_thedus', 'ref_rostgrenze', 'ref_freihafen'],
  'status': 'pass04_r02_in_progress_capture_pending',
  'gap': 'Die bisherigen dünnen Verbindungen und die kleine Padform treffen die gewünschte '
         'Außenpostenwirkung noch nicht.',
  'change': 'Sehr flache rechteckige Metalldecks mit kleinen Fasen, gebrochenen Eck-/Landelinien, '
            'niedrigen Randlichtern und seitlichen Zugangsrampen nach Thedus aufbauen. Breite matte '
            'Servicewege verbinden Basis und Pads. Ein größeres Cutlass- und ein kleineres '
            'Buccaneer-Pad am bewusst stilisierten Fahrzeugmaßstab ausrichten; bisherige H-/Ringform '
            'ersetzen.',
  'check': 'Sechs feste Vorher-/Nachherkameras, Raster an/aus und neue weite Außenpostenansicht prüfen. '
           'Modell-/Padbelegung muss vor Registry-Aufbau gesetzt sein; Crew und Picking bleiben '
           'getrennte echte Funktionsprüfungen.'},
 {'title': 'Boden, Felsen und Wege weiter an die 2D-Ziele annähern',
  'reference': 'Taktische Gesamtkarte, Rostgrenze und Freihafen',
  'reference_ids': ['ref_tactical', 'ref_rostgrenze', 'ref_freihafen'],
  'status': 'pass04_r02_in_progress_capture_pending',
  'gap': 'Der Nutzer wünscht weiterhin eine hübschere, stärker zusammenhängende Landschaft nach den '
         'Bildvorlagen; die vorherigen großen Facetten und Flächen reichen ihm nicht.',
  'change': 'Ruhige weiche Sediment-/Pigmentfelder, gebrochene Felslippen und besser eingebundene '
            'Wegkanten weiterentwickeln. Die Umgebung mit geschlossenen Gebäuden, neuen Schiffen und '
            'Pads als eine Komposition beurteilen; das autoritative Hexraster bleibt erhalten.',
  'check': 'Sechs feste Paaransichten und neue weite/geschlossene Ansichten nativ öffnen. Vorherbilder '
           'erhalten, verbleibende Abstände konkret benennen; keine R01-Captures oder alten '
           'Modellurteile als R02-Freigabe weiterführen.'},
 {'title': 'Kenney-Citizens und Ausrüstung aus Pass02 erhalten',
  'reference': 'Bestehende modulare Kenney-Figuren und originale Idle-/Walk-Clips',
  'reference_ids': ['people', 'ref_tactical'],
  'status': 'retained_from_pass02_no_new_character_revision',
  'gap': 'Der neue Pass betrifft Schiffe, Sets und Außenpostenflächen. Bestehende Figuren sollen dabei '
         'weder verändert noch von großen Baugruppen verdeckt werden.',
  'change': 'Die vorhandenen Körper, Skins und Ausrüstung beibehalten. Aufstellung und Blickbeziehungen '
            'im neuen Layout erhalten; keine zusätzliche Menschenrevision behaupten.',
  'check': 'Vorher-/Nachher-Modellhashes, feste Crewkamera und Walk-Ansicht prüfen. Beibehaltene '
           'Figuren und neue Umgebung in den Metadaten getrennt führen.'}]


def render_next_art_steps(after_ready=False):
    cards = []
    for i, item in enumerate(STEPS, 1):
        status_label = "R02 weiter kritisiert · Astra-Revision beauftragt" if item["status"].startswith("r02_criticized") else "aus Pass 02 beibehalten" if item["status"].startswith("retained") else "native Gegenprobe vorhanden · Urteil offen" if after_ready else "Pass 04 / R02 in Arbeit · Aufnahme ausstehend"
        cards.append(
            '<article class="next-art-card">'
            f'<div class="eyebrow">Schritt {i:02d} · {status_label}</div>'
            f'<h3>{escape(item["title"])}</h3>'
            f'<p class="next-reference">Ziel: {escape(item["reference"])}</p>'
            f'<p><strong>Beauftragter Ausgangsbefund.</strong> {escape(item["gap"])}</p>'
            f'<p><strong>Ziel des Grafikschritts.</strong> {escape(item["change"])}</p>'
            f'<p><strong>Vergleich danach.</strong> {escape(item["check"])}</p>'
            '</article>'
        )
    return (
        '<section id="naechste-grafikschritte" class="section next-art-section" aria-labelledby="next-art-heading">'
        '<div class="section-head"><div><div class="eyebrow">Nächste Grafikschritte / konkret am Bild</div>'
        '<h2 id="next-art-heading">Bildfortschritt prüfen, Schiffe weiter überarbeiten.</h2></div>'
        '<p>Die vollständigen Hauptvorlagen bestimmen die Ziele. Ausgangsbefund, Arbeitsziel und Bildprüfung '
        'bleiben getrennt; der native Vergleich oben zeigt den tatsächlich aufgenommenen Stand.</p></div>'
        '<p class="next-art-intro">R01 wurde abgelehnt; auch R02 bleibt für den Nutzer bei den Schiffen zu weit vom Ziel entfernt. Die nächste Schiffsrevision läuft im separaten Astra-Ultra-Blender-Chat. Geschlossene Gebäude mit Schrägen/Fasen/Nieten und die nähere 2D-Landschaft werden hier weiter beurteilt. '
        'Die vorhandenen Kenney-Citizens bleiben bestehen. Neue leere Notizen und ein eigener Exportbereich trennen diesen Auftrag vom eingefrorenen Pass 03.</p>'
        '<div class="next-art-grid">' + ''.join(cards) + '</div>'
        '<p class="section-footnote">Nach jedem Schritt dieselben Kameras in Nah- und Spielansicht aufnehmen '
        'und direkt gegen die zugeordnete Vorlage stellen. Proportionen, Farbflächen und Silhouetten '
        'bewerten, bevor weitere Details hinzukommen.</p></section>'
    )


NEXT_ART_CSS = """
.next-art-section{padding-top:30px}.next-art-section .section-head h2{max-width:680px}
.next-art-intro{max-width:1050px;color:var(--muted);font-size:14px;margin-bottom:24px}
.next-art-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:20px}
.next-art-card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:25px}
.next-art-card h3{font:400 25px/1.2 Georgia,serif;letter-spacing:-.02em;margin:10px 0 12px}
.next-art-card p{font-size:13px;line-height:1.7;color:var(--muted);margin:12px 0 0}
.next-art-card p strong{color:var(--body)}.next-art-card .next-reference{color:var(--teal);font-size:12px}
@media(max-width:760px){.next-art-grid{grid-template-columns:1fr}.next-art-card{padding:19px}.next-art-card h3{font-size:23px}.next-art-intro{font-size:13px}}
"""
