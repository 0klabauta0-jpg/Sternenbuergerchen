# AP5 Gruppenankunft und Viewreader

Basis a66b84522. FireteamMovementController verwendet seinen bestehenden Root
für Ziele/Ankunft und logische Start-/Formationsanker. TerrainMap3DView liest
Rootprojektionsmetadaten, benutzt den vorhandenen Höhenmaßstab und glättet
Hexpositionen nicht doppelt. Kein Sandbox-/Kamera-/Raster-/Ship-/Metabesitz.

Isolierte Godot4.6.2-Privatprojekte mit tatsächlichen Produktionsquellen:
`python scripts/tests/run_hex_tactical_check.py --case CASE`.

| Case | Bestanden / fehlgeschlagen |
|---|---:|
| movement_consumers |65 /0|
| movement |42 /0|
| security |34 /0|

Consumer erbt42 Bewegungsprüfungen des Vorgängers; die65 sind keine zusätzlichen
65 Prüfungen. Alle Prozesse0, Originalprofil-/Quell-/Canaryguards grün, keine
Script-/Leakfehler. Manifest nennt finale Hashes, consumer_runs.zip archiviert
unveränderte Reports/Logs samt Fehlversuchen. Preloadgrafiken werden ausschließlich
für die tatsächliche Viewklasse in das Privatprojekt kopiert; kein Mainstart.

Neue Fälle benutzen tatsächlichen Root/Registry/CapabilityActor und öffentlichen
Fireteam-Start/Update: vor Rootannahme gezeichnetes Ziel, letztes Handoff ohne
Segmentende, echte Ankunft bei falscher Renderposition, Token-/Zielhexabweichung,
expliziter deckender Hold versus generischer Hold ohne Ziel, fehlendes Mitglied
und Legacy-Pixelankunft. Zweierformation auf zwölf Feldern behält ihre Stageziele
trotz geänderter Renderpositionen. Viewreader prüft stetige Rampenhöhe mit Mapping
0.5 und Regionalhöhe0.75, große Metrik256/128, kosmetischen Combatposturewrite,
reine Readseite und Release. Kein tatsächlicher Renderer-/Asset-/Animationstest.

RED: nach Nachladen der tatsächlichen Preloadressourcen sauber42/2 fehlende APIs,
dann43/3 einschließlich echter Frühankunft. Vorherige zwei Dependencyfehler und
ein Aufruf mit falscher Testsignatur sind keine gültigen Produkt-REDs. Erster
GREENversuch55/0 hatte noch falsche Releasearity im Test/ScriptError und gilt
nicht als bestanden. Korrigierter Zwischenstand61/0. Frischer Review fand vier
P2: verbliebene Renderposition im Formationsanker, Weltvektor unter Yawtoleranz
bei großer Metrik, null-Holdzielcast und allgemeines Facingmeta mit weiteren
Schreibern. Repro62/3 plus tatsächlicher Nil→Vector2-Fehler, final65/0 ohne Fehler.
Nachreview schloss alle vier Befunde, keine weiteren engen Befunde; Reviewer
führte keine Engine aus und änderte keine Dateien.

Offen: Türguard, skillabhängiger Bewegungsschuss, Backoff, Lifecycle/Save/Netzwerk
und kleine integrierte Kandidatenanbindung. Keine Karte aktiviert, keine Main-/
EXEfreigabe, keine native Grafik-/Spielgefühl- oder Performanceabnahme. Große
Karten-/Gefechts-/GPU-/Save-/Multiplayerprüfungen bleiben AP9 für später.
