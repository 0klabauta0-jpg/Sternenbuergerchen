# Vollständige Korridortopologie an Planer und Owner anbinden

Ziel/Ursache: Der lokale64-Graph darf lange Engstellen nicht als fertige
Teilgruppen freigeben. Übernommene Helfer4753975d8/472f1ad8f werden hinter
derselben Registry verwendet; Zusagen bleiben ausschließlich im Ground-Owner.

Umfang: Registryreadadapter, kanonischer Türfallback im neuen Cache,
Planerabfrage und unabhängige Ownerprüfung vollständiger Gruppen. Kleine
Runnercases verwenden originale Cachefixture und tatsächliche Integration.
Keine Actortransforms, aktiven Karten, Save-/Netzwerk- oder großen Tests.

Verträge: hex_corridor_topology_cache_contract.md, hex_reservation_plan_contract.md,
explicit_hex_ramps_contract.md, hex_tactical_runtime_contract.md. Dateien:
TerrainRegistry, HexCorridorTopologyCache, BottleneckReservationResolver,
HexGroundRuntime, isolierter Runner und neue kleine Integrationsfixture.

Akzeptanz: maximal64 neue Knoten pro Query; vollständige Komponente vor Grant;
Fortsetzung über Aufrufe, leere Pending-Ergebnisse verlieren keine Requests.
Unabhängige ältere Pendingjobs blockieren fertig bekannte aktuelle Punkte nicht.
Owner liest denselben Kontext mit0 Baubudget und akzeptiert keine abgeschnittenen
Gruppen. Terrainänderungen dürfen bestehende Gruppen nicht dauerhaft sperren.
Runtime-Türfallback stimmt mit Registry-API überein, Rampenregeln bleiben erhalten.

Lokale Prüfung: originale18 Cachechecks, RED/GREEN der echten Integration,
danach nur betroffene Planer-/Owner-/Cachefälle. Schematische80-Felder-Linie
prüft die64+16-Fortsetzung, kein großes Gefecht oder Framerateversuch.

Risiken: Nodebudget zählt neue Klassifikationen; Kopieren/Ordnen fertiger
Komponenten und Pfadlisten sind zusätzliche CPUarbeit, noch nicht profiliert.
Kein allgemeines Deadlockfreiheitsversprechen; AP5-Ausführung und AP6–8 folgen.

Ergebnis: Cache18/0, Integration15/0, Planer26/0, ReservationOwner36/0,
Topologie23/0, RootOwner51/0. Frischer Review fand stale ferne Ausfahrt;
RED12/3, GREEN15/0 mit aktueller Ein-/Austrittskante und Indexadjazenz im Gang.
Enge Nachprüfung ohne offenen Befund. QA hex_corridor_integration_20261111.
