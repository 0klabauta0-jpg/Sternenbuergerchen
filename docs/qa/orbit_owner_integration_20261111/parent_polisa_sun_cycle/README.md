# Polisa und Sonne: begrenzte gemeinsame Ownerzyklen

Sourcee928a44b6 als5539844d8 integriert nach unabhaengigem Read-only-Review.
Keine Produktlogikaenderung durch dieses Testpaket. Frisch privat im Parent:
`python scripts/tests/run_orbit_owner_integration_check.py polisa_cycle`
und `... sun_cycle`, beide Exit0, saubere Logs, source/profile/canary true.

Polisa verbindet echte Fleet/Flight/Equipment/Supply/Campaign/Rootuebergaenge:
Root-Warpeintritt Glut2, lokale Moveabsicht, Dockgate, oeffentlicher Dockadapter,
Cancel/Wiederanflug, Visitphase/Undock, Root-Warp zum Mond und Heimatlandung.
Harnessgrenzen: Flightpose samt Index bewusst6/7Felder vor Gates versetzt, danach
nur kurze echte Move-/60Hz-Strecke. Pilot, Visit und Flow bleiben Fixtures;
finish_approach ist trustedDomaincommand, Homecallback nur kontrollierter Zaehler.
Also kein durchgehender Flug oder tatsaechlicher AP6-/Crew-/UI-/Nativebeweis.

Sun baut Produkt-V3 in der neu angelegten privaten Projekt-/Datenkopie. Nur deren
project.godot setzt space_reader_probe/isolated=true. Echter Reader und Root
pruefen lokalen Warpeintritt Sonne, Ablehnung einer Sonnenoberflaeche und
Warpabflug. Live-Sternkatalog weiterhinV2; Original-JSONhash im Report erfasst
und nach Test gegen Originaldatei bestaetigt. Isolationsflag niemals im echten
Projekt setzen. Keine Flag-/Liveumschaltung und kein EXE-Build.

Nachfolgende flaggebundene Adapterumschaltung069 ist durch diese Reports nicht
geprueft; deren oeffentliche Kauf-Replayroute ist noch im Source-Reviewfix.
