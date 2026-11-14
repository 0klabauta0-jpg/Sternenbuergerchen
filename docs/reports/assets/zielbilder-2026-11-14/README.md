# SternenBuergerchen – 17 visuelle Zielbilder

Bildpaket vom 14.11.2026. Die Serie zeigt mögliche Spielsituationen in einer
Mischung aus der funktionalen Science-Fiction-Gestaltung von Star Citizen und
einer lesbaren, illustrierten Wimmelbildwelt. Bodenansichten berücksichtigen
das Hexfeld, Maßstab, freie Wege, Deckung und funktionale Baugruppen.

**Status: Boden-Stilrichtung positiv bestätigt, Raumkarten R03 / Polisar R04 zur Sichtung.**
Der Nutzer findet die Bodenmotive insgesamt passend. Die vier kritisierten
Weltraumansichten 13–16 wurden ersetzt; ihre neue Bewertung ist offen.
Die Zielbilder sind keine nativen Godot-Aufnahmen oder integrierten Modelle.
Die voneinander abweichenden Schiffe, Wracks, Pads und Gebäude
sind eigenständige Szenenvarianten. Sie sind keine maßgleichen Mehransichten
eines bereits vereinbarten Modells.

## Motive

Die aktive Dateizuordnung und der vollständige jeweils verwendete Prompt
stehen in [prompts.json](prompts.json). Bei Revisionen gilt dessen Feld `file`.

| Nr. | Motiv | Schwerpunkt |
|---|---|---|
| 01 | Satellitenabsturz auf Mondboden | Lange Schleiffurche, aufgeworfener Regolith, gerichtete Trümmer |
| 02 | Die Spur zum Wrack | Physische Suchspuren; unbekanntes Gebiet bleibt schwarz |
| 03 | Felsen, Geröll und Laufwege | Geologische Gruppen, freie Passagen und Höhenwechsel |
| 04 | Eine vollständige Einsatzkarte | Landezone, Siedlung, Missionsort und lesbare Verbindungen |
| 05 | Außenposten am Canyon | Funktionale Gebäudegruppen und belebter Arbeitsalltag |
| 06 | Anflug auf die Landeplattform | Niedriges Pad, Sicherheitsbereich und Schiffsmaßstab |
| 07 | Landepad: Wartung und Versorgung | Deckkante, Zugänge, Serviceanschlüsse und Arbeitszone |
| 08 | Basisräume als Schnittansicht | Schlafen, Messe, Werkstatt und freie Durchgänge |
| 09 | Fracht, Rohstoffe und Werkstatt | Geordnete Materialgruppen mit Platz zum Rangieren |
| 10 | Feuerteams im Bodengefecht | Deckung, Truppabstände und verständliche Feuerlinien |
| 11 | Außenposten bei Nacht | Lesbare Verteidigung, Arbeitslicht und dunkle Umgebung |
| 12 | Rückzug zur Abholung | Bewegungsrichtung, Schutz und Schiffszugang |
| 13 | Orbitkarte – Planetenanflug | Planetensaum oben, Systemrichtung unten, kleine Schiffe auf großer Hexkarte |
| 14 | Raumkampf im Asteroidenfeld | Kleine Rotten, zusammenhängendes Hexraster und freie Manöverräume |
| 15 | Wrackbegegnung | Kleines beschädigtes Schiff und gerichtete Trümmer im Kartenausschnitt |
| 16 | Polisar – Stationsanflug | Stehende Ringe, kompakte Pads, größerer Innenbereich, zwei Dockports, hintere Hälfte außerhalb der Map |
| 17 | Anbaupods am Außenposten | Geschlossene Anbaumodule auf kargem Außengelände |

## Nutzerkorrektur und Bildgrenzen

„Acker“ war eine bildhafte Beschreibung der Einschlagfurche. Die zunächst
zu wörtlich ausgelegten Landwirtschaftsfassungen von 01, 02 und 04 bleiben
als verworfene Zwischenstände erhalten; aktive Revisionen zeigen kargen
Mondboden ohne Feldfrüchte oder Ackerreihen. Bild 17 untersucht Pflanzen
gezielt innerhalb geschlossener Anbaupods. Einzelne andere Motive dürfen als
gesonderte Biome-/Stilvarianten betrachtet werden, nicht als identische
Ansichten dieser Mondoberfläche.

