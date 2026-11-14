# SternenBuergerchen – 17 visuelle Zielbilder

Bildpaket vom 14.11.2026. Die Serie zeigt mögliche Spielsituationen in einer
Mischung aus der funktionalen Science-Fiction-Gestaltung von Star Citizen und
einer lesbaren, illustrierten Wimmelbildwelt. Bodenansichten berücksichtigen
das Hexfeld, Maßstab, freie Wege, Deckung und funktionale Baugruppen.

**Status: generierte 2D-Ziele zur Sichtung.** Die Bilder sind keine nativen
Godot-Aufnahmen, keine integrierten Modelle und noch nicht vom Nutzer
abgenommen. Die voneinander abweichenden Schiffe, Wracks, Pads und Gebäude
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
| 13 | Mondorbit und Weiterreise | Schiff, Himmelskörper und Reiseatmosphäre |
| 14 | Raumkampf im Asteroidenfeld | Erkennbare Schiffe, Richtungen und räumliche Staffelung |
| 15 | Hilfe für ein havariertes Schiff | Bergung als übersichtliche Raumbegegnung |
| 16 | Kleine Orbitalstation | Technische Baugruppen und Anflugraum |
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
Karten-, Höhen-, Navigations- und Sichtdaten des Spiels. Ein in Weltraumbildern
verwendetes Sensor-Hexraster ist lediglich ein Darstellungskonzept; daraus
folgt keine zusätzliche Raumkampf- oder Navigationsmechanik.

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
Alle 23 Originalausgaben (17 aktuelle Bilder und sechs Zwischenstände)
wurden unverändert ins Paket kopiert und gegen ihre Generatororiginale
mit SHA-256 verglichen. Die finalen Dateinamen stehen in `prompts.json`.

[sources.json](sources.json) ordnet zehn unveränderte lokale Referenzkopien
zu: vier frühere Projektillustrationen und sechs Star-Citizen-Screenshots
aus der Bildersammlung des Nutzers. Es enthält Originalpfad, Herkunft,
Rolle, Hinweise und SHA-256. Das gezeigte SC-Innenraumbild ist vom
Hauptagenten als Windows-Hintergrundbild zugeordnet. Alle zehn Quellen
wurden am 14.11.2026 tatsächlich geöffnet. Die Kopien liegen unter
`sources/art/` und `sources/star-citizen/`; die Originale bleiben unverändert.

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
