# Hexsicht und ein NPC pro Feld: Entwurfsgrundlage V1

Status: Planungsgrundlage zum Nutzerauftrag vom 11.11.2026. Keine Umsetzung
oder Performancefreigabe. Details unter [Arbeitsauftrag](../../tasks/HEX_SIGHT_OCCUPANCY_2026_11_11_PLAN.md).

## Ziel und bestätigte Entscheidungen

- Die Berechnung verwendet das logische Hexfeld; Figuren bewegen sich sichtbar flüssig.
- Ein am Boden befindlicher NPC belegt genau ein Hexfeld, teamübergreifend.
- Bewegungsschüsse bleiben möglich; ihr Trefferabzug hängt vom Skill ab.
- Selbstständiges Reagieren auf Geräusche hängt von Skill und Auftrag ab.
- Sicht/Erkennung vereinfachen und Engpassreservierung tatsächlich ausführen.
- Den bestätigten expliziten Rampenvertrag konsumieren.
- Größere Tests später; diese Runde liefert nur den konkreten Arbeitsplan.

## Vorgehen und Alternativen

Gewählter Planungsansatz: bestehende Terrain-, LOS-, Cache-, Kontakt- und
Commandpfade verwenden, einen SimulationRoot-gebundenen logischen Ground-State
ergänzen und Verbraucher paketweise anschließen. Sicht und Bewegung teilen
dieselben Hexpositionen und Höhen; ihre Ausführung wird nacheinander integriert.

Nur Würfe anstelle bisheriger Berechnungen hinzuzufügen würde wiederholte
Geometrie- und Sucharbeit erhalten. Ein vollständiger Wechsel auf eine neue
KI-/Navigationsarchitektur wäre deutlich breiter als der Auftrag. Deshalb
bleiben FTL, ContactTracker, TerrainRegistry, A*/HPA und Effect-Authority bestehen.

## Vorgeschlagene V1-Defaults

Diese Werte sind Entscheidungen des Planentwurfs, keine rückwirkend behauptete
Zustimmung des Nutzers. Sie sind zentral zu konfigurieren und vor Aktivierung
im Vertrag festzuhalten:

- Sichtkegel 120 Grad einschließlich Rand; sechs logische Blickrichtungen
  gemäß `HexGrid.DIRECTIONS`. Blickrichtung ist unabhängig von Laufrichtung.
- Der Feldwechsel geschieht am ersten Simulationstick an/nach der gemeinsamen
  Hexkante, bei Nachbarzentren also nach der halben Schrittdauer. Belegung
  aller gleichzeitig wechselnden Figuren wird atomar angewendet.
- Neue Bewegung nur bis zu drei Übergänge voraus reservieren. Einspurige
  Durchgänge behalten ihre Durchlassrichtung bis zur sicheren Räumung.
- Pro Tick höchstens 16 neue Übergangsanfragen planen; übrige Anfragen bleiben
  geordnet pending. Rücksetzsuche höchstens 64 expandierte Felder pro Anfrage,
  danach `blocked` mit Grund. Diese Arbeitsgrenzen sind keine Millisekundengarantie.
- Reiner Geometriecache höchstens 16.384 Beziehungen, deterministische LRU-Verdrängung.
  Karten-/Terrainrevision zunächst konservativ global invalidieren.
- Verwundete am Boden behalten ihren Platz. Gestorbene Figuren geben ihn erst
  über den vorhandenen Entfernen-/Despawnpfad frei; keine neue Leichenphysik.

## Besitz und Geltungsbereich

`SimulationRoot` besitzt einen `HexGroundRuntime`-Helper unter `scripts/core/`.
Dieser hält logische Zelle, Blickrichtung, Bewegungssegment, Belegung und
verbindliche Reservierungen. `units_by_id` und `occupant_by_grid` sind zwei
Indizes desselben Zustands, keine getrennten Gameplayowner. Mutationen werden
ausschließlich im autoritativen SimulationRoot-Pfad committed.

Die Registry bleibt Terrain-/Lookupindex. Der vorhandene CombatVisibilityCache
hält nur abgeleitete Geometrie; ContactTracker bleibt Kontaktwissen. Die
Basisruntime behält Aktionen, Betten und Boardingzustände; sie beauftragt
Bewegung und liest Ankunft aus dem Ground-State. UI und Visuals konsumieren
Snapshots und senden bestehende Commands.

