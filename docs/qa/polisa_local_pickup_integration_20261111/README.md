# Polisa: begrenzte gemeinsame Abholintegration

Basis b67b307b0, keine Main-/EXE-Integration. Frische gemeinsame Laeufe:
- Aktuelle Return-Vertikalprobe18/0: echte Flow/Adapter/Root/Supply/Travel/Equipment/BasePersonnel/
  Tacticalpfade und echte R08Map/Registry/Modellprojektion. Sourcebesuch und
  Ownerbootstrap sind kontrollierter Aufbau; Actors sind Doubles. Kauf/Handoff/
  Servicebelege werden nicht durch Fakeerfolg ersetzt. Echter Legacy-Effectcommit
  bestaetigt genau den Piloten an Bord; Adapter-Rueckflug, expliziter Surfaceexit/
  Retirementendpunkt, Warp und HomeLanding ergeben Pilot zuhause/Operatoren remote.
  **Grenze explicit_lifecycle_endpoints**: Fixture platziert beim Boarding bewusst
  am Pad und ruft Animationsendpunkte explizit auf. Keine echte Weg-/Animations-
  oder automatisch ausgespielte Gesamtreise nachgewiesen. Aeltere10/0-Queued-
  und14/0-Effectproben sind historische Zwischenbelege, nicht aktuelle Abnahme.
- Flowprobe23/0: eigener leerer Visit, getrennte parallele Teamarrays, globale
  Pilot-/BasePersonnelbindung, fremder View/Job, Reject/Replay, historischer
  Homepilot im echten Planningcallback; ownerloser Kauf nicht angeboten. Tactical
  ist dort gezielter Double.
- Backend43/0: echte Wallet/Stock/Travel-/Equipment-/CheckpointStorepfade,
  einschliesslich Surfacebirth, Rueckflugfuel, Route und altem/neuem Heimatbeleg.
  Flow/Tactical sind dort Admission-/Crewdoubles; Heimatpayload ist konstruiert,
  kein durchgespielter Save/Continue-Nachweis.
- Root-eigene Flow/BasePersonnel-Dateien check-only Exit0 ohne Scriptfehler.

Teilbelege Helper27/0 und Controller26/0 sowie Sourcecompiles stehen unter
output/native_glut_maps/polisa_local_pickup_20261111. Backendbelege/Manifest unter
docs/qa/polisa_local_pickup_backend_20261111. Keine alte grosse Matrix wiederholt.

Unabhaengiger Gesamtreview und gezielte Deltareviews: Historische Ready-Karten
duerfen weder Pilotbesitz vortaeuschen noch ihn zurueck ins globale Mapping
schreiben. Neue Stationsschiffe duerfen ohne eigenen Visit keine Legacycrew
erben. Campaignmarker fehlt in Skirmish; lokale Erwerbsherkunft/Stationspad
erzwingen trotzdem echte Pilot-/Boardingguards. Gefundene Luecken korrigiert,
finale enge Reviews ohne weiteren Blocker. BasePersonnelremoteBinding wird
emitfrei mit Visits/globalen Piloten umgeschrieben, damit Heimkehr wirklich
dem neuen Schiff folgt. Verbliebene Fireteamplaene bleiben beim Pilotabflug.

Lokaler Kauf reserviert weiterhin ein gebautes freies Heimatpad. Kauf startet
unbemannt; echte abgesetzte Personen werden ausdruecklich uebernommen und
muessen zum Zielschiff laufen/einsteigen. Neue Modelle, Away-Saves und neue
Kartenaktivierung bleiben ausserhalb. Native Gesamtbedienung, Geh-/Fluganimation,
automatisch ausgeloeste Heimkehr/Save/Continue und Gefechts-/Performanceabnahme spaeter.
Der Tabletop-Chat behielt Move/Root/Ground/Actor-/Doorbesitz; sein naechster
gesicherter Bewegungscommit stand bei dieser Abholpruefung noch aus.
