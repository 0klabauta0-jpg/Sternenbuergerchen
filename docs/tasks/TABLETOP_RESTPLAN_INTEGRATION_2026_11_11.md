# Tabletop-Abstimmung und Restplan-Integration

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
