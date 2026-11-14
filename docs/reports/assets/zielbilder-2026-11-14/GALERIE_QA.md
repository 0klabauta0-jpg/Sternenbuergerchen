# Offline-Galerie: lokale Bedienpruefung

Stand: 14.11.2026. Geprueft mit echtem Chromium ueber Playwright CLI auf der lokalen `file://`-Datei. Keine Engine-/Gameplaypruefung und keine gestalterische Nutzerabnahme.

## Ergebnis

- HTML ohne externe Laufzeitabhaengigkeiten; aktuelle Metadaten aus `prompts.json` eingebettet.
- Nach Nutzerkorrektur 17 aktuelle Eintraege; 01/02/04 referenzieren ausschliesslich `*_r02.png`. Historische Feld-/Ackerfassungen sind nicht in der aktiven Galerie.
- Suche: `Satellit` liefert einen Treffer. Weltraumfilter liefert vier Motive. Bewertungsfilter liefert nur den gewaehlten Testeintrag.
- Einzelentscheidung, Einzelnotiz, Gesamtnotiz und Checkbox lassen sich bedienen und bleiben nach Reload erhalten.
- Lightbox oeffnet das angeklickte Motiv; Pfeil rechts wechselt von Motiv 01 auf Motiv 02, Escape schliesst den Dialog.
- Ansichtsschalter: bei 1440px Fensterbreite zwei Spalten von je 676px; grosse Einzelansicht eine Spalte von 1376px.
- 390x844: einspaltige Karten, Dokumentbreite 390px ohne horizontalen Ueberlauf. Desktop- und schmale Screenshots visuell geoeffnet; Bildstatus/Bedienung bleiben lesbar.
- `JSON exportieren` loest auf `file://` einen echten Download aus und fuellt gleichzeitig das lesbare Textfeld. Schema, alle 16 damaligen Einzelzuordnungen, Testentscheidung, Einzel-/Gesamtnotiz und Checkboxwert im erzeugten JSON geprueft.
- Import derselben Testdatei in die auf 17 Eintraege erweiterte Galerie erfolgreich: Notiz uebernommen, neuer Eintrag bleibt offen, Exportzaehler 17.
- Testnotizen anschliessend aus dem isolierten Browserprofil entfernt. Keine Testbewertung in die HTML-Datei geschrieben.

## Dateien und Reproduktion

- Galerie: `docs/reports/ZIELBILDER_2026_11_14.html`.
- Generator: `build_gallery.py`; liest `prompts.json`, veraendert keine Bilder und erzeugt die Galerie erneut.
- Vorlage: aktuelles `C:/dev/SternenBuergerchen/docs/reports/_html_workbench_template.html`; uebernommen sind das Controls-/Notizen-/Choices-Modell, Schema v1 und Download-/Textfallback.
- Arbeitsbelege liegen lokal unter `output/playwright/visual-gallery/` (Snapshots, Desktop-/Mobilaufnahme und Testexport). Diese sind Pruefbelege, keine Nutzerurteile.
- Playwright CLI musste fuer den ausdruecklich gewuenschten lokalen Datei-Aufruf mit seiner dokumentierten Option `PLAYWRIGHT_MCP_ALLOW_UNRESTRICTED_FILE_ACCESS=1` gestartet werden. Es wurden nur Galerie und ihre lokalen Dateien geoeffnet.

## Abschliessende Pruefung der finalen 17 Bilder

Nach Abschluss der Generierung am 14.11.2026 um 15:25-15:27 Uhr Europe/Berlin wurde die finale Galerie auf `file://` erneut geladen. HTML und Generator wurden dabei nicht veraendert.

- **17/17 aktuelle PNGs im Browser erfolgreich mit `HTMLImageElement.decode()` dekodiert**, jedes 1672 x 941 Pixel. Fuer die Gesamtpruefung wurden auch noch nicht in den Viewport gescrollte Lazy-Bilder im Browser geladen.
- Browserkonsole nach diesem frischen Laden und nach der abschliessenden Lightboxpruefung: **0 Meldungen, 0 Fehler, 0 Warnungen**. Keine fehlenden Dateien, keine JavaScriptfehler.
- Aktuelle Revisionen: `01_satellitenabsturz_r02.png`, `02_suchspur_fog_r02.png`, **`03_geologie_hex_r02.png`**, `04_map_uebersicht_r02.png` und **`17_nahrungspods_r03.png`**. Alle uebrigen aktiven Bilder 05-16 verwenden ihre in `prompts.json` genannten Originaldateinamen. Keine ueberholte 01/02/03/04/17-Fassung wird von der Galerie geladen.
- Neuer echter JSON-Download aus der finalen Galerie: `output/playwright/visual-gallery/visual-targets-20261114-2026-11-14T14-26-28-417Z-01.json`. Sowohl Textfeld als auch heruntergeladene Datei geprueft: Schema `sternenbuergerchen.html_workbench.v1`, Gesamtzahl **17**, **17** Einzelentscheidungen, **17** Einzelnotizen plus Gesamtnotiz und **17** Asset-Zuordnungen mit den finalen Dateinamen. Alle Entscheidungen `unreviewed`, alle Notizen leer; keine verbliebenen QA-Urteile.
- Finale Ansicht 1440 x 1000: kein horizontaler Ueberlauf. Finale schmale Ansicht 390 x 844: Dokumentbreite 390px, Kartenspalte 366px, alle 17 Bilder geladen. Mobile Lightbox fuer die korrigierte Absturzstelle oeffnet `01_satellitenabsturz_r02.png`, Dialogbreite 366px innerhalb des 390px-Viewports, Escape schliesst.
- Finale Screenshots `output/playwright/visual-gallery/final-desktop.png` und `final-mobile.png` visuell geoeffnet: Einzelkarten, Notizen und Export passen in die jeweilige Ansicht.

