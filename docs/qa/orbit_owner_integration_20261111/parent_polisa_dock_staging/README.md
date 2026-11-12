# Polisa: lokale Maske und vorbereitete Stationsoperationen

Parentintegration der Sourcepakete df6ffbf4a, 981d14420 und Identitaetsfix
e1559e440 als ade36387e, 8fd22ed8c und 067bd014d. Unabhaengiger enger
Review: Flightobjekt muss auch seine echte Craft-ID behalten; der Fix schliesst
die zuvor moegliche Wiederbindung eines fremden Flightobjekts.

Frische isolierte gemeinsame Godot-4.6.2-Pruefungen:

- `python scripts/tests/run_orbit_owner_integration_check.py polisa_mask`
- `python scripts/tests/run_orbit_owner_integration_check.py polisa_dock_owner`

Beide Exit 0, saubere Logs, private Canary, geladene Quellen und echtes
Spielerprofil unveraendert. Die zugehoerigen Reports enthalten die Quellhashes.
Geprueft sind die statische Stationssperrflaeche mit freiem Gate und getrennte
vorbereitete Fleet-/Traveloperationen samt Identitaets-/Revisionsgrenzen.

Grenzen: kalter Start und standardmaessig deaktivierter lokaler Automatismus.
Bereits innerhalb der Sperrflaeche befindliche Actors werden nicht migriert
oder versetzt. Kein Hot-Layoutwechsel, kein Dock-Gameplaycommit und keine
UI-Aktivierung durch dieses Paket. Live-Sternsystem bleibt V2. Keine native
Grafik-, Reise-, Gefechts- oder Leistungsabnahme; kein EXE-Build.
