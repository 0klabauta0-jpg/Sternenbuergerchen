# Begehbare Basis: lebendige Karte und Zugänge zur Verwaltung
## Ziel / Ursache
Nutzerscreenshot10.11.2026: nach Flugdeck nur eingefrorenes Pad, Labels bewegen
sich unabhängig. Basis soll ihre tatsächlich vorhandenen Werkzeuge zugänglich
machen: Bauen, Blueprints/Herstellung, Lager/Ausrüstung, Personal, Schiff.
## Umfang / Dokumente
Gleicher Auftrag/Branch wie Flugdeck und Datenfeedback. Bestehende
SingleplayerServicesPresenter-/Inventar-/Navigationcommands wiederverwenden;
keine neue Gebäude-/Schiffskomponenten-Simulation. Vorhandener Ausbau ist Pad2;
vorhandene Rezepte leichte Rüstung/Miningtool/Sturmgewehr. Gesperrte Blueprints
sichtbar erklären statt kostenlose Artikel erzeugen.
Contracts: homebase_operations_ux_contract, personnel_inventory_contract,
orbit_quantum_travel_contract. Dateien: operations/explorable_homebase,
services_presenter, gezielte Native-/Serviceverifier.
## Akzeptanz / Prüfung
Preview→Basis zeigt Übersicht, native Pixel ändern sich bei Zoom/Pan synchron
zu Weltprojektion. Basisaktionsleiste öffnet bestehende Bereiche; Bauen und
Werkstatt zeigen echte Freigaben und führen vorhandene Ownercommands aus.
Lager/Ausrüstung öffnet endlichen Bestand, Personal bestehende Verwaltung.
Kein Item-/Kosten-/Pad-/Blueprintduplikat. Physik/Simulation unverändert.
## Risiken / offen
Austauschbare Schiffskomponenten sind bisher nicht implementiert; Nutzerentscheidung: zusätzliche Schiffskomponenten zunächst planen;
siehe SHIP_COMPONENTS_2026_11_10_PLAN.md. Keine Behauptung eines
freien Gebäudeeditors oder neuer Modelle. Main/EXE weiterhin nicht Teil des
bislang ausdrücklich beauftragten Folgeabschlusses.

## Abschluss / Prüfbeleg
Quellstand umgesetzt und gezielt geprüft. Ergebnisse, native Bilder und
Baselinegrenzen: docs/qa/flugdeck_basis_data_20261110/README.md.
Kein Mainmerge/EXE-Export in diesem Folgeabschluss.
