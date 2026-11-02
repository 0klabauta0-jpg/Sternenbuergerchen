# Performance-/Architekturzyklen, 2026-11-03

## Ziel / Ursache
Nutzerauftrag: auf aktuellem Main erneut Performance/Architektur pruefen und
anschliessend selbststaendig drei Review-/Fix-/Retest-Runden durchfuehren.
Nach jeder Runde den veraenderten Stand erneut auf konkrete Probleme pruefen.

## Basis / Umfang / Nicht-Ziele
Basis ist der per Fetch bestaetigte Main `8eaeadd27e92d68539550058a4795c3ba626dcdc`.
Eigener Branch `task/performance-architecture-cycles-20261103` vom aktuellen Main,
wie fuer den Review explizit beauftragt. Nur bestaetigte Performance-/Architektur-
und daraus folgende Verhaltensfehler beheben, keine pauschalen Refactors oder
neuen Features. Keine automatische Main-Integration, keine Release-Abnahme.

## Dokumente / Contracts
`AGENTS.md`, `PROJECT_BRIEF.md`, `ARCHITECTURE.md`, `CODEX_RULES.md`,
`IMPLEMENTATION_STATUS.md`, `TASK_ROADMAP.md`; owning Contracts der bestaetigten
Befunde unter `docs/dev/`, bisherige Review2-Regressionen und deren Evidenz.

## Akzeptanz / Vorgehen
- Drei aufeinanderfolgende Runden mit Review, konkretem Repro, minimalem Fix,
  passenden Regressionen und unabhaengiger Nachpruefung.
- Neue Fehler zuerst durch erwartbar fehlschlagenden Verhaltenstest nachweisen;
  Performance mit Operationen messen, keine FPS-Aussagen aus Headless-Fixtures.
- Alle Godot-Laeufe ausschliesslich durch `scripts/tests/run_review2_isolated.py`
  mit frischen eindeutigen Nutzerdaten, erstem Pfadguard und Canary; keine
  parallel laufenden Engineprozesse oder Benchmarks.
- Neuer unveraenderlicher Roster-Ausgangsvergleich fuer diesen Auftrag; Bytes,
  Laenge und Schreibzeit vor/nach jedem Test gleich. Keine automatische
  Profilwiederherstellung, keine privaten Rosterbytes im Repository.
- Relevante alte Gates und die gemeinsame Review2-Auswahl nach den Fixes pruefen.
  Bekannte Baselinefehler explizit erhalten/dokumentieren, Tests nicht abschwaechen.
- Runde getrennt committen, Status/Ergebnisindex aktualisieren und Task-Branch
  pushen. Bestehende fremde/ungetrackte Dateien bleiben unberuehrt.

## Betroffene Dateien / lokale Pruefung
Erst nach Bestaetigung je Befund unten ergaenzen. Neue Regressionen unter
`scripts/tests/review_cycles_20261103_*`, Evidenz und neue Roster-Metadaten unter
`output/review_cycles_20261103/`. Produktive Ownership bleibt bei SimulationRoot,
Runtime/Contracts und Registries; UI/Visuals bleiben Leseschichten.

## Risiken / offene Punkte
Unvollstaendige Review-Abdeckung ist keine Bugfreiheit. Headless-Tests ersetzen
keine native FPS-/GPU-/Release-Abnahme. Der vorhandene TASK_348-Baselinefehler
bleibt bis zu einem passenden bestaetigten Fix separat sichtbar.

## Rundenstatus
- [x] Runde 1: Review, bestaetigte Befunde, Fixes und Regressionen.
- [x] Runde 2: erneuter Review des neuen Stands, Fixes und Regressionen.
- [x] Runde 3: erneuter Review, Fixes und gezielte Regressionen.
- [ ] Unabhaengiger Abschlussreview, gezielte Commits und Task-Push.

## Bestaetigte Ursachen / Testziele
### Runde 1 - Fireteam-Autoritaet
Der Netzwerkcontract vertraut bei Unit-Commands der behaupteten `fireteam_id`
vor der Fireteam-Zuordnung der bekannten Unit. Peer-Zugriff muss die auf der
Authority bekannten Ziel-Units und alle tatsaechlich kommandierten Fireteams
abdecken. Eine Payload darf durch andere Labels keine Rechte erweitern.
Legitime eigene Units, Commander-/Hostrechte und bisher erlaubte Payloads
bleiben kompatibel. Contract: `multiplayer_authority_command_contract.md`.

### Runde 2 - Cooldown-Zeitbasis
Der spaeter eingefuehrte Combat-Decision-Throttle kehrt vor den drei relativen
Cooldown-Zaehlern zurueck. Deren unveraenderte Tickwerte muessen weiterhin pro
Simulationstick ablaufen; die teure Ziel-/Feuerentscheidung bleibt gethrottelt.
Die Regression prueft den echten Driver-Tickpfad statt nur die drei Helfer.

