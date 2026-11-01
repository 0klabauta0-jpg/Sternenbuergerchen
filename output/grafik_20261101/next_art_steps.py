"""Pass-02 art targets, their starting gaps and explicit native review criteria."""
from html import escape

STEPS = [{'title': 'Geologie: gebrochene Umrisse statt gleichförmiger Schichtstapel',
  'reference': 'Rostgrenze-Cutaway, Freihafen und taktische Gesamtkarte',
  'reference_ids': ['ref_rostgrenze', 'ref_freihafen', 'ref_tactical'],
  'status': 'pass03_native_candidate_captured_visual_acceptance_open',
  'gap': 'Pass 02 zeigt deutliche Schichtklippen, aber viele Felskörper bleiben regelmäßig und '
         'wiederholen ähnliche horizontale Stufen.',
  'change': 'Unterschiedliche Lagenstärken, versetzte Felskonturen, gebrochene Flanken und ruhige '
            'Schuttanschlüsse zu zusammengehörigen Körpern formen. Wenige große Massen führen die '
            'Komposition; keine bloße zufällige Kleinteilverteilung.',
  'check': 'Feste Übersicht und Geländeansicht vor/nach dem Pass vergleichen. Große Umrisse und Lagen '
           'müssen natürlich variieren; sichtbare Felsen dürfen nicht auf weiterhin begehbaren Feldern '
           'stehen.'},
 {'title': 'Rostgrenze: lesbare Cutaway-Raumgruppen',
  'reference': 'Rostgrenze-Cutaway, besonders Unterkunft, Lager, Werkstatt und Aufenthalt',
  'reference_ids': ['ref_rostgrenze', 'outpost'],
  'status': 'pass03_native_candidate_captured_visual_acceptance_open',
  'gap': 'Die erste Gebäudefamilie zeigt einzelne äußere Hüllen. Sichtbare verbundene Funktionsräume der '
         'Rostgrenze fehlen im Pass-02-Ausgangsstand.',
  'change': 'Originale Kenney-Space-Station-Wände, Betten, Displays, Computer und Container tatsächlich '
            'importieren und mit eigener editierbarer Schnittbasis, Außenkante, Eingang und '
            'Funktionsgruppen verbinden. Anpassungen, Quellhashes und Lizenzen im Modellmanifest '
            'belegen. Möbel und Arbeitsausstattung gruppieren; keine Bettenzahl oder Bildbeschriftung '
            'als Gameplay-Regel übernehmen.',
  'check': 'Nahansicht, feste Übersicht und Spielabstand gegen dieselbe Rostgrenze-Vorlage prüfen. '
           'Raumgruppen müssen ohne Text erkennbar sein; der Cutaway ist eine Darstellung, kein '
           'begehbarer simulierter Innenraum.'},
 {'title': 'Freihafen: Hallenensemble und Vorplatz verbinden',
  'reference': 'Freihafen / Distribution Center: große Hallenrahmen, Nebenmodul, Container und '
               'Plattformen',
  'reference_ids': ['ref_freihafen', 'ref_tactical'],
  'status': 'pass03_native_candidate_captured_visual_acceptance_open',
  'gap': 'Pass 02 hat eine kleine offene Werkstatt und wenige verbundene Einzelformen. Die größere '
         'Hallenhierarchie und der zusammengehörige Arbeitsvorplatz fehlen.',
  'change': 'Originale Kenney-Factory-Torrahmen, Kran- und Tankgeometrie mit eigener creme-oranger '
            'Hallenkonstruktion verbinden. Ruhige Dachgruppen und geordnete Arbeitsbuchten mit Vorplatz '
            'und Wegen zu einer Komposition zusammenfassen. Originalquellen, Übernahme und Anpassung '
            'nachvollziehbar belegen; keine Warenwirtschaft oder Fahrzeugmechanik aus dem Bild ableiten.',
  'check': 'Feste Werkstatt-, Übersichts- und Geländeansicht vergleichen. Hauptbau und Nebenformen '
           'müssen in kleiner Ansicht unterscheidbar bleiben; keine Warenwirtschaft oder '
           'Fahrzeugmechanik aus dem Bild ableiten.'},
 {'title': 'Komposition: neue Modelle mit Gelände und Wegen abstimmen',
  'reference': 'Taktische Gesamtkarte, Rostgrenze-Wege und Freihafen-Vorplatz',
  'reference_ids': ['ref_tactical', 'ref_rostgrenze', 'ref_freihafen'],
  'status': 'pass03_native_candidate_captured_visual_acceptance_open',
  'gap': 'Der vorhandene Pass-02-Ausschnitt ist noch weit offener und regelmäßiger als die vollständigen '
         'Konzepte. Neue größere Modelle können Figuren, Wege oder Blickbeziehungen verdecken.',
  'change': 'Modellmassen, Felsrand, offene Bewegungsräume und Arbeitsflächen gemeinsam setzen. '
            'Farbflächen und gezielte Requisitengruppen führen die Lesbarkeit; Hex bleibt der gemeinsame '
            'Logik-/Auswahlvertrag.',
  'check': 'Alle fünf unveränderten Kameras und Raster an/aus beurteilen. Renderer, Kamera, Licht und '
           'Modellhashes dokumentieren; Footprints, Picking und tatsächliche Crewbewegung getrennt '
           'prüfen.'},
 {'title': 'Citizens: vorhandene Kenney-Ausrüstung erhalten und maßstäblich zeigen',
  'reference': 'Beibehaltene Pass-02-Ausrüstung auf Kenney; kleine Figuren in Rostgrenze und Gesamtkarte',
  'reference_ids': ['people', 'ref_rostgrenze', 'ref_tactical'],
  'status': 'retained_from_pass02_no_new_character_revision',
  'gap': 'Die vier Figuren sind vorhandene Ausrüstungskandidaten. Größere Hallen und Cutaway-Wände '
         'können ihre Silhouetten oder den menschlichen Maßstab verdecken.',
  'change': 'Die bestehenden Körper, Skins, Rüstungsteile und Idle-/Walk-Clips beibehalten. Aufstellung, '
            'Türen und Arbeitsflächen so abstimmen, dass die Figuren im Spielabstand verständlich '
            'bleiben. Keine neue Figurenvariante als Teil dieses Passes behaupten.',
  'check': 'Feste Crewkamera, Übersicht und Walk-Aufnahme prüfen. Vorher-/Nachher-Modellhashes '
           'abgleichen und beibehaltene Ausrüstung von einer neuen Figurenfreigabe unterscheiden.'},
 {'title': 'Cutlass und Buccaneer bleiben separate Modellarbeit',
  'reference': 'Aktuelle Bildpaare Cutlass 08/09 und Buccaneer 13/11',
  'reference_ids': ['cutlass_front', 'cutlass_rear', 'buccaneer_front', 'buccaneer_rear'],
  'status': 'future_model_revision_not_part_of_pass03',
  'gap': 'Die älteren hochauflösenden Schiffsmaterialproben behalten bekannte Flächenfehler und sind '
         'keine einsatzbereiten vereinfachten Spielmodelle.',
  'change': 'Vereinfachte echte Spielgeometrie in einem eigenen Arbeitspaket nach denselben Bildpaaren '
            'aufbauen. Der Pass-03-Gelände-/Strukturumbau übernimmt keine alten Materialproben als '
            'aktive Schiffsmodelle.',
  'check': 'Später Vorder-/Rückansicht und Spielabstand sowie Geometrie, Normalen und nativen Import '
           'gesondert prüfen.'}]


