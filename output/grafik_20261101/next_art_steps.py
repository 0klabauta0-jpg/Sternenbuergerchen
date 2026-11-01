"""Pass-02 art targets, their starting gaps and explicit native review criteria."""
from html import escape

STEPS = [
    {
        "title": "Gelände: zusammenhängende Landschaft statt flacher Platten",
        "reference": "Rostgrenze-Cutaway + taktische Rostwelt-Gesamtkarte; ergänzend Landschaft 01",
        "reference_ids": ["ref_rostgrenze", "ref_tactical", "terrain"],
        "status": "pass02_in_progress_capture_pending",
        "gap": "Der native Boden ist noch großflächig leer. Wege und Höhenkanten zeichnen die Hexgrenzen sehr deutlich nach; die Vorlagen zeigen geschichtete Felsen, natürliche Übergänge und räumliche Tiefe.",
        "change": "Den roten Schichtstein der vollständigen Vorlagen in breite unregelmäßige Klippen, gestaffelte Felstürme und wenige große Steingruppen übersetzen. Offene rostrote Bodenflächen ruhig variieren und natürliche Übergänge statt wiederholter Randplatten bilden. Das Hexraster bleibt für Logik und Auswahl erhalten; die im Kartenbild sichtbaren Quadratfelder werden nicht übernommen.",
        "check": "Gleiche Übersichtskamera mit Raster an/aus vergleichen: Weg und Plateau müssen ohne Raster lesbar sein; sichtbare Hindernisse müssen zu belegten Zellen passen.",
    },
    {
        "title": "Basis: die drei Gebäude näher an die Silhouetten bringen",
        "reference": "Rostgrenze-Cutaway + Freihafen / Distribution Center; ergänzend Außenposten 03",
        "reference_ids": ["ref_rostgrenze", "ref_freihafen", "outpost"],
        "status": "pass02_in_progress_capture_pending",
        "gap": "Creme/Petrol und die Gebäudetypen sind erkennbar. Dächer, Rahmen und Sockel wirken noch geradliniger und flächiger als im Zielbild; die Werkstatt ist deutlich leerer.",
        "change": "Creme-orange Außenrahmen, breite Sockel, verständliche Eingänge und eine offene, ausgestattete Werkstatt zusammenführen. Die großen Dach- und Raumgruppen aus den Hauptbildern über wenige kräftige Bauteile aufnehmen. Werkbank, Kran und Tankanschluss als Funktionsgruppen setzen; keine Bettenzahlen oder Raumtexte als neue Simulation interpretieren.",
        "check": "Front-, Rück- und feste Werkstattkamera gegen Rostgrenze/Freihafen und 03 prüfen. Silhouette, Türmaß und große Funktionsgruppen müssen schon im Spielabstand lesbar sein; native Import- und Kontaktprüfung separat belegen.",
    },
    {
        "title": "Verbindungen: eine gebaute Basis statt einzelner Objekte",
        "reference": "Wege, Pad und Raumgruppen der Rostgrenze; Plattformen und Arbeitsbuchten im Freihafen; Gesamtkarte",
        "reference_ids": ["ref_rostgrenze", "ref_freihafen", "ref_tactical"],
        "status": "pass02_in_progress_capture_pending",
        "gap": "Zwischen den Gebäuden fehlen noch die kleinen zusammenhängenden Szenen der Vorlagen. Das lässt die Basis trotz passender Grundfarben unbelebt wirken.",
        "change": "Gebäude, Arbeitsflächen und Landepad durch klare gebaute Verbindungen zusammenfassen. Wenige Container-/Werkzeuggruppen an sinnvolle Arbeitsorte stellen, trockene Vegetation und Felsgruppen am Rand bündeln. Die Raumkomposition aus der Gesamtkarte führen lassen; weder eine vollständige Warenwirtschaft noch eine komplette Innenraumsimulation ergänzen.",
        "check": "Dieselbe Übersicht vor/nach dem Pass und mit/ohne Hexraster zeigen. Wege müssen ohne Raster lesbar bleiben. Keine blickdichten Hindernisse auf unverändert begehbaren Feldern; Dekoration erzeugt keine versteckte Gameplay-Wirkung.",
    },
    {
        "title": "Licht und Materialien: mehr gemalte Farbigkeit",
        "reference": "Warme rote Felsen und creme-orange Module in Rostgrenze/Freihafen; weite Staffelung der Gesamtkarte",
        "reference_ids": ["ref_rostgrenze", "ref_freihafen", "ref_tactical"],
        "status": "pass02_in_progress_capture_pending",
        "gap": "Matte Flächen und echte Schatten sind vorhanden. Der Ausschnitt wirkt noch stärker wie sauberes flaches 3D als wie die farbig abgestufte Illustration.",
        "change": "Nach den großen Formen warme Rostflächen, helle creme-orange Architektur, kühle graue Bauflächen und dezente Kontaktverdunklung abstimmen. Das frühere Petrol ist ergänzend, keine unveränderliche Endpalette. Glanz und kleinteiligen Schmutz sparsam halten; große Schatten lesbar staffeln.",
        "check": "Feste Kameras vergleichen und Änderungen der Lichtparameter ausdrücklich dokumentieren. Türen, Gesichter und Dachkanten müssen in Sonne und Schatten lesbar bleiben; Schwarzflächen und ausgebrannte Kanten vermeiden.",
    },
    {
        "title": "Citizens: Kenney als vorläufige Basis weiterentwickeln",
        "reference": "Originale Kenney-Astronauten als Grundfigur; kleine Figuren in Rostgrenze/Gesamtkarte; Personenstudie 02 und lokale Rüstungsbilder",
        "reference_ids": ["ref_rostgrenze", "ref_tactical", "people", "ref_armor"],
        "status": "pass02_in_progress_capture_pending",
        "gap": "Die ursprünglichen Kenney-Figuren gefallen besser als der verworfene Eigenbau. Sie sind vorläufig gesetzt; eigene Rüstung, Ausrüstung und mehr Variation im Aussehen fehlen noch.",
        "change": "Auf der vorhandenen Grundfigur wenige große Rüstungs-/Ausrüstungsteile als separate Kandidaten erproben, etwa Brustschutz, Schulterteile und Rucksack. Die ursprünglichen Körper und Skins als unveränderten Vergleich erhalten; keine erneute fremde Körperform erzwingen. Die Grundfigur bleibt Ausgangspunkt für spätere gezielte Variation.",
        "check": "Original und Umbau nebeneinander in gleicher Kamera zeigen. Vorder-/Rückansicht, Idle und Walk sowie angewinkelte Arme auf Durchdringungen prüfen; die Figuren müssen auch im Spielabstand unterscheidbar bleiben.",
    },
    {
        "title": "Cutlass und Buccaneer: vereinfachte echte Spielmodelle",
        "reference": "Aktuelle Bildpaare: Cutlass 08/09, Buccaneer 13/11; lokale/RSI-Formreferenzen",
        "reference_ids": ["cutlass_front", "cutlass_rear", "buccaneer_front", "buccaneer_rear"],
        "status": "future_model_revision_not_part_of_pass02",
        "gap": "Die vereinfachten 2D-Ansichten sind vorhanden. Die alten hochauflösenden Materialproben behalten zu viel Geometrie und haben bekannte Flächenfehler; sie erfüllen das Ziel noch nicht.",
        "change": "Neue einfache Spielgeometrie nach den aktuellen Ansichten aufbauen: bei der Cutlass Frachtrumpf, Kanzel, Rampe und getrennte Hecktriebwerke; bei der Buccaneer schmale Kanzel, große Triebwerkspods und kurze Flügel. Kleine Paneele, Waffenanbauten und technische Fugen stark reduzieren. Keine reine Umfärbung der fehlerhaften Rohmodelle.",
        "check": "Vorne/hinten und in Spielgröße gegen dasselbe Bildpaar vergleichen. Silhouette zuerst, dann Farbflächen; Normalen, Rückseiten, Maßstab, Pivot und nativen Godot-Import gesondert prüfen.",
    },
]


