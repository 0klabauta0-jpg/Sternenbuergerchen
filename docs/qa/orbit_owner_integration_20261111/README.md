# Isolierte Orbitowner-Integration

Basis 3fb8d2985, gesicherter Space-Stand exakt 613a03c3c. Mergecommit
8f62183f7 erhaelt beide Eltern/Historien. Kein Import von fremdem WIP oder
799b1b025. Branch task/orbit-owner-integration-20261111 im separaten Worktree.

## Konflikte und Dateibesitz

Elf konfliktbehaftete Dateien, hunkweise aufgeloest:

- SimulationRoot: unsere can_block_hex_ground_cells-Methode erhalten; Space-
  Grundlagen additiv. Warp-/Equipment-/Base-/Polisahooks bleiben unveraendert.
- SingleplayerSpaceTravelState: gemeinsamer Flightheadingreader und optionales
  configure(craft_id) aus Space; unsere Epoch-/PreparedTravel-API erhalten.
- SingleplayerRuntimeAdapter: Spacewing-Snapshot und Spacewing-Commandroute aus
  gesichertem Space-Stand uebernommen. Keine eigenen Adapteraenderungen.
- run_hex_tactical_check.py: unsere DoorGuardcase/Abhaengigkeiten erhalten.
- .gitattributes: unsere vollstaendige Evidenzliste erhalten.
- IMPLEMENTATION_STATUS: Spaceeintraege additiv, unsere Door-/Moveintegration
  erhalten. hex_tactical_runtime_contract, hex-sight-occupancy-Plan,
  ACTIVE_WORKPLAN, RESTPLAN_FORTSETZUNG und TABLETOP_RESTPLAN_INTEGRATION:
  neuere eigene Door-/AP5-/EXE-Zustimmungen statt veralteter Gegenbranchtexte.

Ground, DoorDriver, UnitProfileMath, TestUnit, TerrainMap3DView, Supply,
Campaign und CheckpointStore sind gegen 3fb8d2985 byteidentisch. Fleet,
MetaLayerFlow, StarMapScreen und die sonstigen Spacequellen wurden automatisch
vereinigt; keine eigenen Aenderungen ausserhalb Travel und eigener Tests/Doku.
Parent arbeitet parallel an Adapter.preview_departure: beim Mergeback die
dortigen additiven Zeilen erhalten, niemals den ganzen Adapter ersetzen.

## Enger Polisa-IDfix

Echter Befund: prepare_surface_registration erstellt Travel via configure()
mit __unassigned__-Flight. initialize_surface setzte nur _craft_id und Pose.
Lokaler Fleet-/Travel-/Flightzustand widersprach sich in der Craftidentitaet.
Nun bindet initialize_surface den bestehenden Flight ohne allow_rebind vor
erstem Travel-/Posewrite. Fremde bereits gebundene Flight-ID wird geschlossen
abgelehnt; kein Ersatzflight, kein zweiter Owner, keine fingierte Heimatreise.

## Kleine frische Nachweise

Godot4.6.2, je ein privates Minimalprojekt mit tatsaechlicher GD-Abhaengigkeits-
closure und eigenem Userprofil/Canary. Keine Hauptszene, keine breite Suite.
Runner: python scripts/tests/run_orbit_owner_integration_check.py CASE.

| Case | Ergebnis |
|---|---|
| birth vor Fix | 1 bestanden / 3 fehlgeschlagen, sauberer RED |
| birth nach Fix | 4/0 |
| prepared | 15/0, existierende reine Ownerfixture unveraendert |
| root | 14/0, bestehende echte Root-/Fleet-/Travelfixture |

Alle GREENprozesse Exit0 ohne Script-/Leakfehler; kopierte Quellen und echtes
Nutzerprofil unveraendert, private Canary vorhanden. Logs und Hashreports aller
Versuche in owner_runs.zip. Ein erster Harnessstart hatte den falschen privaten
Appnamenspraefix und wurde vom Userguard abgewiesen; kein Produkt-RED, kein
Nutzerprofilzugriff. Danach sauberer 1/3-RED vor dem zweizeiligen Produktfix.

Rootfixture prueft mutationsfreie Vorbereitung, Release, Nooprequest-Kollision,
falsche Requestsignatur, echten Flight-/Travel-/Wing-/Indexcommit und Replay.
Sie ist weiterhin explizit fixtureonly, nur space_fixture_real; keine produktive
Warp-/Flight-/Saum-/Surface-/Fuel-/Campaignreise. Die Birthprobe prueft dasselbe
Flightobjekt, exakte IDs, unveraenderten Retry und atomare Ablehnung fremder IDs.
Keine Renderer-/Native-/Animation-/Performance-/Multiplayer-/Away-Savefreigabe.

## Uebergabe

Productkarten/Flags unveraendert, kein Mainmerge/Push/EXE. Root prueft den
isolierten Branch und uebernimmt selbst. Der Root-/Supply-/Campaignanschluss
bleibt bei den zustaendigen Chats. Der integrierte fremde Source beschreibt
seine weiteren Grenzen in SPACE_COMBAT_EXECUTION_2026_11_11.
