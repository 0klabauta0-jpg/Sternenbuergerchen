# Heimat-/Stationslifecycle im gemeinsamen Stand

Source605291c05 erst mit Operationsfix ed57b2266 und echtem Nichtkampagnen-
Pilotguardfix a9a2d0857 sowie Testnachtrag9773a72cc integriert. Elternstand
9c293ac8d, davor Polisa-Profilowner244a7354a. Enge unabhaengige Reviews der
Owner-, Adapter- und Guardteile; bekannte Fehler vor Integrationspass geschlossen.

Frische private gemeinsame Proben: warp_cycle, home_launch und regular_polisa_pilot
bestanden. Alle drei Logs sauber, Quellen und echtes Spielerprofil unveraendert,
private Canary vorhanden. Berichte enthalten die genauen Quellhashes.
Heimat-/Warpownerzyklen verwenden kleine Pilot-/Flowdoubles; die separate
Pilotenprobe verwendet die echte Controllermethode mit kontrollierten Personen,
Visit- und Sequenceinputs. Keine native Boarding-/Reiseabnahme.

Neue Singletonrotte beim bestaetigten Heimat-/Stationsstart; fehlende Rotten
bestehender fliegender Schiffe ueber gebundenen Reconcile. Polisa behaelt den
strategischen Stationspfad, keine Planetenoberflaechenaliasse. Explizite lokale
Heimatlandung verlangt echtes Pilot-/Pad-/Mondgate und ganzen Footprint.

Pruefrunnerkorrektur, kein Produktfix: Die neue echte Controller-Unterklasse
brauchte quoted extends sowie nicht-GD Ressourcen in der privaten Kopie.
Bekannter vorhandener Ressourcensammler und externe Station-GLB-Farbtextur wurden
uebernommen. Fruehe fehlgeschlagene Kopier-/Importlaeufe sind im ZIP erhalten;
zusaetzlich wurde ein kopierter Verzeichnispfad vor dem finalen Lauf ausgeschlossen.
Keiner dieser Versuche zaehlt als gruener Produktpass.

Automatischer lokaler Warptick bleibt standardmaessig AUS. Offener Retryrand
(Fehler bei grossem Abschlusstick, kleinerer Folgetick) wird mit Source61af7ec9a
separat nachgeprueft. Kein Live-V3-Switch. Polisa-Profilowner benoetigt noch
AP6c-Bindungsproducer fuer regulaere Besucher, auch im alten Kaufpfad. Keine EXE.
