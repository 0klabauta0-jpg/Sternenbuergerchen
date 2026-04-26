# TASK_128 - Navigation Budgeting und Debug

## Ziel
Navigation soll messbar und budgetiert werden, damit mehrere Units nicht gleichzeitig teure Pfadqueries ausloesen und CPU-Spitzen verursachen.

## Status: IMPLEMENTIERT

## Voraussetzung
- `TASK_126 - HPA Navigation Foundation`
- `TASK_127 - HPA Pathfinder Integration`

## Kontext
- Godot empfiehlt, Path-Queries nicht jedes Frame fuer alle Agents neu zu starten.
- Unser System cached Pfade im Command, kann aber bei Kontakt und bei Fallbacks mehrere Queries in kurzer Zeit erzeugen.
- Nach HPA-Integration brauchen wir klare Messwerte, ob die neue Struktur wirklich CPU-Spitzen reduziert.

## Umfang
1. Pfadquery-Metriken erfassen:
   - Query-Anzahl pro Tick
   - Query-Dauer
   - HPA vs. direkter A*
   - Fallback-Queries
   - unerreichbare Ziele
   - grob: expandierte Knoten oder getestete Kandidaten
2. Navigation-Budget in `SimulationRoot` oder einem kleinen Navigation-Service einfuehren:
   - maximale neue Pfadqueries pro Physics-Tick
   - Queue fuer verzoegerte Pfadqueries
   - deterministische Reihenfolge nach Command-Prioritaet und Eingangsreihenfolge
3. Kontakt-Recompute staffeln:
   - nicht alle Fireteam-Mitglieder im selben Tick neu planen
   - bestehendes `CONTACT_PATH_RECOMPUTE_INTERVAL_MSEC` respektieren oder ersetzen
4. Debug-Snapshot bereitstellen:
   - letzte Queries
   - teuerste Query
   - pending Query Count
   - Grund fuer Fallback/Delay
5. Optional lesbare Debug-Zeile im Tactical Controller erweitern, aber nur abschaltbar.

## Nicht-Ziele
- Keine neue taktische Bewegungs-KI.
- Kein Worker-Threading.
- Keine Multiplayer-Synchronisierung von Navigation-Metriken.
- Keine UI-Pflichtanzeige im normalen Spiel.

## Architekturregeln
- Budgeting darf Movement nicht im UI verstecken.
- Verzoegerte Queries muessen deterministisch bleiben.
- Debug ist rein lesend und abschaltbar.
- Kein per-frame Vollscan aller Units.

## Akzeptanzkriterien
- [x] Pfadqueries werden gezaehlt und als Snapshot lesbar.
- [x] Pro Tick wird ein konfigurierbares Query-Limit eingehalten.
- [x] Mehrere gleichzeitige Commands werden deterministisch ueber mehrere Ticks abgearbeitet.
- [x] Kontakt-Recompute erzeugt keine Query-Spitze fuer alle Units im selben Frame.
- [x] Unerreichbare Ziele werden im Debug klar markiert.
- [x] Bestehende Movement- und Area-Tests bleiben gruen.

## Erwartetes Ergebnis
- Navigation-CPU-Last wird sichtbar und kontrollierbar.
- HPA-Nutzen kann lokal verglichen werden.
- Spaetere Optimierungen koennen datenbasiert statt nach Bauchgefuehl entschieden werden.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_128_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_127_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_125_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_110_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/fireteam_dev_testing_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/path_recompute_under_fire_verifier.gd`

## Dateien
- `scripts/core/simulation_root.gd`
- `scripts/tests/task_128_verifier.gd`

## Ergebnis
- `SimulationRoot` besitzt jetzt ein konfigurierbares Budget fuer neue Pfadrequests pro Physics-Tick.
- Budget-Delays werden deterministisch ueber die bestehende Command-Reihenfolge nach Prioritaet und Eingangsindex requeued.
- `get_navigation_debug_snapshot()` liefert Zaehler, Pending Count, Delay-/Fallback-Grund, letzte Queries, teuerste Query und unreachable-Markierungen.
- Contact-Recompute nutzt denselben Budgetpfad und kann dadurch nicht mehr alle Units im selben Tick neu planen.

## Risiken
- Query-Budgeting kann sichtbare Startverzoegerung erzeugen, wenn zu viele Units gleichzeitig neue Befehle erhalten.
- Deshalb muss die Queue nach Prioritaet arbeiten und der Debug pending Queries sichtbar machen.
