# Gemeinsame Orbitkarten: Integrationsschritte

## Ziel / Ursache

Ein breiter, räumlich blockierbarer Orbitbereich pro Himmelskörper ersetzt drei
separate Marker. Der Planet wirkt groß, obwohl nur ein flacher Rand sichtbar ist.
Alle fliegenden Schiffe einschließlich Dropships verwenden den Rottenowner des
Weltraumkampf-Chats.

## Umfang / Nicht-Ziele

Lokale Karte 512 × 256, Ankunft unten, mittiger Körpersaum oben 256 breit und
höchstens vier tief. Strategische Karte unverändert 256 × 256. Kein zweiter
Flugowner, kein neues Kampfsystem, kein Away-Save und keine große Testmatrix.

## Verträge / Quellen

- `docs/dev/orbital_approach_contract.md` (neues verbindliches Ziel)
- `docs/dev/orbit_approach_layout_contract.md` (reiner Geometriekandidat)
- `docs/dev/orbit_quantum_travel_contract.md` (bisheriger Produktstand)
- `docs/tasks/ORBIT_BODYMAP_INTERFACE_AUDIT_2026_11_11.md`
- Weltraumkampf-Chat: `SPACE_ORBIT_WING_HANDOFF_2026_11_11.md`, Commit aa9177433

## Schritte / Akzeptanz

1. Reinen Geometriedescriptor mit stabiler Körperbereichs-ID, Bounds, Eintrittsband,
   Körpermaske und erreichbarem Saum erstellen. Kleine Geometrieprüfung genügt.
2. Mit dem Weltraumkampf-Chat Bereich/Koordinaten, atomaren Rootübergang und
   revisionsgesicherte Saumfreigabe abstimmen. Er besitzt kanonische Flight-/
   Rottenänderungen; dieser Chat besitzt Layout und anschließende Kartenintegration.
3. Gesicherte Owneränderungen integrieren. Sämtliche lokalen 256er-Grenzen und
   Belegungsindizes auf gebietsspezifische Definitionen umstellen; strategische
   Normierung getrennt halten. Zwei Gebiete mit gleichen Zellkoordinaten trennen.
4. Warp-/Oberflächenübergänge, Pflichtrotte und Eintritt atomar verbinden. Saumgate
   vor erstem Debit prüfen. Voll belegte Ankunft und veraltete Revision ablehnen.
5. Ein Orbitziel pro Körper samt Sternorbit, Migration alter Marker-IDs, Liste,
   Kartenklick und lokale Ansicht gemeinsam umschalten. Vorher kein halber Switch.
6. Kleine Owner-/Gateprüfung; große native Gefechts-, Performance-, Save- und
   Mehrspielerprüfungen ausdrücklich später.

## Betroffene Dateien

Zunächst `scripts/mission/orbit_approach_layout.gd` und diese Verträge/Notizen.
Später abgestimmt SpaceFlightState, SpaceWingState, SimulationRoot, Bereichsindex,
Reiseowner, Körperdaten/Validator und Orbitkartenprojektion. Kein fremdes WIP ändern.

## Lokale Prüfung / Status

Schnittstellenaudit abgeschlossen. Layoutkandidat und kleine Geometrieprüfung in
Arbeit. Noch keine neue produktive Orbitreise, Rotteintegration oder Blockadeabnahme.

Abstimmung bestätigt (Weltraumkampf-Chat, a6dffd0e2): Dort liegen Flightbereich,
gebietsspezifische Registry/Navigation/Commands/Footprints und Roottransition.
Hier liegen Layout, Orbitvertrag, Ansicht und nach gesichertem Import Reisegate
und Migration. Vereinbarter Entwurf:
`prepare_space_area_transition(craft_id, area_id, target_pose,
expected_flight_revision, expected_travel_revision, authority_context)` und
`commit_space_area_transition(transition_token, authority_context)`.
Prepare bleibt mutationsfrei; Commit revalidiert und veröffentlicht atomar.
Konkreter Travel-Prepare/Commit-Anschluss samt Rücktritt bleibt gemeinsam
festzulegen, bevor diese gemeinsamen Produktdateien geändert werden.

## Risiken / offene Punkte

Flight besitzt bisher keine Bereichs-ID; mehrere Spacepfade sind auf 256 begrenzt.
Zellindizes ohne Bereich würden verschiedene Karten vermischen. Bisheriger
Travelgate blockiert taktischen Flug pauschal; neue autoritative Übergänge müssen
diesen Fall sauber unterscheiden. Aktueller Anflug prüft den Saum noch nicht.
Methodennamen/Dateibesitz werden mit dem Weltraumkampf-Chat abgestimmt.

## Konkrete Travelgrenze (Abstimmung nach 2a17362d1)

Der Weltraumkampfstand bietet Bereichs-/Index-/Geometrievorstufen, aber noch
keinen atomaren Root-/Travelübergang. Deshalb nicht als fertige Reise integrieren.
Für den Fleetowner sind folgende Delegationssignaturen vereinbart:

- `prepare_space_area_transition(craft_id, expected_travel_revision,
  source_area_id, target_area_id, root_context) -> Dictionary`
- `validate_prepared_space_area_transition(candidate, root_context) -> Dictionary`
- `commit_prepared_space_area_transition(candidate, root_context) -> Dictionary`

Rootkontext bindet zusätzlich Request-ID/Signatur, erlaubte Reiseoperation und
deren Ziel/Phase. Identische Quell-/Zielbereiche allein beweisen keinen Saumanflug.
Kandidaten bleiben Root-privat, Prepare verändert keinen Gameplayzustand und
bucht keinen Treibstoff. Der vorhandene Travelowner bietet diese APIs noch nicht.
Nach finaler gemeinsamer Revision-/Belegungsprüfung soll ein synchroner,
signal-/awaitfreier Tail vorbereitete Zustände veröffentlichen; dabei nicht den
alten `apply_command`-/`_arrive`-Pfad erneut aufrufen, der strategische Flugposen
schreibt. Events erst nach Veröffentlichung aller beteiligten Owner.

Der aktuelle Adapter ruft vor Anflug `authorize_departure` auf. Dies mutiert
Supply-Fuel und Campaign-Abflug/Job. Travelvorbereitung allein macht daher noch
keinen atomaren Anflug: auch diese Effekte müssen vor erstem Debit vorbereitet
und gemeinsam veröffentlicht werden. Keine Dummyrefunds oder halbe Freigabe.
Root-private Reservierungen/Token bei Abbruch freigeben; erfolgreiche gleiche
Requests idempotent beantworten, geänderte Signatur ablehnen. Roottransition bis
zum vollständigen Anschluss nur als nichtproduktive Ownerfixture ausweisen.

Integrationsbedingung aus Weltraumkampf-Commit 238b89c5f: `commit_travel_pose`
weist strategische Posewrites im lokalen Koordinatenbezug zurück. Der dortige
alte Travelpfad `_set_travel_pose` erwartet bisher Erfolg per Assertion. Vor
produktiver lokaler Aufnahme müssen sämtliche alten Reiseaktionen im Travelowner
passend abgefangen werden; Übergänge verwenden den vorbereiteten stillen Tail.
Nicht durch Entfernen der Assertion oder Akzeptieren des Posewrites umgehen.
Bis dahin bleibt der lokale Produktpfad gesperrt. Quellseitig grüne strategische
Fleet-/Taktchecks sind keine Prüfung dieses noch offenen lokalen Anschlusses.
