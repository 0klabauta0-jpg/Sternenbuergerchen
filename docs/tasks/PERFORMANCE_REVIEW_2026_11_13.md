# Performance-Review und begrenzte Reparaturen — 13.11.2026

## Ziel / Ursache
Nutzerauftrag: erneuter Performance-Review und bestätigte Befunde beheben.
Basis origin/main 5196cc08b, eigener Taskbranch; fremdes WIP bleibt erhalten.
Aktuelle Simulation/Hexsicht, UI sowie Laden/Speichern auf vermeidbare Arbeit
prüfen. Frühere Messungen sind Hinweise, kein Beleg für aktuellen Main.

## Umfang / Nichtziele
Quellreview, reproduzierbare CPU-Messungen, kleine verhaltenserhaltende Fixes,
gezielte Regressionen. Keine Reduktion von Grafikqualität, Akteuren, Karten oder
Spielregeln. Keine Desktopbedienung, EXE oder ungemessene FPS-/GPUbehauptung.
Bestätigte Befunde und offene Kandidaten getrennt dokumentieren.

## Verträge
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS, TASK_ROADMAP;
docs/performance/performance_regression_gate.md; relevante Runtime-/Hex-/UI-
Contracts vor betroffenen Änderungen lesen. HTML nach Workbenchvertrag.

## Akzeptanz / Dateien / lokale Prüfung
Vorher/Nachher dieselbe Last und Engine, rohe Messwerte und Kontext aufheben.
Jeder Produktfix braucht einen Verhaltenstest, bei Caches auch Invalidierung,
Instanzwechsel und begrenzte Lebensdauer prüfen. Keine zweite Gameplaywahrheit.
Betroffene Dateien nach Bestätigung ergänzen; Evidenz unter
docs/qa/performance_review_20261113/. Bericht samt privater Website aktualisieren.
Nur relevante Dateien committen/pushen, Mainintegration nach erfolgreichen Checks.

## Risiken / offen
Headless CPU ist keine native Render-/GPUabnahme. Zeitmessungen seriell und ohne
gleichzeitige Imports durchführen. Wachhalteprozess nur für diese Sitzung.

## Bestätigte Quellkandidaten / Akzeptanz Hexcache
HexSightRuntimeAdapter fragt query_hex_visibility an, CombatVisibilityCache
implementiert es bisher nicht. Wiederholte Hexsichtpaare fallen dadurch auf
neue LOS-Abfragen zurück. Terrainantwort je Tick teilen; Range/Facing stets
frisch prüfen. Positions-, Höhen-, Registry- und Terrainrevisionswechsel müssen
sofort frisch rechnen. Cache begrenzen und am Tickwechsel leeren, keine Exporte.
Reproduzierbarer Adapterbenchmark: identische 64 gerichtete Paare, je vier
Leser pro Tick, 30 Samples nach Warmup. Gegen reine Queryantworten vergleichen.

## Ergebnis
Drei bestätigte CPUprobleme behoben: Hexterraincache 27/0, Teamfanout 11/0,
schmaler Encounterread 18/0. Echte Kampagnen-Readmessung 9/0, Frontier 76/0,
Legacycache über 600 Ticks 12/0, bestehender Hex-ENet-Nachbar 24/0; insgesamt 177/0.
Je 30 Samples: Hexmedian −40,2 %, Netzwerkpacken −66,5 %, Encountergetter −99,9 %
verborgen bzw. −99,7 % sichtbar (20 Aufrufe). Keine Gesamtspiel-/FPSaussage.
Alle Verhaltens-, Quellen- und Profilguards grün. Vier Produktdateien: SimulationRoot,
CombatVisibilityCache, CampaignSpaceEncounterPresenter, SingleplayerRuntimeAdapter.
Personenvisualsnapshots bleiben ungemessener Kandidat. Vollständige Evidenz,
rote Repros, frühe Harnessfehler und Grenzen: docs/qa/performance_review_20261113/README.md.
