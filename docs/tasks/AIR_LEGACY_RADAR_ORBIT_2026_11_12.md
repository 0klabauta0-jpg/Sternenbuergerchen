# Luftunterstützung auf regulären Bodenkarten

## Ziel und Ursache

Ab Main `95abade90` soll die vorhandene Cutlass mit echtem Flugowner in der
regulären Satellitenmission starten, fliegen, feuern, zurückkehren und landen.
Die reale Karte verwendet Hexgeometrie, aber den Legacy-Bodenowner; der
bisherige Luftpfad verlangt `hex_tactical_v1` und meldet `ground_unavailable`.
Das private Hex-Opt-in soll ebenfalls einen echten Rückweg ermöglichen.

## Umfang und Grenzen

Bestehende Fleet-, Flight-, Wing-, Combat-, Transport- und Bodenowner nutzen;
keine Produktionskarte still auf einen anderen Bodenmodus schalten. Radar
erfasst im Raum und auf Bodenkarten Luftziele; Bodenfeuer behält Bodensicht.
Der bestätigte automatische Orbitdurchflug und seine Abschaltung gehören zum
Auftrag. Companion besitzt Mission-Save/Continue und integriert Main;
Save-/Restore-Methoden und gemeinsame Dateien nur nach Abstimmung verbinden.
Keine EXE durch diesen Task.

## Akzeptanz und Prüfung

Regulärer Missionsstart und physisches Boarding, Start, Bewegung, sicht- und
waffengeprüftes Feuer, Rückflug, Landung und Boarding mit realen Identitäten;
Legacy- und privater Hexpfad getrennt prüfen. Radar-Reichweite und Luft-Luft-
Grenze sowie Orbit-Durchflugrichtung und Abschaltung gezielt prüfen. Keine
Fixtures als nativen Gesamtspielnachweis ausgeben. Tests in isolierten
Profilen bündeln und auf nötige Regressionen beschränken.

## Betroffene Dateien und Risiken

Insbesondere Air-Methoden in `scripts/core/simulation_root.gd`, bestehende
Registries und Bodenschadenspfade, Flug-/Combat-Owner, Missionscontroller,
Radar-/Orbitresolver und gezielte Verifier. Große gemeinsame Dateien nicht
als Ganzes portieren. Sichtbarkeit, Mehrfachbelegung und Landekollision auf
Legacykarten sowie Persistenz- und Indexvalidierung sind ausdrücklich offen.

Stand: Der Radarowner verwendet vorläufig die bereits im Raumkampf vorhandene
Reichweite 12. Bodenradar fragt ausschließlich Schiffe im gleichen Fluggebiet
ab und projiziert erkannte Kontakte als generischen Marker. Eine technische
Headless-Prüfung ersetzt keine visuelle Spielabnahme. Ein Luft-Luft-Feuerbefehl
von der Bodenkarte, regulärer Beschuss einer echten Szenariowache und der
automatische Orbitdurchflug sind noch nicht nachgewiesen. Im privaten Hex-
Versuch meldete der Bewegungsowner beim Rückweg `unreachable_target`; die
Produktionskarte bleibt unverändert im Legacy-Modus.

Ein eigenständiger Routenplaner schlägt inzwischen einen freien geraden Weg
vom unteren Eintrittsband zu einem oberen Planetentor beziehungsweise zurück
vor und lehnt erkannte Kontakte oder versperrte Wege ab. Er ist noch nicht an
Ankunft, Flugtick oder Bedienung angeschlossen; automatische Fortsetzung,
Abschaltung, Änderung während des Flugs, Pilotenfolgen und Persistenz fehlen.
Polisa benötigt weiter den direkten Reiseweg und darf keinen solchen Auftrag
erhalten. Der Planer allein ist kein Durchflugnachweis.

## Entwurf für portable aktive Sorties

Ein versionierter Sortie-Datensatz braucht je `craft_id` die `location_id`,
`previous_pose` mit den von der Landung benötigten Flugfeldern,
`landing_position`, `landing_grid` und `was_inactive`. Die aktuelle Flugpose
gehört separat dem Flight-Owner. Objekt-Referenzen, WeakRefs und Instanz-IDs
sind nicht portabel. Bewegung, Feuerauftrag, Waffenzustand und Cooldowns,
RNG und die zugehörigen Move-, Order-, Fire- und Impact-Receipts müssen
konsistent erhalten oder bei aktiver Funktion ausdrücklich abgelehnt werden.
Identität und Boarding der originalen Crew, Pilotenzuordnung, Missionsidentität
und laufende Drop-Sequenzen sind mit den jeweiligen Ownern abzugleichen.

Vorgeschlagene Restore-Reihenfolge: Szenario und originale Unit-Registries
vorbereiten; Fleet, Ausrüstung, Pilot und Boarding sowie Flugpose validieren;
denselben Fleet-Flugowner mit Wing, Combat-Systemen und Raumindex binden;
anschließend die Missionssimulation mit Source und Adapter verbinden und die
Sortie-Referenzen neu aufbauen; Navigation, Feuer und UI zuletzt vorbereiten.
Alle beteiligten Owner müssen vor gemeinsamer Veröffentlichung Identitäten,
Revisionen, Atmosphäre und Landeplatz prüfen. Bei Fehlern darf kein partieller
Restore veröffentlicht werden. Dies ist ein Entwurf, kein getesteter Vertrag.
