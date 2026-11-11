# Parallele Orte und freie Ansichtswechsel

## Ziel / Ursache
Nutzer will zwischen Heimatbasis, Polisa und mehreren Missionen wechseln,
Nachschub/weitere Personen senden und einkaufen, waehrend anderswo ein Trupp
weiterkaempft. Die bestehende Mehrort-Runtime ist vorhanden; Reisefokus und
globale Flotten-Heimatgates blockieren noch Ansichten und lokale Aktionen.

## Verbindliches Verhalten
- Pro Ort bleibt dieselbe registrierte Runtime mit Personen, Schiffen,
  Befehlen, Inventar, Fortschritt und Simulation aktiv. Ansicht ist Projektion.
- Verdeckte Orte laufen weiter. Kamera/Input/Rendering duerfen ruhen, keine
  Stop-/Clear-/Admission-/Resetoperation beim blossen Ansichtswechsel.
- Heimat ansehen unabhaengig vom Reise-/Kampfstatus fremder Schiffe; echte
  Abflug-, Boarding-, Kauf- und Transportgates bleiben autoritativ.
- Nachschicken nutzt vorhandene Ortsaufnahme und echte Personen-/Crew-/
  Schiffszustaendigkeit, keine Kopien oder Teleportation durch Navigation.
- Ort und Serviceschiff explizit waehlen; nur tatsaechlich anwesende Schiffe
  anbieten, jeden Command erneut gegen aktuelle Orts-/Servicegates pruefen.
- Lokale Basisaktionen nicht an die ganze zurueckgekehrte Flotte koppeln.
  Ansicht allein erteilt aber keine Gameplayberechtigung. Basisressourcen/
  Chips/Personen nur nach tatsaechlichem Runtime-Orts-/Zugangsbeleg verwenden.
- Hintergrundankunft darf fremden betrachteten Kampf nicht wegschalten.

## Umfang / Nicht-Ziele
Erster Slice: vorhandene Ansichts-/Ortsbefehle, Laden/Nachschicken und lokale
Serviceaktionen korrekt erreichbar machen. Keine neue Missionssimulation,
automatische Einkaufs-KI, allgemeine Schiffsdockingfunktion oder vorgezogene
Kartenaktivierung. Checkpoint bleibt explizit heimatgebunden; unterwegs
Speichern ist ein eigener Lifecycle-/Persistenzschritt. Grosse Tests spaeter.

## Dateibesitz / Schnittstellen
Viewagent: MetaLayerFlow, StarMapScreen, zentraler view-only Einstieg
open_location_view(location_id, craft_id), read-only get_location_view_snapshot
und reine gepruefte Serviceschiffwahl select_location_view_craft. Auswahl bleibt
UI-Zustand; _active_singleplayer_identity nicht fuer Shopwahl umschreiben.
Sandbox-Navigationszweig nur nach Abstimmung mit Tabletop.

Serviceagent: SingleplayerRuntimeAdapter, SingleplayerServicesPresenter und
PolisaStationScreen fuer explizite Orts-/Craftprojektion und lokalspezifische
Aktionsgates. Supply bleibt Bestand-/Creditowner, keine direkten neuen Mutatoren.
Tabletop besitzt Ground/Root/Driver/FoW/Actorbewegung und DoorOverrideguards.

## Vertraege / Quellen
ARCHITECTURE, singleplayer_locations_jobs_contract, inventory-/basepersonnel-
Vertraege, polisa_ship_equipment_contract, hex_tactical_runtime_contract und
RESTPLAN_FORTSETZUNG_2026_11_11. Readonly-Audit bestaetigt LocationRegistry,
verdecktes Processing, erhaltene Ortsinstanzen und bestehende Craftaufnahme.

## Akzeptanz / kleine Pruefung
Zwei geladene Ortsroots bleiben bei Home-/Starmap-/Ortswechsel dieselben und
prozessieren weiter; keine Admission-/Clearaufrufe. Hintergrundankunft erhaelt
aktuellen View. Zwei Schiffe an unterschiedlichen Orten werden nicht im
Service verwechselt; stale/airborne/pending/unknown Craftcommands abgewiesen.
Lokaler Basiszugang bei fernem Schiff erlaubt, Ferninventar/Chip nicht dadurch
freigegeben. Nur enge Headless-/Ownerchecks und Compile, kein grosses Gefecht.

## Risiken / offen
Mission-/Service-/Reisefokus muessen getrennt bleiben; Hintergrundcallbacks
duerfen den betrachteten Kontext nicht ueberschreiben. Aktionen verlangen
lokale Runtimebeweise statt bloss eine Homeansicht. Save- und echte Actor-/
Render-/Mehrort-Reiseabnahme bleiben spaeter; keine unbelegte End-to-End-Aussage.

## Begrenzter Abschluss
View-/Servicepaket gemeinsam integriert, unabhaengig reviewed und nach zwei
Korrekturen frisch eng geprueft: View44/0, Service30/0, Flow/Adapter Compile0.
Same-root Admission und terminaler versteckter Callback lesen aktuelle
Controller-/Setupdaten statt alte Planung zurueckzuschreiben. Pilotenrettung
prueft den bestehenden Erfolgsowner nichtverbrauchend. Nachweise unter
docs/qa/parallel_location_integration_20261111. Grosse Abnahme bleibt offen.
