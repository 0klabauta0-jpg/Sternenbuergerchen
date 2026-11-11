# Tabletop-Abstimmung und Restplan-Integration

## Lokaler Türschutz integriert

e4c098f63 nach unabhängigem Review als 26303641d auf ce57b07f7 übernommen.
Produkt automatisch zusammengeführt; additive Statusdokumentation beidseitig
erhalten. Frischer enger gemeinsamer DoorGuard58/0 einschließlich 42 Grundchecks,
Quell-/Profil-/Canaryguards grün. Beleg: QA-Unterordner `door_guard`.
Kein MP-/Szenariorebuildnachweis. Noch offen: AP5 Backoff, AP6 Aufnahme/Freigabe,
AP7 Restore/Authority, AP8 kleiner Kandidat. AP9 große Tests später. Nutzer verlangt
vor nächstem EXE-Build ausdrücklich eine Nachfrage; bis dahin weitere APs umsetzen.

## Bewegungsschuss nach Konsumentenanschluss

a74fbab2f nach unabhängigem Review als 615327eaf auf 698188f64 integriert.
Frischer enger gemeinsamer MovingShotlauf 65/0 inklusive 42 Grundchecks,
Profil-/Canary-/Sourceguards grün. Nur additive Statusdokumentation konfliktbehaftet.
Belege: `docs/qa/tabletop_restplan_integration_20261111/moving_shot/`.
Vorläufiger Faktor 0.65..0.95 ist keine Balancefreigabe; weniger Profilreads sind
keine gemessene Performanceverbesserung. Keine Karte aktiviert, große Tests später.
Driver `_refresh_mission_interaction_door_runtime_overrides` und entsprechender
autoritativer Runtimeeventanschluss sind für den nächsten Tabletop-Türguard frei;
der zweite genannte Handlername existiert hier bisher nicht. Kein breiterer
Driver-/Sandbox-/Polisa-/Orbitbesitz daraus. Noch offen: Türguard, Backoff, AP6–8.

## Neuester AP5-Anschluss: Gruppen und 3D-View

5a8544fea nach unabhängigem Review als 6a3f9c535 auf 9874511c4 integriert.
Logische Gruppenankunft und Formationsanker lesen denselben Ortsroot;
View übernimmt stetige Höhe, Phase und committete Richtung ohne zweite Glättung.
Nur additive Statusdokumentation konfliktbehaftet, beide Abschnitte erhalten.
Frischer isolierter gemeinsamer Consumerlauf 65/0 einschließlich 42 Grundchecks;
Profil-/Canary-/Sourceguards grün. Keine native Darstellung oder aktive Karte.
QA: `docs/qa/tabletop_restplan_integration_20261111/move_consumers/`.
Noch offen: Türguard, Bewegungsschuss, Backoff, AP6–8 und spätere große Abnahme.

## Aktueller Stand nach Polisa-Freigabe
AP1-3, Facing/Sicherung und AP4-Owner samt Sparse-Grantfix sind integriert.
Vollstaendiger Korridorcache04dc691bb wurde nach unabhaengigem Review als
f4353eed4 konfliktfrei uebernommen. Root/Ground/Resolver frisch check-only0;
keine erneute grosse Matrix. Naechster aktiver Schritt liegt im Tabletop-Chat:
AP5-Commands und Bewegungsprojektion mit vorhandenen Tempo-/Accuracygettern,
danach AP6-8-Lifecycle-/Save-/Netzgrenzen. Keine Kartenaktivierung daraus.
Die folgenden Abschnitte sind die historische Fortschreibung.

## Ziel und Ursache
Der Nutzer beauftragt am 11.11.2026 die selbststaendige Fortsetzung, Abstimmung und Zusammenfuehrung der Tabletop-Aenderungen. Grosse Tests werden spaeter gebuendelt. Gesicherte Pakete werden integriert; unfertige aktive Gameplay-Anschluesse werden nicht als abgeschlossen markiert.

## Arbeitsbasis
Isolierter Worktree native-glut-maps-20261110, Taskbranch auf c8c7b7d3b. Kein Main-/EXE-Schritt. Foundation bereits in 22dc4cb61/0bc338151 integriert. AP1-Quelle: 814faabac aus dem Tabletop-Chat, direkte Folge der Foundation. AP3 ist dort in Arbeit.

## Umfang / Nicht-Ziele
- AP1 und anschliessend kohaerente gesicherte AP3-Pakete nach engem unabhaengigem Review zusammenfuehren.
- Rampen H+0.5, Mapversion 3, A/B/C 512x256, Sternkarte 256x256 und Editor erhalten.
- Unabhaengige Forschungsfortsetzung auf vorhandenen Rezept-/Supply-Ownern sowie konkrete Polisa-Restpunkte bearbeiten.
- Keine vorzeitige Kartenaktivierung, keine neue UI-Gameplay-Wahrheit, keine Fahrzeugmodelle, keine grossen Gefechts-/FPS-/Save-Matrizen.

## Vertraege und betroffene Dateien
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, explicit_hex_ramps_contract, hex_tactical_runtime_contract, ACTIVE_WORKPLAN_2026_11_11; gesicherte Tabletop-Task-/QA-Dateien. AP1: simulation_root.gd, terrain_map_data.gd und zugehoerige kleine Verifier. Weitere Dateien nur nach konkreter Paketabstimmung. Forschung und Polisa erhalten eigene enge Tasks.