V1 umfasst freundliche, feindliche und neutrale Ground-NPCs sowie echte
Basispersonen. Personen an Bord oder im Transit besitzen keine Ground-Zelle.
Schiffe/Fahrzeuge erhalten keine NPC-Reservierungen; ihre bestehenden
Landungs-/Objektfootprints bleiben Hindernisse.

## Einführung und Kompatibilität

MapData erhält `tactical_grid_rules = "hex_tactical_v1"` als versionierte
Metadaten. Aktiv ist der neue Pfad nur zusammen mit `hex_axial_v1`. Square-
Karten und Karten ohne Kennung behalten ihren bisherigen Pfad. Eine unbekannte
Kennung ergibt einen Load-Issue, keinen stillen Fallback.

Die Kennung ist unabhängig von `terrain_height_rules`. Sie darf die Rampen-
version weder ersetzen noch implizieren. Aktuelle native Karten werden erst
nach AP8 ausdrücklich aktiviert; keine globale Generator- oder Kartenvergrößerung.
Der alte Bewegungs-/Sichtpfad bleibt bis zur späteren Abnahme erreichbar.

Bestehende Saves bleiben ohne stilles Konvertieren nutzbar. Save-Restore und
Ground-Admission validieren neue aktive Zustände vor der ersten Bewegung.
Eine Kollision führt zu einer eindeutigen Diagnose oder ausstehender
Einsetzung, nicht zu Teleportieren oder Löschen von Personen.

## Verbindliche Rampeneingabe

Eingabe ist `docs/dev/explicit_hex_ramps_contract.md` aus der separaten
Kartenarbeit. Vor AP1 muss dessen freigegebener Commit samt APIs integriert sein.

- `terrain_height_rules = "explicit_hex_ramps_v1"`.
- `ramp_direction = -1`: Plateau; `0..5`: Aufwärtsrichtung entlang `HexGrid.DIRECTIONS`.
- `height_level = H` bezeichnet bei Rampen die untere Ebene.
- Rampe: genau eine Zelle, Enden H/H+1, Standhöhe H+0,5, seitlich gesperrt,
  in beiden Richtungen benutzbar. H8→H9 bleibt ungültig.
- Reine Plateau-H0/H1-Kante ist gesperrt; kein automatisches Steigen oder Klettern.
- APIs: `TerrainTileData.allows_step(from_tile, to_tile)`,
  `endpoint_height(tile, neighbor_grid)`, `stand_height(tile)`;
  Registry: `get_stand_height_at(grid) -> float` und
  `get_stand_height_at_world(position) -> float`.

TerrainPathfinder.can_traverse_step bleibt der gemeinsame öffentliche
Übergangseinstieg und delegiert im neuen Pfad auf diese Terrainregeln und
Runtime-Walkability. Reservierung prüft keine alternative Höhenformel.
HPA, tatsächlicher Schritt und Rücksetzsuche verwenden denselben Einstieg.

Höhen in Sichtschlüsseln werden als `roundi(2.0 * stand_height)` geführt.
Dadurch bleibt H+0,5 exakt erhalten. Augen-/Haltungsaufschläge bleiben beim
bestehenden Profilowner; neue Zahlen oder Änderungen halbhoher Deckung gehören
nicht unbemerkt in diesen Umbau. Die kontinuierliche Renderhöhe auf einer
Rampe ist Projektion; sie ändert nicht pro Animationsframe die logische Höhe.

## Sichtgeometrie

`HexVisibilityQuery` ist ein reiner Helper. Er prüft zunächst Hexreichweite und
Blickrichtung in der physischen Hexebene, danach die bestehende kanonische
`HexGrid.line` und Terrain-/Objektblocker. Bekannte Rand-/Wandregeln bleiben
durch Fixtures beschrieben; kein neuer zweiter Raycast aus einem Render-Mesh.

Gemeinsame Eingabe je Teilnehmer: `unit_id`, `grid: Vector2i`,
`facing_dir: int`, `stand_height_steps2: int`, `posture_key`, `state_revision`.
Ein Sichtprofil liefert `range_hex`, `arc_degrees` und vorhandene Höhenklasse.
Ausgabe: `in_range`, `in_arc`, `terrain_clear`, `visible`, `reason`.
Halb-/Volldeckung und erlaubte Schusswirkung sind getrennte Ergebnisse des
bestehenden Cover-/Combatowners. Sichtbarkeit allein erlaubt noch keinen Schuss.

