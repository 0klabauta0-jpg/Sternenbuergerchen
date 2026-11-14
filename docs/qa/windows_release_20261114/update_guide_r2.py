"""Apply only after the R2 package has passed its package smoke."""
import argparse, re
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--build", required=True)
parser.add_argument("--release-url", required=True)
args = parser.parse_args()
assert re.fullmatch(r"[0-9a-f]{40}", args.build)
assert args.release_url.startswith("https://github.com/0klabauta0-jpg/Sternenbuergerchen/releases/tag/")
root = Path(__file__).resolve().parents[3]
path = root / "docs/player_guide/index.html"
text = path.read_text(encoding="utf8")
replacements = {
    "WINDOWS PLAYTEST<br>14.11.2026": "WINDOWS PLAYTEST R2<br>14.11.2026",
    "<code>a377c7346</code>. Neuere Karten- und Frachtänderungen folgen separat.": "<code>" + args.build[:9] + "</code>. Mit Karten-, Fracht- und Servicerevision.",
    "https://github.com/0klabauta0-jpg/Sternenbuergerchen/releases/tag/playtest-2026-11-14": args.release_url,
    "<p>Die im Anschluss an diesen Build gewünschte Bodensiedlung mit ausgebautem Frachtaufzug und neuen Pad-/Mechanikerdiensten ist noch nicht Bestandteil dieser EXE.</p>": "<p>Am Handelsposten meldest du dich beim Händler an und stellst dein Schiff auf ein freigegebenes Servicepad. In der Versorgung wählst du das Schiff. Gekaufte Ware landet im örtlichen Frachtaufzug. Mit <strong>Frachtaufzug → Schiff</strong> lädst du sie ein; <strong>Schiff → Frachtaufzug</strong> lagert Ware aus. Verkaufbare Rohstoffe können auch aus diesem Lager verkauft werden. Der Frachtauftrag läuft über die Zeit; prüfe den angezeigten Fortschritt.</p><p><strong>Auftanken und Reparaturservice</strong> funktionieren nur an einem Ort, der diese Dienste anbietet und dein Schiff zulässt. Eine freie Landefläche allein gibt keinen Service. Die Reparatur stellt den Rumpf wieder her; beachte einen gegebenenfalls angezeigten Reparaturtimer. An einem anderen Ort oder mit einem fremden Teamschiff wird der Auftrag abgewiesen.</p>",
    "Die in diesem Build sichtbaren großen Felsmodelle sind allerdings noch nicht automatisch landbare Oberflächen; diese Überarbeitung folgt separat.": "Ausgewiesene flache Felskappen besitzen jetzt echte erhöhte Hexoberflächen. Die neue breite Mesa bietet Platz für eine geprüfte Buccaneer-Landung. Das bedeutet nicht, dass jedes größere Schiff auf jede kleine Kuppe passt.",
    "Diese Anleitung beschreibt den Windows-Playtest vom 14.11.2026. Die danach beauftragte Karten-, Felsoberflächen- und Frachtaufzugrevision ist hier noch keine zugesagte Funktion des Pakets.": "Diese Anleitung beschreibt den Windows-Playtest R2 vom 14.11.2026. Die erste EXE bleibt als ältere Version erhalten; Karten-, Fracht- und Serviceänderungen benötigen R2. Ein vollständiger Kampagnensieg und eine allgemeine WAN-Abnahme sind weiterhin nicht bestätigt.",
}
for old, new in replacements.items():
    assert old in text, old
    text = text.replace(old, new)
path.write_text(text, encoding="utf8", newline="\n")
notes = root / "docs/player_guide/SOURCE_NOTES.md"
existing = notes.read_text(encoding="utf8")
notes.write_text("# R2-Aktualisierung 14.11.2026\n\nAktueller Exportcommit: `" + args.build + "`. R2-Paket erst nach bestandenem\nPaketstart verlinkt. Karten-/Serviceverhalten durch map_services_20261114-Nachweise\nbelegt. Ergänzte Quellen: ground_service_access, field_landing_contract,\nSingleplayerRuntimeAdapter/SupplyState, SpaceCombatState und ServicesPresenter.\nDie folgende Erstfassung dokumentiert die Herkunft der unveränderten Kampf-\nund Bedienkapitel; ihre damalige Abgrenzung ist historisch.\n\n" + existing, encoding="utf8", newline="\n")
print("Guide now targets verified R2 build " + args.build)