## Akzeptanz und Pruefung
- Nur gesicherte Commits; kein fremder uncommitteter WIP.
- Code-/Datenkonflikte fachlich aufloesen, anschliessend enges Compile und erforderlichenfalls kleine Vertragsprobe.
- Bestehende Legacykarten bleiben unveraendert; kein stilles taktisches Versionsflag.
- Status unterscheidet implementierte Grundlagen, aktive Verbraucher und spaetere Abnahme.
- Selektive Commits und Push; verbleibende Risiken dokumentieren.

## Risiken / offen
Aktivierung braucht erst konsistente Owner, Sicht-/Schuss-/FoW-Verbraucher, Facing/Overwatch, Belegung/Reservierung und Lifecycle. Eine kleine Vertragsprobe belegt keine fluessigen Gefechte oder Save-/Netzspielabnahme. Schiffswaffen und lokale Stationsabholung benoetigen echte vorhandene oder eng abgegrenzte Runtime-Owner.

## Gesicherte Integration
AP1 814faabac nach unabhaengigem statischem Review konfliktfrei als 7b532a316 uebernommen. SimulationRoot und TerrainMapData im gemeinsamen Stand check-only Exit0. Die frueheren 39/0 sind AP1-Quellbelege, keine erneut ausgefuehrte Integrationsmatrix. Version3 bleibt erhalten; kein Kartenfile aktiviert. Nachweise docs/qa/tabletop_restplan_integration_20261111.

AP3-Reader 2a0ffeef8 nach unabhaengigem Review konfliktfrei als 2ff978d1a uebernommen. Driver/Setup im gemeinsamen Stand jeweils Compile0; keine erneute Consumer-/Gefechtmatrix. Neue Karten bleiben inaktiv. Sicherung/Facing/Overwatch und AP4-8 werden abgestimmt weiterbearbeitet.

Restpakete integriert: Bergungswerkzeug-Forschung 1f676bfbc (kleine Industrie22/0, Schutz24/0), Polisa-Tank-/Frachtservice538eb737e (kleine11/0), Workbench-Baseline ba4135069 (27 statische Datenpruefungen, kein neuer Browsertest). Sourcechecks ersetzen keine native Gesamtbedienung. Schiffswaffen/-komponenten und lokale Stationsabholung bleiben ausdruecklich offen.


## Fortsetzung: Blickrichtung, Sicherung und Bewegung
Erneuter Nutzerauftrag: die naechsten fertigen Schritte selbststaendig abstimmen und zusammenfuehren; grosse Tests bleiben spaeter. Tabletop bearbeitet Facingqueue/Ownercommit und Sicherung/Overwatch/Flank-Adapter. Ein unabhaengiger reiner AP4-Planer ist an einen Agenten delegiert: ausschliesslich bottleneck_reservation_resolver.gd (neuer build_hex_plan-Pfad, Legacy erhalten), neuer hex_reservation_verifier.gd sowie eigene Task/QA/neuer hex_reservation_plan_contract.md. GroundOwner, SimulationRoot, Driver, Runner und aktive Bewegung bleiben im Tabletop-Chat. Snapshot-/Segmentgrenzen werden vor Code abgestimmt; Handoff erfolgt wie in der bestehenden Spec in der Segmentmitte, nicht erst bei Bewegungsende. Zusagen und Commit sind Owneraufgabe.

## Fortschreibung AP4/AP5 und Ortsansichten
Facing/Sicherung b3d5f4b62, AP4-Owner c69269578 mit SparseGrantkorrektur8eabf50cd und vollstaendiger Korridorcache f4353eed4 sind integriert. AP5-Readprojektion3095c11b0 und Stop-/Zentrierkernfd8ed553a wurden unabhaengig geprueft und Root/Ground frisch kompiliert. Keine Aktivierung von Actorcommands oder Karten. Enge Integrationsbelege jeweils in docs/qa/tabletop_restplan_integration_20261111.

Neue Nutzeranforderung parallele Ortsansichten abgestimmt: kein Stop/Clear/Configure/Admission durch Ansichtswechsel; Root/Ground/Registry/Actor und Dooroverrideguards bleiben im Tabletop-Chat. Root bearbeitet Flow/Serviceprojektion sowie ausdruecklich freigegebenen Sandbox-homebase-Navigationszweig. Bewegungsabzug pro Schuss wird dort spaeter aus kanonischem Profilbundle abgestimmt, ohne neue Rootformel hier. Grosse Tests weiterhin spaeter.

## Echte AP5-Commands/2DActor und Polisa-Abholung
Abholpaket d539cbe89 gesichert (eigenes Vertrags-/QA-Paket). Anschliessend fertigen
Quellcommit a66b84522 nach unabhaengigem Review als c5e536d0d integriert; nur
additive Evidenzattrs konfliktbehaftet, beide Seiten erhalten. Rootwarphooks
und freigegebene Ship-/Crewbereiche blieben bestehen. ActualMove42/0 frisch im
isolierten gemeinsamen Quellstand, Profilguard/Canary/Sourceguard gruen. Eigene
Polisa-Ownerheimkehr18/0 nach Rootzusammenfuehrung erneut gruen; Root/neuerRuntime
check-only0. Kleine CapabilityActor-/2D-/Ownernachweise, keine Produktionskarte
aktiviert. Noch offen:3DView/Fireteamankunft/Tuerguard/MovingShot/Backoff sowie
AP6–8; grosseTests/Main/EXE weiter spaeter. QA actual_move.
