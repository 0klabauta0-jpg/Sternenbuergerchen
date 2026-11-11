# Skirmish mit gemeinsamer Punktebasis

## Ziel und Ursache

Der Nutzer möchte Skirmish an einer begehbaren Heimatbasis beginnen und ein
1000- oder 1500-Punkte-Deck aus Personal, Ausrüstung, Schiffen und Infrastruktur
zusammenstellen. Drei verständliche Erfahrungsstufen ersetzen die Einzelwerte
in der normalen Einkaufsentscheidung. Die Gestaltung folgt den vorhandenen
nativen Gebäuden und Schiffen, mit den neuen individuellen Porträts.

## Umfang und Abgrenzung

Der Menüweg Skirmish → Punktebudget führt in eine leere Basis. Links werden
konkrete Personenvorschläge mit Identität, Porträt und vollständigem Paketpreis
angeboten. Rolle, Erfahrung, Rüstung und Waffe lassen sich vor dem Kauf ändern.
Rekrutieren und Entlassen wirken auf echte Basisakteure. Ausrüsten verwendet
das vorhandene endliche Basislager und den gemeinsamen Ausrüstungsbildschirm.
Habitat, Werkhalle, zusätzliche Feldbetten und bis zu sechs Landeplätze sind
kaufbar. Zwei Betten gehören zum Habitat. Die Gebäude nutzen feste Bauplätze.
Die aktuell spielbaren Cutlass und Buccaneer sind kaufbar. Weitere Fahrzeug-
modelle und Rüstungsmeshes folgen VEHICLE_ARMOR_TRAINING_2026_11_11.

## Akzeptanz

- Ein frischer Punkte-Start erzeugt keine kostenlosen Personen, Schiffe,
  Lagergegenstände, Betten oder Landeplätze.
- Ein gemeinsamer Runtime-Kontostand bezahlt jeden Einkauf zum Katalogpreis.
- Wiederholte erfolgreiche Anfragen liefern den ursprünglichen Beleg.
  Abweichende Daten mit derselben ID und zu teure Käufe werden abgelehnt.
- Entlassen erstattet den Personalanteil. Tatsächlich getragene und mitgeführte
  Ausrüstung geht ins Lager. Volles Lager verhindert die gesamte Entlassung.
- Schiffe benötigen gebaute freie Pads. Rückgabe verlangt ein gelandetes,
  leeres und unbesetztes Schiff und entfernt dessen Reise-/Inventareinträge.
- Unbebaute Flächen sind begehbar. Gebaute Gebäude stellen die ursprünglichen
  Kollisions- und Sichtdaten wieder her. Personen und laufende Wege auf dem
  Bauplatz verhindern die Errichtung bis zur Freigabe.
- Die letzten Personen lassen sich entfernen, ohne Kamera- oder Registryreste.
- Der gekaufte Startertrupp erreicht das Schiff zu Fuß und kann regulär starten.
- Die bisherigen Presets und gespeicherten Teams bleiben bedienbar.

## Besitzer und relevante Verträge

SimulationRoot bindet SkirmishEconomyState für Budget und Kaufbelege.
Roster und Flotte bleiben im bestehenden MetaLayerFlow, physische Personen in
BasePersonnelRuntime, Bestand in SingleplayerSupplyState, getragene Ausrüstung
in PersonnelLoadoutState und Reisen in den bisherigen Reise-Ownern. Der Adapter
führt die vorgeprüften synchronen Transaktionen aus. Das UI bearbeitet nur
Kaufvorschläge und liest Projektionen. Siehe skirmish_prepared_starts_contract.md,
personnel_inventory_contract.md und graphics_reference_revision_contract.md.

## Betroffene Dateien

skirmish_points_catalog.gd, skirmish_economy_state.gd,
skirmish_start_configuration.gd, game_start_contract.gd, main_menu_screen.gd,
skirmish_points_dialog.gd, skirmish_base_shop.gd, singleplayer_runtime_adapter.gd,
SimulationRoot, BasePersonnelRuntime, BaseCapacityLayout, ExplorableHomebase,
HomebaseScreen/OperationsPresenter, Supply-, Loadout- und Flottenreise-Owner.
Die Charakteransicht zeigt ergänzend die drei verständlichen Erfahrungsstufen.

## Lokale Prüfung

Die QA-Datei docs/qa/skirmish_points_base_20261111/checks.json führt die gezielten
Prüfungen auf. Acht Prüfprogramme sind bestanden. Der anschließende native
Menü-/Basis-/Inventarvergleich bei 1920 × 1080 und 1280 × 720 besteht 56 Checks.
Ein regulärer Abflug des 995-Punkte-Pakets ist mit 14 Checks bis in den Mondorbit
belegt. Wiederholtes Pilot-Boarding erhält jetzt den bereits laufenden Gruppenweg.

## Risiken und offene Arbeit

Preise sind erste Balancewerte. Freies Platzieren und zusätzliche Fahrzeug-
Spezialfunktionen gehören zu späteren Ausbauschritten. Die native Gestaltung
wurde geprüft, eine persönliche Abnahme des Nutzers steht aus. Der bestehende
ObjectDB-Hinweis beim Editorimport bleibt getrennt von den bestandenen
Laufzeitprüfungen offen. Mainintegration und EXE-Export sind nicht erfolgt.
