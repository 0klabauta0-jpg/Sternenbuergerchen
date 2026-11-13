# Revision der abgelehnten weißen Hexmodule

Der Nutzer hat am 13.11.2026 sowohl die native Station64 als auch die isolierte
Modul-/Rampen-Testszene ausdrücklich abgelehnt: dicke weiße Klumpen. Beide
angehängten Bilder sind hier unverändert als `user_rejected_*.png` erhalten.
Die entsprechenden technischen Prüfungen sind keine gestalterische Abnahme.

Die Bild-KI erhielt diese beiden tatsächlichen Ist-Bilder und die vorhandene
Rostwelt-Stilreferenz `03_taktische_rostwelt_gesamtkarte.png`. Der exakte Prompt
steht in `deck_revision_prompt.txt`, Eingaben und Prüfsummen in `sources.json`.
`deck_revision_concept.png` ist die daraus erzeugte neue Gestaltungsreferenz:
flache zusammenhängende Metallflächen, gedecktes Grau, schmale Fugen und
zurückhaltende Hexlinien statt dicker heller Einzelplatten.

Status: Der Nutzer hat auch diesen dunklen Entwurf ausdrücklich abgelehnt:
dunkelgraue Masse, unpassender Winkel, Bäume in der Wüste und fehlendes Hexgrid.
Positiv benannt wurde nur das weiße Lagerhaus mit seinem richtigen Winkel.
Die weitere Richtung sind dünne helle Auflagen, unverzerrte Wandkörper,
Wüstengestein statt Bäume und lesbares Hexgrid. Keine native Spielaufnahme.
Die Spielumsetzung wird separat mit derselben Stationskamera
gerendert. Layout, echte Terrainhöhen und autoritative Hexbelegung bleiben;
Originalmodelle werden nicht überschrieben. Die isolierte Testszene belegt nur
technische Höhen-/Modulfälle und wird nicht als fertige Spielgestaltung verkauft.

Generator: integriertes image_gen, 13.11.2026. Das Original unter
`C:/Users/bjoer/.codex/generated_images/01a1d1e5-8752-7a71-b3d1-5f6cc1ecf388/exec-2be26cd3-9edd-4787-af84-19fe6cbb0466.png`
bleibt erhalten.

## Gelände- und Klippenvorschläge
`map_detail_proposal.png`: KI-Vorschlag für freie Flächen und Hügel, auf Basis
von zwei tatsächlichen Kartenaufnahmen plus historischem HUD als Beleg belegter
Bildbereiche. Noch keine Nutzerentscheidung oder native Umsetzung.

`cliff_detail_proposal.png`: zwei Vorschläge aus tatsächlichen Hügel-/Klippen-
Aufnahmen. Links Schichtgestein, rechts kantiger Bruchstein mit sparsamem Geröll.
**Nutzerentscheidung: „wir nehmen rechts, bruchstein“.** Die rechte Hälfte ist
die freigegebene Stilrichtung. Das Bild selbst ist keine native Umsetzung;
diese wird separat bei gleicher Kamera geprüft. Terrainhöhen, Routen und
Walkability bleiben unverändert, Hexlinien liegen auf begehbaren Flächen.

Exakte Prompts und Eingabelisten stehen jeweils in den gleichnamigen
`*_prompt.txt` und `*_inputs.json`. Generator: integriertes image_gen.

## Anschließende native Kritik
`user_wall_angle_and_scatter_feedback.png` hält die konkrete Rückmeldung fest:
Mauern und Korridore sollen zur Perspektive des weißen Lagerhauses passen;
Kamera, Modellbasis und Hex-Anpassung sind gemeinsam zu prüfen. Immer sichtbares
Grid, identifizierbare Klippen/Rampen statt unklarer brauner Streifen, weniger
regelmäßige Gesteinsverteilung und eine gemeinsame Wüstenpalette auch für die
bisher weißen Steine. Der Boden soll ruhiger werden. Zusätzliche Flecken aus
der offenen Gelände-KI-Studie sind ausdrücklich nicht übernommen.
Die Auswahl rechts/Bruchstein bleibt davon unberührt.

## Freigegebener Winkel, offene Anschlüsse
`user_station_seams_corners_gate_feedback.png` dokumentiert die anschließende
native Nutzerprüfung: **Der neue Wandwinkel ist ausdrücklich richtig.** Auch
die Steinformen und die Orientierung der übrigen Objekte werden positiv benannt.
Fugen sollen bündig schließen; Eckverbinder und Türversätze sind zu korrigieren.
Vorhandene schmalere helle Mauern mit gelbem Streifen sind als Variante zu prüfen.
Boden soll auch unter Mauern liegen können, einschließlich geteilter rot/heller
Halbhexflächen entlang der gebauten Grenze. Die Rohrleitung soll zusammenhängend
am Lagerhaus anschließen, die grüne Linie muss zugeordnet werden.

Weniger regelmäßige Steinstreuung und kleine rein dekorative Steinchen sind
gewünscht. Diese neuen Kleinteile geben weder Deckung noch Weg-/Sichtblockaden.
**Die vorhandenen hellen Flecken vorerst behalten**: Das ist die letzte explizite
Entscheidung trotz des vermuteten Blumencharakters. Eine Stilüberarbeitung der
übrigen Objekte wurde ausdrücklich auf später verschoben. Quelle, Prüfsumme und
Entscheidungen stehen in der zugehörigen JSON-Datei. Keine pauschale Grafikabnahme.
