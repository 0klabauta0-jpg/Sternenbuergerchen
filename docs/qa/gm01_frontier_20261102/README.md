# GM01 Frontier – Prüfung und Übergabe

Die reguläre Standardkarte ist mit den vorhandenen Frontier-Grafiken neu gebaut. Auf die weiteren Nutzerwünsche wächst sie auf **48×48 echte Hexfelder** (2304 Zellen, etwa 48×41 Meter in der Spielebene). Es gibt den ursprünglichen Außenposten, einen östlichen Versorgungshof, zwei Zufahrten, zusätzliche Felszüge und dezente sichtbare Hexkanten.

Der historische Pfad `maps/Ground_Mission01_32x32.json` bleibt für bestehende Szenarioreferenzen erhalten. Der tatsächliche Kartenname, die Topologie und alle 2304 gespeicherten Zellen entsprechen dem neuen Inhalt. Das Szenario einschließlich acht Gegnern, Taktiken, Zeitlimit und Zielradius bleibt bytegleich.

## Maßgeblicher Stand

- `VERIFIKATION.json`: letzte akzeptierte Einzelgates, native Startläufe, Auflösungen und Umfang.
- `SOURCE_SNAPSHOT.json`: bytegenaue Quellen- und Asset-Hashes.
- `frontier_capture_results.json`: je Auflösung der letzte vollständig bestandene normale Start mit PNG-/Quellberichtspfaden.
- `cover_query_comparison.json`: gezielter CPU-Vergleich, Rohdaten in den verlinkten Vorher-/Nachherdateien und `cover_radius_query_pairs_*.json`.
- `STALE_GATES.md`: Nachweis, warum alte englische Buttontexte und dauerhaft offene Detailpanels bereits vor dem Cache nicht mehr zum R4-UI passten.
- [Workbench](../../reports/STERNENBUERGERCHEN_GM01_FRONTIER_2026-11-02.html): echte Vorher-/Nachherbilder, Gründe und lokale Feedbackfelder mit JSON-Export.

Die zuletzt akzeptierten **24 Engine-Gates mit 881 Assertions** sind grün. Dazu kommen **102 Checks in zwei vollständigen nativen Startläufen** bei 1920×1080 und 1280×720. Beide akzeptierten Prozesse enden mit Exit0 ohne Script-/Leakfehler. Jede Auflösung wurde tatsächlich so gerendert; keine nachträglich verkleinerten Ersatzbilder.

## Was geprüft wurde

Deterministische Autorierung, echte Hexnachbarn, negative Axialkoordinaten, breite A*/HPA-Routen, die tatsächlichen Spawnabstände, Rampenübergänge, Save/Load, Editor-Schutz, Kamera und Minimap. Zwei Legacy-Vergleiche sichern die identischen Coverergebnisse und die Auswahlreihenfolge ab. Briefing-, Loadout-, Readiness-, Boarding-, Handoff- und Startfreigaben werden mit den bestehenden fachlichen Gates geprüft.

Der normale Start verwendet die echten Menü-/Heimatbasis-/Missionsaktionen, die gespeicherte GM01, den zeitgesteuerten Transfer, LZ-Auswahl, Cutlass-Anflug, Entladung und Move/GO. Actors, Positionen, HP und Timer wurden dafür nicht gepatcht; es gibt keine Zeitbeschleunigung. Die Kameraansichten des Osthofs und der Gesamtkarte werden erst nach diesem Ablauf aufgenommen. Sie beweisen keinen tatsächlichen Truppmarsch zum entfernten Osthof.

TASK1179 ist zusätzlich ein **beschleunigter Objective-/Navigation-/Debrief-Logiktest** mit seinen vorhandenen Deployshortcuts. Er ersetzt den physischen Startlauf nicht.

## Das kleinere Quadrat und das schwarze Aufblitzen

Das frühere dunkle Quadrat war die Sichtmaske der gespeicherten Zellen über einer größeren durchgehenden Bodenfläche. Bei ihrem schrittweisen Aufbau kam zusätzlich kurz ein schwarzer Schutzkasten zum Einsatz.

Im Standardmodus `known_terrain` ist das Terrain bereits bekannt. Hier erscheint dieser Kasten jetzt nicht mehr. Dynamische Feinde bleiben separat gefiltert. `unexplored_blackout` behält den Schutz; die Masken reichen über die tatsächlichen hohen Modelle. Die neue Hexmaske besteht aus sechs flachen Dreiecken statt doppelten Prismenseiten. Ein Mehrframe-Gate prüft den bekannten Modus einschließlich erzwungenem Neuaufbau und den weiterhin geschützten unbekannten Modus.