def render_next_art_steps(after_ready=False):
    cards = []
    for i, item in enumerate(STEPS, 1):
        cards.append(
            '<article class="next-art-card">'
            f'<div class="eyebrow">Schritt {i:02d} · {"separate Modellarbeit offen" if i == 6 else "native Gegenprobe vorhanden · Urteil offen" if after_ready else "Pass 02 in Arbeit · Aufnahme ausstehend"}</div>'
            f'<h3>{escape(item["title"])}</h3>'
            f'<p class="next-reference">Ziel: {escape(item["reference"])}</p>'
            f'<p><strong>Ausgangsbefund vor Pass 02.</strong> {escape(item["gap"])}</p>'
            f'<p><strong>Ziel des Grafikschritts.</strong> {escape(item["change"])}</p>'
            f'<p><strong>Vergleich danach.</strong> {escape(item["check"])}</p>'
            '</article>'
        )
    return (
        '<section id="naechste-grafikschritte" class="section next-art-section" aria-labelledby="next-art-heading">'
        '<div class="section-head"><div><div class="eyebrow">Nächste Grafikschritte / konkret am Bild</div>'
        '<h2 id="next-art-heading">Woran der Grafikpass gemessen wird.</h2></div>'
        '<p>Die vollständigen Hauptvorlagen bestimmen die Ziele. Ausgangsbefund, Arbeitsziel und Bildprüfung '
        'bleiben getrennt; der native Vergleich oben zeigt den tatsächlich aufgenommenen Stand.</p></div>'
        '<p class="next-art-intro">Zuerst Gelände, Gebäudekörper und Bildkomposition angleichen; '
        'danach Ausstattung, Licht und Figurenvarianten. Rostgrenze, Freihafen und Gesamtkarte ergänzen '
        'die bisherigen 01/02/03-Vorlagen. Die normalen Kenney-Astronauten sind '
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
