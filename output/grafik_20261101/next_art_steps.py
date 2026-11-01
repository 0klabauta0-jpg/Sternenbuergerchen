"""Visible, reference-linked next art steps; proposals, not completed changes."""
from html import escape

STEPS = [
    {
        "title": "Gelände: zusammenhängende Landschaft statt flacher Platten",
        "reference": "Rostwelt-Landschaft (01) und Außenposten (03)",
        "gap": "Der native Boden ist noch großflächig leer. Wege und Höhenkanten zeichnen die Hexgrenzen sehr deutlich nach; die Vorlagen zeigen geschichtete Felsen, natürliche Übergänge und räumliche Tiefe.",
        "change": "Zuerst breite Sand-/Farbzonen und weich auslaufende Wegspuren über Zellgrenzen legen. Danach zusammenhängende Plateau- und Klippenformen, wenige große Felsgruppen und eine hellere, kühlere Ferne aufbauen. Das Hexraster bleibt für Logik und Auswahl erhalten; die Oberfläche darf natürlicher wirken.",
        "check": "Gleiche Übersichtskamera mit Raster an/aus vergleichen: Weg und Plateau müssen ohne Raster lesbar sein; sichtbare Hindernisse müssen zu belegten Zellen passen.",
    },
    {
        "title": "Basis: die drei Gebäude näher an die Silhouetten bringen",
        "reference": "Außenposten (03), besonders Dach, Eingang und offene Werkstatt",
        "gap": "Creme/Petrol und die Gebäudetypen sind erkennbar. Dächer, Rahmen und Sockel wirken noch geradliniger und flächiger als im Zielbild; die Werkstatt ist deutlich leerer.",
        "change": "Die breiten Dachschrägen, abgerundeten Ecken, Türrahmen und Sockel gezielt nacharbeiten. Wenige große Funktionsdetails ergänzen: Werkbank, Kran, seitliche Leitungsgruppe und klarer Tankanschluss. Farbflächen und Proportionen haben Vorrang vor zusätzlichen Schrauben oder Paneelfugen.",
        "check": "Je Gebäude Front-, Rück- und Spielansicht neben 03 prüfen: Silhouette und Funktion sollen schon klein erkennbar sein; Menschen/Türen und Handkontakte müssen stimmen.",
    },
    {
        "title": "Umgebung: ausgewählte Wimmelbild-Gruppen ergänzen",
        "reference": "Fels-/Pflanzengruppen und Arbeitsbereiche in 01 und 03",
        "gap": "Zwischen den Gebäuden fehlen noch die kleinen zusammenhängenden Szenen der Vorlagen. Das lässt die Basis trotz passender Grundfarben unbelebt wirken.",
        "change": "Eine kleine wiederverwendbare Familie aus Felsen, trockenem Busch, Agave, Kisten und Werkzeugwagen bauen. In Gruppen an Gebäudeecken, Klippen und Arbeitsplätzen setzen; Wege und wichtige Silhouetten frei lassen. Klare große Formen, wenig Oberflächendetail.",
        "check": "In Spielgröße prüfen, ob jede Gruppe als Ganzes lesbar bleibt. Begehbare Flächen und Sichtlinien prüfen; reine Dekoration erhält keine verdeckte Gameplay-Wirkung.",
    },
    {
        "title": "Licht und Materialien: mehr gemalte Farbigkeit",
        "reference": "Warme Sonnenflächen, kühle Schatten und Luftperspektive in 01/03",
        "gap": "Matte Flächen und echte Schatten sind vorhanden. Der Ausschnitt wirkt noch stärker wie sauberes flaches 3D als wie die farbig abgestufte Illustration.",
        "change": "Nach den großen Formen Licht und Materialfarben gemeinsam abstimmen: warmes Creme statt grauer Fassaden, gedämpftes Petrol, kühlere Schatten und dezente Kontaktverdunklung. Große ruhige Farbvariationen verwenden; Glanz und winzige Schmutzdetails sparsam halten.",
        "check": "Gleiche Kameras mit einem festen Beleuchtungszustand vergleichen. Türen, Gesichter und Dachkanten müssen in Sonne und Schatten lesbar bleiben; Schwarzflächen und ausgebrannte Kanten vermeiden.",
    },
    {
        "title": "Citizens: Kenney als vorläufige Basis weiterentwickeln",
        "reference": "Normale Kenney-Astronauten + Personenstudie (02) + lokale Star-Citizen-Rüstungsbilder",
        "gap": "Die ursprünglichen Kenney-Figuren gefallen besser als der verworfene Eigenbau. Sie sind vorläufig gesetzt; eigene Rüstung, Ausrüstung und mehr Variation im Aussehen fehlen noch.",
        "change": "Auf der vorhandenen Grundfigur modulare Brust-, Schulter- und Knieschützer, Helme/Visiere, Stiefel, Gürtel und Rucksäcke ausprobieren. Zuerst Arbeitsanzug, Pilot und gepanzerte Variante in wenigen großen Farbflächen. Danach Haare, Gesichter und einzelne Silhouetten behutsam variieren; den freundlichen Kenney-Charakter als Ausgangspunkt erhalten.",
        "check": "Original und Umbau nebeneinander in gleicher Kamera zeigen. Vorder-/Rückansicht, Idle und Walk sowie angewinkelte Arme auf Durchdringungen prüfen; die Figuren müssen auch im Spielabstand unterscheidbar bleiben.",
    },
    {
        "title": "Cutlass und Buccaneer: vereinfachte echte Spielmodelle",
        "reference": "Aktuelle Bildpaare: Cutlass 08/09, Buccaneer 13/11; lokale/RSI-Formreferenzen",
        "gap": "Die vereinfachten 2D-Ansichten sind vorhanden. Die alten hochauflösenden Materialproben behalten zu viel Geometrie und haben bekannte Flächenfehler; sie erfüllen das Ziel noch nicht.",
        "change": "Neue einfache Spielgeometrie nach den aktuellen Ansichten aufbauen: bei der Cutlass Frachtrumpf, Kanzel, Rampe und getrennte Hecktriebwerke; bei der Buccaneer schmale Kanzel, große Triebwerkspods und kurze Flügel. Kleine Paneele, Waffenanbauten und technische Fugen stark reduzieren. Keine reine Umfärbung der fehlerhaften Rohmodelle.",
        "check": "Vorne/hinten und in Spielgröße gegen dasselbe Bildpaar vergleichen. Silhouette zuerst, dann Farbflächen; Normalen, Rückseiten, Maßstab, Pivot und nativen Godot-Import gesondert prüfen.",
    },
]


