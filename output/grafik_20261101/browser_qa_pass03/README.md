# Pass 03: frische Offline-Browserprüfung

HTML: `docs/reports/STERNENBUERGERCHEN_GRAFIK_2026-11-01.html`

Unverändertes Archiv: `docs/reports/STERNENBUERGERCHEN_GRAFIK_PASS03_2026-11-01.html`

SHA-256 beider Dateien: `b2e4b6c86b08175112de59a8fd4a6d04e8429d776f70feef4b4f74785e38f9a3`

Aufruf: `node output/grafik_20261101/browser_qa_pass03/verify_report.cjs`

Chromium 151.0.7922.34, headless mit deaktivierter GPU, lokaler file-Aufruf und Browserkontext offline. Desktop 1440×1000, Mobil 390×844 mit Touch-Kontext.

Ergebnis: **136/136 automatisierte Prüfungen bestanden**. Alle **69 eingebetteten Bilder in Thumbnail und Vollansicht (138 Dekodierungen)** geladen, Originalhashes geprüft. Null Browserkonsole-/Page-Fehler, null externe HTTP-Anfragen, keine horizontale Überbreite. **19 aktuelle Screenshots** visuell auf Layout gesichtet, die korrigierte Passnummer im finalen Mobilbild zusätzlich detailliert geprüft.

Geprüft: fünf synchrone native Vorher/Nachher-Paare einschließlich Gelände; gleiche Kameratransforms/Projektion; Wischregler einschließlich Tastatur; Cutaway als zusätzliche Nachheransicht; drei Hauptvorlagen, historische Quellen und alte Bild-/Modellarchive; zehn tatsächlich verwendete Kenney-GLBs und ihre Lizenzhashes getrennt von zwei Hilfsatlanten; Dialog/Zoom/Pfeile/Escape/Fokusrückgabe; echte getrennte Pass03-Notizen ohne Übernahme alter Freigaben, Neuladen und JSON-Download/Textfallback auf Desktop/Mobil. Fünf Paaransichten und drei Zusatzbilder stammen aus dem freigegebenen nativen Pass03-Snapshot. Source-QA-Kontaktwarnungen bleiben transparent im Report.

Ein echter Beschriftungsfehler im kleinen Vergleichstitel wurde korrigiert. Danach wurde die komplette Suite erneut ausgeführt; nur der finale Lauf ist in `browser_qa.json` ausgewiesen. Nach diesem Lauf änderte sich kein HTML-Byte. Frühere JSON-Downloads behalten eigene Zeitstempel; das Prüfmanifest nennt die beiden Downloads des finalen Laufs.

Das Pass02-Archiv mit SHA `97a79d60ae65a3178f037ad226c082c46ce5e773b59e9484a225293ee83879c9` und alle sieben Pass03-Vorher-PNGs bleiben bytegleich erhalten. Diese Prüfung ersetzt keine gestalterische Nutzerfreigabe, keinen Gameplay-/Kampagnentest und keine Performanceabnahme. Die neue Nutzerkritik zu sterilen Bauteilen, Tank/Wagen, Wegen/Pad und Schiffen wird im nächsten Pass bearbeitet; sie verändert den hier gesicherten Nachweis nicht.
