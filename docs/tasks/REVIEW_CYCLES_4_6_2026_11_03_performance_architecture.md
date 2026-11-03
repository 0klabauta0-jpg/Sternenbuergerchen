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
- [x] Drei Review-/Fix-/Nachreview-Runden abgeschlossen.
- [x] Neue Regressionen vor jedem Produktfix korrekt RED, danach GREEN.
- [x] Performanceaussagen durch gleiche Workloads/Operationen belegt.
- [x] Alle Godot-Laeufe ausschliesslich sequenziell ueber
  scripts/tests/run_review2_isolated.py mit frischen Nutzerdaten und Pfadguard.
- [x] Originalroster SHA256, Laenge und Schreibzeit vor/nach jedem Lauf gleich.
- [x] Abschlussmatrix ohne neue Regressionen und unabhaengiges Gesamt-Nachreview;
  etwaige Altfehler separat am Original-Main nachweisen und offen ausweisen.
- [x] Nur Taskdateien committed, Main konfliktfrei integriert und Push verifiziert.

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
Unvollstaendiger Waffen-/Vital-Payload unterdrueckt eigenstaendige Badge-Updates.
Eigene abgeleitete Signatur erfasst Text/Farbe/Stil, Declutter und Sichtbarkeit,
ohne schwere Aim-/Vitalarbeit bei reinen Badge-Aenderungen auszufuehren.

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

## Ergebnis Runde 3
- Nach Runde 2 erneut korrekt RED 25/11 -> GREEN 36/0: normale Frame-Updates
  fuer Kontakt/Command/Status, Overwatch-Farbe, echten Respawn-Timer, Declutter
  und Wiederanzeigen; bestehende Proxy-/Labelidentitaet und explizites Redraw.
- Eigenstaendige Badge-Signatur aus aktuellen Anzeigeausgaben, rein lesend;
  schwere Aim-/Vital-Signatur bleibt getrennt. Unabhaengige Slice- und
  Gesamt-Code-Nachreviews APPROVED.
- Fuenf gezielte Gates: neue Regression, TASK1188, TASK842 und TASK459 gruen.
  TASK839 29/2: vorgelagertes TASK838-Gesamtgate source_findings_polish_passes.
  Exakt Original-Main-Bytes aller sechs geaenderten Produktdateien temporaer
  eingesetzt: identisches 29/2 und identische Fehlerlabels. Danach alle sechs
  Fixbytes per finally/SHA wiederhergestellt. Keine Assertions geaendert.
  Ursache unterhalb von TASK838 ist damit nicht geklaert; keine Verknuepfung
  zum bereits bekannten TASK348 behaupten. In der gemeinsamen 85er-Matrix
  bleibt der Altfehler enthalten und wird explizit ausgewiesen.
- TASK1188, derselbe 28-Unit-/60s-Headless-Workload: p99 3370 -> 4904 us,
  jeweils 8696 Frames und 31/31 Assertions; beide unter 8000 us. Das einzelne
  Paar zeigt Mehraufwand, keine Beschleunigung oder gesicherte Kausal-/Streuung.
  Keine native Bild-, FPS- oder GPU-Abnahme.
- Erstes Badge-Fixture nutzte `idle`, das bei `assigned` zu anderer Postur
  normalisierte. Feste erkannte `crouch`-/`lowered`-Postur isoliert reine
  Statuswechsel; keine Anzeige-/Operations-Erwartung abgeschwaecht.

## Gemeinsame Abschlussmatrix
Auf Sourcecommit `48f96221b807fb2971207f3ec9133b91a0f785a2` in einem
sequenziellen Lauf 85 Gates: 84 PASS mit 2747/2747 Assertions, ein original
bestaetigter TASK839-Baselinefehler 29/2. Gesamt 2776 PASS/2 FAIL-Assertions,
alle vier neuen Verifier 173/173. Kein unbekannter neuer Fehler. TASK839 bleibt
in der Matrix; Tests unveraendert. Bekannten TASK348 nicht erneut geprueft.
TASK1188 im Gesamtlauf p99 4346 us (<8000), 8696 Frames/60004 ms, 31/31.
95 Source-/Test-/Harness-/Projektfingerprints stimmen mit Testcommit und
Arbeitsbytes ueberein. 129 protokollierte Laeufe mit frischen eindeutigen
Userdata-Verzeichnissen, Originalroster SHA/Laenge/Schreibzeit gleich.
Nach diesem Stand nur Doku/Evidence. Gesamtindex und Rohreport:
`output/review_cycles_4_6_20261103/verification_summary.json`,
`final_suite/20261103T044414Z-5b8b1e6c/report.json`.

## Main-Abschluss
Main konfliktfrei per Fast-forward uebernommen. Auf `7210f6752` zusaetzlich
vier neue Verifier und Canary isoliert: 5/5 Gates / 173 Assertions gruen,
alle 95 Quellfingerprints identisch mit dem gemeinsamen Sourcecommit.
Main und Task-Branch nach erfolgreichem Smoke normal gepusht und beide
Remote-IDs `7210f6752` abgeglichen. Anschliessend nur Doku-/Evidence-Nachtrag,
keine Produkt-/Testaenderung. Insgesamt 134 getrennte Isolationslaeufe,
Originalroster SHA256/Laenge/Schreibzeit unveraendert. Abschlussreport:
`output/review_cycles_4_6_20261103/main_smoke/20261103T045507Z-c8d9c375/report.json`.
