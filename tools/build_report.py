"""Build the dated N2 game plan as standalone HTML with available real captures.

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
    ("rooms-orbit/base.png", "Die neue Heimat: vier getrennte Räume, Mittelgang, zwei freie Andockflächen und das eigene Shuttle."),
    ("rooms-orbit/base-landscape.png", "Weiter herausgezoomt: ein Außenposten in einem großzügigen Rostwelt-Gebiet. Die Startkamera bleibt näher am Gebäude."),
    ("rooms-orbit/station.png", "Meridian-Freihafen: größeres Stationsdock mit Handel und Platz für weitere Ladenbereiche."),
    ("rooms-orbit/rust-radar.png", "Suchflug über die große Missionskarte: zunächst nur unbekannte Radarkontakte."),
    ("rooms-orbit/rust-discovered.png", "Satellit in der Nähe identifiziert; neben dem Fund landen und die Crew zur Bergung schicken."),
    ("rooms-orbit/space-contact.png", "Separat geladener Raumkontakt: die Entersäbel und ein schwacher Freibeuter auf einer festen Flugebene."),
    ("product-crew-sheet.png", "Erste Crewakte mit Fähigkeiten, Aufgabe und tatsächlicher Ausrüstung. Traits und Laufbahn sind weitere Entwicklung."),
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