def render_next_art_steps(after_ready=False):
    cards = []
    for i, item in enumerate(STEPS, 1):
        status_label = "aus Pass 02 beibehalten" if i == 5 else "separate Modellarbeit offen" if i == 6 else "native Gegenprobe vorhanden · Urteil offen" if after_ready else "Pass 03 in Arbeit · Aufnahme ausstehend"
        cards.append(
            '<article class="next-art-card">'
            f'<div class="eyebrow">Schritt {i:02d} · {status_label}</div>'
            f'<h3>{escape(item["title"])}</h3>'
            f'<p class="next-reference">Ziel: {escape(item["reference"])}</p>'
            f'<p><strong>Ausgangsbefund aus Pass 02.</strong> {escape(item["gap"])}</p>'
            f'<p><strong>Ziel des Grafikschritts.</strong> {escape(item["change"])}</p>'
            f'<p><strong>Vergleich danach.</strong> {escape(item["check"])}</p>'
            '</article>'
        )
    return (
        '<section id="naechste-grafikschritte" class="section next-art-section" aria-labelledby="next-art-heading">'
        '<div class="section-head"><div><div class="eyebrow">Nächste Grafikschritte / konkret am Bild</div>'
        '<h2 id="next-art-heading">Woran Pass 03 gemessen wird.</h2></div>'
        '<p>Die vollständigen Hauptvorlagen bestimmen die Ziele. Ausgangsbefund, Arbeitsziel und Bildprüfung '
        'bleiben getrennt; der native Vergleich oben zeigt den tatsächlich aufgenommenen Stand.</p></div>'
        '<p class="next-art-intro">Organischere Felsen, die grafische Rostgrenze-Raumgruppe und das kleine Freihafen-Hallenensemble sind die Ziele dieses Passes. '
        'Die Kenney-Ausrüstung aus Pass 02 bleibt bestehen. Der neue Bericht verwendet eigene leere Notizen; frühere Modellurteile sind keine neue Freigabe.</p>'
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
