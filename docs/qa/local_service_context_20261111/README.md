# Lokaler Servicekontext – begrenzter Nachweis

Arbeitsbasis task/native-glut-maps-20261110, gemeinsamer Integrationsworktree.
Kein Commit/Push durch Teilagent. Keine grossen Tests/GPU oder echte Mission.

## Ergebnis
- local_service_context_check.gd: **30 Checks, 0 Fehler**, Prozess beendet.
- Drei geaenderte Sourcefiles per Godot 4.6.2 --headless --check-only kompiliert.
- Zwei echte lokale Crafts: keine willkuerliche erste Auswahl; stale Auswahl
  wechselt nicht auf anderes Schiff. Ausserhalb Polisa kein Polisa-Service.
- Home-Service braucht registrierte Route, grounded, echten Ort und keinen Transfer.
  Polisa braucht lokalen geparkten Actor; bekannte Orbitphase sperrt stale Actor.
- Lokale Werkstatt funktioniert trotz fremdem Schiff; ungebauter/unregistrierter
  Owner sperrt. Ownerless Noncampaign behaelt den alten strikten Flottengate.
- Entfernte Schiffs-/Personenchips abgewiesen; Basis-/lokaler Anzugchip gefunden;
  Uploadcommand mit fernem Chip abgewiesen. Globaler Recoveryfinder unveraendert.
- Fabricatecommand reicht tatsaechlichen lokalen Facilityproof weiter, keine
  Supplymutation im Adapter. Kiste/Rekrut gehoeren zum konkreten Jobcraft.
- Verbrauchender echter Encounter-Resultowner wurde einmal geliefert; neuer
  Readonly-Victoryproof bleibt danach fuer exakt sein Rettungsschiff nutzbar.

## Grenzen
Fixture testet Adapterguards/Projektion und echte kleine Supply-/Encounterdaten,
mit Stub fuer gebundenen Sim-/Base-/Flowkontext. Kein gespielter UI-/Mission-/
Transport-/Kampfpfad. Checkpoint und allgemeiner Padbau bleiben konservativ
heimatgebunden; waiting_pad-Handoff bleibt eigener Restpunkt. Grossabnahme spaeter.

## Artefakte
`domain.log`, drei `*.compile.log`, `manifest.json` (SHA256 der eigenen Quellen).
Godot: C:/Users/bjoer/AppData/Local/Microsoft/WinGet/Links/godot_console.exe.
