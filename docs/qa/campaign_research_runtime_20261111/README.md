# Schutztechnik: erster Runtime-Forschungszweig

Kandidat im bestehenden isoliertenTaskbranch; keinMain-/EXE- oderBalance-PASS.
Auftrag: Forschung/Kampagnenfortsetzung parallel weiterfuehren, groessereTests
spaeter. GemeinsamerSupplyOwner bleibt Wahrheit. Neue3Knoten inresearch.json:
C-Chip wirklich hochgeladen -> Werkstatt180Cr -> Medium120Cr nach tatsaechlich
gefertigterLight -> Heavy240Cr. EntsperrteMedium/Heavy danach je40/80Crfertigen.
Die Werte sind Workbench-/ersteBalancevorschlaege. KeineFahrzeuge/Rohstoff-
verarbeitungs- oderneueMissionsfunktion wird damit als spielbereit ausgegeben.

Bestehende5Jobs undBelohnungen bleiben unveraendert. Keine neueWaehrung, keine
Aenderung anCharakter-/Combatwerten. Forschung ist eine Faehigkeit der bereits
vorhandenenWerkstatt, kein neuesGebaeude-/Kollisionsmodell. Voraussetzungen
lesen bestehende bestaetigteSupplyReward-/Fertigungsbelege. UI liest denselben
Supplysnapshot undsendet campaign_research. Kosten werden einmal gebucht;
Herstellung nutzt weiterhin endlichesBasislager.

## Nur enge Pruefung
-5check-only Programme (Katalog/Supply/RuntimeAdapter/ServicesPresenter/
 HomebaseScreen) exit0, ohneScript-/Enginefehler/Warnungen.
- KleinerSupply-Domaincheck24/0. TrustedFixtures nutzen die unveraenderten
 offiziellenJobdefinitionen, kein echterMissionsflug und keinClaim eines
 tatsaechlichhiergespielten C-Uploads.
- JSONSave-Restore erhaeltBelege; Altstand ohneForschungsfeld laedt leer.
 ManipulierteKosten,fehlendeVorentwicklung/Fertigungsbelege undfehlendesLedger
 mitbestehendenForschungsrequests werden vorMutationabgewiesen.
- RevisionbasierterSnapshotcache vermeidet erneuteRequestlog-Auswertung bei
 unveraendertemSupplyState. KeinPerformancebenchmarkbehauptet.
- diff--check ohneBefund. KeineweiterenSuites/Renderer/Gefechte gestartet.

DieinitialeProbe vergass configure_start_inventory(campaign) und hatte
allgemeinenSTART_STOCK. ZweiMengenchecks scheiterten; die korrekteKampagnen-
fixture besteht. domain_fixture_initial.log bleibt alsDiagnose erhalten.

## Offen
NativeWerkstattklicks/Layout/Erklaerbarkeit, echter5Missionen- undCheckpoint-
Weiterlauf, Preis-/Fuel-/Handelsbalance, volleRegressionspruefung. Die18Knoten-
HTMLWorkbench ist die datiertePlanungsansicht; hier ist nur der3Knoten-
Schutztechnikteil uebernommen. Industrie-/Fahrzeug-/Flottenauftraege bleiben
Vorschlaege bzwzurueckgestellteModelle. KeinWebhosting, keinallgemeinerfertiger
Forschungsbaum. KeineSource-/QA-Tests ausanderenparallelenTeilpaketen enthalten.
