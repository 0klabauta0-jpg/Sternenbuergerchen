# Drei weitere Performance-/Architekturrunden, 2026-11-03

## Ziel / Problem
Drei weitere Review-, Fix- und Nachreview-Runden auf dem aktuellen Main
`21bacf0f2f3268cf058f1c5e52381fce4e4b1792`; bestaetigte aktuelle Probleme
gezielt beheben und den gemeinsam geprueften Stand nach Main pushen.

## Sinnhaftigkeit / Ursache
Weitere reale Hotpath- und Ownership-Fehler suchen. Alte Befunde zuerst gegen
den aktuellen Code pruefen; keine Anzahl von Fehlern erzwingen.

## Umfang und Nicht-Ziele
Kleine integrierbare Fixes, Regressionen, unabhängige Nachreviews, gemeinsame
Abschlusspruefung und Main-Integration. Keine neuen Features, Renderqualitaets-
Absenkung, pauschalen Refactors, Assets, Exporte oder Release-Abnahme.
Vorhandene ungetrackte Arbeiten bleiben unangetastet.

## Relevante Dokumente / Contracts
- AGENTS.md; docs/PROJECT_BRIEF.md; docs/ARCHITECTURE.md; docs/CODEX_RULES.md
- docs/IMPLEMENTATION_STATUS.md; docs/TASK_ROADMAP.md
- docs/tasks/REVIEW_CYCLES_2026_11_03_performance_architecture.md
- docs/dev/runtime_script_layout_contract.md
- Weitere owning Contracts werden pro bestaetigtem Befund ergaenzt.

## Akzeptanzkriterien
- [ ] Drei Review-/Fix-/Nachreview-Runden abgeschlossen.
- [ ] Neue Regressionen vor jedem Produktfix korrekt RED, danach GREEN.
- [ ] Performanceaussagen durch gleiche Workloads/Operationen belegt.
- [ ] Alle Godot-Laeufe ausschliesslich sequenziell ueber
  scripts/tests/run_review2_isolated.py mit frischen Nutzerdaten und Pfadguard.
- [ ] Originalroster SHA256, Laenge und Schreibzeit vor/nach jedem Lauf gleich.
- [ ] Abschlussmatrix und unabhaengiges Gesamt-Nachreview bestanden.
- [ ] Nur Taskdateien committed, Main konfliktfrei integriert und Push verifiziert.

## Betroffene Dateien
Diese Taskdatei; Befund-spezifische Produkt-/Regressiondateien folgen nach Review.
Evidence unter output/review_cycles_4_6_20261103/.

## Lokale Pruefung
Neuer unabhaengiger Roster-Baseline/Sicherheitsabzug ausserhalb des Repositorys;
bewaehrter unveraenderter Isolationsrunner mit synchronem Userdata-Guard.
Gezielte RED/GREEN-Gates, angrenzende Regressionen, gemeinsame Abschlussmatrix.
Kein direkter Godot-Start im echten Profil. Keine automatische Wiederherstellung.

## Risiken / offene Punkte
Headless-Operationsmessungen sind keine native FPS-/GPU-Abnahme.
Keine unbestaetigten Review-Ideen implementieren. Native Langzeitperformance
und bereits bekannte Altfehler bleiben getrennt ausgewiesen.

## Runden / Befunde / Ergebnisse
### Runde 1: P1 Reset ohne erfolgreiches Pflichtarchiv
`PlayerRosterStore.reset_roster()` ignoriert einen Fehler beim Archivieren und
ueberschreibt danach den aktiven Save. Der reale MainMenu-Consumer ersetzt auch
bei fehlgeschlagenem Reset sein In-Memory-Team und verbraucht den Resetindex.
Contract: docs/dev/player_roster_save_contract.md. Ziel: bei bestehendem Save
und erforderlichem fehlgeschlagenem Archiv kein Generieren/Speichern, Original
zurueckgeben, Anzeige/Index erhalten; erfolgreicher Reset, erster Save und
expliziter Archivverzicht bleiben kompatibel. Regression nutzt nur eigene
user://-Pfade und echten Store sowie MainMenu; RED vor Produktfix gespeichert.

#### Zusaetzlicher P2-Befund aus dem Repro
Mehrere unveraenderte Seeds erzeugen legitime effektive Pilot-Toughness unter
0.22: Basis 0.46, Jitter bis -0.10, Trait `reckless` -0.15 ergibt bis 0.21.
Der Validator wendet faelschlich die untere Basis-Generierungsgrenze auf bereits
trait-adjustierte Werte an und lehnt somit echte erzeugte Teams beim Speichern
ab. Eigener Repro vor Fix; den bestehenden 0..1-Skillvertrag validieren, weder
Basiswerte noch Traits oder effektive Werte veraendern. Contract:
docs/dev/character_roster_generation_contract.md.

### Runde 2: HPA-Cache-Hotpath
Vor jedem Cache-Hit materialisiert SimulationRoot alle Terrain-Tiles nur fuer
deren Anzahl. Preliminary RED 29/3: acht Hits materialisieren 131072/524288
Tile-Referenzen auf 128x128/256x256. Ziel: konstante Registry-Zaehlerabfrage bei
unveraenderter Identity-/Count-/Revision-Invalidierung, Legacy-Fallback erhalten.
Owning Report: docs/performance/navigation_pathfinding_los_profile_report.md.

### Runde 3: Status-Badge-Invalidierung
Review untersucht fehlende Badge-Inputs im gecachten Unit-Visual-Payload.
Erst realen normalen Sync-Pfad reproduzieren, dann kleinen Cachefix festlegen.

## Ergebnis Runde 1
- Effektiv-Skill-Domain RED 15/13 -> GREEN 34/0; identische Seeds und Werte
  behalten. Bestehender TASK232 ebenfalls gruen.
- Archivfehler nach Domainfix korrekt RED 32/15 -> Helper-GREEN 47/0.
  Unabhaengiger Nachreview fand auch den echten Button-Consumer: RED 58/5.
  Callback oeffnet Editor nur nach Erfolg; finaler Verifier 65/65, unabhaengig
  APPROVED. Fuenf angrenzende Store-/Roster-/UI-Gates ebenfalls gruen.
- Zunaechst falsche Archiv-Diagnoseannahme an Windows angepasst (Directory-
  oder Writefehler desselben Blockerpfads). Kein Seed ausgetauscht. Finale
  Button-Retry-Fixture liest tatsaechliche Archiveintraege, da ein erfolgreicher
  Editor-Save regulaer die Last-Store-Metadaten ersetzt. Rohhistorie erhalten.
- Produktdateien: start_roster_generator.gd, player_roster_store.gd,
  main_menu_screen.gd; owning Contracts character_roster_generation und
  player_roster_save. Alle Laeufe isoliert, Originalroster unveraendert.

## Ergebnis Runde 2
- Auf dem nach Runde 1 korrigierten Stand RED 35/3, danach GREEN 38/0.
- Acht Cache-Requests auf 128x128/256x256: 8 Tilelisten mit 131072/524288
  Referenzen -> 0 Listen/0 materialisierte Referenzen. Identischer echter
  17-Zellen-Pfad und Graph; Full-/Dirty-Rebuild- und Legacy-Verhalten erhalten.
- Neun gezielte Navigation-/Hex-/Tuer-/Registry-Gates strikt gruen.
  Unabhaengiger Actual-Diff-/Evidence-Nachreview APPROVED.
- Vier Getterzeilen und eine Consumerzeile, keine neue Cache-Wahrheit und
  keine FPS-/GPU-Aussage. Nutzerdaten weiter isoliert/Roster unveraendert.
