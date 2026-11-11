# Polisa-Abholung: begrenzter Backendnachweis

Baseline b67b307b0, gemeinsamer Integrationsworktree. Teilagent verändert nur Supply,
SpaceTravel/FleetTravel, RuntimeAdapter und PolisaScreen sowie eigene Fixtures/Doku.
Flow-/Tactical-/BasePersonnel-/Padhelper kommen von anderen koordinierten Ownern.
Kein Commit/Push, keine GPU/native Bedienung/Gefechts- oder breite Testmatrix.

## Ergebnis
scripts/tests/polisa_local_pickup_backend_check.gd43/0, Exit0 ohne Script-/Engine-
fehler/Leaks. Echte Supply/SimulationRoot/Equipment/Travel/Adapterowner. Nur lokale
Aufnahme und Crewcallbacks benutzen ausdrücklich SetupFlow/Tacticalstubs; echte
geparkte Actor-/Crew-/Presence-/Paddurchführung wird im gemeinsamen Paket geprüft.

- Surfacecandidate bleibt vor Publish unsichtbar, UI/trust/Ort/Konflikt/Tampering
  abgewiesen. Neue stationäre Surfaceidentität ohne Start vom Mond, Fokus bleibt.
- Geld/Stock/Staleintent, fehlendes Heimatpad, volles/invalides Stationspad und
  finaler Admissionreject lassen sämtliche betroffenen Owner unverändert.
- Echter850Cr-Kauf, begrenzter Stock, echte Craftcontainer/Fuel/Equipmentregistrierung,
  normalisierte Kapazität und getrenntes Erwerbs-/Heimatrückkehrpad genau einmal.
  Postcommitfinalisierung erst wenn echter Supplyreceipt existiert.
- Replay keine zweite Welt-/Credit-/Padmutation, delivery-mode-Konflikt abgewiesen.
- Unbemannt kein Return, nach explizitem Pilotguard echter10Fuel-Return via
  Kaufbeleg einmal. Kein gefälschter Heimat-Outboundtoken/Fremdjob.
- Derselbe echte Reiseowner verlässt Oberfläche zum polisa_orbit, springt zum
  Mondorbit und landet regulär zuhause. Kein neuer Reise-/Warpmechanismus.
- JSON-Supplyrestore für lokalen schema2 und alte2Arg-Heimatlieferung; manipulierte
  Origin-/Pad-/Version-/Bodyfitfelder abgewiesen. Echter Checkpointvalidator liest
  vollständiges konstruiertes Heimatpayload und prüft Fleetmodel gegen Kaufbeleg.
  Dies ist keine echte Mehrort-Save-Continuation: vorhandener Besucher bleibt in
  dieser kleinen Fixture weg, Guardprüfung sperrt solche Runtime-Exports weiterhin.
- Exact source/target/crew/pilot/boarding-Routing geprüft; kein eigener Actorzustand
  im Adapter oder UI. Native Entfernung/Boarding/Belegungsabnahme bleibt später.
- Fünf geänderte Sources --headless --check-only Exit0. diff --check ohne Fehler.

initial_orbit_expectation.log bewahrt den ersten29/1-Lauf mit falscher Fixture-
Erwartung planet_orbit; echte Produktdaten verlangen polisa_orbit. Finale Erwartung
wurde korrigiert. Späterer vorübergehender Fixture-Setupfehler (fehlendes Basislager
vor configure_preset_supply) wurde vor finalem43/0 korrigiert, nicht als grün gewertet.

## Verhalten / Grenze
Heimatlieferung bleibt Default und Kaufwahl. Localoption erst wenn echte Flow/
Controllercapability vorhanden ist. Local startet unbemannt, reserviert weiterhin
gebautes freies Heimatpad. Crew wird explizit über vorhandene Owner übernommen;
Menü enthält echtes Absetzen/Übernehmen/Einsteigen/Rückflug, keine Teleportation.
Supplyreceipt trägt schema2/pad_fit_revision1; Erwerbspad ist Historie statt ewige
Belegungswahrheit. Checkpoint weiterhin nurHome, keine Away-Persistenzfreigabe.

Root führt abschließenden unabhängigen Gesamtreview/Callbackintegration separat.