Das Hexraster ist eine sichtbare Gestaltungsvorgabe und keine mathematisch
geprüfte Kartenquelle. Seine örtliche Form und sein Maßstab können zwischen
den KI-Bildern schwanken. Für eine spätere Umsetzung gelten die echten
Karten-, Höhen-, Navigations- und Sichtdaten des Spiels. Die neuen
Weltraumbilder richten sich nach dem gelesenen Raumkampfvertrag:
512 Spalten × 256 Reihen für die gesamte lokale Karte, Ansichten als
gezoomte Ausschnitte. Leichte und mittlere Jäger entsprechen nach aktuellem
Nutzerfeedback einem Hex, größere Nutzschiffe wie die Cutlass zwei Hex.
Die Zahl in der Miniaturansicht bezeichnet die Gesamtkarte, nicht die
Anzahl sichtbarer gezeichneter Zellen. Wrackbergung ist eine mögliche
Bildsituation und kein Nachweis einer fertigen Bergemechanik.

Bei Polisar liegen Räume und kompakte Pads vor der oberen Kartengrenze.
Die hintere Hälfte kann als Dekoration sichtbar bleiben. Senkrechte Ringe
erscheinen von oben schmal; zwei seitliche Dockports dienen großen Schiffen.
Der Nutzer nennt die Station Polisar; die bestehenden gelesenen Code-IDs
heißen `polisa` und werden durch diese Grafikaufgabe nicht geändert.
Die Unterlagen [RAUMKARTEN_RECHERCHE.md](RAUMKARTEN_RECHERCHE.md) und
[POLISAR_BLENDER_AUFTRAG.md](POLISAR_BLENDER_AUFTRAG.md) halten Quellen,
Bildvorgaben und den direkt übergebbaren Modellierungsauftrag fest.

Die gestalterische Prüfung und konkrete offene Stellen stehen in
[BILDPRUEFUNG.md](BILDPRUEFUNG.md). Ein technischer Hash-/Dateinachweis ist
keine gestalterische Freigabe.

## Quellen und Erzeugung

Verwendet wurde das eingebaute Werkzeug **`image_gen.imagegen`**, kein
API-/CLI-Ersatz. Die meisten Bilder wurden aus Textprompts neu erzeugt.
Diese Prompts verdichten die tatsächlich gesichteten Vorlagen und Regeln;
eine lokale Referenzkopie bedeutet nicht, dass diese Datei dem Generator
direkt als Bild-Input übergeben wurde. Die Korrekturen 01/02 R02 verwenden
die jeweiligen ersten Generatorbilder als Edit-Eingabe. Weitere tatsächliche
Generation-/Revisionszuordnungen hält `generation_metadata.json` fest.
Alle 32 Originalausgaben (17 aktuelle Bilder und 15 Zwischenstände)
wurden unverändert ins Paket kopiert und gegen ihre Generatororiginale
mit SHA-256 verglichen. Die finalen Dateinamen stehen in `prompts.json`.

[sources.json](sources.json) ordnet 16 unveränderte Referenzkopien zu:
vier frühere Projektillustrationen, sieben Star-Citizen-Bilder aus dem
Bilderordner, die neue vom Nutzer angehängte Port-Olisar-Draufsicht,
zwei native R08-Aufnahmen aus einem anderen Arbeitsbaum und zwei Webbilder.
Originalpfad bzw. Quellseite, Herkunft, Rolle und SHA-256 sind dokumentiert.
Alle Quellen wurden am 14.11.2026 tatsächlich geöffnet. Quellen liegen
unter `sources/art/`, `sources/star-citizen/`, `sources/native/` und
`sources/web/`; die Originale bleiben unverändert. Die native Referenz
belegt den betrachteten R08-Stand, keine Abnahme der aktuellen Runtime.

