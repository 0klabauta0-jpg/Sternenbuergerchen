# Begrenzte Orbit-Bewegungsintegration

Gepruefter gemeinsamer Stand: a87246495. Quellen bis 00098ed5d sind integriert;
dieser Nachweis betrifft noch nicht die anschliessende produktive Reisegruppe.

- `run_orbit_owner_integration_check.py move`: bestanden, sauberer Godot-Log.
- `run_orbit_owner_integration_check.py reactivation`: 15 bestanden, 0 Fehler.
- Beide Laeufe verwenden ein privates Projekt und Nutzerverzeichnis. Quellhashes,
  echtes Nutzerprofil und Isolation-Canary sind in beiden Reports unveraendert bzw.
  bestaetigt. Die Reports enthalten die jeweils tatsaechlich geprueften Quelldateien.

Belegt sind autoritative Einzelspieler-Raumbewegung und die schmale reale
Travel-/Flight-Reaktivierung. Keine native Boarding-, Gefechts-, FPS-, Save-,
Netz- oder Gesamtreiseabnahme. Strategischer Livekatalog bleibt V2; der V3-Entwurf
und OrbitAreaCanvas sind noch nicht in den Produktbildschirm geschaltet.
AP6 bis AP8 laufen weiter. Keine EXE, keine Main-Integration.
