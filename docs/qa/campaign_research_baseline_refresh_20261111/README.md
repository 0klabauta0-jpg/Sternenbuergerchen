# Forschungs-Workbench: Baseline nach Runtimeintegration

Nur die eingebettete JSON-Baseline und zugehörige Ist-/Quellenhinweise aktualisiert,
auf Taskstand1f676bfbc. Alle18 bisherigen Kennungen erhalten; die4integrierten
Entwicklungsschritte sind jetzt Ist. Drei separate Einzelherstellungsschritte
ergänzt: craft_medium_armor40Cr, craft_heavy_armor80Cr, craft_salvage_tool40Cr.
21Knoten insgesamt; Forschung180/120/240/160Cr bleibt einmalig und gewährt
Baupläne, keine Gratisgegenstände. Kosten ausdrücklich erste Balancewerte.
Rohstoffverarbeitung und Fahrzeug-/Flottenforschung weiterhin Vorschläge.

## Enge Prüfung
`python docs/qa/campaign_research_baseline_refresh_20261111/check_baseline.py`
27Daten-/Quell-/Strukturschutzprüfungen,0Fehler. Ergebnisse in results.json.
- Knoten eindeutig, alle bisherigen IDs und14sonstigen Alt-Knoten unverändert.
- Forschungsdaten, Kosten und Voraussetzungen stimmen mit research.json überein.
-3separate Herstellungen stimmen mit Rezeptpreisen überein, keineGratisItems.
- Alle Abhängigkeiten existieren; keineZyklen. Quellenfragmente auflösbar.
-7Quellenhashes entsprechen den aktuellen lokal gelesenen Dateibytes.
- Ausführbares JavaScript exakt unverändert, ebenso CSS und alleHTML-ControlIDs.
  Somit keine neue Storage-/Import-/Export-/Notizlogik; Report-ID/Storagekey
  bleiben gleich. Bestehende lokale Entwürfe werden weiterhin als eigene Pläne
  geladen. NeueBaseline gilt für frischePläne oder den vorhandenen bewusstenReset.
- Begrenzter git diff --check ohne Befund.

Keine Browserausführung, kein JSON-Klickexport, keine Screenshotmatrix und kein
Spieltest in diesem Paket. Die27Prüfungen sind statische Datensicherheit und
Quellenabgleich, keine neueInteraktions-/Nativeabnahme. Keine Runtimeänderung.
Kein Commit/Push durch den Teilagenten. Manifest enthält den lokalen Quellenfreeze.
