"""Build the dated N4 game plan as standalone HTML with available real captures.

The tracked template contains no local ship images or models. A fresh clone can
generate the text report; captures from the documented window probes enrich it.
"""
from pathlib import Path
from html import escape
from html.parser import HTMLParser
import base64
import struct

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output"
SHOTS = [
    ('n3-main-menu.png', 'Das erhaltene Hauptmenümotiv mit der sitzenden Frau; dieses Motiv bleibt gegenüber N3 unverändert.'),
    ('n4-base.png', 'Aktuelle Heimat mit vier getrennten Räumen, sechs Betten und durchsichtigen Frontwänden. Ausbauplätze sind vorbereitet, noch nicht bebaubar.'),
    ('n4-workshop.png', 'Die Werkstatt zeigt passende Arbeit, Zutaten und die tatsächlich eingesetzte Person. Im vollständigen Spielweg entsteht ein Rucksack aus Startmaterial.'),
    ('n4-crew-dossier.png', 'Das echte Dossier: sichtbare Figur, fünf Slots und getrennte Bestände. Dieser Rucksack wurde in der Mausprobe regulär hergestellt und ausgerüstet.'),
    ('n4-world/crew-equipment.png', 'Darstellungsprobe der riggebundenen Rüstung, des Rucksacks und Handwerkzeugs; Gegenstände für diese Bildprobe gezielt bereitgestellt, nicht als erspielter Fortschritt ausgegeben.'),
    ('n4-world/entersaebel.png', 'Die überarbeitete Entersäbel: vereinfachte Kontur und Fahrwerk. Originaldatei erhalten; Umbau lokal in Blender.'),
    ('n4-manual-seats.png', 'Manuell gewählte Plätze haben Vorrang: Hier pilotiert Jaro, während Ida den freien Turm übernimmt. Beide bleiben bis zum Start an Bord.'),
    ('n4-travel-chart.png', 'Die echte Reisekarte mit benannten Orten, Gebietsgrößen und vorläufigem Begegnungsrisiko.'),
    ('n4-world/orbit.png', 'Der Orbit ist eine eigene geladene Raumkarte. Von hier wird der Zielanflug angefordert.'),
    ('n4-rust-arrival.png', 'Ankunft im Suchgebiet: Das Schiff schwebt am Rand. Lokaler Flug, Landung und Aussteigen bleiben eigene Befehle.'),
    ('n4-satellite.png', 'Die erste Blackbox wurde im vollständigen Produktweg geborgen. Weitere Verwertung benötigt passende Ausrüstung.'),
    ('n4-world/bunker_surface.png', 'Bunkeroberfläche mit geschlossener Hülle, erkennbarer Eingangsöffnung, Flak und Lastenaufzug.'),
    ('n4-world/distribution.png', 'Verteilzentrum auf einer vergrößerten Einzelkarte: Hallen, Ladehof und getrennte Funktionsbereiche.'),
    ('n4-world/tradepost.png', 'Eigener kleiner Handelsposten mit Modulen und Versorgung; die große Umgebung enthält einen weiteren Fund.'),
    ('n4-market.png', 'Ankunft, Landung, Aussteigen und regulärer Einkauf von Multi-Tool und Salvage-Aufsatz im Freihafen Meridian.'),
    ('n4-world/space-contact.png', 'Separat geladener Piratenkontakt, über eine tatsächliche Reise ausgelöst. Der Turm verwendet den besetzten Schützenplatz.'),
]


class ValidatePage(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids = set()
        self.refs = []
        self.images = 0

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if "id" in a:
            assert a["id"] not in self.ids, f"Duplicate ID: {a['id']}"
            self.ids.add(a["id"])
        if tag == "a" and a.get("href", "").startswith("#"):
            self.refs.append(a["href"][1:])
        if tag == "img":
            assert a.get("alt") and a.get("src", "").startswith("data:image/png;base64,")
            self.images += 1


def main():
    page = (ROOT / "docs/reports/ROSTGRENZE_SPIELPLAN_TEMPLATE.html").read_text(encoding="utf-8")
    assert page.count("GAME_IMAGES") == 1
    figures = []
    for name, caption in SHOTS:
        source = OUT / name
        if not source.is_file():
            figures.append(f'<p class="note">{escape(caption)} Lokaler Bildbeleg nicht vorhanden; siehe den veröffentlichten Gesamtplan.</p>')
            continue
        raw = source.read_bytes()
        assert raw[:8] == b"\x89PNG\r\n\x1a\n", source
        width, height = struct.unpack(">II", raw[16:24])
        encoded = base64.b64encode(raw).decode("ascii")
        figures.append(f'<figure><img src="data:image/png;base64,{encoded}" alt="{escape(caption)}" width="{width}" height="{height}" loading="lazy"><figcaption>{escape(caption)}</figcaption></figure>')
    page = page.replace("GAME_IMAGES", "".join(figures))
    check = ValidatePage()
    check.feed(page)
    assert all(ref in check.ids for ref in check.refs if ref), "Broken fragment link"
    assert 'name="viewport"' in page and '@media(max-width:680px)' in page
    OUT.mkdir(exist_ok=True)
    for name in ("ROSTGRENZE_SPIELPLAN.html", "ROSTGRENZE_SPIELSTAND.html"):
        target = OUT / name
        target.write_text(page, encoding="utf-8")
        print(target)
    print(f"REPORT_OK: {check.images} actual captures embedded; IDs, fragments and mobile viewport checked.")


if __name__ == "__main__":
    main()
