# AP4: reiner Hex-Reservierungsplan V1

`BottleneckReservationResolver.build_hex_plan(requests, ground_snapshot,
terrain_registry, options={})` ist statisch und mutiert keine Eingaben, Actoren,
Gameplayzustand in Registries oder Ownern. Rein abgeleitete, revisionierte
Nachbartopologie darf in der Registry wiederverwendet werden. Legacy-Einstiege bleiben unveraendert. Dieser Vertrag
wurde vor Implementierung ueber Root mit dem Tabletop-Owner abgestimmt.

## Snapshot und Segmente

Der vorhandene AP1-Snapshot behaelt `map_id`, `revision`, `current_tick`,
`terrain_revision`, `units_by_id`, `occupant_by_grid`. Zusaetzlich zwingend:
`reservation_schema_version: 1`, `committed_segments: Array` und
`committed_corridor_grants: Array`. Auch leere Listen muessen explizit existieren.
AP1-Snapshots werden als `snapshot_incompatible` abgelehnt. Die Terrainrevision
muss zur uebergebenen Hex-Registry passen. Keine eigene Snapshot-Wahrheit.

Kanonisches Segment: `{unit_id, command_id, from_grid:Vector2i,
to_grid:Vector2i, start_tick:int, duration_ticks:int, handoff_tick:int}`.
`handoff_tick = start_tick + ceil(duration_ticks / 2.0)`; das Segmentende wird
ausschliesslich aus Start und Dauer abgeleitet. Quelle gilt bis Handoff,
Ziel ab Handoff, halboffen. Die gerichtete Kante gilt fuer die gesamte Dauer;
eine ueberlappende Gegenkante bleibt verboten. Das letzte Feld einer Trajektorie
bleibt unbegrenzt belegt, bis eine gemeinsam angenommene Ausfahrt existiert.

Committed-Segmente enthalten laufende und kuenftige Zusagen, keine vollstaendig
abgelaufenen Segmente. Nach Handoff zeigt `units_by_id.grid` bereits das Ziel;
die alte Kante bleibt trotzdem bis zum Segmentende wirksam. Eine neue Bewegung
startet fruehestens danach. Vor noch ausstehenden zugesagten Feldwechseln bleiben
neue Anfragen konservativ vollstaendig `pending/existing_commitment`: der Resolver
schreibt ihre Ursprungszelle nicht um. Nach dem letzten Handoff kann angehaengt
werden. Das ist ein bewusster Wartevertrag dieses isolierten AP4-Teils.

## Requests und Ergebnis

Request: `{unit_id, command_id, priority:int, path_grid_points:Array[Vector2i],
duration_ticks_by_step:Array[int]}`, optional `wait_ticks:int` vom Owner.
Pfad enthaelt die aktuelle Ursprungszelle und mindestens ein Ziel; positive
Dauer pro Uebergang. Planbare Dauer maximal 1000000 Ticks; Snapshotzeit maximal
1000000000000. Es gibt hoechstens drei neue Uebergaenge pro Request und 16 neue
Requests pro Aufruf. Budgetueberlauf bleibt vollstaendig pending; nach drei
Schritten wird nur der noch offene Pfad samt Dauerliste weitergegeben.

Ergebnis: `{ok, reason, expected_revision, terrain_revision, accepted_steps,
waits, blocked, pending_requests, corridor_grants, processed_requests}`.
Accepted-Segmente enthalten nur neue Zusagen. `expected_revision` ist die gelesene
Ownerrevision. Owner muss den gesamten Plan einschliesslich aller gemeinsam
genutzten Freigaben atomar erneut pruefen/committen; der Resolver committet nichts.
`waits` enthaelt unit_id/command_id/wait_ticks/reason; `blocked` dieselben IDs
und einen Grund. Keine Anfrage verschwindet wegen eines Budgets oder Konflikts.

Faire Reihenfolge: bereits im lokalen Gang stehende Personen raeumen zuerst;
danach priority + wait_ticks, stabile Unit-ID bei Gleichstand. Der Score begrenzt
Prioritaet auf +/-1000000 und Alter auf 0..1000000000000, um Int-Ueberlauf zu
vermeiden. Wartezeitsuche standardmaessig 16, optional `max_wait_ticks` 0..64.
Nur echte Fortschritte starten einen weiteren begrenzten Followerdurchlauf.

## Korridore und Ruecksetzvorschlaege

Legalitaet verwendet sechs Hexnachbarn, Runtime-Walkability und ausschliesslich
`TerrainTileData.allows_registry_step` nach beiden maßgeblichen Walkabilitygates.
Dieser Einstieg teilt den kanonischen Endpunkthöhenkern mit `allows_step`;
Runtime-Türübersteuerungen ändern keine Rampenrichtung oder Höhenfreigabe.
Kein pauschales Rampenmutex: breite passende
H+0.5-Baender und Kurven benutzen denselben Graph wie Plateaus und Rampenachsen.
Der aufruflokale Graph liest maximal 64 Felder, niemals get_sorted_tiles oder
die gesamte Karte. Zusammenhaengende lokale Abschnitte mit maximal zwei legalen
Nachbarn werden entlang ihrer Enden stabil geordnet. Geschlossene Ringe werden
nicht als gerichteter Gang interpretiert. Kein persistenter Resolvercache.

Grant: `{cells:Array[Vector2i], unit_ids:Array[String]}`. Ein uebernommener Grant
bleibt bestehen, solange ein Gruppenmitglied im Gang steht ODER ein committed
Segment des Mitglieds den Gang beansprucht, auch nach Handoff. Neue Ankoemmlinge
erweitern diese Bestandsgruppe nicht. Neue Gruppen enthalten ausschliesslich
die in diesem Aufruf angenommenen gleichgerichteten Mitglieder. Ein besetzter
Ausgang wird auch jenseits des Dreischritthorizonts nicht zugefahren; die lokale
Ausgangspruefung ist auf 64 Pfadfelder begrenzt.

Eine schon im Abschnitt stehende fremde Person darf monoton zum naeheren
Gangende raeumen. Diese Ausnahme erlaubt weder Eintritt noch Wiedereintritt
und erweitert die Bestandsgruppe nicht. Sie vermeidet eine durch den Grant
selbst erzeugte Raeumsperre; auch diese Schritte bleiben Owner-Commits.

Bei `no_passing_space` liest die Ruecksetzsuche denselben lokalen Graph, zusammen
maximal 64 untersuchte Felder ueber alle blockierten Requests. Nur freie Pfade
zu einem legalen Feld mit mehr als zwei Anschluessen werden vorgeschlagen.
`blocked.backoff_path_grid_points` und `backoff_examined_cells` sind Lesedaten.
Ein gefundener Pfad setzt `reason: backoff_required`; andernfalls bleibt
`no_passing_space`. Keine accepted_steps werden dadurch ersetzt. Owner/AP5
entscheidet und fuehrt einen Ruecksetzvorschlag separat aus.

## Grenzen

Der lokale Graph ist begrenzt und aufruflokal: kein fertig integrierter globaler
Korridorcache, keine allgemeine Deadlockfreiheit oder optimale Routenwahl.
Grosse Karten-, Lifecycle-, Save-, Netzwerk-, Gefechts- und Performanceabnahmen
sind weiterhin spaeter. Ohne Owner-Commit/AP5 bewegt dieser Plan keine Figur.
