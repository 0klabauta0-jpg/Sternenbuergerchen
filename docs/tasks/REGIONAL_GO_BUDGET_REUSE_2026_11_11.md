# Ungenutztes regionales GO-Suchbudget unter wenigen Jobs verwenden

## Ziel / Ursache
Der reguläre B-GO liefert synchron Aufträge, danach wartet Bewegung auf die
vollständige regionale Route. Trotz96 Expansionen Gesamtbudget werden bei
zwei wartenden Personen nur2×24=48 je Tick verwendet. Der Rest verfällt.
Keine künstliche2s-Reaktionspause wurde im tatsächlichen Movepfad gefunden.

## Basis / Umfang / Nicht-Ziele
Bestehender isolierter Taskbranch task/native-glut-maps-20261110 auf7ef57c931
mit anderer autorisierter WIP. Nur bestehende Admission-/Slicezuordnung in
SimulationRoot ändern. Nach unveränderter Auswahl höchstens vier Jobs,
Priorität/Least-recent-service/Eingangsreihenfolge beibehalten. Die96 werden
unter den zugelassenen Jobs gleich aufgeteilt:1/2/3/4+→96/48/32/24.
Eine frühe Fertigstellung muss Restbudget nicht in zweiter Runde weitergeben.
Außerhalb eines Physikticks bleibt der24er-Slice unverändert.
Keine vorgezogene Teilroute, Kosten-/Heuristik-/Kollisionsänderung,
keine zusätzlichen Suchobjekte für nicht zugelassene Jobs. Kein Kartenschrumpfen,
GPU-/Nativejob, Main/EXE/Commit/Push durch diesen Worker.

## Quellen / Verträge
AGENTS.md, ARCHITECTURE.md, CODEX_RULES.md;
REGIONAL_FIRST_GO_NAVIGATION_2026_11_11.md;
QA navigation_first_go_20261111, combat_frame_accounting_20261111;
SimulationRoot und TerrainPathfinder. Rootfreigabe: enger Budgetfolgefix.

## Akzeptanz / Dateien
- Gesamt96 je Tick und maximal vier zugelassene Jobs unverändert.
-1/2/3Jobs nutzen96/48/32, vier oder mehr weiter24 je zugelassenem Job.
- Sechs Jobs rotieren weiter fair; kleine Aufträge verhungern nicht.
- Kein zusätzlicher Search-/Kostenkontext für nicht zugelassene Jobs.
- BegrenzteQueries=0/2 bleiben respektiert; Suchpartitionierung außerhalbTick24.
- Gleiche vollständige Routen/Kosten wie24er-Oracle, keine Bewegung vor Route.
- Bestehende Revision-/Kosten-/Hold-/Kollisions- und Bewegungschecks bleiben.
Dateien: scripts/core/simulation_root.gd, neuer regional_go_budget_reuse_test.gd,
eigener Task und docs/qa/regional_go_budget_reuse_20261111.

## Prüfung / Risiken / offene Punkte
RED/GREEN mit echten SimulationRoot-/TestUnit-/Registry-Calls auf kleiner
kontrollierter Hexgeometrie; Registry-Fixture meldet regionale Kartengröße,
um exakt den großen-Map-Pfad zu prüfen. Tatsächliche Expansionen/Suchobjekte,
Ticks bis Route/Bewegung und CPU-Kosten getrennt erfassen. Private APPDATA.
Größere Einzelslices können CPU-Arbeit anders über Frames verteilen, obwohl
Gesamt96 gleich bleibt. CPU-Zahlen während Artparallelität sind Diagnose,
keine FPS-Freigabe. Isolierter nativer B-1×-Vergleich erst nach Rootfenster.
Keine zusätzliche produktive Traceinstrumentierung in diesem engen Schritt.

## Ergebnis / noch offene native Abnahme
Minimaler Admission-Anteilfix umgesetzt. Neuer Verifier RED37/9→GREEN37/0;
passende bestehende Nav-/Lifecycle-/Token-/Korridorchecks15/0,14/0,51/0,
10/0,15/0,36/0. Kontrollierte Umwegrouten exakt identisch, erster physischer
Move1Job96→24Ticks,2Jobs96→48Ticks. CPU-Tradeoff größerer Einzelslices ist
in QA ausdrücklich dokumentiert. Kein neuer Tracepfad, kein Nativejob.
Quelle/alter24er-Stand und Rohdaten unter regional_go_budget_reuse_20261111.
