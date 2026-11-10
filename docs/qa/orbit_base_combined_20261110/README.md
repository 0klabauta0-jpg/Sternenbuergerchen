# Gemeinsame Orbit-/Basis-/Charakterintegration

Grundlage: fertiger anderer Chat, Main43b1f153b14d59e4299e94fe0bb4d26eb48e5e05,
und eigener Orbit-/Charakterstand0f2425aa7 (Produkt03807239a). Separater
Integrationsbranch `task/orbit-base-integration-20261110`; fremde WIP erhalten.
Auftrag/Naehte: `docs/tasks/ORBIT_BASE_INTEGRATION_2026_11_10.md`.

## Gemeinsame Grenzen

- Mondabflug prueft tatsaechliche Pilotanwesenheit. Zugewiesener, wieder
  ausgestiegener Pilot trotz gueltigem Trupppayload sperrt ohne Nebenwirkung.
- Basisaktionen und Checkpointexport verlangen grounded; Orbit ist keine Basis.
- Padpreview besitzt die geteilte Simulation nicht. Ansichts-/Keyboardwechsel
  loeschen keine angeforderten Personalwege; optionales Modell ist erlaubt.
- Reparaturmetadaten versetzen entfernte Schiffe nicht nach Hause. Remote
  Reparaturzeit pausiert; terminaler Personalausfall bietet ausdruecklich den
  letzten sicheren Checkpoint an. Deutscher Debrief behaelt Folge und Dauer.

## Gezielte RED/GREEN-Belege

Alle nachfolgenden Pfade liegen unter
`../orbit_quantum_20261109/raw/`; Prozesse headless, CreateNoWindow,
BelowNormal und private APPDATA-Profile.

| Grenze | RED | GREEN |
|---|---|---|
| Physischer Pilot am neuen Mondstart | combined-launch-red:6/2 | combined-launch-green:35/0, Start-/Hilfeflaeche42/0 |
| Basiszustand in Orbit/Quantum/Abbruch | integration-base-valid-red:16 erwartete Fehler | integration-base-green:65/0 |
| Shared-Sim-/Nullmodell-Padvorschau | 4 erwartete Assertions und2 Nullfehler | integration-base-green:37/0; Weltbedienung9/0 |
| Drei echte Orbit-Hinreisen mit Crewverlust, davon ein beschaedigtes Schiff | integration-casualty-red:152/4 | integration-casualty-green:159/0, inklusive10000s-Recoveryadvance |
| Deutsche Verlustfolge und Ersatzdauer sichtbar | combined-domain-recovery-red:34/2 | combined-recovery-copy-green:36/0 |
| Unvollstaendige Vorbereitung fortsetzen | vorhandene Kampagnenregression | integration-preparation:13/0 |

Kamera, Sternkartenaktionen, Anflug-/Auswahl-/Fuelgrenzen, Namens-/Portrait-
Zuordnung, grosser Bogen, kompakter Bogen und Kampagneneinstieg in
`combined-final-matrix/` bestanden. Die Domain liegt zusaetzlich mit67/0 unter
`combined-domain-recovery-red/space_travel_state_verifier.log`; die erste
Matrix enthielt einen abgelehnten falschen Skriptdateinamen, keinen Produkttest.

## Bestehender unabhaengiger Befund

TASK503:9/1 auf unveraendertem Main43b1f153b und hier gleich. Fehlassertion:
`Selected embarked FT1 has only read-only roster cards and no ground operators`.
Test/Missionsszene und acht beteiligte UI-/Controllerquellen bytegleich;
SimulationRoot unterscheidet sich erwartungsgemaess durch Reiserouten.
Beleg `integration-task503-baseline/{results.json,source_parity.json}`.
Keine allgemeine Gesamttestbestandsfreigabe daraus ableiten.

## Abgeschlossene Rundfluege und Review

- `integration-pilot-flow-owned-services/`:152/0, beide wirklichen Ausfluege,
  alternativer Pilot, beide Personen am Boden/Embark, beide Continue-Meilensteine.
- `integration-skirmish-flow-owned-services/`:105/0, beide ganzen Rundfluege,
  bestehende Skirmish-Personen/Loadouts, Fuel, Kauf und Belohnungsreplay erhalten.

Beide pruefen das tatsaechliche Flow-Panel
`SingleplayerServiceLayer/MissionServices`, seine sichtbaren freigegebenen
Aktionen und den echten Rueckflugklick. Die Anzeige wird nach Embark hoechstens
2s ueber ihren regulaeren0,25s-Refresh abgewartet; kein manueller Refresh oder
Commandbypass. Der alte isolierte Panel-Pruefpfad lieferte123/1; der Diagnose-
Dump bestaetigte jedoch schon gueltigen Ownerkontext/Pilot/Pad. Ein vermuteter
Ownerfehler wurde deshalb nicht implementiert. Die staerkere echte UI-Probe
besteht. Unabhaengige Gegenpruefung der Runtime-/Recovery-/UI- und Testadapter-
Aenderungen ohne verbleibenden konkreten Befund.

`source_checks.json` fasst nur die abgeschlossenen gueltigen GREEN-Belege
zusammen; bekannte Baseline und verworfene/RED-Aufrufe bleiben hier benannt.
`SOURCE_MANIFEST.json` bindet die geaenderten Produkt-/Harnessquellen an diesen
Pruefstand (Text UTF8/BOM entfernt, CRLF zu LF; Binaerdateien unveraendert).
Erst nach gemeinsamem Mainpush folgt der Export aus exakt diesem sauberen Stand.
Build-/Remote-/EXE-Abschlussbeleg wird beim neuen Paket abgelegt:
`C:/dev/SternenBuergerchen-builds/2026-11-10-orbit-base-main-r01/PRUEFBERICHT.md`.

Keine nativen Fenster/Fokuswechsel; keine subjektive Gestaltungs-, breite
Performance- oder neue Multiplayerabnahme behauptet. Kleine Portraitkarten
bleiben erhalten; gespeicherte eigene Identitaeten werden nicht umgedeutet.
