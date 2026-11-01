# Pass 02: frische Offline-Browserprüfung

Geprüfte HTML-Datei: `docs/reports/STERNENBUERGERCHEN_GRAFIK_2026-11-01.html`

SHA-256: `97a79d60ae65a3178f037ad226c082c46ce5e773b59e9484a225293ee83879c9`

Die Datei blieb zwischen Start, Abschluss und anschließender Sichtprüfung unverändert. Keine Generator- oder HTML-Änderung nach diesem finalen Lauf. Die frühere Pass-01-QA unter `browser_qa/` ist ein eigener historischer Nachweis.

## Ausgeführt

`node output/grafik_20261101/browser_qa_pass02/verify_report.cjs`

Chromium 151.0.7922.34, headless, GPU deaktiviert. Lokaler `file://`-Aufruf mit Browserkontext offline; Desktop 1440×1000 und Mobile 390×844 mit Touch-Kontext.

Ergebnis: **114/114 automatisierte Prüfungen bestanden**, keine Console-/Page-Fehler und keine HTTP-/HTTPS-Anfragen. Alle **67 Bilder als Thumbnail und Vollansicht (134 Dekodierungen)** geladen; Originalhashes geprüft. Die 15 aktuellen Screenshots wurden auf Layout gesichtet, die mobilen Bildkarten zusätzlich detailliert.

## Abgedeckt

- Hero zeigt das echte Pass-02-Nachherbild; vier Ansichten schalten Vorher/Nachher synchron.
- Wischvergleich einschließlich Tastaturbedienung, lokaler Auswahl und Reglerzustand.
- Vier Vorherdateien gegen das eingefrorene Verifikationsmanifest; gleiche Kameragrößen und unterschiedliche Bildhashes.
- Drei aktuelle Nutzerreferenzen mit Herkunft, Originalpfad und Hash im Bilddialog; acht historische Quellen separat.
- Landschaft/Gehpose/Profil-aus als drei zusätzliche Nachheransichten; Landschaft hat ausdrücklich kein Vorherpaar.
- Neue Kenney-Ausrüstungskandidaten: vier Rollen, je zwei Meshes, vier Materialien, ein Skin; Originalkörper erhalten.
- Suche, Gruppenfilter, fünf erhaltene Zielvorfassungen, ältere Schiffsproben und erste Hex-Basis.
- Bilddialog, Zoom, Pfeiltasten, Escape/Fokusrückgabe, Textbearbeitung ohne versehentlichen Bildwechsel.
- Lokale Notizen/Urteile auf Desktop und Mobile einschließlich Neuladen, Dialognotiz und Umlauten.
- Zwei echte JSON-Downloads, unterschiedliche Dateinamen, Schema und tatsächliche Notiz-/Regler-/Referenzwerte; sichtbarer Text- und Kopierfallback.
- Keine horizontale Überbreite auf Desktop/Mobile, auch nach Bedienung und im Dialog; relative Dokumentlinks vorhanden.

## Grenzen

Der Browsernachweis gilt nur für diese HTML-Fassung. Er ersetzt keinen Spieltest, Performance-/Kampagnennachweis oder gestalterische Nutzerfreigabe. Die nativen Felsen bleiben regelmäßiger als die Konzepte; vollständige Rostgrenze-Cutaway-Raumgruppen, Freihafen-Hallenensemble und gesamte Landschaftskomposition bleiben offen. Licht wurde in Pass 02 bewusst geändert und im Vergleich benannt.

Details, Skripthash, Originalhashes, Downloads und Screenshot-Hashes: `browser_qa.json`. Frühere Downloaddateien eines vorausgehenden QA-Laufs bleiben unter eigenen Zeitstempeln erhalten; das JSON nennt ausschließlich die Downloads des finalen Laufs.