Web-Bildreferenzen: **Hasgaha**, [Port Olisar Over the Years](https://robertsspaceindustries.com/community-hub/post/screenshots-of-port-olisar-over-the-years-03Z7D1CWw5L2H),
mit Credit und Verweis auf [hasgaha.com](https://hasgaha.com).
Die verlinkte Sammlung erlaubt Nutzung mit Namensnennung und Website-Link.
Auch die vom Nutzer übermittelte Draufsicht trägt ein Hasgaha-Wasserzeichen.
Der historische Aufbau wurde ergänzend mit der
[Port-Olisar-Beschreibung](https://starcitizen.tools/Port_Olisar) abgeglichen;
die Kompaktfassung und die zwei zusätzlichen Dockports sind Nutzerwünsche
für Polisar, keine behauptete Originalausstattung von Port Olisar.

Polisar R03 ist ein direkter Bild-Edit mit der nativen R08-Nahaufnahme,
der vom Nutzer übermittelten Draufsicht und R02 als reiner Detail-/Materialquelle.
R03 der anderen Raumkarten verkleinert die Schiffe und korrigiert
Auswahlmarkierungen bzw. den Auto-Schalter. Polisar R04 editiert unmittelbar
die letzte vom Nutzer farbig annotierte Chat-Anlage: Ringe vergrößert und
auf die verlängerte Nabenachse zentriert, Streben ergänzt, links zwei
Solarflügel, rechts vier Tanks und längere Dockarme. Die Farbmarkierungen
sind entfernt, Beschriftung und unteres Raster korrigiert. Für die Annotation
wurde kein lokaler Dateipfad mitgeteilt; der tatsächliche Toolaufruf
verwendete num_last_images_to_include=1. Die alten Fassungen bleiben erhalten.

Die ältere taktische Rostwelt-Vorlage enthält noch ein Quadratgitter.
Übernommen wurden daraus Komposition und Formenstaffelung; die neue
Zielserie verlangt ausdrücklich sechseckige Felder. Frühere warme
Außenpostenillustrationen begründen ebenfalls keine Landwirtschaft auf dem
kargen Mond der korrigierten Absturzmotive.

Der Bezug auf bisherige Projektentscheidungen kommt insbesondere aus:

- `docs/dev/graphics_reference_revision_contract.md`
- `docs/dev/hex_grid_v1_contract.md`
- `docs/dev/gm01_frontier_map_contract.md`
- `docs/tasks/ART_2026_11_01_graphics_references.md`
- `docs/tasks/ART_2026_11_01_pass04.md` bis `ART_2026_11_01_pass07_paths_runtime.md`
- `docs/tasks/ART_2026_11_01_astra_ship_revision.md`
- `docs/tasks/PLAYTEST_REWORK_2026_11_14.md` (nur gelesen)

Die neue Paketbasis ist der isolierte Worktree
`C:/dev/SternenBuergerchen-worktrees/visual-targets-20261114`.
`prompts.json` verzeichnet Basiskommit und den gelesenen Hauptarbeitsstand
getrennt. Das Paket ändert keine Gameplay-Wahrheit.

## Reproduzierbarer Dateinachweis

[build_manifest.py](build_manifest.py) benötigt nur Python 3.9 oder neuer und
die Standardbibliothek. Es liest die aktuelle aktive und verworfene
Dateizuordnung aus `prompts.json`, prüft die Referenzkopien gegen
`sources.json`, hasht die vorhandenen Bilder und erfasst PNG-/JPEG-Abmessungen.
Eine noch verfügbare Originalquelle wird zusätzlich gegen ihren gesicherten
Hash geprüft; das portable Paket benötigt die externe Originaldatei nicht.

Aus diesem Ordner ausführen:

```powershell
python build_manifest.py --check
python build_manifest.py
```

Der erste Aufruf prüft ohne Ausgabeänderung. Der zweite schreibt
`manifest.json` mit aktiven Bildern, verworfenen Fassungen, Quellen,
Zusatzbildern und vorhandenen Dokumenten. Vorhandene
`generation_metadata.json` wird samt Dokumenthash eingebunden. Fehlende oder
abweichende Bilddateien führen zu Exitcode 2; ein unvollständiges Paket wird
nicht als vollständiges Manifest gespeichert. Die Bilddateien selbst werden
weder umkodiert noch verändert.

Prompts und Quellen machen den Entstehungsweg nachvollziehbar. Ein erneuter
Aufruf des Bildgenerators garantiert keine byteidentische Illustration.
