# Flugdeck: kompakter Startbereich und zuverlässige Padvorschau

## Ziel / Ursache
Screenshot Unbenannt.PNG vom10.11.2026: großer schwarzer Vorschaubereich,
mehrfach verteilte Schiffsselektion, zu breite Start-/Pilotgruppen. Begriff
Einsatz & Abflug verdeckt die Funktion als reales Flugdeck.

## Umfang / Entwurf
Navigation und Schritt03 heißen Flugdeck, Sternkarte unmittelbar darunter.
Rechts oben reales Pad mit zugehörigem Schiff; unter der Vorschau kompakter
Bereich mit Padwahl und Schiffs-Dropdown rechts, Pilot/Status etwa halb so breit
wie bisher. Boarding/Zurückholen/Abheben in gemeinsamer horizontaler Zeile
darunter. Auf schmalen Fenstern kompakte klar begrenzte Controls statt Überlauf.
Trupp und echtes Inventar bleiben links. Doppelte kleine Schiffskarte wird im
Flugdeckmodus verborgen, bleibt in Trupp/Ausrüstung bei Bedarf erhalten.
Padwahl ist UI-Fokus auf vorhandene base_personnel.layout.landing_pads und
Craft-Zuordnung des Runtimeadapters. Leeres gebautes Pad darf angeschaut werden;
Auswahl erzeugt kein Schiff, verschiebt keine Belegung und startet kein Boarding.
Orbit-/Abwesenheitsdarstellung bleibt wahrheitsgetreu. Kein neuer Main-/EXE-
Abschluss, keine neue Flugphysik oder Basiskonstruktion in diesem Task.

## Dokumente / Dateien
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS, TASK_ROADMAP;
orbit_quantum_travel_contract, personnel_inventory_contract,
graphics_reference_revision_contract. Betroffen: homebase_operations_presenter,
explorable_homebase, neuer gezielter Verifier; nur nötige Projektion ergänzen.

## Akzeptanz / lokale Prüfung
Flugdeck vor Sternkarte, keine alte sichtbare Überschrift. Echte Pad-/Schiff-
Vorschau bei direktem Menüeinstieg und wiederholtem Wechsel (native Pixelprobe).
Drop-down für tatsächlich vorhandene Pads, gekoppelte passende Craftwahl,
leeres Pad und anwesendes/abwesendes Schiff korrekt. Pilotfeld begrenzt,
Aktionen in einer Reihe, Schiffs-Dropdown rechts bei1280/1920/3440px.
Bestehende Boarding-/Pilot-/Abflug-Gates unverändert; UI-Auswahl mutiert keine
Besetzung. Gezielte Kamera-/Weltwahl-/Inventar-/Orbitregressionen.

## Risiken / offen
Native Darstellung und Lesbarkeit per Screenshot prüfen; technische Tests
ersetzen keine menschliche Stilfreigabe. Gebäudestellung unverändert.

## Bestätigter Pilotennachtrag
Nutzer bestätigt: Pilot bleibt in FT1 und fliegt zusätzlich. Zuweisung zum
Pilotenplatz ist eine Funktion, kein Ausschluss aus Truppmitgliedschaft.
Echte Anwesenheit separat als An Bord/Nicht an Bord zeigen. Nach Ausstieg
darf er per bestehendem Drag-/Assigncommand in FT1; auch zu bereits
geboardetem FT desselben Schiffes, ohne Anja aussteigen zu lassen. Abheben
erst nach realem Wiedereinstieg des Piloten. Andere Schiffe, volle Teams,
unterwegs befindliche Personen bleiben gesperrt. Bestehende Owner behalten
Zuweisung, Payload und Positionen. Keine Doppelperson/-ladung erzeugen.

## Absetzen-Nachtrag
Nutzer bestätigt: Ausstieg funktionierte, Beschriftung unklar. Heimatbasis
nennt den bestehenden Unboard-Befehl Trupp absetzen. Am gelandeten
Kampagnenschiff dieselbe Bezeichnung und bestehende SimulationRoot-Deployeffekte
für erneutes Absetzen nach Einsteigen; Landen bleibt der separate Anflug.
Keine Absetzung unterwegs, in Vorschau oder ohne lokale Commandberechtigung.

## Abschluss / Prüfbeleg
Quellstand umgesetzt und gezielt geprüft. Ergebnisse, native Bilder und
Baselinegrenzen: docs/qa/flugdeck_basis_data_20261110/README.md.
Kein Mainmerge/EXE-Export in diesem Folgeabschluss.

## Beauftragte Mainintegration und EXE — 10.11.2026
Ziel: Task befc157a9 auf Main b92808399 integrieren und neue Windows-EXE
bereitstellen. Integrationsbranch task/flugdeck-main-exe-20261110,
konfliktfreier Merge b9c9b4b2d mit exakt gleichem Produktbaum. Keine weiteren
Produktänderungen. Frische gezielte Quell-/Nativeprüfung vor Main-Push;
Releaseexport aus sauberem Main-Commit mit dem vorhandenen Exportvertrag.
Akzeptanz: Main/Remote/Exportcommit identisch, EXE-Menüstart und native
D3D12-Einzelspieler-Startprobe ohne Enginefehler; Paket und Hashbelege.
Offene Komponenten-/Modell-/Gebäudepläne und alte vier Basistestabweichungen
bleiben wie im bestehenden QA-Bericht begrenzt. Private Testprofile;
keine alten Builds löschen und fremdes WIP nicht verändern.