Die fruehe Bedienpruefung lief parallel zur Erzeugung und enthielt erwartbare `ERR_FILE_NOT_FOUND` fuer damals noch nicht vorhandene PNGs. Diese historische Begrenzung ist durch die vollstaendige finale Ladepruefung aufgehoben. Fruehe Screenshots koennen weiterhin die historische 16er-Beschriftung und inzwischen ersetzte Bilder zeigen; fuer den Abschluss gelten die hier genannten finalen Belege.

## Weltraumrevision: Feedback und dateigebundene Bewertungen

Gezielte Folgepruefung am 14.11.2026, 15:57-16:03 Uhr Europe/Berlin. Keine Runtime-QA.

- Die 17 Motivkarten und die Lightbox zeigen das dokumentierte `user_feedback`. Boden 01-12 und 17: insgesamt positiv bestaetigte Stilrichtung, ausdruecklich keine native Modellabnahme. Weltraum 13-16: ueberarbeitete Fassung, aktuelles Nutzerurteil offen.
- Neues Browserspeicherformat v2 bindet Bewertungen und Notizen an den Dateinamen. Historische Eintraege bleiben je Revision erhalten und werden im `revision_history`-Teil des JSON-Exports ausgegeben. Aktuelle Dateizuordnung steht zusaetzlich in `metadata.asset_files`.
- Migration des alten dateilosen Browserformats mit absichtlich verschiedenen Testurteilen geprueft: Bodenentscheidung/-notiz und Nahrungspodnotiz bleiben erhalten; alte Weltraum-Urteile und -Notizen landen bei den bekannten urspruenglichen PNGs. Die neue R03 beginnt mit `unreviewed` und leerer Notiz. Zwei vorhandene Alturteile erzeugten zwei sichtbare Revisionshinweise.
- Neue R03-Notiz und -Entscheidung ueber die echten Bedienfelder gesetzt; nach Reload bleiben diese unter `13_orbit_reise_r03.png` erhalten, gleichzeitig die abweichende alte Notiz unter `13_orbit_reise.png`.
- Echter JSON-Download `output/playwright/visual-gallery/visual-targets-20261114-2026-11-14T15-00-04-383Z-01.json`: 17 Assetzuordnungen, aktuelle und historische Notiz der Orbitkarte getrennt, alle Nutzerfeedbackobjekte enthalten. Diese Datei enthaelt ausdruecklich synthetische QA-Urteile, keine Nutzerentscheidungen.
- Export-Roundtrip und anschliessender Import einer alten dateigebundenen Exportdatei geprueft: neue R03-Bewertung bleibt erhalten. Leere Altwerte ueberschreiben keine bereits archivierte aussagekraeftige Altnotiz; diese Kante wurde beim Test gefunden, behoben und erneut ueber die echte Importbedienung bestanden.
- 17/17 Bilder im Browser geladen und dekodiert; 13-15 sind `*_r03.png`. 390px-Ansicht mit 366px-Kartenspalte, Dokumentbreite 390px, kein horizontaler Ueberlauf. Konsole ohne Meldungen, Fehler oder Warnungen. Polisar-Lightbox mit sichtbarem Nutzerfeedback passt in denselben Viewport.
- Sichtbarer Link `Blender-Auftrag: Polisar` im Header und Footer; `Raumkarten-Recherche` im Footer. Links zeigen auf die zugehoerigen lokalen Markdown-Dateien im Bildpaket.

## Aktueller Abschluss: Polisar R04

Am 14.11.2026 um 16:07 Uhr Europe/Berlin nach erneuter Nutzerkorrektur abgeschlossen. Der aktuelle Satz besteht aus 17 Motiven; Weltraum 13-15 verwendet R03, Station 16 verwendet ausschliesslich `16_orbitalstation_r04.png`. Die frueher genannten R03-Belege der Station sind historische Zwischenstaende.

- Finale Galerie erneut aus `prompts.json` erzeugt. Alle 17 aktuellen Bilder im echten `file://`-Browser erfolgreich dekodiert. Konsole: 0 Meldungen, 0 Fehler, 0 Warnungen.
- Tatsaechlichen Dateiwechselschutz R03 -> R04 mit vorhandenem v2-Speicher geprueft: alte Stationentscheidung `good` und Notiz `QA nur Station R03` bleiben unter `16_orbitalstation_r03.png`; aktuelle Station R04 beginnt `unreviewed` mit leerer Notiz. Die unveraenderte Bodenentscheidung und Bodennotiz bleiben erhalten. Die R03-Notiz ist im sichtbaren Revisionsverlauf der Stationskarte abrufbar.
- Echter Download `output/playwright/visual-gallery/visual-targets-20261114-2026-11-14T15-07-29-920Z-01.json`: 17 Assetzuordnungen, aktuelle Stationdatei R04, historisches R03-Urteil getrennt und aktuelles `user_feedback` mit Label `Markierungen umgesetzt · Bewertung offen` enthalten.
- Schmale Ansicht 390px: Dokumentbreite 390px ohne Ueberlauf. Desktop 1440px: kein Ueberlauf. Header und Footer enthalten beide den lokalen Blender-Auftrag-Link. Die Recherche ist im Footer verlinkt.
- Synthetische QA-Eintraege danach aus dem isolierten Browserprofil entfernt; abschliessender Reload zeigt leere Notizfelder. Keine synthetische Bewertung oder Abnahme in HTML/Prompts geschrieben.
- Generator, erzeugte HTML-Datei und dieses QA-Dokument sind abschliessend mit LF-Zeilenenden gespeichert. Keine Runtime-Dateien geaendert und kein Commit durch diesen Teilauftrag.