def render_next_art_steps():
    cards = []
    for i, item in enumerate(STEPS, 1):
        cards.append(
            '<article class="next-art-card">'
            f'<div class="eyebrow">Schritt {i:02d} · noch offen</div>'
            f'<h3>{escape(item["title"])}</h3>'
            f'<p class="next-reference">Ziel: {escape(item["reference"])}</p>'
            f'<p><strong>Sichtbarer Abstand.</strong> {escape(item["gap"])}</p>'
            f'<p><strong>Was ich ändern würde.</strong> {escape(item["change"])}</p>'
            f'<p><strong>Vergleich danach.</strong> {escape(item["check"])}</p>'
            '</article>'
        )
    return (
        '<section id="naechste-grafikschritte" class="section next-art-section" aria-labelledby="next-art-heading">'
        '<div class="section-head"><div><div class="eyebrow">Nächste Grafikschritte / konkret am Bild</div>'
        '<h2 id="next-art-heading">So würde ich näher an die Vorlagen kommen.</h2></div>'
        '<p>Vorgeschlagene Reihenfolge für den nächsten Durchgang. Diese Änderungen sind noch offen; '
        'die Godot-Bilder oben zeigen den tatsächlich erreichten Stand.</p></div>'
        '<p class="next-art-intro">Zuerst Gelände, Gebäudekörper und Bildkomposition angleichen; '
        'danach Ausstattung, Licht und Figurenvarianten. Die normalen Kenney-Astronauten sind '
        '<strong>vorläufige Grundlage</strong>: Rüstung und Aussehen sollen später gezielt weiterentwickelt werden. '
        'Die vereinfachten Schiffe behalten wenige gut lesbare Formen.</p>'
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
