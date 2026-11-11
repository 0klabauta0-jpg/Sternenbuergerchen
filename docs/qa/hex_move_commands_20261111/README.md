# AP5 echte Commands, kleines 2DActorpaket

Basis d00eba780. Root-eigener Bewegungsadapter verarbeitet bestehende Commands,
Ground bleibt alleiniger Belegungs-/Segmentowner. Angenommenes Ziel bleibt bis
Ankunft oder Abbruch; keine Legacy-Frame-Requeue für Hexfiguren. 2DActorposition
ist Darstellung. Keine aktive Produktionskarte, keine Main-/EXEänderung.

Kleine isolierte Godot4.6.2-Projekte, tatsächliche Produktionsquellen:
`python scripts/tests/run_hex_tactical_check.py --case CASE`.

| Case | Bestanden / fehlgeschlagen |
|---|---:|
| movement |42 /0|
| owner |56 /0|
| movement_stop |34 /0|
| projection |56 /0|
| facing |24 /0|
| security |34 /0|
| consumers |39 /0|
| reservation_owner |36 /0|
| corridor_integration |15 /0|

Alle finalen Prozesse0, Originalprofil unverändert, private Canary und
Quellguards grün, keine Script-/Leakfehler. Manifest nennt final ausgeführte
Quellhashes; unveränderte Reports/Logs aller Versuche in move_runs.zip.
Bewegungsfixtures höchstens zwölf Felder; alte schematische Korridorprobe
nutzt80/81 Felder ohne Szene/Gefechtslast, unverändert zum Vorgängerpaket.

Echte Rootqueue, echte UnitRegistry und kleiner CapabilityActor prüfen langsamere
Führung/schnelleren Folger, Exklusivität, gehaltene Ziele, tatsächliche Ankunft
nach Segmentende, sechs Richtungen bei anisotroper Projektion, Rampen auf/ab
und gesperrte Flanke. Zero-Navbudget, Hold, echter Damageproducer/Downclaim,
Umweg um Verwundete, Legacy-Rückfallgrenze, zwei getrennte weiter tickende
Ortsroots mit gleicher lokaler ID, Render/RNG-Reinheit und logisches Capture.
Kein TestUnit-/3D-/Meta-UI- oder echter Bildschirmwechseltest.

Review schloss drei P2-Befunde: fehlende stationäre Richtungsprojektion,
wiederholte Oberflächenzeitlesung ganzer Routen und Mutation des angenommenen
UnitCommand durch NaN-Ziele. Zusätzliche Aliasgrenze war sauber3/1 reproduziert;
normalisierter Hex-UnitCommandstatus wird vor Bewegung geprüft. Gemeinsame
Reviewrepro10/3→13/0, Capture15/2→17/0. Frühe Variante mit null Command/Timeout
ist kein gültiger RED-Nachweis. Zwei spätere41/1-Pending-Cancel-Versuche hatten
eine falsche Fixturevorbedingung (Folger bereits zugesagt); die eigene Zweifeld-
Probe bestätigt nun wartenden Pfad ohne Groundclaims und vollständige Bereinigung
bei Hold. Enge Nachreviews ohne verbleibende Befunde, Reviewer ohne Engine.

Limits pro Tick: vier Navscheiben/96 Expansionen,16 Planrequests/48 neue Schritte.
Gecachte Oberflächenzeitprofile und nur nächste drei bindende Dauerupdates;
Initialaufbau und Pfadrestkopien bleiben linear und sind nicht als gemessene
Performanceverbesserung bewertet. Keine SceneTree-Suche im neuen Runtimepfad.

Offen bleiben 3DView-/Fireteamankunft, Türmutationsguard, skillabhängiger
Bewegungsschuss, Backoff-Ausführung sowie Lifecycle/Save/Authority AP6–8.
Große Karten-/Gefechts-/GPU-/FPS-/Netzwerktests und Aktivierung erst später AP9.
