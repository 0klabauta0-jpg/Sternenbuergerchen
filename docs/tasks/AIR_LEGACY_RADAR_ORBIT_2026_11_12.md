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

Ein Routenplaner schlägt einen freien geraden Weg vom unteren Eintrittsband
zu einem oberen Planetentor beziehungsweise zurück vor und lehnt erkannte
Kontakte oder versperrte Wege ab. Der Flugowner führt den Weg im Opt-in über
seine normalen Bewegungsticks aus; Abschalten und neue Kontakte lösen Bremsen
aus. Zielort und Wartestatus sind pro Schiff gebunden. Ein regulärer 1x-Lauf
mit Opt-in erreichte nach tatsächlichem Durchflug die Satellitenmission und
bestand den Dropship-Flug mit 49/49 Prüfungen. Die Gegenrichtung bis zum
Warp-Gate ist bisher im Ownerfixture geprüft. Polisa behält den direkten Weg.

Der neue Pfad bleibt standardmäßig ausgeschaltet, bis lokale Flight-,
Transit-, Receipt- und Bedienzustände mit Save/Continue gemeinsam abgesichert
sind; die Auswahl ist derzeit nicht dauerhaft gespeichert und die Bedienung
im Standardpfad ausgeblendet. Ein Szenariogefecht
und eine visuelle Abnahme sind noch offen. Pilotenabhängige Hindernisfolgen
sind noch nicht implementiert.

Ein weiterer realer Rückrundlauf erreichte Landung und Bewegungsbefehl zum
Satelliten, aber die Interaktion wurde innerhalb 45 Sekunden nicht benutzbar.
Die Ursache ist nicht geklärt. Ein separater realer 1×-Lauf mit Orbit-Opt-in,
regulärem Missionsabbruch und physisch eingeboardeter Originalcrew bestand
38/38 Prüfungen bis zur tatsächlichen Heimatlandung des ursprünglichen Schiffs.
Dieser Lauf ist kein Abschluss des Satellitenziels und kein Save/Load-Nachweis.

Beim anschließenden Zweimondlauf lieferte der unindizierte
`get_mission_for_craft`-Fallback während des zweiten Flugs noch die aktive
Instanz der ersten Karte, obwohl das Schiff dort nicht mehr anwesend war.
Der Fallback darf nur für ein tatsächlich als `mission` geführtes Schiff
gelten; explizite Location-Registry-Bindungen behalten Vorrang. Ein gezielter
Test deckt alte Instanz, Missionsbesitz und explizite neue Bindung ab.

## Reale Zweimond-Rundflüge, kombinierter Stand

Der isolierte 1×-Lauf auf Source `2f37621a69a328c908b5d9cd1ab236ec80b2a61c`
bestand 84/84. Er nutzte die bestätigten Sternsystemdaten `21c7c23b` und die
512×256-Karten aus `3f5e2c21` sowie ein ausdrücklich aktiviertes Orbit-Opt-in.
Auf Glut 1a wurde der Satellit durch echten Lauf und zeitgesteuertes Use
geborgen, das ursprüngliche Schiff flog heim und der Chip wurde hochgeladen.
Ein echter Heimat-Checkpoint wurde danach gespeichert und über den Store
gelesen. Der dadurch freigeschaltete Besuch auf Glut 1b wurde nach Landung
und echtem Boarding regulär abgebrochen; das ursprüngliche Schiff flog heim.
Personen, Positionen, Gesundheit und Fortschritt wurden nicht gepatcht.

Das Ergebnisprotokoll liegt unter
`C:/Users/bjoer/AppData/Local/Temp/codex-two-moon-native-fixed-503c8fc727e54ef1bf660c8504c185aa/roundtrips.log`.
Der unveränderte Checkpoint `source_a_upload_checkpoint.json` im selben Profil
hat SHA-256 `aa6841f32b7cdd00fe7506d8c4960ebe4a76fe41416633f12e3e50770b2c7618`.
Der Store-Read ist kein Szenen-Continue; der B-Auftrag wurde nicht erfüllt.
Ein nativer Sichttest und lokales Flight-/Automatik-Save/Load bleiben offen.

## Ausstehende Befehle während Orbitdurchflug

Ein vorgemerkter Oberflächenanflug gehört ausschließlich zu einem laufenden
Einflug; ein vorgemerkter Warp gehört ausschließlich zu einem laufenden
Ausflug. Pro Schiff dürfen die beiden vorgemerkten Befehle nicht zugleich
existieren. Wiederholungen desselben Befehls bleiben idempotent; widersprüchliche
Anfragen werden mit einer nachvollziehbaren Ablehnung beantwortet. Die Prüfung
bleibt auf den vorhandenen Reiseadapter begrenzt und verändert keine Flugphysik.

Die kanonische Oberflächenzuordnung ordnet `satellite_crash` Glut 1a,
`trade_outpost` Glut 1b und `fortified_outpost` Glut 1 zu. Ihre Szenarien
verweisen auf die zugehörigen Karten. `distress_orbit` und `polisa` sind keine
Planetoberflächen. Die im Parallelchat wiederhergestellten Sternsystemdaten
müssen dazu gemeinsam integriert werden. Hin- und Rückübergangsprüfung nutzen
diese Zuordnung zusammen mit der bestehenden Orbit-/Bodyprüfung. Die oben
genannten 1×-Läufe basieren auf Main `95abade90` mit damaliger abweichender
Orbitzuordnung und beweisen noch keinen Flug zu den neu gebundenen Monden.

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
