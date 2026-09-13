"""Build the dated N3 game plan as standalone HTML with available real captures.

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
    ('n3-main-menu.png', 'Das wiederverwendete Menümotiv mit der sitzenden Frau; Karriere und Koop im neuen Menü.'),
    ('rooms-orbit/base.png', 'Die Heimat aus vier Räumen. Die beiden freien Andockplätze sind bisher vorbereitet, noch nicht bebaubar.'),
    ('ground-world/armor.png', 'Ida mit sichtbarem Schutzsatz aus Brust- und Schulterteilen; Jaro trägt die einfache Ausgangsausrüstung.'),
    ('n3-armor-profile.png', 'Die Crewakte nennt aktuelle Fähigkeiten, Gesundheit und echte Ausrüstung. Erfahrungszuwachs folgt später.'),
    ('ground-world/rust-mining.png', 'Im großen Suchgebiet: Erz entdecken, landen, abbauen und mit begrenztem Frachtraum heimbringen.'),
    ('ground-world/rust-wreck.png', 'Ein zusätzliches Schiffwrack liefert endliche Schiffslegierung. Die Crew arbeitet am Fundort.'),
    ('ground-world/geier.png', 'Geier: das in Blender vereinfachte Mietschiff mit zwei Bergungsarmen und größerem Frachtraum.'),
    ('ground-world/bunker-surface.png', 'Bunkeroberfläche mit Flak, einfachem Wächter, Lastenaufzug und durchsichtiger Vorderwand.'),
    ('ground-world/bunker-depths.png', 'Das Untergeschoss wird separat geladen. Die erste Fassung hat Zentralgang, Lager und Sicherheitsraum.'),
    ('ground-world/distribution.png', 'Das Verteilzentrum: mehrere Hallen und ein Ladehof als erste spielbare Struktur für Handel und Kampf.'),
    ('ground-world/tradepost.png', 'Der kleine Handelsposten auf einer eigenen Karte. Ein weiterer Materialfund liegt abseits im Gelände.'),
    ('rooms-orbit/space-contact.png', 'Der vorhandene zufällige Raumkontakt: Freibeuter und Entersäbel auf einer festen Flugebene.'),
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
