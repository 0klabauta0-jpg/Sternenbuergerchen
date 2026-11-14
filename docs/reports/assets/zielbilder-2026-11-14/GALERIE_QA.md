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