## Gemessene Engpässe und gezielte Korrekturen

Die größere Hexkarte legte bestehende Kosten offen. Die Coverauswahl bewertete identische Kandidaten mehrfach und fragte für weit entfernte Zellen unnötig Walkability und Deckung ab. Ein lokaler Scorememo und die vorgezogene Distanzprüfung erhalten Ergebnisse, Reihenfolge, LOS, Range, Overrides und Gegnerregeln.

Für acht feste Abfragen auf derselben echten Karte sank der Median von **20,8 auf 2,4 ms**, gemessen in 32 alternierenden warmen Paaren. Das ist ein **Headless-CPU-Funktionstest**, kein Gesamt-FPS-Nachweis. Die tatsächlichen nativen Profile zeigen ebenfalls deutlich geringere Taktikkosten.

Der Transporttimer aktualisierte außerdem die versteckte Heimatbasis: fünf Briefing-Neubauten und bis zu zehn vollständige Kartenladevorgänge pro Aktualisierung. Gemessen wurden über zwei Sekunden im Heimatbasis-Refresh. Der bestehende statische Briefing-Snapshot wird nun bei identischen Inhalts-SHAs wiederverwendet. Gleich große Änderungen innerhalb derselben Sekunde, fehlende/später verfügbare Quellen und neu angelegte Panels sind geprüft. Auswahl, Loadout-Steuerung, Belegung, Readiness und Startbutton bleiben frisch. Die Timer selbst bleiben unverändert.

**Es verbleiben merkliche UI-/Transport-Zeitspitzen. Eine insgesamt flüssige Performance ist nicht abgenommen.** Der reguläre Ablauf besteht die unveränderten Zeitfenster der Startprüfung; das ist kein Langzeit-, Balance-, Mehrspieler-, Kampagnen- oder EXE-Nachweis.

## Wiederholen

Alle Engine-Läufe nacheinander, im Task-Worktree:

```powershell
python docs/qa/gm01_frontier_20261102/import_once.py
python docs/qa/gm01_frontier_20261102/run_isolated_checks.py
python docs/qa/gm01_frontier_20261102/startup_gm01.py
python docs/qa/gm01_frontier_20261102/build_report.py
node docs/qa/gm01_frontier_20261102/html_qa.cjs
python docs/qa/gm01_frontier_20261102/verify_gm01.py
```

Die Wrapper verwenden eigene Userdatenverzeichnisse und stellen `project.godot` bytegenau wieder her. Der vorhandene ältere Hex-Slice-Verifier schreibt einen historischen Ausgabepfad; der Wrapper sichert diesen und stellt ihn wieder her. Alte Reports und die ursprüngliche GM01 sind erhalten.

Optionaler Profilierer: `startup_gm01.py --sizes 1920x1080 --script res://scripts/tests/gm01_frontier_hex_start_diagnostic.gd`. Mit `--observe-seconds 10` entsteht ausdrücklich nur eine kurze Beobachtung; sie aktualisiert keine Normalstartabnahme.

## Verworfene Vorläufe und Grenzen

Vorläufe mit der kleineren Square8-Komposition, roten Gates, Ankunftstimeouts und ein Profilierlauf mit ObjectDB-Warnung bleiben als Rohbelege erhalten. Sie sind nicht als finale Abnahme ausgewählt. Der abschließende normale 1280-Lauf ist ohne diese Warnung sauber beendet. Die Mehrframe-Blackoutprüfung ist ein Engine-/Statecheck, kein vollständiger nativer Sichtbarkeitstest aus allen Kamerawinkeln.

Der erste Headless-Vorlauf erfolgte vor Einrichtung des Isolationswrappers im normalen Userdatenverzeichnis. Es gibt dafür keine Vorherkopie der Profildatei; eine bytegenaue Unverändertheit dieses frühen Profils wird daher nicht behauptet. Alle final ausgewählten Gates und physischen Startläufe sind isoliert.

Das HTML-JavaScript wurde mit einem synthetischen DOM in Node geprüft, einschließlich Tabs, Export, UTF-8-Notizen, Kopieren und Fallback. Browserlayout, echter Browserdownload und Ordnerfreigabe sind damit nicht abgenommen.

Das feste Ensemble ist im Editor gegen freies Bemalen/Löschen/Verschieben geschützt; Ansicht und unveränderter Roundtrip funktionieren. Freie Multi-Cell-Platzierung ist eine spätere Aufgabe. Dieser Branch baut bewusst auf dem noch nicht integrierten UI R4 `49220b59e` mit dessen Main-Grafikbasis auf. Keine Mainintegration und kein Release.
