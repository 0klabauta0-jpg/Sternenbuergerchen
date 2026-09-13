"""Build the dated N5 game plan as standalone HTML with available real captures.

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
    ('n5-world/base-details.png', 'Aktuelle N5-Basis mit getrennten Räumen, Satellitenschüssel und Kenney-Versorgungsmodulen.'),
    ('n5-world/terraced-canyon.png', 'Breite Felsstufen und eine gewundene Schlucht in der Heimatkarte. Der Bodenweg ist begehbar; die Terrassen sind Hindernisse.'),
    ('n5-world/travel-chart.png', 'Die echte native Reisekarte: neun Ziele, Bunkerstufen, Ortsgrößen, Risiken und die drei Handelsstrecken.'),
    ('n5-world/entersaebel.png', 'Die neue lokale Blender-Entersäbel mit achteckigem Turm und vereinfachter Silhouette.'),
    ('n5-world/bunker_surface.png', 'Karst: leichte Bunkeroberfläche, echte Reiseankunft.'),
    ('n5-world/bunker_medium.png', 'Kluft: mittlere Bunkerbesatzung und Versorgung.'),
    ('n5-world/bunker_hard.png', 'Bastion: schwere Oberfläche mit verstärkter Besatzung.'),
    ('n5-world/bunker_hard_depths-fixture.png', 'Die größere unterirdische Bastion mit unterteilten Hallen. Diese Aufnahme ist eine Darstellungsprobe; der separate Kerntest prüft den echten Aufzug.'),
    ('n5-world/distribution_friendly.png', 'Freihafen: freundliches Verteilzentrum und regulärer Handel.'),
    ('n5-world/distribution.png', 'Knotenwerk: besetztes Verteilzentrum; Handel erst nach Sicherung.'),
    ('n5-world/tradepost.png', 'Staubmarkt auf seiner eigenen großen Karte.'),
    ('n5-world/market-prices.png', 'Die tatsächliche Marktoberfläche in Meridian mit regionalen Preisen.'),
    ('n5-world/orbit.png', 'Vergrößerte eigene Orbitkarte, weiterhin Flug auf einer Ebene.'),
    ('n5-world/space-contact.png', 'Tatsächlich ausgelöster Piratenkontakt auf einer eigenen Raumkarte.'),
    ('n4-crew-dossier.png', 'Das bestehende Dossier mit der weißen Helmfigur, Ausrüstungsslots und persönlichem Rucksack.'),
    ('n3-main-menu.png', 'Das erhaltene Hauptmenümotiv mit der sitzenden Frau.'),
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
