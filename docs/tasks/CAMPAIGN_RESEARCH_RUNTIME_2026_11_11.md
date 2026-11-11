# Erster Runtime-Forschungszweig: Schutztechnik

## Ziel / Ursache / Basis
Nach den vorhandenen5Missionen soll Entwicklung weitergehen. Die18Knoten der
Kampagnen-Workbench sind ein Plan, kein fertiger Runtimebaum. Dieser enge Slice
uebernimmt Werkstatt/Medium/Heavy ohne neue Karten, Missionen oder Fahrzeuge.
Basis: bestehender isolierter task/native-glut-maps-20261110; UI-Hilfe0d2864468.
User verlangt autonome parallele Umsetzung, groessere Tests spaeter.

## Konkrete Folge und Balance
Echter hochgeladenerC-Chip (vorhandener bestaetigter Belohnungsbeleg fuer
outpost_chip_recovery) -> Werkstattentwicklung180Cr -> Mediumentwicklung120Cr
(zusaetzlich tatsaechlich gefertigte leichteRuestung) -> Heavyentwicklung240Cr.
Jede Entwicklung wird einmal bezahlt; keine fertige Ruestung als Gratisbelohnung.
Einzelfertigung danach separat: Medium40Cr, Heavy80Cr.180/120/240 stammen aus
Workbench-Vorschlaegen,40/80 sind erste eigene Balancewerte, keine finaleBalance.
Es gibt keine zweite Forschungswaehrung und keine Entwicklung vor dem Upload.
Die urspruenglichen drei Blueprints und deren Preise bleiben unveraendert.

## Besitz / Umfang / Nicht-Ziele
SingleplayerSupplyState besitzt Credits, Forschungsbelege und Einzelherstellung.
Die neue JSON-Datei beschreibt nur unveraenderliche Knoten/Kosten. Bestehende
Supplycommands/RuntimeAdapter binden den Schreibweg. ServicesPresenter zeigt
den Owner-Snapshot und sendet Commands. Kein State im UI, kein neuer Runtime-
Owner. Alte Checkpoints ohne Forschungsbelege starten mit leerem Forschungsstand;
neue Belege werden defensiv gegen Katalog, Requests und Voraussetzungen validiert.
KeineAenderung an5Jobs/Belohnungen, SimRoot, Ziel/Sicht/Werten, Fahrzeugmodellen.
Industrie-/Fahrzeugfortsetzung bleibt markierter Vorschlag fuer den Folge-Slice.

## Dateien / Vertraege
Neu data/singleplayer/research.json, scripts/mission/campaign_research_catalog.gd.
SupplyState, SupplyCommandContract, SingleplayerRuntimeAdapter (Campaignrouting),
SingleplayerServicesPresenter (bestehendeWerkstatt), HomebaseScreen(Allowlist).
ARCHITECTURE, campaign_introduction_contract, singleplayer_locations_jobs_contract,
CAMPAIGN_RESEARCH_WORKBENCH und CAMPAIGN_FIVE_MISSIONS_2026_11_10_PLAN gelten.

## Akzeptanz / Vorgehen
- [x] Datenknoten und reine Voraussetzungsauswertung, ohne Fahrzeuge freizuschalten.
- [x] Entwicklung autoritativ anBasis, Credits einmal, Requestreplay idempotent.
- [x] Medium/Heavy erst nachEntwicklung separat fertigen; Lagergrenzen bleiben.
- [x] Forschung persistieren/restorevalidieren; alteStaende ohneFeldweiterladen.
- [x] Werkstatt zeigt Schritte/Kosten/Sperrgruende vomSupplyowner.
- [x] EngesKompilieren + kleinerDaten-/Domaincheck (keineMissionen/Gefechte).

## Spaeter / Risiken
Voller5Missionsablauf, UI-/Klick-/Screenshotabnahme, Save/Continue im echtenFlow,
Balance inklFuel/Handel, Mehrschiffstatus und Kampagnenabschluss bleiben spaeter.
DieWorkbench bleibt eine datierte Planungsansicht; dieser uebernommene Teilzweig
wird hier als Runtime-Slice gefuehrt. Kein fertiger allgemeinerForschungsbaum,
keinMainmerge/EXE. Historische18Knoten-/QA-Daten sind keine aktuelleAbnahme.


## Enger Umsetzungsnachweis
Katalog/Supply/Adapter/ServicesPresenter/HomebaseScreen kompiliert mitGodot4.6.2
--headless --check-only: jeweilsExit0 ohneFehler/Warnungen. Kleiner isolierter
Supply-Domaincheck24/0 mit offiziellerJobdefinition als Vertrauensfixture:
Sperren vorUpload/ausserHaus,180/120/240Credits, echtesLight-Fertigungsereignis,
RequestReplay/Konflikt/Doppelklick, keinGratisItem,40/80Einzelfertigung,
JSONSave-Restore und manipulierteKosten/Voraussetzungen/Belege abgewiesen.
Der ersteProbeaufbau hatte die allgemeineSTART_STOCKbefuellung statt dem
Kampagnenstart und scheiterte deshalb2Assertions zuGratisItems/Mengen. Die
Fixture verwendet jetzt wie der echteAdapter configure_start_inventory(campaign).
Produktcode musste fuer diese2Befunde nicht veraendert werden; Log archiviert.
Dies ist KEIN echterMissionsabschluss, keine nativeWerkstatt-/Klickabnahme und
kein vollstaendigerSave/Continue-Flow. GrossePruefungen bleiben spaeter.
