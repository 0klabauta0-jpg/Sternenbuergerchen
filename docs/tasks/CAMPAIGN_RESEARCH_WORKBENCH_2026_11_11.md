# Kampagnenfolge, Forschung und gezeichnete Porträts

## Ziel und Anlass

Der Nutzer möchte die offenen Integrationspunkte selbstständig abgearbeitet
haben. Die vier neuen fotografisch wirkenden Porträts gefallen ihm weniger als
die gezeichneten. Zusätzlich möchte er eine interaktive Kampagnen-Webseite,
auf der er Voraussetzungen, Reihenfolge und Belohnungen festlegen kann, und
einen weiterführenden Forschungsbaum.

## Umfang und Entscheidungen

- Vier neue Porträtkennungen beibehalten, Bilddarstellung zur Illustration ändern.
  Alte Quellen und frühere Kandidaten bleiben erhalten. Gemeinsame Atlasvorlage
  mit vier unterschiedlichen Gesichtern und sichtbaren Konturen/Farbflächen.
- Lokale HTML-Workbench mit dem bestehenden Fünf-Auftrags-Pfad und den drei
  tatsächlichen Rezepten als nachvollziehbarem Ausgangspunkt.
- Voraussetzungen, Belohnung, Kosten, Notizen und neue Knoten bearbeiten;
  Pfeile, erreichbare Schritte und Fehler wie Zyklen sichtbar machen.
- Weitere Forschungszweige für Schutz, Industrie und Fahrzeuge als ausdrücklich
  vorgeschlagene Fortsetzung. Baupläne aus Einsätzen, Entwicklung an der Basis,
  danach bezahlte Einzelanfertigung. Keine zusätzliche abstrakte Punktewährung
  als Voraussetzung dieser ersten Planung.
- Export/Import und lokale Wiederaufnahme funktionieren ohne Server. Keine
  Änderung von Spielständen durch die Planungsseite. Eine spätere Integration
  übernimmt geprüfte Entscheidungen über die bestehenden Runtime-Owner.

## Nicht-Ziele

Kein Webhosting, kein Onlinekonto, kein ersetzter Spielstand und kein behaupteter
fertiger Runtime-Forschungsbaum. Fahrzeug- und Rüstungsintegration bleibt im
Task VEHICLE_ARMOR_TRAINING_2026_11_11; Performance separat dokumentiert.

## Verträge und Dateien

ARCHITECTURE.md, campaign_introduction_contract.md,
singleplayer_locations_jobs_contract.md, html_report_workbench_contract.md,
graphics_reference_revision_contract.md; data/singleplayer/jobs.json,
SingleplayerCampaignState und SingleplayerSupplyState sind die Ist-Quellen.
Betroffen: docs/reports, tools, art/portraits_20261111, Porträtkatalog und
Atlasressourcen, gezielte Verifikation und QA-Dokumentation.

## Akzeptanz und lokale Prüfung

1. Bestehende Aufträge und Rezeptkosten stimmen mit ihren Quellen überein.
2. Knotenwahl zeigt Voraussetzungen und Belohnungen. Änderungen aktualisieren
   Pfeile und Erreichbarkeit; Zyklen werden benannt und nicht still akzeptiert.
3. Neue Schritte und Forschungszweige sind editierbar; Vorschläge bleiben von
   der unveränderten Ist-Baseline unterscheidbar.
4. Export/Import bewahrt Graph, Status, Änderungen, Entscheidungen und Notizen;
   beschädigter Import ersetzt keinen funktionierenden Stand.
5. Desktop und schmale Ansicht, Tastaturbedienung und lokaler Dateiexport prüfen.
6. Vier Porträts als native Ressourcen und in echten Personenansichten prüfen.

## Risiken / offene Punkte

Kosten neuer Forschung bleiben Balancevorschläge. HTML-Entscheidungen müssen
vor Runtimeübernahme geprüft werden. Nutzerurteil zur Bildrevision bleibt von
technisch bestandenem Import getrennt. Der aktuelle Branch enthält bereits
unabgeschlossene Rüstungsarbeiten; diese werden nicht als fertig ausgewiesen.

## Baseline-Nachzug nach Runtimeintegration — 11.11.2026
Ziel/Ursache: Die eingebettete Ausgangsplanung bezeichnet inzwischen vorhandene
Schutz-/Bergungsentwicklung noch als Vorschlag. Nur Baseline-/Quellhinweise
nachziehen, bezogen auf CAMPAIGN_RESEARCH_RUNTIME_2026_11_11,
CAMPAIGN_INDUSTRY_RUNTIME_2026_11_11 und html_report_workbench_contract.
Akzeptanz: Vier echte Forschungsknoten als Ist markieren; ihre einmaligen
180/120/240/160Cr-Kosten und getrennte40/80/40Cr-Herstellung korrekt darstellen.
Drei Einzelherstellungsknoten ergänzen, alle bisherigen IDs erhalten. Erweiterte
Rohstoffverarbeitung und Fahrzeug-/Flottenzweige bleiben Vorschläge. Aktuelle
Quellenhashes dokumentieren. Layout, JavaScript, Storagekey, Export/Import und
lokale Nutzerentwürfe/Notizen bleiben unangetastet. Bestehende Entwürfe werden
nicht automatisch mit der neuen Baseline überschrieben; nur frischer Plan bzw.
vorhandener expliziter Reset nutzt den neuen Ausgangsstand.
Betroffene Dateien: docs/reports/campaign_research_workbench.html, diese Task,
eigene QA unter docs/qa/campaign_research_baseline_refresh_20261111.
Nur enge JSON-/Quell-/Abhängigkeitsprüfung; keine Browser-/Screenshotmatrix oder
neue Spieltests. Initiale Forschungs-/Herstellungspreise bleiben unbalanciert;
Workbench ist ein Planspiel mit einmal abschließbaren Knoten, keine vollständige
Produktion oder Gameplay-Wahrheit. Kein Commit/Push durch diesen Teilagenten.

Nachzug umgesetzt: Baseline21Knoten (alle18altenIDs erhalten),4Runtimeforschungen
alsIst,3separateHerstellungen40/80/40. Quellen-/Isthinweise korrigiert,
weitergehendeVerarbeitung/Fahrzeuge alsVorschläge. StatischerDatencheck27/0;
JavaScript/CSS/ControlIDs unverändert. KeineBrowser- oderSpieltestwiederholung.
QA: docs/qa/campaign_research_baseline_refresh_20261111/README.md.