### Runde 3 - Terrain-Preview und Visual-Lifecycle
Commander-Area-Order-Preview projiziert fuer kleine Bildschirmrechtecke alle
Tiles. Begrenzte Kandidaten muessen dieselben Tilezentren in derselben Reihenfolge
wie der bisherige exhaustive Pfad liefern, auch bei Hex, H0-H2 und Kamera-Yaw.
Ausserdem muss eine nach `render_map()` unveraenderte Contact-Heatmap wieder
sichtbar sein, ohne dass UI/Visuals Gameplay-Kontakte mutieren.
Der Nachreview prueft zusaetzlich FoW-Deltas innerhalb des Heatmap-Intervalls:
Ein normaler Kontaktrefresh darf den zuvor unterdrueckten Layer erst freigeben,
wenn die gecachten Zellen zur aktuell erlaubten Quellenlage passen. Das Intervall
darf erhalten bleiben, waehrend alte unerlaubte Zellen unsichtbar bleiben.

Betroffene produktive Pfade: `multiplayer_command_contract.gd`,
`mission_combat_loop_driver.gd`, `terrain_map_3d_view.gd` sowie zugehoerige Tests.
Jeder Kandidat wird vor dem jeweiligen Produktivfix durch RED verifiziert.

## Ergebnis Runde 1
- P1 behoben: Fireteam-Rechte verwenden bekannte Runtime-Zuordnung; widersprechende
  Payload-Hinweise koennen keine Unit umetikettieren. Nur fuenf Produktionszeilen.
- Echte Authority-Fixture RED 13/9 -> GREEN 22/0. Sechs relevante alte Gates
  (166, 1186, 1083, 1099, 1100, 1114) ebenfalls strikt gruen; effektiv sieben
  Gates / 151 Assertions. Unabhaengiger Nachreview APPROVED.
- Erstes Testfixture nutzte versehentlich lokalen Non-Authority-Bypass; korrigiert,
  Originalcontract exakt fuer erneuten RED eingesetzt und Fix per SHA256 wieder
  hergestellt. Keine Assertions abgeschwaecht, Rohberichte bleiben erhalten.
- Alle Runtime-Laeufe isoliert; Rosterbytes, Laenge und Schreibzeit unveraendert.

## Ergebnis Runde 2
- Erneuter unabhaengiger Review auf dem nach Runde 1 korrigierten Stand bestaetigt
  die Zeitbasisregression. Bestehenden Cooldownblock vor den Decision-Return
  verschoben; alle Authority-/Startup-/Missionsende-Gates bleiben davor.
- Realer Driver-Ticktest RED 9/10 -> GREEN 19/0. Teure Entscheidungen laufen
  weiterhin nur auf jedem dritten Simulationstick; absolute Return-Fire-Grenze
  bleibt unveraendert. Der Fixture-Pausecheck ist keine gesamte Pause-Abnahme.
- Sechs Gates / 191 Assertions strikt gruen: neuer Tickpfad, Medic-Support,
  Discipline, Misidentification, Combat-Authority und Tick-Budget. Tatsaechlicher
  Diff und Rawreport unabhaengig APPROVED.
- Erster Testlauf hatte einen typisierten Array-Fixturefehler und wurde gezielt
  beendet; unveraenderte Erwartungen danach als korrektes RED geprueft. Die
  Rohhistorik bleibt erhalten. Roster weiterhin unveraendert.

## Ergebnis Runde 3
- Frischer Review nach Runde 2 bestaetigt Area-Vollscan und verlorenen Heatmap-
  Layer. Area RED 16/2 -> GREEN 18/0; Rebuild-Lifecycle RED 14/8 -> GREEN 22/0.
- Area-Preview 128x128/256x256: statt 16384/65536 Projektionen und 32769/131073
  Tile-Positionslesungen jetzt jeweils 25 Projektionen und 51 Lesungen. Original-
  Auswahl, Quellreihenfolge, Square/Hex/H0-H2/Yaw und grosse Fallbacks erhalten.
- Nachreview fand zusaetzlich den vorzeitigen FoW-Visibility-Reset im Heatmap-
  Intervall. Eigene Regression RED 18/2 -> GREEN 20/0; Unterdrueckung bleibt bis
  zu sicherem Signaturtreffer oder fertigem Rebuild bestehen. Intervall unveraendert.
- Zwoelf gezielte Gates / 301 Assertions strikt gruen, inklusive drei FoW-Gates.
  Unabhaengige Actual-Diff-Reviews fuer Area und Heatmap APPROVED.
- Alter TASK377 war auf unveraenderter Basis ebenfalls 20/3. Seine Fixture fuehrt
  nun nach dem oeffentlichen Updateintervall den normalen Kontaktrefresh aus;
  alle 23 Erwartungen erhalten, auch mit Originalview 23/23. Neuer Immediate-
  FoW-Test schuetzt gerade das dabei nicht abgedeckte Drosselfenster.
- Ein erster neuer Timer-Fixturelauf wurde auf monotone Wallclock-Deadline
  korrigiert, passend zur Produktionsuhr. Keine Assertions abgeschwaecht.
- Gemeinsame Abschlussmatrix: `scripts/tests/review_cycles_20261103_checks.json`
  mit 69 unterschiedlichen Gates; Ergebnis und Gesamt-Nachreview folgen.