Geometriecache-Schlüssel: Karten-/Registryidentität, Terrainrevision, geordnete
Quell-/Zielzelle und deren effektive Höhen-/Hindernisprofile. Blickkegel und
Reichweite werden mit aktuellem Profil vor der Geometrie ausgewertet.
Ein reiner Renderpositionswechsel invalidiert nichts. Zellen-, Höhen-,
Blocker-, Tür- und Kartenwechsel invalidieren betroffene Beziehungen; eine
konservative globale Revision ist für V1 korrekt.

Keine volle Karte pro NPC scannen und kein dauerhaftes N×N-Feldpaararray.
UnitRegistry/Belegungsindex liefern lokale Kandidaten. Abfragen erfolgen
zielbezogen; FoW nutzt seine begrenzten Jobs und publiziert atomar. Vor einem
Schuss wird mit aktuellen logischen Eingaben validiert, nötigenfalls synchron.
Eine überholte FoW-Generation darf keine sichtbaren Gegner bestätigen.

## Erkennung, Aufmerksamkeit und Auftrag

Günstige Zeit-/Cooldownfortschreibung bleibt pro Simulationstick aktiv.
Teure unveränderte Sichtprüfung wird durch die gemeinsame Hexabfrage ersetzt.
Ein Erkennungsepisode beginnt bei neu möglicher Sicht; Skill und vorhandene
Auftrags-/Haltungsprofile bestimmen die bestehende Reaktionsdauer. Der
Fälligkeitszeitpunkt wird gespeichert, statt dieselbe Dauer ständig neu zu
berechnen. Echte Sichtunterbrechung beendet die Episode gemäß Kontaktvertrag.

Der Umbau führt keine zusätzlichen Wahrnehmungswürfe mit unbeschränkten
Wiederholungen ein. Werden später Zufallseinflüsse ergänzt, erfolgen sie auf
der Authority genau einmal je Episode/Ereignis, mit bestehender Seedquelle.
Aktuelle direkte Sicht, Verdacht, letzte bekannte Position und Meldungen
bleiben getrennt. Ein Relay oder Geräusch macht ein Ziel nicht schussfähig.

Geräusche kommen als Fakten aus dem autoritativen Ereignispfad, unabhängig
von abgespieltem oder stummgeschaltetem Audio. Auftrag bestimmt, ob Umsehen,
Melden oder Nachsehen erlaubt ist; vorhandener Awareness-/Initiative-/FTL-
Skillpfad liefert Reaktionsqualität und Verzögerung. Ein Ereignis wird je NPC
nur einmal behandelt. Keine neue Schallausbreitung und keine perfekte
Feindposition aus einem Geräusch. Fehlende bestehende Geräuschproduzenten
werden als eigener Folgepunkt benannt, nicht durch SceneTree-Polling simuliert.

Bewegungsstatus stammt aus dem Ground-Segment. Combat verwendet ihn für den
skillabhängigen Bewegungsabzug; die konkreten Beispielmali aus dem Gespräch
werden nicht als freigegebene Balance übernommen. Bestehende Schussintervalle,
Friendly Fire, Damage-Effects und Cooldowns bleiben im bisherigen Ownerpfad.

## Bewegung, Reservierung und Engpassdurchlass

Ein Segment beschreibt `from_grid`, `to_grid`, `start_tick`, `duration_ticks`
und `handoff_tick = start_tick + ceil(duration_ticks / 2.0)`.
Quell-/Zielbelegung benutzt halboffene Zeitintervalle. Ungeplantes Stehen
reserviert das aktuell gehaltene Feld unbegrenzt; nur eine zugesagte Ausfahrt
darf dieses Intervall verkürzen. Kanten werden für die gesamte Überquerung
reserviert; eine Gegenrichtung im selben Zeitraum ist unzulässig.

Der vorhandene BottleneckReservationResolver wird um einen reinen
Hex-Planungseinstieg erweitert. Verbindliche Reservierungen liegen im Ground-
Owner und überleben einzelne Resolveraufrufe. Alle vorgeschlagenen Schritte
werden vor dem Commit gegen Belegung, Terrainrevision und Endpunkthöhen
validiert. Eine Folgebewegung kann die zugesagte Freigabe ihres Vordermanns
nutzen; ein aufgenommener Plan wird atomar committed, sonst unverändert verworfen.

Korridore werden mit sechs Nachbarn als zusammenhängende einspurige Abschnitte
erkannt und bis zur Terrainänderung gecacht. Vor Einfahrt müssen Richtung,
Ausfahrt und Warteflächen geklärt sein. Personen im Abschnitt haben Vorrang
beim Räumen. Danach werden Warteanfragen fair nach zunehmender Wartezeit,
Auftragspriorität und stabiler Unit-ID entschieden. Eine Durchlassgruppe
übernimmt höchstens die bereits zugelassenen Mitglieder; neue Ankömmlinge
verlängern die Gegenrichtungssperre nicht unbegrenzt.

Ein blockierter Ausgang wird nicht zugefahren. Gegenverkehr wartet außerhalb.
Bereits verkeilte Figuren erhalten eine begrenzte Rücksetzsuche bis zur
erreichbaren Ausweichstelle. Fehlt Platz, bleibt `blocked/no_passing_space`
mit ruhigem Feedback bestehen, bis sich Belegung, Auftrag oder Terrain ändert.
Kein wiederholtes blindes Repathing, kein zufälliger Vorfahrtswechsel und kein
Versprechen freier Durchfahrt durch eine vollständig gefüllte Sackgasse.

Normale Tempo-/Skilländerungen wirken auf noch nicht begonnene Segmente.
Die Dauer eines bereits begonnenen Segments bleibt Teil seiner Zusage.
Eine harte Unterbrechung entwertet auch davon abhängige noch nicht begonnene
Folgeschritte, bevor deren zugesagte Feldfreigabe verwendet wird.

Bei normalem Auftragswechsel darf das begonnene sichere Segment enden; die
Folgeroute wird ersetzt. Harte Unterbrechungen werden mit der aktuellen
logischen Zelle atomar behandelt: aktuelle kontinuierliche Projektion stoppen,
keine neue Doppelbelegung, überholte zukünftige Reservierungen freigeben.
Der Terrainowner verhindert ein Schließen/Blockieren mitten in einer belegten
oder bereits zugesagt überquerten Tür; die Mutation wartet oder wird abgelehnt.

Visuals interpolieren ausschließlich die committed Segmente. Für aktive
Hex-NPCs dürfen kontinuierliche Avoidance-/Spacing-Solver nicht zusätzlich
deren Positionen verschieben. Legacy-NPCs behalten den bisherigen Solver.
Registry, SceneTree und Renderer werden keine Belegungsowner.

## Lifecycle, Save und Netzwerk

Einsetzen, Aussteigen und Respawn verwenden eine atomare Gruppenplatzierung
mit verschiedenen legalen Feldern, ausgehend vom bestehenden Anker und nur
über erlaubte Terrainübergänge. Bei Platzmangel bleiben Personen im vorhandenen
Warte-/Bordzustand; kein Crewverlust und keine teilweise behauptete Einsetzung.
Tod/Entfernen, Missionwechsel und Abbruch räumen Reservierungen genau einmal.

Neue Saves speichern logische Zelle/Blickrichtung und nötigenfalls ein
angefangenes Segment mit Dauer und Fortschritt, keine Cache-/Warteschlangen-
Snapshots. Restore validiert Belegung und rekonstruiert zwingende aktive
Segmente vor Tickfreigabe. Ungültige Zustände scheitern ohne Überschreiben des
bisherigen Saves. Die bestehenden Grenzen für Reisen und Mehrort-Saves bleiben.

Nur die Authority entscheidet Feldwechsel und Zufall. Peer-Snapshots enthalten
die benötigte versionierte Zelle/Blickrichtung/Bewegungsprojektion für bereits
sichtbare eigene oder bekannte Objekte. Keine fremden Reservierungslisten oder
verdeckten NPC-IDs zum Client senden. Clients senden Absichten; direkte
Belegungs-, Sicht- oder Zustandsmutationen bleiben verboten.

## Prüfung und Freigabegrenze

Jetzt: Dokument-/Referenz-/Diffprüfung. Bei späterer Umsetzung: je Paket eine
kleine isolierte Fixture und direkt betroffene Nachbarn. Große Native-, A/B/C-,
Gefechts-, Save-Matrix-, Mehrspieler- und Performance-Serien sind AP9 und
bleiben bis zum späteren Nutzerauftrag zurückgestellt. AP8 ist ein Kandidat,
keine Veröffentlichung oder allgemeine Performanceabnahme.
